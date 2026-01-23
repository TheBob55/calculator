import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownEditor extends StatefulWidget {
  final Note note;
  final Function(Note) onSave;
  final Function(String) onWikilinkTap;

  const MarkdownEditor({
    super.key,
    required this.note,
    required this.onSave,
    required this.onWikilinkTap,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _controller;
  bool _isPreviewMode = false;
  bool _isSplitView = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.content);
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _controller.text = widget.note.content;
    }
  }

  @override
  void dispose() {
    _saveNote();
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_controller.text != widget.note.content) {
      final updatedNote = widget.note.copyWith(
        content: _controller.text,
        outgoingLinks: Note.extractWikilinks(_controller.text),
        tags: Note.extractTags(_controller.text),
      );
      widget.onSave(updatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.note.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isSplitView ? Icons.view_column : Icons.view_agenda),
                onPressed: () {
                  setState(() {
                    _isSplitView = !_isSplitView;
                    if (_isSplitView) {
                      _isPreviewMode = false;
                    }
                  });
                },
                tooltip: _isSplitView ? 'Single View' : 'Split View',
              ),
              IconButton(
                icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _isPreviewMode = !_isPreviewMode;
                    if (_isPreviewMode) {
                      _isSplitView = false;
                    }
                  });
                },
                tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Mode',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveNote,
                tooltip: 'Save',
              ),
            ],
          ),
        ),

        // Editor/Preview area
        Expanded(
          child: _isSplitView
              ? Row(
                  children: [
                    Expanded(child: _buildEditor()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildPreview()),
                  ],
                )
              : _isPreviewMode
                  ? _buildPreview()
                  : _buildEditor(),
        ),

        // Status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${_controller.text.length} chars | ${_controller.text.split('\n').length} lines',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Text(
                '${widget.note.outgoingLinks.length} links',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Text(
                '${widget.note.tags.length} tags',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start writing...',
        ),
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'monospace',
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildPreview() {
    final processedMarkdown = _processWikilinks(_controller.text);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Markdown(
        data: processedMarkdown,
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            // Check if it's a wikilink
            if (_isWikilink(text)) {
              widget.onWikilinkTap(text);
            } else {
              // External link
              _launchUrl(href);
            }
          }
        },
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          p: const TextStyle(fontSize: 16),
          code: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  String _processWikilinks(String content) {
    // Convert [[wikilink]] to [wikilink](wikilink)
    return content.replaceAllMapped(
      RegExp(r'\[\[([^\]]+)\]\]'),
      (match) {
        final linkText = match.group(1)!;
        return '[$linkText]($linkText)';
      },
    );
  }

  bool _isWikilink(String text) {
    // Check if this was originally a wikilink
    return !text.startsWith('http://') && !text.startsWith('https://');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
