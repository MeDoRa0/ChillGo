// ignore_for_file: subtype_of_sealed_class

import 'package:chillgo/features/live_meetup/data/services/firestore_live_meetup_transition_service.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/domain/services/live_meetup_transition_service.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirestore firestore;
  late MockCollection outings;
  late MockCollection transitions;
  late MockDocumentReference outingRef;
  late MockDocumentReference transitionRef;
  late MockDocumentSnapshot outingSnapshot;
  late MockDocumentSnapshot transitionSnapshot;

  setUp(() {
    firestore = MockFirestore();
    outings = MockCollection();
    transitions = MockCollection();
    outingRef = MockDocumentReference();
    transitionRef = MockDocumentReference();
    outingSnapshot = MockDocumentSnapshot();
    transitionSnapshot = MockDocumentSnapshot();
    when(() => firestore.collection('outings')).thenReturn(outings);
    when(
      () => firestore.collection('live_meetup_transitions'),
    ).thenReturn(transitions);
    when(() => outings.doc('outing-1')).thenReturn(outingRef);
    when(() => transitions.doc()).thenReturn(transitionRef);
    when(() => outingRef.get(any())).thenAnswer((_) async => outingSnapshot);
    when(() => outingSnapshot.exists).thenReturn(true);
    when(() => outingSnapshot.data()).thenReturn({'crewId': 'crew-1'});
    when(() => transitionRef.set(any())).thenAnswer((_) async {});
    when(() => transitionSnapshot.exists).thenReturn(true);
    when(() => transitionSnapshot.id).thenReturn('transition-1');
    when(() => transitionSnapshot.data()).thenReturn({'status': 'succeeded'});
    when(
      () => transitionRef.snapshots(),
    ).thenAnswer((_) => Stream.value(transitionSnapshot));
  });

  test(
    'creates an exact end-outing envelope and observes only its result',
    () async {
      final service = FirestoreLiveMeetupTransitionService(
        firestore: firestore,
        currentUid: () => 'user-1',
      );

      final result = await service.endOuting(
        'outing-1',
        OutingStatus.completed,
      );

      expect(
        result,
        const LiveMeetupTransitionResult(
          transitionId: 'transition-1',
          status: LiveMeetupTransitionStatus.succeeded,
        ),
      );
      final captured =
          verify(() => transitionRef.set(captureAny())).captured.single
              as Map<String, Object?>;
      expect(captured.keys.toSet(), {
        'type',
        'outingId',
        'crewId',
        'targetOutingStatus',
        'requestedByUserId',
        'status',
        'createdAt',
        'purgeAt',
      });
      expect(captured['type'], 'end_outing');
      expect(captured['targetOutingStatus'], 'completed');
      expect(captured['requestedByUserId'], 'user-1');
    },
  );

  test('creates a self-targeted accepted-to-declined transition', () async {
    final service = FirestoreLiveMeetupTransitionService(
      firestore: firestore,
      currentUid: () => 'user-1',
    );

    await service.declineAttendance('outing-1');

    final captured =
        verify(() => transitionRef.set(captureAny())).captured.single
            as Map<String, Object?>;
    expect(captured['type'], 'change_attendance');
    expect(captured['targetUserId'], 'user-1');
    expect(captured['targetAttendanceStatus'], 'declined');
  });

  test('times out without retrying or reporting success', () async {
    when(() => transitionRef.snapshots()).thenAnswer(
      (_) => Stream.periodic(
        const Duration(milliseconds: 2),
        (_) => transitionSnapshot,
      ),
    );
    when(() => transitionSnapshot.data()).thenReturn({'status': 'pending'});
    final service = FirestoreLiveMeetupTransitionService(
      firestore: firestore,
      currentUid: () => 'user-1',
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      service.endOuting('outing-1', OutingStatus.completed),
      throwsA(isA<LiveMeetupOfflineFailure>()),
    );

    verify(() => transitionRef.set(any())).called(1);
  });

  test('rejects non-terminal outing targets before writing', () async {
    final service = FirestoreLiveMeetupTransitionService(
      firestore: firestore,
      currentUid: () => 'user-1',
    );

    expect(
      () => service.endOuting('outing-1', OutingStatus.meeting),
      throwsA(isA<LiveMeetupValidationFailure>()),
    );
    verifyNever(() => transitionRef.set(any()));
  });

  test('maps terminal backend errors to requester-safe failures', () async {
    when(() => transitionSnapshot.data()).thenReturn({
      'status': 'failed',
      'errorCode': 'permission_denied',
      'errorMessage': 'must never be surfaced',
    });
    final service = FirestoreLiveMeetupTransitionService(
      firestore: firestore,
      currentUid: () => 'user-1',
    );

    final result = await service.deleteCrew('crew-1');

    expect(result.status, LiveMeetupTransitionStatus.failed);
    expect(result.failure, isA<LiveMeetupAccessDenied>());
    expect(result.failure!.message, isNot(contains('never')));
  });
}
