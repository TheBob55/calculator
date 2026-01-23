class Vault {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime lastOpened;

  Vault({
    required this.id,
    required this.name,
    required this.path,
    DateTime? createdAt,
    DateTime? lastOpened,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastOpened = lastOpened ?? DateTime.now();

  Vault copyWith({
    String? name,
    String? path,
    DateTime? lastOpened,
  }) {
    return Vault(
      id: id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'lastOpened': lastOpened.toIso8601String(),
    };
  }

  factory Vault.fromJson(Map<String, dynamic> json) {
    return Vault(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      createdAt: DateTime.parse(json['createdAt']),
      lastOpened: DateTime.parse(json['lastOpened']),
    );
  }
}
