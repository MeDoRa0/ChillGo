import 'crew_role.dart';

class CrewMembership {
  final String id;
  final String crewId;
  final String userId;
  final CrewRole role;
  final DateTime joinedAt;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const CrewMembership({
    required this.id,
    required this.crewId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'crewId': crewId,
      'userId': userId,
      'role': role.value,
      'joinedAt': joinedAt.toUtc().toIso8601String(),
      'username': username,
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  factory CrewMembership.fromMap(Map<String, dynamic> map, String docId) {
    return CrewMembership(
      id: docId,
      crewId: map['crewId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      role: CrewRole.fromValue(map['role'] as String?),
      joinedAt: _readDate(map['joinedAt']),
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  CrewMembership copyWith({
    String? id,
    String? crewId,
    String? userId,
    CrewRole? role,
    DateTime? joinedAt,
    String? username,
    String? displayName,
    String? avatarUrl,
  }) {
    return CrewMembership(
      id: id ?? this.id,
      crewId: crewId ?? this.crewId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  static DateTime _readDate(Object? rawDate) {
    if (rawDate is DateTime) return rawDate.toUtc();
    if (rawDate is String) {
      return DateTime.tryParse(rawDate)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
