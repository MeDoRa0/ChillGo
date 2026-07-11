class CrewInvitation {
  final String id;
  final String crewId;
  final String invitedUserId;
  final String invitedByUserId;
  final DateTime createdAt;
  final String crewName;
  final String invitedByUsername;
  final String invitedByDisplayName;

  /// The ChillGo username of the user being invited. Captured at invitation
  /// time so the UI can show `@alice` instead of the Firebase UID. May be
  /// empty for very old invitation records written before this field was
  /// introduced.
  final String invitedUsername;

  const CrewInvitation({
    required this.id,
    required this.crewId,
    required this.invitedUserId,
    required this.invitedByUserId,
    required this.createdAt,
    required this.crewName,
    required this.invitedByUsername,
    required this.invitedByDisplayName,
    this.invitedUsername = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'crewId': crewId,
      'invitedUserId': invitedUserId,
      'invitedByUserId': invitedByUserId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'crewName': crewName,
      'invitedByUsername': invitedByUsername,
      'invitedByDisplayName': invitedByDisplayName,
      'invitedUsername': invitedUsername,
    };
  }

  factory CrewInvitation.fromMap(Map<String, dynamic> map, String docId) {
    return CrewInvitation(
      id: docId,
      crewId: map['crewId'] as String? ?? '',
      invitedUserId: map['invitedUserId'] as String? ?? '',
      invitedByUserId: map['invitedByUserId'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      crewName: map['crewName'] as String? ?? '',
      invitedByUsername: map['invitedByUsername'] as String? ?? '',
      invitedByDisplayName: map['invitedByDisplayName'] as String? ?? '',
      invitedUsername: map['invitedUsername'] as String? ?? '',
    );
  }

  CrewInvitation copyWith({
    String? id,
    String? crewId,
    String? invitedUserId,
    String? invitedByUserId,
    DateTime? createdAt,
    String? crewName,
    String? invitedByUsername,
    String? invitedByDisplayName,
    String? invitedUsername,
  }) {
    return CrewInvitation(
      id: id ?? this.id,
      crewId: crewId ?? this.crewId,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      createdAt: createdAt ?? this.createdAt,
      crewName: crewName ?? this.crewName,
      invitedByUsername: invitedByUsername ?? this.invitedByUsername,
      invitedByDisplayName: invitedByDisplayName ?? this.invitedByDisplayName,
      invitedUsername: invitedUsername ?? this.invitedUsername,
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
