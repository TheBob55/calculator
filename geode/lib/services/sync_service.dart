import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/vault.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncConfig {
  final String serverUrl;
  final String? authToken;
  final bool enabled;

  SyncConfig({
    required this.serverUrl,
    this.authToken,
    this.enabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'authToken': authToken,
      'enabled': enabled,
    };
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      serverUrl: json['serverUrl'] ?? '',
      authToken: json['authToken'],
      enabled: json['enabled'] ?? false,
    );
  }
}

class SyncService {
  static const String _syncConfigKey = 'sync_config';
  static const String _lastSyncKey = 'last_sync_time';

  SyncStatus _status = SyncStatus.idle;
  String? _error;

  SyncStatus get status => _status;
  String? get error => _error;

  /// Get sync configuration
  Future<SyncConfig?> getSyncConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_syncConfigKey);

    if (configJson == null) return null;

    return SyncConfig.fromJson(jsonDecode(configJson));
  }

  /// Save sync configuration
  Future<void> saveSyncConfig(SyncConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncConfigKey, jsonEncode(config.toJson()));
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);

    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Sync vault with remote server
  Future<void> syncVault(Vault vault, List<Note> notes) async {
    final config = await getSyncConfig();

    if (config == null || !config.enabled) {
      throw Exception('Sync is not configured or not enabled');
    }

    _status = SyncStatus.syncing;
    _error = null;

    try {
      // Get modified notes since last sync
      final lastSync = await getLastSyncTime();
      final modifiedNotes = lastSync != null
          ? notes.where((n) => n.modifiedAt.isAfter(lastSync)).toList()
          : notes;

      // Upload modified notes
      await _uploadNotes(config, vault, modifiedNotes);

      // Download remote changes
      await _downloadNotes(config, vault);

      await _updateLastSyncTime();

      _status = SyncStatus.success;
    } catch (e) {
      _status = SyncStatus.error;
      _error = e.toString();
      debugPrint('Sync error: $e');
      rethrow;
    }
  }

  /// Upload notes to remote server
  Future<void> _uploadNotes(
    SyncConfig config,
    Vault vault,
    List<Note> notes,
  ) async {
    for (final note in notes) {
      try {
        final url = Uri.parse('${config.serverUrl}/notes/${vault.id}/${note.id}');
        final headers = {
          'Content-Type': 'application/json',
          if (config.authToken != null) 'Authorization': 'Bearer ${config.authToken}',
        };

        final body = jsonEncode({
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'filePath': note.filePath,
          'modifiedAt': note.modifiedAt.toIso8601String(),
          'tags': note.tags,
        });

        final response = await http.put(
          url,
          headers: headers,
          body: body,
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('Failed to upload note: ${response.body}');
        }
      } catch (e) {
        debugPrint('Error uploading note ${note.title}: $e');
        // Continue with other notes
      }
    }
  }

  /// Download notes from remote server
  Future<void> _downloadNotes(SyncConfig config, Vault vault) async {
    try {
      final lastSync = await getLastSyncTime();
      final url = Uri.parse('${config.serverUrl}/notes/${vault.id}');
      final headers = {
        'Content-Type': 'application/json',
        if (config.authToken != null) 'Authorization': 'Bearer ${config.authToken}',
      };

      // Add query parameter for incremental sync
      final queryParams = lastSync != null
          ? {'since': lastSync.toIso8601String()}
          : <String, String>{};

      final finalUrl = url.replace(queryParameters: queryParams);

      final response = await http.get(
        finalUrl,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        for (final noteData in data) {
          await _saveRemoteNote(vault, noteData);
        }
      } else {
        throw Exception('Failed to download notes: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error downloading notes: $e');
      rethrow;
    }
  }

  /// Save a remote note to local vault
  Future<void> _saveRemoteNote(Vault vault, Map<String, dynamic> noteData) async {
    try {
      final file = File(noteData['filePath']);

      // Only update if remote version is newer
      if (await file.exists()) {
        final localModified = (await file.stat()).modified;
        final remoteModified = DateTime.parse(noteData['modifiedAt']);

        if (localModified.isAfter(remoteModified)) {
          // Local version is newer, skip
          return;
        }
      }

      // Write file
      await file.writeAsString(noteData['content']);
    } catch (e) {
      debugPrint('Error saving remote note: $e');
    }
  }

  /// Check if sync is configured
  Future<bool> isSyncConfigured() async {
    final config = await getSyncConfig();
    return config != null && config.enabled && config.serverUrl.isNotEmpty;
  }

  /// Test sync connection
  Future<bool> testConnection(SyncConfig config) async {
    try {
      final url = Uri.parse('${config.serverUrl}/ping');
      final headers = {
        if (config.authToken != null) 'Authorization': 'Bearer ${config.authToken}',
      };

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  /// Manual sync with conflict resolution
  Future<Map<String, dynamic>> syncWithConflictResolution(
    Vault vault,
    List<Note> notes,
  ) async {
    final conflicts = <String, Map<String, dynamic>>{};
    final synced = <String>[];
    final failed = <String>[];

    final config = await getSyncConfig();
    if (config == null || !config.enabled) {
      throw Exception('Sync not configured');
    }

    try {
      _status = SyncStatus.syncing;

      for (final note in notes) {
        try {
          // Check for conflicts
          final remoteVersion = await _getRemoteNoteVersion(config, vault, note);

          if (remoteVersion != null) {
            final remoteModified = DateTime.parse(remoteVersion['modifiedAt']);

            if (remoteModified.isAfter(note.modifiedAt)) {
              // Conflict detected
              conflicts[note.id] = {
                'local': note.toJson(),
                'remote': remoteVersion,
              };
              continue;
            }
          }

          // No conflict, upload
          await _uploadNotes(config, vault, [note]);
          synced.add(note.id);
        } catch (e) {
          failed.add(note.id);
        }
      }

      await _updateLastSyncTime();
      _status = SyncStatus.success;

      return {
        'synced': synced,
        'failed': failed,
        'conflicts': conflicts,
      };
    } catch (e) {
      _status = SyncStatus.error;
      _error = e.toString();
      rethrow;
    }
  }

  /// Get remote note version
  Future<Map<String, dynamic>?> _getRemoteNoteVersion(
    SyncConfig config,
    Vault vault,
    Note note,
  ) async {
    try {
      final url = Uri.parse('${config.serverUrl}/notes/${vault.id}/${note.id}');
      final headers = {
        if (config.authToken != null) 'Authorization': 'Bearer ${config.authToken}',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Enable/disable auto sync
  Future<void> setAutoSync(bool enabled) async {
    final config = await getSyncConfig();
    if (config != null) {
      await saveSyncConfig(config.copyWith(enabled: enabled));
    }
  }
}

extension on SyncConfig {
  SyncConfig copyWith({
    String? serverUrl,
    String? authToken,
    bool? enabled,
  }) {
    return SyncConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      authToken: authToken ?? this.authToken,
      enabled: enabled ?? this.enabled,
    );
  }
}
