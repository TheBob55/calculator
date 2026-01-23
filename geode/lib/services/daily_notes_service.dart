import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../models/note.dart';
import '../models/vault.dart';

class DailyNotesService {
  static const String dailyNotesFolder = 'Daily Notes';

  /// Get or create today's daily note
  Future<Note> getTodayNote(Vault vault, List<Note> existingNotes) async {
    final today = DateTime.now();
    final title = _formatDailyNoteTitle(today);

    // Check if today's note already exists
    final existingNote = existingNotes.where((n) => n.title == title).firstOrNull;
    if (existingNote != null) {
      return existingNote;
    }

    // Create new daily note
    return await _createDailyNote(vault, today);
  }

  /// Get daily note for a specific date
  Future<Note> getDateNote(
    Vault vault,
    DateTime date,
    List<Note> existingNotes,
  ) async {
    final title = _formatDailyNoteTitle(date);

    // Check if note exists
    final existingNote = existingNotes.where((n) => n.title == title).firstOrNull;
    if (existingNote != null) {
      return existingNote;
    }

    // Create new daily note
    return await _createDailyNote(vault, date);
  }

  /// Create a new daily note
  Future<Note> _createDailyNote(Vault vault, DateTime date) async {
    final title = _formatDailyNoteTitle(date);
    final dailyNotesPath = path.join(vault.path, dailyNotesFolder);

    // Create daily notes folder if it doesn't exist
    final directory = Directory(dailyNotesPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final fileName = '$title.md';
    final filePath = path.join(dailyNotesPath, fileName);

    // Create note with template
    final content = _getDailyNoteTemplate(date);
    final file = File(filePath);
    await file.writeAsString(content);

    return Note(
      title: title,
      content: content,
      filePath: filePath,
      createdAt: date,
      modifiedAt: date,
    );
  }

  /// Get all daily notes in the vault
  Future<List<Note>> getAllDailyNotes(List<Note> allNotes) async {
    // Filter notes that are in the Daily Notes folder or match the daily note pattern
    return allNotes.where((note) {
      return note.filePath.contains(dailyNotesFolder) ||
          _isDailyNoteTitle(note.title);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get the previous daily note
  Note? getPreviousDailyNote(List<Note> dailyNotes, DateTime currentDate) {
    final previousNotes = dailyNotes.where((note) {
      final noteDate = _parseDailyNoteTitle(note.title);
      return noteDate != null && noteDate.isBefore(currentDate);
    }).toList()
      ..sort((a, b) {
        final dateA = _parseDailyNoteTitle(a.title)!;
        final dateB = _parseDailyNoteTitle(b.title)!;
        return dateB.compareTo(dateA);
      });

    return previousNotes.isNotEmpty ? previousNotes.first : null;
  }

  /// Get the next daily note
  Note? getNextDailyNote(List<Note> dailyNotes, DateTime currentDate) {
    final nextNotes = dailyNotes.where((note) {
      final noteDate = _parseDailyNoteTitle(note.title);
      return noteDate != null && noteDate.isAfter(currentDate);
    }).toList()
      ..sort((a, b) {
        final dateA = _parseDailyNoteTitle(a.title)!;
        final dateB = _parseDailyNoteTitle(b.title)!;
        return dateA.compareTo(dateB);
      });

    return nextNotes.isNotEmpty ? nextNotes.first : null;
  }

  /// Format daily note title (YYYY-MM-DD)
  String _formatDailyNoteTitle(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Check if a title matches daily note format
  bool _isDailyNoteTitle(String title) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return regex.hasMatch(title);
  }

  /// Parse daily note title to DateTime
  DateTime? _parseDailyNoteTitle(String title) {
    try {
      return DateFormat('yyyy-MM-dd').parse(title);
    } catch (e) {
      return null;
    }
  }

  /// Get daily note template
  String _getDailyNoteTemplate(DateTime date) {
    final dayOfWeek = DateFormat('EEEE').format(date);
    final fullDate = DateFormat('MMMM d, yyyy').format(date);

    return '''# $fullDate - $dayOfWeek

## Tasks
- [ ]

## Notes


## Links
- [[${_formatDailyNoteTitle(date.subtract(const Duration(days: 1)))}|Yesterday]]
- [[${_formatDailyNoteTitle(date.add(const Duration(days: 1)))}|Tomorrow]]

---
_Daily note created on ${DateTime.now().toIso8601String()}_
''';
  }

  /// Get calendar view of daily notes
  Map<DateTime, Note> getDailyNotesCalendar(List<Note> dailyNotes) {
    final calendar = <DateTime, Note>{};

    for (final note in dailyNotes) {
      final date = _parseDailyNoteTitle(note.title);
      if (date != null) {
        calendar[date] = note;
      }
    }

    return calendar;
  }

  /// Get daily notes for a specific month
  List<Note> getDailyNotesForMonth(List<Note> dailyNotes, int year, int month) {
    return dailyNotes.where((note) {
      final date = _parseDailyNoteTitle(note.title);
      return date != null && date.year == year && date.month == month;
    }).toList()
      ..sort((a, b) {
        final dateA = _parseDailyNoteTitle(a.title)!;
        final dateB = _parseDailyNoteTitle(b.title)!;
        return dateB.compareTo(dateA);
      });
  }
}
