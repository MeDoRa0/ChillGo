import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../outings/domain/entities/outing_status.dart';
import '../../domain/repositories/live_meetup_repository.dart';
import '../../domain/services/live_meetup_transition_service.dart';

class FirestoreLiveMeetupTransitionService
    implements LiveMeetupTransitionService {
  FirestoreLiveMeetupTransitionService({
    required this.firestore,
    required this.currentUid,
    this.timeout = const Duration(seconds: 30),
  });

  final FirebaseFirestore firestore;
  final String Function() currentUid;
  final Duration timeout;

  @override
  Future<LiveMeetupTransitionResult> endOuting(
    String outingId,
    OutingStatus targetStatus,
  ) {
    if (!const {
      OutingStatus.completed,
      OutingStatus.cancelled,
      OutingStatus.archived,
    }.contains(targetStatus)) {
      throw const LiveMeetupValidationFailure(
        'A terminal outing status is required.',
      );
    }
    return _submit(
      type: 'end_outing',
      outingId: outingId,
      fields: {'targetOutingStatus': targetStatus.value},
    );
  }

  @override
  Future<LiveMeetupTransitionResult> declineAttendance(String outingId) =>
      _submit(
        type: 'change_attendance',
        outingId: outingId,
        fields: {'targetUserId': _uid, 'targetAttendanceStatus': 'declined'},
      );

  @override
  Future<LiveMeetupTransitionResult> removeParticipant(
    String outingId,
    String userId,
  ) => _submit(
    type: 'remove_participant',
    outingId: outingId,
    fields: {'targetUserId': userId},
  );

  @override
  Future<LiveMeetupTransitionResult> removeMembership(
    String crewId,
    String userId,
  ) => _submit(
    type: 'remove_membership',
    crewId: crewId,
    fields: {'targetUserId': userId},
  );

  @override
  Future<LiveMeetupTransitionResult> deleteCrew(String crewId) =>
      _submit(type: 'delete_crew', crewId: crewId);

  String get _uid {
    final uid = currentUid();
    if (uid.isEmpty) throw const LiveMeetupAuthenticationFailure();
    return uid;
  }

  Future<LiveMeetupTransitionResult> _submit({
    required String type,
    String? outingId,
    String? crewId,
    Map<String, Object?> fields = const {},
  }) async {
    try {
      final uid = _uid;
      var resolvedCrewId = crewId;
      if (resolvedCrewId == null) {
        final outing = await firestore
            .collection('outings')
            .doc(outingId)
            .get(const GetOptions(source: Source.server));
        if (!outing.exists) throw const LiveMeetupAccessDenied();
        resolvedCrewId = outing.data()?['crewId'] as String?;
      }
      if (resolvedCrewId == null || resolvedCrewId.isEmpty) {
        throw const LiveMeetupAccessDenied();
      }
      final ref = firestore.collection('live_meetup_transitions').doc();
      await ref.set({
        'type': type,
        'outingId': ?outingId,
        'crewId': resolvedCrewId,
        ...fields,
        'requestedByUserId': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'purgeAt': Timestamp.fromDate(
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      });
      return await ref
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) throw const LiveMeetupServiceFailure();
            final data = snapshot.data()!;
            final status = switch (data['status']) {
              'pending' => LiveMeetupTransitionStatus.pending,
              'processing' => LiveMeetupTransitionStatus.processing,
              'succeeded' => LiveMeetupTransitionStatus.succeeded,
              'failed' => LiveMeetupTransitionStatus.failed,
              _ => throw const LiveMeetupServiceFailure(),
            };
            return LiveMeetupTransitionResult(
              transitionId: snapshot.id,
              status: status,
              failure: status == LiveMeetupTransitionStatus.failed
                  ? _failureFor(data['errorCode'])
                  : null,
            );
          })
          .firstWhere((result) => result.isTerminal)
          .timeout(timeout);
    } on TimeoutException {
      throw const LiveMeetupOfflineFailure();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        throw const LiveMeetupAccessDenied();
      }
      if (error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'aborted') {
        throw const LiveMeetupOfflineFailure();
      }
      throw const LiveMeetupServiceFailure();
    }
  }

  LiveMeetupFailure _failureFor(Object? code) => switch (code) {
    'unauthenticated' => const LiveMeetupAuthenticationFailure(),
    'permission_denied' ||
    'not_found' ||
    'invalid_outing_state' => const LiveMeetupAccessDenied(),
    'invalid_transition' => const LiveMeetupValidationFailure(),
    _ => const LiveMeetupServiceFailure(),
  };
}
