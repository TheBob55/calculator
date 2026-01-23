import '../models/note.dart';

class SearchResult {
  final Note note;
  final List<String> matchingLines;
  final int matchCount;

  SearchResult({
    required this.note,
    required this.matchingLines,
    required this.matchCount,
  });
}

class SearchService {
  /// Search notes by query
  Future<List<SearchResult>> searchNotes(
    List<Note> notes,
    String query, {
    bool caseSensitive = false,
    bool useRegex = false,
  }) async {
    if (query.isEmpty) return [];

    final results = <SearchResult>[];

    for (final note in notes) {
      final matchingLines = <String>[];
      var matchCount = 0;

      final searchQuery = caseSensitive ? query : query.toLowerCase();
      final searchTitle = caseSensitive ? note.title : note.title.toLowerCase();

      final lines = note.content.split('\n');

      if (useRegex) {
        try {
          final regex = RegExp(
            query,
            caseSensitive: caseSensitive,
          );

          for (final line in lines) {
            if (regex.hasMatch(line)) {
              matchingLines.add(line);
              matchCount += regex.allMatches(line).length;
            }
          }

          if (regex.hasMatch(note.title)) {
            matchCount++;
          }
        } catch (e) {
          // Invalid regex, fall back to simple search
          continue;
        }
      } else {
        for (final line in lines) {
          final searchLine = caseSensitive ? line : line.toLowerCase();
          if (searchLine.contains(searchQuery)) {
            matchingLines.add(line);
            matchCount += searchQuery.allMatches(searchLine).length;
          }
        }

        if (searchTitle.contains(searchQuery)) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        results.add(SearchResult(
          note: note,
          matchingLines: matchingLines,
          matchCount: matchCount,
        ));
      }
    }

    // Sort by relevance (match count)
    results.sort((a, b) => b.matchCount.compareTo(a.matchCount));

    return results;
  }

  /// Search by tag
  Future<List<Note>> searchByTag(List<Note> notes, String tag) async {
    return notes.where((note) => note.tags.contains(tag)).toList();
  }

  /// Get all tags from notes
  Set<String> getAllTags(List<Note> notes) {
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }

  /// Search notes that link to a specific note
  Future<List<Note>> findBacklinks(List<Note> notes, String noteTitle) async {
    return notes.where((note) => note.outgoingLinks.contains(noteTitle)).toList();
  }
}
