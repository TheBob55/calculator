class NoteLink {
  final String sourceNoteId;
  final String targetNoteId;
  final String targetTitle;
  final int strength; // Number of times this link appears

  NoteLink({
    required this.sourceNoteId,
    required this.targetNoteId,
    required this.targetTitle,
    this.strength = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceNoteId': sourceNoteId,
      'targetNoteId': targetNoteId,
      'targetTitle': targetTitle,
      'strength': strength,
    };
  }

  factory NoteLink.fromJson(Map<String, dynamic> json) {
    return NoteLink(
      sourceNoteId: json['sourceNoteId'],
      targetNoteId: json['targetNoteId'],
      targetTitle: json['targetTitle'],
      strength: json['strength'] ?? 1,
    );
  }
}
