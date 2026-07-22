import 'attendance_status.dart';

class OutingParticipant {
  final String id;
  final String outingId;
  final String crewId;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String addedByUserId;
  final DateTime addedAt;
  final bool isCreatorParticipant;
  final AttendanceStatus attendanceStatus;
  final DateTime? respondedAt;

  const OutingParticipant({
    required this.id,
    required this.outingId,
    required this.crewId,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.addedByUserId,
    required this.addedAt,
    required this.isCreatorParticipant,
    AttendanceStatus? attendanceStatus,
    this.respondedAt,
  }) : attendanceStatus =
           attendanceStatus ??
           (isCreatorParticipant
               ? AttendanceStatus.accepted
               : AttendanceStatus.invited);

  Map<String, dynamic> toMap() {
    return {
      'outingId': outingId,
      'crewId': crewId,
      'userId': userId,
      'username': username,
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'addedByUserId': addedByUserId,
      'addedAt': _writeDate(addedAt),
      'isCreatorParticipant': isCreatorParticipant,
      'attendanceStatus': attendanceStatus.value,
      if (respondedAt != null) 'respondedAt': _writeDate(respondedAt!),
    };
  }

  factory OutingParticipant.fromMap(Map<String, dynamic> map, String docId) {
    return OutingParticipant(
      id: docId,
      outingId: _readRequiredString(map, 'outingId'),
      crewId: _readRequiredString(map, 'crewId'),
      userId: _readRequiredString(map, 'userId'),
      username: _readRequiredString(map, 'username'),
      displayName: _readRequiredString(map, 'displayName'),
      avatarUrl: _readOptionalString(map, 'avatarUrl'),
      addedByUserId: _readRequiredString(map, 'addedByUserId'),
      addedAt: _readRequiredDate(map, 'addedAt'),
      isCreatorParticipant: _readRequiredBool(map, 'isCreatorParticipant'),
      attendanceStatus: map['attendanceStatus'] is String
          ? AttendanceStatus.fromValue(map['attendanceStatus'] as String)
          : null,
      respondedAt: map['respondedAt'] == null
          ? null
          : _readRequiredDate(map, 'respondedAt'),
    );
  }

  OutingParticipant copyWith({
    String? id,
    String? outingId,
    String? crewId,
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? addedByUserId,
    DateTime? addedAt,
    bool? isCreatorParticipant,
    AttendanceStatus? attendanceStatus,
    DateTime? respondedAt,
    bool clearRespondedAt = false,
  }) {
    return OutingParticipant(
      id: id ?? this.id,
      outingId: outingId ?? this.outingId,
      crewId: crewId ?? this.crewId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedAt: addedAt ?? this.addedAt,
      isCreatorParticipant: isCreatorParticipant ?? this.isCreatorParticipant,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      respondedAt: clearRespondedAt ? null : respondedAt ?? this.respondedAt,
    );
  }

  static String _readRequiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing or invalid outingParticipant.$field');
  }

  static String? _readOptionalString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Invalid outingParticipant.$field');
  }

  static bool _readRequiredBool(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is bool) return value;
    throw FormatException('Missing or invalid outingParticipant.$field');
  }

  static DateTime _readRequiredDate(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is DateTime) return value.toUtc();
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid outingParticipant.$field');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Missing or invalid outingParticipant.$field');
    }
    return parsed.toUtc();
  }

  static String _writeDate(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
      utc.millisecond,
    ).toIso8601String();
  }
}
