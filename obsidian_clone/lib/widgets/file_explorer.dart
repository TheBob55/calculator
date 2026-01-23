import 'package:flutter/material.dart';
import '../models/note.dart';

class FileExplorer extends StatefulWidget {
  final List<Note> notes;
  final Note? selectedNote;
  final Function(Note) onNoteSelected;
  final VoidCallback onNewNote;

  const FileExplorer({
    super.key,
    required this.notes,
    required this.selectedNote,
    required this.onNoteSelected,
    required this.onNewNote,
  });

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  String _searchQuery = '';
  String _sortBy = 'title'; // title, modified, created

  @override
  Widget build(BuildContext context) {
    final filteredNotes = widget.notes.where((note) {
      if (_searchQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort notes
    filteredNotes.sort((a, b) {
      switch (_sortBy) {
        case 'modified':
          return b.modifiedAt.compareTo(a.modifiedAt);
        case 'created':
          return b.createdAt.compareTo(a.createdAt);
        case 'title':
        default:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text('Sort by:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'title', child: Text('Title')),
                      DropdownMenuItem(value: 'modified', child: Text('Modified')),
                      DropdownMenuItem(value: 'created', child: Text('Created')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notes list
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.note, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No notes found',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: widget.onNewNote,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Note'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final isSelected = widget.selectedNote?.id == note.id;

                      return ListTile(
                        selected: isSelected,
                        leading: const Icon(Icons.note),
                        title: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatDate(note.modifiedAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: note.outgoingLinks.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${note.outgoingLinks.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => widget.onNoteSelected(note),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
