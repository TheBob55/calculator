import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../models/note.dart';
import '../widgets/file_explorer.dart';
import '../widgets/markdown_editor.dart';
import '../widgets/backlinks_panel.dart';
import 'vault_selector_screen.dart';
import 'graph_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Note? _selectedNote;
  bool _showBacklinks = true;

  @override
  Widget build(BuildContext context) {
    final vaultProvider = Provider.of<VaultProvider>(context);

    if (vaultProvider.currentVault == null) {
      return const VaultSelectorScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(vaultProvider.currentVault!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GraphScreen(),
                ),
              );
            },
            tooltip: 'Graph View',
          ),
          IconButton(
            icon: Icon(_showBacklinks ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showBacklinks = !_showBacklinks;
              });
            },
            tooltip: _showBacklinks ? 'Hide Backlinks' : 'Show Backlinks',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VaultSelectorScreen(),
                ),
              );
            },
            tooltip: 'Change Vault',
          ),
        ],
      ),
      body: Row(
        children: [
          // File Explorer
          SizedBox(
            width: 250,
            child: FileExplorer(
              notes: vaultProvider.notes,
              selectedNote: _selectedNote,
              onNoteSelected: (note) {
                setState(() {
                  _selectedNote = note;
                });
              },
              onNewNote: () {
                _showNewNoteDialog(context, vaultProvider);
              },
            ),
          ),
          const VerticalDivider(width: 1),

          // Editor
          Expanded(
            child: _selectedNote != null
                ? MarkdownEditor(
                    note: _selectedNote!,
                    onSave: (updatedNote) {
                      vaultProvider.saveNote(updatedNote);
                    },
                    onWikilinkTap: (noteTitle) {
                      final note = vaultProvider.getNoteByTitle(noteTitle);
                      if (note != null) {
                        setState(() {
                          _selectedNote = note;
                        });
                      } else {
                        _showCreateNoteDialog(context, vaultProvider, noteTitle);
                      }
                    },
                  )
                : const Center(
                    child: Text('Select a note or create a new one'),
                  ),
          ),

          // Backlinks Panel
          if (_showBacklinks && _selectedNote != null) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 250,
              child: BacklinksPanel(
                note: _selectedNote!,
                allNotes: vaultProvider.notes,
                onNoteTap: (note) {
                  setState(() {
                    _selectedNote = note;
                  });
                },
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewNoteDialog(context, vaultProvider);
        },
        tooltip: 'New Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNewNoteDialog(BuildContext context, VaultProvider vaultProvider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Note Title',
            hintText: 'Enter note title',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              vaultProvider.createNote(value).then((_) {
                final newNote = vaultProvider.getNoteByTitle(value);
                if (newNote != null) {
                  setState(() {
                    _selectedNote = newNote;
                  });
                }
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                vaultProvider.createNote(controller.text).then((_) {
                  final newNote = vaultProvider.getNoteByTitle(controller.text);
                  if (newNote != null) {
                    setState(() {
                      _selectedNote = newNote;
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteDialog(
    BuildContext context,
    VaultProvider vaultProvider,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Not Found'),
        content: Text('The note "$title" does not exist. Would you like to create it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              vaultProvider.createNote(title).then((_) {
                final newNote = vaultProvider.getNoteByTitle(title);
                if (newNote != null) {
                  setState(() {
                    _selectedNote = newNote;
                  });
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(
      context: context,
      delegate: NoteSearchDelegate(
        Provider.of<VaultProvider>(context, listen: false),
        (note) {
          setState(() {
            _selectedNote = note;
          });
        },
      ),
    );
  }
}

class NoteSearchDelegate extends SearchDelegate<Note?> {
  final VaultProvider vaultProvider;
  final Function(Note) onNoteSelected;

  NoteSearchDelegate(this.vaultProvider, this.onNoteSelected);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Enter search query'));
    }

    final results = vaultProvider.notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(query.toLowerCase());
      final contentMatch = note.content.toLowerCase().contains(query.toLowerCase());
      final tagMatch = note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));

      return titleMatch || contentMatch || tagMatch;
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return ListTile(
          title: Text(note.title),
          subtitle: Text(
            note.content.length > 100
                ? '${note.content.substring(0, 100)}...'
                : note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            onNoteSelected(note);
            close(context, note);
          },
        );
      },
    );
  }
}
