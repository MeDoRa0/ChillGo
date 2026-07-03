class Crew {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;

  const Crew({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory Crew.fromMap(Map<String, dynamic> map, String docId) {
    return Crew(
      id: docId,
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Crew copyWith({
    String? id,
    String? name,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return Crew(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
