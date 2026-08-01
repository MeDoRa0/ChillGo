class Crew {
  final String id;
  final String name;
  final String ownerId;

  const Crew({required this.id, required this.name, required this.ownerId});

  Map<String, dynamic> toMap() {
    return {'name': name, 'ownerId': ownerId};
  }

  factory Crew.fromMap(Map<String, dynamic> map, String docId) {
    return Crew(
      id: docId,
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
    );
  }

  Crew copyWith({String? id, String? name, String? ownerId}) {
    return Crew(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
