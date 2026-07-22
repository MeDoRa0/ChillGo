import 'outing_status.dart';

const outingCleanupDelay = Duration(hours: 12);

class Outing {
  final String id;
  final String crewId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final String locationText;
  final OutingStatus status;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancelledReason;
  final DateTime? cancelledAt;
  final DateTime? archivedAt;
  final int agreementRoundSequence;
  final String? activeAgreementRoundId;
  final String? confirmedAgreementRoundId;

  const Outing({
    required this.id,
    required this.crewId,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.locationText,
    required this.status,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledReason,
    this.cancelledAt,
    this.archivedAt,
    this.agreementRoundSequence = 0,
    this.activeAgreementRoundId,
    this.confirmedAgreementRoundId,
  });

  bool isOutdatedAt(DateTime now) => scheduledAt.isBefore(now);

  bool isCleanupEligibleAt(DateTime now) =>
      !scheduledAt.add(outingCleanupDelay).isAfter(now);

  bool isCurrentCrewPlanAt(DateTime now) =>
      !status.isHistorical && !isOutdatedAt(now);

  Map<String, dynamic> toMap() {
    return {
      'crewId': crewId,
      'title': title,
      if (description != null) 'description': description,
      'scheduledAt': _writeDate(scheduledAt),
      'locationText': locationText,
      'status': status.value,
      'createdByUserId': createdByUserId,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
      if (cancelledReason != null) 'cancelledReason': cancelledReason,
      if (cancelledAt != null) 'cancelledAt': _writeDate(cancelledAt!),
      if (archivedAt != null) 'archivedAt': _writeDate(archivedAt!),
      'agreementRoundSequence': agreementRoundSequence,
      if (activeAgreementRoundId != null)
        'activeAgreementRoundId': activeAgreementRoundId,
      if (confirmedAgreementRoundId != null)
        'confirmedAgreementRoundId': confirmedAgreementRoundId,
    };
  }

  factory Outing.fromMap(Map<String, dynamic> map, String docId) {
    return Outing(
      id: docId,
      crewId: _readRequiredString(map, 'crewId'),
      title: _readRequiredString(map, 'title'),
      description: _readOptionalString(map, 'description'),
      scheduledAt: _readRequiredDate(map, 'scheduledAt'),
      locationText: _readRequiredString(map, 'locationText'),
      status: OutingStatus.fromValue(map['status']),
      createdByUserId: _readRequiredString(map, 'createdByUserId'),
      createdAt: _readRequiredDate(map, 'createdAt'),
      updatedAt: _readRequiredDate(map, 'updatedAt'),
      cancelledReason: _readOptionalString(map, 'cancelledReason'),
      cancelledAt: _readNullableDate(map['cancelledAt']),
      archivedAt: _readNullableDate(map['archivedAt']),
      agreementRoundSequence: map['agreementRoundSequence'] as int? ?? 0,
      activeAgreementRoundId: _readOptionalString(
        map,
        'activeAgreementRoundId',
      ),
      confirmedAgreementRoundId: _readOptionalString(
        map,
        'confirmedAgreementRoundId',
      ),
    );
  }

  Outing copyWith({
    String? id,
    String? crewId,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? scheduledAt,
    String? locationText,
    OutingStatus? status,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancelledReason,
    bool clearCancelledReason = false,
    DateTime? cancelledAt,
    bool clearCancelledAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    int? agreementRoundSequence,
    String? activeAgreementRoundId,
    bool clearActiveAgreementRoundId = false,
    String? confirmedAgreementRoundId,
    bool clearConfirmedAgreementRoundId = false,
  }) {
    return Outing(
      id: id ?? this.id,
      crewId: crewId ?? this.crewId,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      locationText: locationText ?? this.locationText,
      status: status ?? this.status,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledReason: clearCancelledReason
          ? null
          : cancelledReason ?? this.cancelledReason,
      cancelledAt: clearCancelledAt ? null : cancelledAt ?? this.cancelledAt,
      archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
      agreementRoundSequence:
          agreementRoundSequence ?? this.agreementRoundSequence,
      activeAgreementRoundId: clearActiveAgreementRoundId
          ? null
          : activeAgreementRoundId ?? this.activeAgreementRoundId,
      confirmedAgreementRoundId: clearConfirmedAgreementRoundId
          ? null
          : confirmedAgreementRoundId ?? this.confirmedAgreementRoundId,
    );
  }

  static String _readRequiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing or invalid outing.$field');
  }

  static String? _readOptionalString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Invalid outing.$field');
  }

  static DateTime _readRequiredDate(Map<String, dynamic> map, String field) {
    final value = _readNullableDate(map[field]);
    if (value != null) return value;
    throw FormatException('Missing or invalid outing.$field');
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid outing timestamp: $value');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid outing timestamp: $value');
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
