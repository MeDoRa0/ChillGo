import 'package:equatable/equatable.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/live_meetup_status.dart';

class LiveMeetupStatusModel extends Equatable {
  LiveMeetupStatusModel({
    required this.outingId,
    required this.crewId,
    required this.userId,
    required this.value,
    required DateTime acceptedAt,
    required this.acceptedCommandId,
  }) : acceptedAt = acceptedAt.toUtc() {
    if ([
      outingId,
      crewId,
      userId,
      acceptedCommandId,
    ].any((value) => value.isEmpty)) {
      throw const FormatException('Invalid live meetup status identity.');
    }
  }

  final String outingId;
  final String crewId;
  final String userId;
  final LiveMeetupStatus value;
  final DateTime acceptedAt;
  final String acceptedCommandId;

  factory LiveMeetupStatusModel.fromMap(Map<String, dynamic> map) {
    final acceptedAt = readFirestoreTimestamp(map['acceptedAt']);
    if (acceptedAt == null) {
      throw const FormatException('Invalid live meetup status timestamp.');
    }
    String requiredString(String key) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
      throw FormatException('Invalid live meetup status $key.');
    }

    return LiveMeetupStatusModel(
      outingId: requiredString('outingId'),
      crewId: requiredString('crewId'),
      userId: requiredString('userId'),
      value: LiveMeetupStatus.fromValue(map['value']),
      acceptedAt: acceptedAt,
      acceptedCommandId: requiredString('acceptedCommandId'),
    );
  }

  @override
  List<Object> get props => [
    outingId,
    crewId,
    userId,
    value,
    acceptedAt,
    acceptedCommandId,
  ];
}
