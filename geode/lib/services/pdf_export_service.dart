import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class PdfExportService {
  /// Export a single note to PDF
  Future<File> exportNoteToPdf(Note note) async {
    final pdf = pw.Document();

    // Convert markdown to plain text (simplified)
    final plainText = _stripMarkdown(note.content);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              note.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Created: ${_formatDate(note.createdAt)}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Modified: ${_formatDate(note.modifiedAt)}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          if (note.tags.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Tags: ${note.tags.map((t) => '#$t').join(', ')}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blue,
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),
          ..._buildMarkdownContent(plainText),
        ],
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${note.title}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Export multiple notes to a single PDF
  Future<File> exportNotesToPdf(List<Note> notes, String fileName) async {
    final pdf = pw.Document();

    for (final note in notes) {
      final plainText = _stripMarkdown(note.content);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Modified: ${_formatDate(note.modifiedAt)}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 12),
            ..._buildMarkdownContent(plainText),
          ],
        ),
      );
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Preview PDF before saving
  Future<void> previewPdf(Note note) async {
    final pdf = pw.Document();
    final plainText = _stripMarkdown(note.content);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              note.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          ..._buildMarkdownContent(plainText),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Share/print PDF
  Future<void> sharePdf(Note note) async {
    final file = await exportNoteToPdf(note);
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: '${note.title}.pdf',
    );
  }

  List<pw.Widget> _buildMarkdownContent(String content) {
    final lines = content.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      // Basic markdown formatting
      if (line.startsWith('# ')) {
        widgets.add(pw.Header(
          level: 0,
          child: pw.Text(
            line.substring(2),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(pw.Header(
          level: 1,
          child: pw.Text(
            line.substring(3),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(pw.Header(
          level: 2,
          child: pw.Text(
            line.substring(4),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(pw.Bullet(
          text: line.substring(2),
          style: const pw.TextStyle(fontSize: 12),
        ));
      } else {
        widgets.add(pw.Paragraph(
          text: line,
          style: const pw.TextStyle(fontSize: 12),
        ));
      }
    }

    return widgets;
  }

  String _stripMarkdown(String markdown) {
    // Remove markdown syntax for cleaner PDF
    var text = markdown;

    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '[Code Block]');

    // Remove inline code
    text = text.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Remove bold/italic
    text = text.replaceAll(RegExp(r'\*\*([^\*]+)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'\*([^\*]+)\*'), r'$1');
    text = text.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    text = text.replaceAll(RegExp(r'_([^_]+)_'), r'$1');

    // Remove wikilinks
    text = text.replaceAll(RegExp(r'\[\[([^\]]+)\]\]'), r'$1');

    // Remove regular links
    text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');

    return text;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
