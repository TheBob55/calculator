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

  /// Get all orphaned notes (notes with no incoming or outgoing links)
  Future<List<Note>> getOrphanedNotes(List<Note> notes) async {
    return notes.where((note) =>
        note.incomingLinks.isEmpty && note.outgoingLinks.isEmpty).toList();
  }
}
