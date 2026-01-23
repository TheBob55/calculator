import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/link_service.dart';

class BacklinksPanel extends StatelessWidget {
  final Note note;
  final List<Note> allNotes;
  final Function(Note) onNoteTap;

  const BacklinksPanel({
    super.key,
    required this.note,
    required this.allNotes,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final linkService = LinkService();
    final backlinks = allNotes.where((n) =>
      n.outgoingLinks.contains(note.title)
    ).toList();

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Backlinks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),

          // Linked mentions
          if (backlinks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Linked mentions (${backlinks.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...backlinks.map((backlink) => ListTile(
              leading: const Icon(Icons.link),
              title: Text(backlink.title),
              subtitle: _getContextSnippet(backlink, note.title),
              onTap: () => onNoteTap(backlink),
              dense: true,
            )),
          ],

          const Divider(height: 1),

          // Unlinked mentions
          FutureBuilder<List<Note>>(
            future: linkService.findUnlinkedMentions(allNotes, note.title),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final unlinkedMentions = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Unlinked mentions (${unlinkedMentions.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ...unlinkedMentions.map((mention) => ListTile(
                    leading: const Icon(Icons.notes),
                    title: Text(mention.title),
                    subtitle: _getContextSnippet(mention, note.title),
                    onTap: () => onNoteTap(mention),
                    dense: true,
                  )),
                ],
              );
            },
          ),

          // Outgoing links
          if (note.outgoingLinks.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Outgoing links (${note.outgoingLinks.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...note.outgoingLinks.map((linkTitle) {
              final linkedNote = allNotes.where((n) => n.title == linkTitle).firstOrNull;
              return ListTile(
                leading: Icon(
                  linkedNote != null ? Icons.note : Icons.help_outline,
                  color: linkedNote != null ? null : Colors.orange,
                ),
                title: Text(linkTitle),
                subtitle: linkedNote == null
                    ? const Text('Note does not exist', style: TextStyle(fontStyle: FontStyle.italic))
                    : null,
                onTap: linkedNote != null ? () => onNoteTap(linkedNote) : null,
                dense: true,
              );
            }),
          ],

          // Tags
          if (note.tags.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tags',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  onDeleted: null,
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget? _getContextSnippet(Note note, String searchTerm) {
    final lines = note.content.split('\n');
    for (final line in lines) {
      if (line.toLowerCase().contains(searchTerm.toLowerCase())) {
        return Text(
          line.trim(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        );
      }
    }
    return null;
  }
}
