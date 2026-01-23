import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String filePath;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String> tags;
  final List<String> outgoingLinks; // Links to other notes
  final List<String> incomingLinks; // Backlinks from other notes

  Note({
    String? id,
    required this.title,
    required this.content,
    required this.filePath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    List<String>? outgoingLinks,
    List<String>? incomingLinks,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        tags = tags ?? [],
        outgoingLinks = outgoingLinks ?? [],
        incomingLinks = incomingLinks ?? [];

  Note copyWith({
    String? title,
    String? content,
    String? filePath,
    DateTime? modifiedAt,
    List<String>? tags,
    List<String>? outgoingLinks,
    List<String>? incomingLinks,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      outgoingLinks: outgoingLinks ?? this.outgoingLinks,
      incomingLinks: incomingLinks ?? this.incomingLinks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags,
      'outgoingLinks': outgoingLinks,
      'incomingLinks': incomingLinks,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      outgoingLinks: List<String>.from(json['outgoingLinks'] ?? []),
      incomingLinks: List<String>.from(json['incomingLinks'] ?? []),
    );
  }

  /// Extract wikilinks from content [[link]]
  static List<String> extractWikilinks(String content) {
    final regex = RegExp(r'\[\[([^\]]+)\]\]');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Extract tags from content #tag
  static List<String> extractTags(String content) {
    final regex = RegExp(r'#([\w-]+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }
}
