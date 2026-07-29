import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/repositories/live_meetup_repository.dart';

class LiveMeetupCommandModel {
  const LiveMeetupCommandModel._();

  static Map<String, Object?> pendingMap({
    required String type,
    required String outingId,
    required String crewId,
    required String userId,
    required Map<String, Object?> payload,
    required DateTime purgeAt,
  }) => {
    'type': type,
    'outingId': outingId,
    'crewId': crewId,
    'requestedByUserId': userId,
    'payload': payload,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'purgeAt': writeFirestoreTimestamp(purgeAt),
  };

  static LiveMeetupCommandResult fromMap(
    Map<String, dynamic> map,
    String commandId,
  ) {
    final status = switch (map['status']) {
      'pending' => LiveMeetupCommandStatus.pending,
      'processing' => LiveMeetupCommandStatus.processing,
      'succeeded' => LiveMeetupCommandStatus.succeeded,
      'superseded' => LiveMeetupCommandStatus.superseded,
      'failed' => LiveMeetupCommandStatus.failed,
      _ => throw const FormatException('Invalid live meetup command status.'),
    };
    final result = map['result'] is Map
        ? Map<String, dynamic>.from(map['result'] as Map)
        : const <String, dynamic>{};
    return LiveMeetupCommandResult(
      commandId: commandId,
      status: status,
      acceptedAt: readFirestoreTimestamp(result['acceptedAt']),
      expiresAt: readFirestoreTimestamp(result['expiresAt']),
      failure: status == LiveMeetupCommandStatus.failed
          ? failureFromCode(map['errorCode'])
          : null,
    );
  }

  static LiveMeetupFailure failureFromCode(Object? code) => switch (code) {
    'unauthenticated' => const LiveMeetupAuthenticationFailure(),
    'permission_denied' ||
    'not_found' ||
    'invalid_outing_state' ||
    'attendance_required' ||
    'outing_deleting' => const LiveMeetupAccessDenied(),
    'invalid_command' ||
    'invalid_status' ||
    'invalid_location' ||
    'stale_location' => const LiveMeetupValidationFailure(),
    'transfer_required' => const LiveMeetupTransferRequired(),
    'session_transferred' ||
    'session_stopped' => const LiveMeetupSessionEnded(),
    _ => const LiveMeetupServiceFailure(),
  };
}
