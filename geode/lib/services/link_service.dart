import '../models/note.dart';
import '../models/link.dart';

class LinkService {
  /// Build the link graph from all notes
  Future<List<NoteLink>> buildLinkGraph(List<Note> notes) async {
    final links = <NoteLink>[];
    final noteTitleToId = <String, String>{};

    // Build title to ID mapping
    for (final note in notes) {
      noteTitleToId[note.title] = note.id;
    }

    // Create links
    for (final note in notes) {
      for (final linkTitle in note.outgoingLinks) {
        final targetId = noteTitleToId[linkTitle];
        if (targetId != null) {
          links.add(NoteLink(
            sourceNoteId: note.id,
            targetNoteId: targetId,
            targetTitle: linkTitle,
          ));
        }
      }
    }

    return links;
  }

  /// Update backlinks for all notes
  Future<List<Note>> updateBacklinks(List<Note> notes) async {
    final noteTitleToNote = <String, Note>{};
    final backlinksMap = <String, List<String>>{};

    // Build title to note mapping
    for (final note in notes) {
      noteTitleToNote[note.title] = note;
      backlinksMap[note.id] = [];
    }

    // Build backlinks
    for (final note in notes) {
      for (final linkTitle in note.outgoingLinks) {
        final targetNote = noteTitleToNote[linkTitle];
        if (targetNote != null) {
          backlinksMap[targetNote.id]!.add(note.title);
        }
      }
    }

    // Update notes with backlinks
    final updatedNotes = <Note>[];
    for (final note in notes) {
      final incomingLinks = backlinksMap[note.id] ?? [];
      updatedNotes.add(note.copyWith(incomingLinks: incomingLinks));
    }

    return updatedNotes;
  }

  /// Find unlinked mentions (notes that mention a title but don't link to it)
  Future<List<Note>> findUnlinkedMentions(
    List<Note> notes,
    String targetTitle,
  ) async {
    final mentions = <Note>[];

    for (final note in notes) {
      if (note.title == targetTitle) continue;

      final alreadyLinked = note.outgoingLinks.contains(targetTitle);
      if (alreadyLinked) continue;

      if (note.content.toLowerCase().contains(targetTitle.toLowerCase())) {
        mentions.add(note);
      }
    }

    return mentions;
  }

  /// Convert wikilinks to clickable links in markdown
  String processWikilinks(String content, Function(String) onLinkTap) {
    // This is a simple version - in real implementation,
    // you'd use a custom markdown builder
    return content.replaceAllMapped(
      RegExp(r'\[\[([^\]]+)\]\]'),
      (match) {
        final linkText = match.group(1)!;
        return '[$linkText]($linkText)';
      },
    );
  }

  /// Extract block references (^block-id)
  List<String> extractBlockReferences(String content) {
    final regex = RegExp(r'\^([\w-]+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Extract block references with their content
  Map<String, String> extractBlocksWithContent(String content) {
    final blocks = <String, String>{};
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Look for block references at the end of lines: ^block-id
      final match = RegExp(r'\^([\w-]+)\s*$').firstMatch(line);
      if (match != null) {
        final blockId = match.group(1)!;
        // Get the content before the block reference
        final blockContent = line.substring(0, match.start).trim();
        blocks[blockId] = blockContent;
      }
    }

    return blocks;
  }

  /// Find block reference in a specific note
  String? findBlockInNote(Note note, String blockId) {
    final blocks = extractBlocksWithContent(note.content);
    return blocks[blockId];
  }

  /// Extract wikilinks with block references [[note#^block-id]]
  List<String> extractBlockLinks(String content) {
    final regex = RegExp(r'\[\[([^\]]+)#\^([\w-]+)\]\]');
    final matches = regex.allMatches(content);
    return matches
        .map((m) => '${m.group(1)}#^${m.group(2)}')
        .toList();
  }

  /// Parse block link into note title and block ID
  Map<String, String>? parseBlockLink(String blockLink) {
    final match = RegExp(r'^([^#]+)#\^([\w-]+)$').firstMatch(blockLink);
    if (match != null) {
      return {
        'note': match.group(1)!,
        'block': match.group(2)!,
      };
    }
    return null;
  }

  /// Find all notes that reference a specific block
  Future<List<Note>> findBlockReferences(
    List<Note> notes,
    String noteTitle,
    String blockId,
  ) async {
    final references = <Note>[];
    final searchPattern = '$noteTitle#^$blockId';

    for (final note in notes) {
      if (note.content.contains(searchPattern)) {
        references.add(note);
      }
    }

    return references;
  }

  /// Generate a unique block ID
  String generateBlockId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'block-$timestamp';
  }

  /// Add block reference to a line
  String addBlockReferenceToLine(String line, String blockId) {
    return '$line ^$blockId';
  }

  /// Get all orphaned notes (notes with no incoming or outgoing links)
  Future<List<Note>> getOrphanedNotes(List<Note> notes) async {
    return notes.where((note) =>
        note.incomingLinks.isEmpty && note.outgoingLinks.isEmpty).toList();
  }
}
