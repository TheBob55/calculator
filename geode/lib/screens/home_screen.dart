import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../models/note.dart';
import '../widgets/file_explorer.dart';
import '../widgets/markdown_editor.dart';
import '../widgets/backlinks_panel.dart';
import '../services/daily_notes_service.dart';
import '../services/pdf_export_service.dart';
import '../services/sync_service.dart';
import 'vault_selector_screen.dart';
import 'graph_screen.dart';
import 'advanced_search_screen.dart';

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
            icon: const Icon(Icons.today),
            onPressed: () => _openDailyNote(context, vaultProvider),
            tooltip: 'Today\'s Note',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showAdvancedSearch(context),
            tooltip: 'Advanced Search',
          ),
          if (_selectedNote != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _exportToPdf(context, _selectedNote!),
              tooltip: 'Export to PDF',
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
            icon: const Icon(Icons.sync),
            onPressed: () => _syncVault(context, vaultProvider),
            tooltip: 'Sync',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'backlinks':
                  setState(() {
                    _showBacklinks = !_showBacklinks;
                  });
                  break;
                case 'vault':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VaultSelectorScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'backlinks',
                child: Text(
                  _showBacklinks ? 'Hide Backlinks' : 'Show Backlinks',
                ),
              ),
              const PopupMenuItem(
                value: 'vault',
                child: Text('Change Vault'),
              ),
            ],
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

  Future<void> _showAdvancedSearch(BuildContext context) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedSearchScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedNote = result;
      });
    }
  }

  Future<void> _openDailyNote(
    BuildContext context,
    VaultProvider vaultProvider,
  ) async {
    try {
      final dailyNotesService = DailyNotesService();
      final todayNote = await dailyNotesService.getTodayNote(
        vaultProvider.currentVault!,
        vaultProvider.notes,
      );

      setState(() {
        _selectedNote = todayNote;
      });

      // Reload notes to include the new daily note
      await vaultProvider.loadNotes();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening daily note: $e')),
        );
      }
    }
  }

  Future<void> _exportToPdf(BuildContext context, Note note) async {
    try {
      final pdfService = PdfExportService();

      // Show options dialog
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export to PDF'),
          content: const Text('Choose an action:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'preview'),
              child: const Text('Preview'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'share'),
              child: const Text('Share'),
            ),
          ],
        ),
      );

      if (action == null) return;

      switch (action) {
        case 'preview':
          await pdfService.previewPdf(note);
          break;
        case 'save':
          final file = await pdfService.exportNoteToPdf(note);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF saved to ${file.path}')),
            );
          }
          break;
        case 'share':
          await pdfService.sharePdf(note);
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  Future<void> _syncVault(
    BuildContext context,
    VaultProvider vaultProvider,
  ) async {
    final syncService = SyncService();

    // Check if sync is configured
    if (!await syncService.isSyncConfigured()) {
      if (context.mounted) {
        _showSyncSetupDialog(context);
      }
      return;
    }

    // Show syncing dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Syncing...'),
            ],
          ),
        ),
      );
    }

    try {
      await syncService.syncVault(
        vaultProvider.currentVault!,
        vaultProvider.notes,
      );

      await vaultProvider.loadNotes();

      if (context.mounted) {
        Navigator.pop(context); // Close syncing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close syncing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  void _showSyncSetupDialog(BuildContext context) {
    final urlController = TextEditingController();
    final tokenController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Sync'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://your-server.com',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Auth Token (optional)',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final syncService = SyncService();
              final config = SyncConfig(
                serverUrl: urlController.text,
                authToken: tokenController.text.isEmpty
                    ? null
                    : tokenController.text,
                enabled: true,
              );

              await syncService.saveSyncConfig(config);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync configured')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
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
