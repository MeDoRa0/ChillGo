// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/crews/data/datasources/firestore_crews_datasource.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class MockTransaction extends Mock implements Transaction {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference crews;
  late MockCollectionReference memberships;
  late MockCollectionReference invitations;
  late MockCollectionReference usernames;
  late MockCollectionReference users;
  late MockCollectionReference outings;
  late MockCollectionReference participants;
  late FirestoreCrewsDatasource datasource;

  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    firestore = MockFirebaseFirestore();
    crews = MockCollectionReference();
    memberships = MockCollectionReference();
    invitations = MockCollectionReference();
    usernames = MockCollectionReference();
    users = MockCollectionReference();
    outings = MockCollectionReference();
    participants = MockCollectionReference();

    when(() => firestore.collection('crews')).thenReturn(crews);
    when(
      () => firestore.collection('crew_memberships'),
    ).thenReturn(memberships);
    when(
      () => firestore.collection('crew_invitations'),
    ).thenReturn(invitations);
    when(() => firestore.collection('usernames')).thenReturn(usernames);
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => firestore.collection('outings')).thenReturn(outings);
    when(
      () => firestore.collection('outing_participants'),
    ).thenReturn(participants);

    final outingsQuery = MockQuery();
    final outingsSnapshot = MockQuerySnapshot();
    final participantsQuery = MockQuery();
    final participantsSnapshot = MockQuerySnapshot();
    when(
      () => outings.where('crewId', isEqualTo: 'crew1'),
    ).thenReturn(outingsQuery);
    when(() => outingsQuery.get()).thenAnswer((_) async => outingsSnapshot);
    when(() => outingsSnapshot.docs).thenReturn([]);
    when(
      () => participants.where('crewId', isEqualTo: 'crew1'),
    ).thenReturn(participantsQuery);
    when(
      () => participantsQuery.get(),
    ).thenAnswer((_) async => participantsSnapshot);
    when(() => participantsSnapshot.docs).thenReturn([]);

    datasource = FirestoreCrewsDatasource(firestore: firestore);
  });

  group('usernameExists', () {
    test('returns true when normalized username document exists', () async {
      final usernameRef = MockDocumentReference();
      final usernameSnap = MockDocumentSnapshot();

      when(() => usernames.doc('bob_chill')).thenReturn(usernameRef);
      when(() => usernameRef.get()).thenAnswer((_) async => usernameSnap);
      when(() => usernameSnap.exists).thenReturn(true);

      expect(await datasource.usernameExists(' Bob_Chill '), isTrue);
      verify(() => usernames.doc('bob_chill')).called(1);
    });

    test(
      'returns false for invalid username without reading Firestore',
      () async {
        expect(await datasource.usernameExists('bob chill'), isFalse);
        verifyNever(() => usernames.doc(any()));
      },
    );
  });

  group('inviteUser', () {
    test('writes invitation using inviter profile from Firestore', () async {
      final usernameRef = MockDocumentReference();
      final usernameSnap = MockDocumentSnapshot();
      final inviterRef = MockDocumentReference();
      final inviterSnap = MockDocumentSnapshot();
      final invitationRef = MockDocumentReference();

      when(() => usernames.doc('bob')).thenReturn(usernameRef);
      when(() => usernameRef.get()).thenAnswer((_) async => usernameSnap);
      when(() => usernameSnap.exists).thenReturn(true);
      when(() => usernameSnap.data()).thenReturn({'uid': 'bob'});
      when(() => users.doc('alice')).thenReturn(inviterRef);
      when(() => inviterRef.get()).thenAnswer((_) async => inviterSnap);
      when(() => inviterSnap.exists).thenReturn(true);
      when(() => inviterSnap.data()).thenReturn({
        'username': 'alice_profile',
        'displayName': 'Alice Profile',
      });
      when(() => invitations.doc('crew1_bob')).thenReturn(invitationRef);
      when(() => invitationRef.set(any())).thenAnswer((_) async {});

      await datasource.inviteUser(
        crewId: 'crew1',
        inviterUid: 'alice',
        crewName: 'Weekend Hikers',
        targetUsername: ' Bob ',
      );

      verifyNever(() => memberships.doc('crew1_bob'));
      final invitationData =
          verify(() => invitationRef.set(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(invitationData, isNot(contains('id')));
      expect(invitationData['crewId'], 'crew1');
      expect(invitationData['invitedUserId'], 'bob');
      expect(invitationData['invitedByUserId'], 'alice');
      expect(invitationData['invitedByUsername'], 'alice_profile');
      expect(invitationData['invitedByDisplayName'], 'Alice Profile');
      expect(invitationData['invitedUsername'], 'bob');
    });
  });

  group('streamCrewsForUser', () {
    test('ignores malformed membership records while loading crews', () async {
      final membershipsQuery = MockQuery();
      final membershipsSnap = MockQuerySnapshot();
      final invalidMembershipDoc = MockQueryDocumentSnapshot();
      final membershipDoc = MockQueryDocumentSnapshot();
      final crewRef = MockDocumentReference();
      final crewDoc = MockDocumentSnapshot();

      when(
        () => memberships.where('userId', isEqualTo: 'alice'),
      ).thenReturn(membershipsQuery);
      when(
        () => membershipsQuery.snapshots(),
      ).thenAnswer((_) => Stream.value(membershipsSnap));
      when(
        () => membershipsSnap.docs,
      ).thenReturn([invalidMembershipDoc, membershipDoc]);
      when(() => invalidMembershipDoc.data()).thenReturn({'crewId': null});
      when(() => membershipDoc.data()).thenReturn({'crewId': 'crew1'});

      when(() => crews.doc('crew1')).thenReturn(crewRef);
      when(() => crewRef.get()).thenAnswer((_) async => crewDoc);
      when(() => crewDoc.exists).thenReturn(true);
      when(() => crewDoc.id).thenReturn('crew1');
      when(() => crewDoc.data()).thenReturn({
        'name': 'Weekend Hikers',
        'ownerId': 'alice',
        'createdAt': '2026-07-01T00:00:00Z',
      });

      final result = await datasource.streamCrewsForUser('alice').first;

      expect(result, hasLength(1));
      expect(result.single.id, 'crew1');
      expect(result.single.name, 'Weekend Hikers');
      verify(() => crews.doc('crew1')).called(1);
      verifyNever(() => crews.where(any(), whereIn: any(named: 'whereIn')));
    });

    test('loads crew documents directly without serial waits', () async {
      final membershipsQuery = MockQuery();
      final membershipsSnap = MockQuerySnapshot();
      final firstMembershipDoc = MockQueryDocumentSnapshot();
      final secondMembershipDoc = MockQueryDocumentSnapshot();
      final firstCrewRef = MockDocumentReference();
      final secondCrewRef = MockDocumentReference();
      final firstCrewDoc = MockDocumentSnapshot();
      final secondCrewDoc = MockDocumentSnapshot();
      final firstGet = Completer<DocumentSnapshot<Map<String, dynamic>>>();
      final secondGet = Completer<DocumentSnapshot<Map<String, dynamic>>>();

      when(
        () => memberships.where('userId', isEqualTo: 'alice'),
      ).thenReturn(membershipsQuery);
      when(
        () => membershipsQuery.snapshots(),
      ).thenAnswer((_) => Stream.value(membershipsSnap));
      when(
        () => membershipsSnap.docs,
      ).thenReturn([firstMembershipDoc, secondMembershipDoc]);
      when(() => firstMembershipDoc.data()).thenReturn({'crewId': 'crew0'});
      when(() => secondMembershipDoc.data()).thenReturn({'crewId': 'crew1'});

      when(() => crews.doc('crew0')).thenReturn(firstCrewRef);
      when(() => crews.doc('crew1')).thenReturn(secondCrewRef);
      when(() => firstCrewRef.get()).thenAnswer((_) => firstGet.future);
      when(() => secondCrewRef.get()).thenAnswer((_) => secondGet.future);
      when(() => firstCrewDoc.exists).thenReturn(true);
      when(() => secondCrewDoc.exists).thenReturn(true);
      when(() => firstCrewDoc.id).thenReturn('crew0');
      when(() => secondCrewDoc.id).thenReturn('crew1');
      when(() => firstCrewDoc.data()).thenReturn({
        'name': 'Crew 0',
        'ownerId': 'alice',
        'createdAt': '2026-07-01T00:00:00Z',
      });
      when(() => secondCrewDoc.data()).thenReturn({
        'name': 'Crew 1',
        'ownerId': 'alice',
        'createdAt': '2026-07-01T00:00:00Z',
      });

      final resultFuture = datasource.streamCrewsForUser('alice').first;
      await Future<void>.delayed(Duration.zero);

      verify(() => firstCrewRef.get()).called(1);
      verify(() => secondCrewRef.get()).called(1);

      firstGet.complete(firstCrewDoc);
      secondGet.complete(secondCrewDoc);
      final result = await resultFuture;

      expect(result.map((crew) => crew.id), ['crew0', 'crew1']);
      verifyNever(() => crews.where(any(), whereIn: any(named: 'whereIn')));
    });
  });

  group('acceptInvitation', () {
    test(
      'creates membership using stored crewId and deletes invitation',
      () async {
        final invitationRef = MockDocumentReference();
        final invitationSnap = MockDocumentSnapshot();
        final userRef = MockDocumentReference();
        final userSnap = MockDocumentSnapshot();
        final membershipRef = MockDocumentReference();
        final transaction = MockTransaction();

        when(
          () => invitations.doc('crew_with_underscore_alice'),
        ).thenReturn(invitationRef);
        when(
          () => transaction.get<Map<String, dynamic>>(invitationRef),
        ).thenAnswer((_) async => invitationSnap);
        when(() => invitationSnap.exists).thenReturn(true);
        when(() => invitationSnap.id).thenReturn('crew_with_underscore_alice');
        when(() => invitationSnap.data()).thenReturn({
          'id': 'crew_with_underscore_alice',
          'crewId': 'crew_actual',
          'invitedUserId': 'alice',
          'invitedByUserId': 'owner',
          'createdAt': '2026-07-01T00:00:00Z',
          'crewName': 'Weekend Hikers',
          'invitedByUsername': 'owner_user',
          'invitedByDisplayName': 'Owner',
        });

        when(() => users.doc('alice')).thenReturn(userRef);
        when(
          () => transaction.get<Map<String, dynamic>>(userRef),
        ).thenAnswer((_) async => userSnap);
        when(() => userSnap.data()).thenReturn({
          'username': 'alice_cool',
          'displayName': 'Alice',
          'avatarUrl': 'https://example.com/alice.png',
        });

        when(
          () => memberships.doc('crew_actual_alice'),
        ).thenReturn(membershipRef);
        when(
          () => transaction.set<Map<String, dynamic>>(any(), any()),
        ).thenReturn(transaction);
        when(() => transaction.delete(invitationRef)).thenReturn(transaction);
        when(() => firestore.runTransaction<void>(any())).thenAnswer((
          invocation,
        ) async {
          final handler =
              invocation.positionalArguments.single
                  as Future<void> Function(Transaction);
          await handler(transaction);
        });

        await datasource.acceptInvitation(
          invitationId: 'crew_with_underscore_alice',
          userId: 'alice',
        );

        final membershipData =
            verify(
                  () => transaction.set<Map<String, dynamic>>(
                    any(),
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(membershipData, isNot(contains('id')));
        expect(membershipData['crewId'], 'crew_actual');
        expect(membershipData['userId'], 'alice');
        expect(membershipData['role'], 'member');
        verify(() => transaction.delete(invitationRef)).called(1);
        verify(() => firestore.runTransaction<void>(any())).called(1);
      },
    );

    test('rejects invitation for a different user before writing', () async {
      final invitationRef = MockDocumentReference();
      final invitationSnap = MockDocumentSnapshot();
      final userRef = MockDocumentReference();
      final transaction = MockTransaction();

      when(() => invitations.doc('crew1_bob')).thenReturn(invitationRef);
      when(() => users.doc('alice')).thenReturn(userRef);
      when(
        () => transaction.get<Map<String, dynamic>>(invitationRef),
      ).thenAnswer((_) async => invitationSnap);
      when(() => invitationSnap.exists).thenReturn(true);
      when(() => invitationSnap.id).thenReturn('crew1_bob');
      when(() => invitationSnap.data()).thenReturn({
        'id': 'crew1_bob',
        'crewId': 'crew1',
        'invitedUserId': 'bob',
        'invitedByUserId': 'owner',
        'createdAt': '2026-07-01T00:00:00Z',
        'crewName': 'Weekend Hikers',
        'invitedByUsername': 'owner_user',
        'invitedByDisplayName': 'Owner',
      });
      when(() => firestore.runTransaction<void>(any())).thenAnswer((
        invocation,
      ) async {
        final handler =
            invocation.positionalArguments.single
                as Future<void> Function(Transaction);
        await handler(transaction);
      });

      expect(
        () => datasource.acceptInvitation(
          invitationId: 'crew1_bob',
          userId: 'alice',
        ),
        throwsException,
      );
      verifyNever(() => transaction.set<Map<String, dynamic>>(any(), any()));
    });
  });

  test('removeMember deletes that user participant records in the crew', () async {
    final participantQuery = MockQuery();
    final participantSnapshot = MockQuerySnapshot();
    final crewParticipant = MockQueryDocumentSnapshot();
    final otherCrewParticipant = MockQueryDocumentSnapshot();
    final crewParticipantRef = MockDocumentReference();
    final otherCrewParticipantRef = MockDocumentReference();
    final membershipRef = MockDocumentReference();
    final batch = MockWriteBatch();

    when(
      () => participants.where('userId', isEqualTo: 'bob'),
    ).thenReturn(participantQuery);
    when(
      () => participantQuery.get(),
    ).thenAnswer((_) async => participantSnapshot);
    when(
      () => participantSnapshot.docs,
    ).thenReturn([crewParticipant, otherCrewParticipant]);
    when(() => crewParticipant.data()).thenReturn({'crewId': 'crew1'});
    when(() => otherCrewParticipant.data()).thenReturn({'crewId': 'crew2'});
    when(() => crewParticipant.reference).thenReturn(crewParticipantRef);
    when(
      () => otherCrewParticipant.reference,
    ).thenReturn(otherCrewParticipantRef);
    when(() => memberships.doc('crew1_bob')).thenReturn(membershipRef);
    when(() => firestore.batch()).thenReturn(batch);
    when(() => batch.delete(any())).thenReturn(null);
    when(() => batch.commit()).thenAnswer((_) async {});

    await datasource.removeMember('crew1', 'bob');

    verify(() => batch.delete(crewParticipantRef)).called(1);
    verifyNever(() => batch.delete(otherCrewParticipantRef));
    verify(() => batch.delete(membershipRef)).called(1);
    verify(() => batch.commit()).called(1);
  });

  group('deleteCrew', () {
    test('splits deletes across batches at Firestore write limit', () async {
      const crewId = 'crew1';
      final membershipsQuery = MockQuery();
      final invitationsQuery = MockQuery();
      final membershipsSnap = MockQuerySnapshot();
      final invitationsSnap = MockQuerySnapshot();
      final crewRef = MockDocumentReference();
      final crewSnap = MockDocumentSnapshot();
      final ownerMembershipRef = MockDocumentReference();
      final firstBatch = MockWriteBatch();
      final secondBatch = MockWriteBatch();
      var batchIndex = 0;

      final membershipDocs = List<MockQueryDocumentSnapshot>.generate(
        499,
        (_) => MockQueryDocumentSnapshot(),
      );
      final invitationDocs = [MockQueryDocumentSnapshot()];
      final membershipRefs = List<MockDocumentReference>.generate(
        membershipDocs.length,
        (_) => MockDocumentReference(),
      );
      final invitationRef = MockDocumentReference();

      when(
        () => memberships.where('crewId', isEqualTo: crewId),
      ).thenReturn(membershipsQuery);
      when(
        () => membershipsQuery.get(),
      ).thenAnswer((_) async => membershipsSnap);
      when(() => membershipsSnap.docs).thenReturn(membershipDocs);
      for (var i = 0; i < membershipDocs.length; i++) {
        when(() => membershipDocs[i].reference).thenReturn(membershipRefs[i]);
        when(() => membershipDocs[i].id).thenReturn('member_$i');
      }

      when(
        () => invitations.where('crewId', isEqualTo: crewId),
      ).thenReturn(invitationsQuery);
      when(
        () => invitationsQuery.get(),
      ).thenAnswer((_) async => invitationsSnap);
      when(() => invitationsSnap.docs).thenReturn(invitationDocs);
      when(() => invitationDocs.single.reference).thenReturn(invitationRef);

      when(() => crews.doc(crewId)).thenReturn(crewRef);
      when(() => crewRef.get()).thenAnswer((_) async => crewSnap);
      when(() => crewSnap.data()).thenReturn({'ownerId': 'owner'});
      when(
        () => memberships.doc('${crewId}_owner'),
      ).thenReturn(ownerMembershipRef);
      when(() => ownerMembershipRef.id).thenReturn('${crewId}_owner');
      when(() => firestore.batch()).thenAnswer((_) {
        final batch = [firstBatch, secondBatch][batchIndex];
        batchIndex++;
        return batch;
      });
      when(() => firstBatch.delete(any())).thenReturn(null);
      when(() => secondBatch.delete(any())).thenReturn(null);
      when(() => firstBatch.commit()).thenAnswer((_) async {});
      when(() => secondBatch.commit()).thenAnswer((_) async {});

      await datasource.deleteCrew(crewId);

      verify(() => firstBatch.delete(any())).called(500);
      verify(() => firstBatch.commit()).called(1);
      verify(() => secondBatch.delete(ownerMembershipRef)).called(1);
      verify(() => secondBatch.delete(crewRef)).called(1);
      verify(() => secondBatch.commit()).called(1);
    });

    test('rebuilds and retries a failed delete batch', () async {
      const crewId = 'crew1';
      final membershipsQuery = MockQuery();
      final invitationsQuery = MockQuery();
      final membershipsSnap = MockQuerySnapshot();
      final invitationsSnap = MockQuerySnapshot();
      final membershipDoc = MockQueryDocumentSnapshot();
      final membershipRef = MockDocumentReference();
      final crewRef = MockDocumentReference();
      final crewSnap = MockDocumentSnapshot();
      final ownerMembershipRef = MockDocumentReference();
      final dependencyBatch = MockWriteBatch();
      final failedBatch = MockWriteBatch();
      final retryBatch = MockWriteBatch();
      var batchIndex = 0;

      when(
        () => memberships.where('crewId', isEqualTo: crewId),
      ).thenReturn(membershipsQuery);
      when(
        () => membershipsQuery.get(),
      ).thenAnswer((_) async => membershipsSnap);
      when(() => membershipsSnap.docs).thenReturn([membershipDoc]);
      when(() => membershipDoc.reference).thenReturn(membershipRef);
      when(() => membershipDoc.id).thenReturn('crew1_member');

      when(
        () => invitations.where('crewId', isEqualTo: crewId),
      ).thenReturn(invitationsQuery);
      when(
        () => invitationsQuery.get(),
      ).thenAnswer((_) async => invitationsSnap);
      when(() => invitationsSnap.docs).thenReturn([]);

      when(() => crews.doc(crewId)).thenReturn(crewRef);
      when(() => crewRef.get()).thenAnswer((_) async => crewSnap);
      when(() => crewSnap.data()).thenReturn({'ownerId': 'owner'});
      when(
        () => memberships.doc('${crewId}_owner'),
      ).thenReturn(ownerMembershipRef);
      when(() => ownerMembershipRef.id).thenReturn('${crewId}_owner');
      when(() => firestore.batch()).thenAnswer((_) {
        final batch = [dependencyBatch, failedBatch, retryBatch][batchIndex];
        batchIndex++;
        return batch;
      });
      when(() => dependencyBatch.delete(any())).thenReturn(null);
      when(() => failedBatch.delete(any())).thenReturn(null);
      when(() => retryBatch.delete(any())).thenReturn(null);
      when(() => dependencyBatch.commit()).thenAnswer((_) async {});
      when(() => failedBatch.commit()).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      when(() => retryBatch.commit()).thenAnswer((_) async {});

      await datasource.deleteCrew(crewId);

      verify(() => dependencyBatch.delete(membershipRef)).called(1);
      verify(() => dependencyBatch.commit()).called(1);
      verify(() => failedBatch.delete(ownerMembershipRef)).called(1);
      verify(() => failedBatch.delete(crewRef)).called(1);
      verify(() => failedBatch.commit()).called(1);
      verify(() => retryBatch.delete(ownerMembershipRef)).called(1);
      verify(() => retryBatch.delete(crewRef)).called(1);
      verify(() => retryBatch.commit()).called(1);
    });

    test('surfaces partial failure state when a later chunk fails', () async {
      const crewId = 'crew1';
      final membershipsQuery = MockQuery();
      final invitationsQuery = MockQuery();
      final membershipsSnap = MockQuerySnapshot();
      final invitationsSnap = MockQuerySnapshot();
      final crewRef = MockDocumentReference();
      final crewSnap = MockDocumentSnapshot();
      final ownerMembershipRef = MockDocumentReference();
      final committedBatch = MockWriteBatch();
      final failedBatches = [
        MockWriteBatch(),
        MockWriteBatch(),
        MockWriteBatch(),
      ];
      var batchIndex = 0;

      final membershipDocs = List<MockQueryDocumentSnapshot>.generate(
        499,
        (_) => MockQueryDocumentSnapshot(),
      );
      final invitationDocs = [MockQueryDocumentSnapshot()];
      final membershipRefs = List<MockDocumentReference>.generate(
        membershipDocs.length,
        (_) => MockDocumentReference(),
      );
      final invitationRef = MockDocumentReference();

      when(
        () => memberships.where('crewId', isEqualTo: crewId),
      ).thenReturn(membershipsQuery);
      when(
        () => membershipsQuery.get(),
      ).thenAnswer((_) async => membershipsSnap);
      when(() => membershipsSnap.docs).thenReturn(membershipDocs);
      for (var i = 0; i < membershipDocs.length; i++) {
        when(() => membershipDocs[i].reference).thenReturn(membershipRefs[i]);
        when(() => membershipDocs[i].id).thenReturn('member_$i');
      }

      when(
        () => invitations.where('crewId', isEqualTo: crewId),
      ).thenReturn(invitationsQuery);
      when(
        () => invitationsQuery.get(),
      ).thenAnswer((_) async => invitationsSnap);
      when(() => invitationsSnap.docs).thenReturn(invitationDocs);
      when(() => invitationDocs.single.reference).thenReturn(invitationRef);

      when(() => crews.doc(crewId)).thenReturn(crewRef);
      when(() => crewRef.get()).thenAnswer((_) async => crewSnap);
      when(() => crewSnap.data()).thenReturn({'ownerId': 'owner'});
      when(
        () => memberships.doc('${crewId}_owner'),
      ).thenReturn(ownerMembershipRef);
      when(() => ownerMembershipRef.id).thenReturn('${crewId}_owner');
      when(() => firestore.batch()).thenAnswer((_) {
        final batches = [committedBatch, ...failedBatches];
        final batch = batches[batchIndex];
        batchIndex++;
        return batch;
      });
      when(() => committedBatch.delete(any())).thenReturn(null);
      when(() => committedBatch.commit()).thenAnswer((_) async {});
      for (final batch in failedBatches) {
        when(() => batch.delete(any())).thenReturn(null);
        when(() => batch.commit()).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );
      }

      await expectLater(
        datasource.deleteCrew(crewId),
        throwsA(
          isA<CrewDeletePartialFailureException>()
              .having((error) => error.crewId, 'crewId', crewId)
              .having(
                (error) => error.committedChunkCount,
                'committedChunkCount',
                1,
              )
              .having(
                (error) => error.failedChunkNumber,
                'failedChunkNumber',
                2,
              )
              .having((error) => error.totalChunkCount, 'totalChunkCount', 2)
              .having(
                (error) => error.remainingDocumentCount,
                'remainingDocumentCount',
                2,
              ),
        ),
      );
      verify(() => failedBatches.last.commit()).called(1);
    });
  });
}
