import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../services/search_service.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  bool _useRegex = false;
  bool _caseSensitive = false;
  bool _searchInFiles = true;
  bool _searchInTags = true;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
    final searchService = SearchService();

    try {
      final results = await searchService.searchNotes(
        vaultProvider.notes,
        query,
        caseSensitive: _caseSensitive,
        useRegex: _useRegex,
      );

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid search pattern: ${e.toString()}';
        _results = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
      ),
      body: Column(
        children: [
          // Search bar and options
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _useRegex
                        ? 'Enter regex pattern...'
                        : 'Enter search query...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results = [];
                                _errorMessage = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),

                // Search options
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Regex'),
                      selected: _useRegex,
                      onSelected: (value) {
                        setState(() {
                          _useRegex = value;
                        });
                        _performSearch();
                      },
                    ),
                    FilterChip(
                      label: const Text('Case Sensitive'),
                      selected: _caseSensitive,
                      onSelected: (value) {
                        setState(() {
                          _caseSensitive = value;
                        });
                        _performSearch();
                      },
                    ),
                    FilterChip(
                      label: const Text('Search in Files'),
                      selected: _searchInFiles,
                      onSelected: (value) {
                        setState(() {
                          _searchInFiles = value;
                        });
                        _performSearch();
                      },
                    ),
                    FilterChip(
                      label: const Text('Search in Tags'),
                      selected: _searchInTags,
                      onSelected: (value) {
                        setState(() {
                          _searchInTags = value;
                        });
                        _performSearch();
                      },
                    ),
                  ],
                ),

                // Regex help
                if (_useRegex) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Regex examples: \\d+ (numbers), ^word (starts with), word\$ (ends with), .* (any)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results header
          if (!_isSearching && _searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Found ${_results.length} result${_results.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),

          // Results list
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Enter a search query',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final result = _results[index];
                              return _SearchResultTile(
                                result: result,
                                query: _searchController.text,
                                onTap: () {
                                  Navigator.pop(context, result.note);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final String query;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.note),
        title: Text(
          result.note.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.matchingLines.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...result.matchingLines.take(3).map((line) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${result.matchCount} match${result.matchCount == 1 ? '' : 'es'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (result.note.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: result.note.tags.take(3).map((tag) {
                        return Chip(
                          label: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
