import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/vault.dart';
import '../models/note.dart';

class VaultService {
  static const String _vaultsKey = 'vaults';
  static const String _currentVaultKey = 'current_vault';

  /// Get all saved vaults
  Future<List<Vault>> getVaults() async {
    final prefs = await SharedPreferences.getInstance();
    final vaultsJson = prefs.getString(_vaultsKey);

    if (vaultsJson == null) return [];

    final List<dynamic> vaultsList = jsonDecode(vaultsJson);
    return vaultsList.map((json) => Vault.fromJson(json)).toList();
  }

  /// Save vaults list
  Future<void> saveVaults(List<Vault> vaults) async {
    final prefs = await SharedPreferences.getInstance();
    final vaultsJson = jsonEncode(vaults.map((v) => v.toJson()).toList());
    await prefs.setString(_vaultsKey, vaultsJson);
  }

  /// Get current vault
  Future<Vault?> getCurrentVault() async {
    final prefs = await SharedPreferences.getInstance();
    final vaultJson = prefs.getString(_currentVaultKey);

    if (vaultJson == null) return null;

    return Vault.fromJson(jsonDecode(vaultJson));
  }

  /// Set current vault
  Future<void> setCurrentVault(Vault vault) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentVaultKey, jsonEncode(vault.toJson()));

    // Update last opened time
    final vaults = await getVaults();
    final index = vaults.indexWhere((v) => v.id == vault.id);
    if (index != -1) {
      vaults[index] = vault.copyWith(lastOpened: DateTime.now());
      await saveVaults(vaults);
    }
  }

  /// Create a new vault
  Future<Vault> createVault(String name, String directoryPath) async {
    final vaultPath = path.join(directoryPath, name);
    final directory = Directory(vaultPath);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final vault = Vault(
      id: const Uuid().v4(),
      name: name,
      path: vaultPath,
    );

    final vaults = await getVaults();
    vaults.add(vault);
    await saveVaults(vaults);

    return vault;
  }

  /// Open existing vault
  Future<Vault> openVault(String directoryPath) async {
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      throw Exception('Directory does not exist');
    }

    final vaultName = path.basename(directoryPath);
    final vault = Vault(
      id: const Uuid().v4(),
      name: vaultName,
      path: directoryPath,
    );

    final vaults = await getVaults();
    vaults.add(vault);
    await saveVaults(vaults);

    return vault;
  }

  /// Get all notes in a vault
  Future<List<Note>> getNotesInVault(Vault vault) async {
    final directory = Directory(vault.path);
    final notes = <Note>[];

    if (!await directory.exists()) {
      return notes;
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final note = await _loadNoteFromFile(entity);
        if (note != null) {
          notes.add(note);
        }
      }
    }

    return notes;
  }

  /// Load a note from file
  Future<Note?> _loadNoteFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final title = path.basenameWithoutExtension(file.path);
      final stats = await file.stat();

      final outgoingLinks = Note.extractWikilinks(content);
      final tags = Note.extractTags(content);

      return Note(
        title: title,
        content: content,
        filePath: file.path,
        createdAt: stats.changed,
        modifiedAt: stats.modified,
        tags: tags,
        outgoingLinks: outgoingLinks,
      );
    } catch (e) {
      debugPrint('Error loading note from ${file.path}: $e');
      return null;
    }
  }

  /// Save a note to file
  Future<void> saveNote(Vault vault, Note note) async {
    final file = File(note.filePath);
    await file.writeAsString(note.content);
  }

  /// Create a new note
  Future<Note> createNote(Vault vault, String title, {String? subfolder}) async {
    final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}.md';
    final filePath = subfolder != null
        ? path.join(vault.path, subfolder, fileName)
        : path.join(vault.path, fileName);

    final file = File(filePath);

    if (file.parent.path != vault.path && !await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final note = Note(
      title: title,
      content: '',
      filePath: filePath,
    );

    await file.writeAsString('');
    return note;
  }

  /// Delete a note
  Future<void> deleteNote(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Rename a note
  Future<Note> renameNote(Note note, String newTitle) async {
    final oldFile = File(note.filePath);
    final newFileName = '${newTitle.replaceAll(RegExp(r'[^\w\s-]'), '')}.md';
    final newPath = path.join(path.dirname(note.filePath), newFileName);
    final newFile = await oldFile.rename(newPath);

    return note.copyWith(
      title: newTitle,
      filePath: newFile.path,
    );
  }

  /// Get default vaults directory
  Future<String> getDefaultVaultsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'Geode', 'Vaults');
  }
}
