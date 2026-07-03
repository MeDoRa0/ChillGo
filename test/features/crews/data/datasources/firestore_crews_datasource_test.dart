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

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference crews;
  late MockCollectionReference memberships;
  late MockCollectionReference invitations;
  late MockCollectionReference usernames;
  late MockCollectionReference users;
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

    when(() => firestore.collection('crews')).thenReturn(crews);
    when(
      () => firestore.collection('crew_memberships'),
    ).thenReturn(memberships);
    when(
      () => firestore.collection('crew_invitations'),
    ).thenReturn(invitations);
    when(() => firestore.collection('usernames')).thenReturn(usernames);
    when(() => firestore.collection('users')).thenReturn(users);

    datasource = FirestoreCrewsDatasource(firestore: firestore);
  });

  group('streamCrewsForUser', () {
    test('ignores malformed membership records while loading crews', () async {
      final membershipsQuery = MockQuery();
      final membershipsSnap = MockQuerySnapshot();
      final invalidMembershipDoc = MockQueryDocumentSnapshot();
      final membershipDoc = MockQueryDocumentSnapshot();
      final crewsQuery = MockQuery();
      final crewsSnap = MockQuerySnapshot();
      final crewDoc = MockQueryDocumentSnapshot();

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

      when(
        () => crews.where(any(), whereIn: any(named: 'whereIn')),
      ).thenReturn(crewsQuery);
      when(() => crewsQuery.get()).thenAnswer((_) async => crewsSnap);
      when(() => crewsSnap.docs).thenReturn([crewDoc]);
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
      final whereInValues =
          verify(
                () => crews.where(any(), whereIn: captureAny(named: 'whereIn')),
              ).captured.single
              as List<String>;
      expect(whereInValues, ['crew1']);
    });

    test(
      'splits crew lookups into 30-id chunks without serial waits',
      () async {
        final membershipsQuery = MockQuery();
        final membershipsSnap = MockQuerySnapshot();
        final membershipDocs = List<MockQueryDocumentSnapshot>.generate(
          31,
          (_) => MockQueryDocumentSnapshot(),
        );
        final firstCrewsQuery = MockQuery();
        final secondCrewsQuery = MockQuery();
        final firstCrewsSnap = MockQuerySnapshot();
        final secondCrewsSnap = MockQuerySnapshot();
        final firstCrewDoc = MockQueryDocumentSnapshot();
        final secondCrewDoc = MockQueryDocumentSnapshot();
        final firstGet = Completer<QuerySnapshot<Map<String, dynamic>>>();
        final secondGet = Completer<QuerySnapshot<Map<String, dynamic>>>();

        when(
          () => memberships.where('userId', isEqualTo: 'alice'),
        ).thenReturn(membershipsQuery);
        when(
          () => membershipsQuery.snapshots(),
        ).thenAnswer((_) => Stream.value(membershipsSnap));
        when(() => membershipsSnap.docs).thenReturn(membershipDocs);
        for (var i = 0; i < membershipDocs.length; i++) {
          when(() => membershipDocs[i].data()).thenReturn({'crewId': 'crew$i'});
        }

        when(
          () => crews.where(any(), whereIn: any(named: 'whereIn')),
        ).thenAnswer((invocation) {
          final ids = invocation.namedArguments[#whereIn] as List<String>;
          return ids.length == 30 ? firstCrewsQuery : secondCrewsQuery;
        });
        when(() => firstCrewsQuery.get()).thenAnswer((_) => firstGet.future);
        when(() => secondCrewsQuery.get()).thenAnswer((_) => secondGet.future);
        when(() => firstCrewsSnap.docs).thenReturn([firstCrewDoc]);
        when(() => secondCrewsSnap.docs).thenReturn([secondCrewDoc]);
        when(() => firstCrewDoc.id).thenReturn('crew0');
        when(() => secondCrewDoc.id).thenReturn('crew30');
        when(() => firstCrewDoc.data()).thenReturn({
          'name': 'Crew 0',
          'ownerId': 'alice',
          'createdAt': '2026-07-01T00:00:00Z',
        });
        when(() => secondCrewDoc.data()).thenReturn({
          'name': 'Crew 30',
          'ownerId': 'alice',
          'createdAt': '2026-07-01T00:00:00Z',
        });

        final resultFuture = datasource.streamCrewsForUser('alice').first;
        await Future<void>.delayed(Duration.zero);

        verify(() => firstCrewsQuery.get()).called(1);
        verify(() => secondCrewsQuery.get()).called(1);

        firstGet.complete(firstCrewsSnap);
        secondGet.complete(secondCrewsSnap);
        final result = await resultFuture;

        expect(result.map((crew) => crew.id), ['crew0', 'crew30']);
        final whereInValues = verify(
          () => crews.where(any(), whereIn: captureAny(named: 'whereIn')),
        ).captured.cast<List<String>>();
        expect(whereInValues.map((ids) => ids.length), [30, 1]);
      },
    );
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
        final batch = MockWriteBatch();

        when(
          () => invitations.doc('crew_with_underscore_alice'),
        ).thenReturn(invitationRef);
        when(() => invitationRef.get()).thenAnswer((_) async => invitationSnap);
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
        when(() => userRef.get()).thenAnswer((_) async => userSnap);
        when(() => userSnap.data()).thenReturn({
          'username': 'alice_cool',
          'displayName': 'Alice',
          'avatarUrl': 'https://example.com/alice.png',
        });

        when(
          () => memberships.doc('crew_actual_alice'),
        ).thenReturn(membershipRef);
        when(() => firestore.batch()).thenReturn(batch);
        when(() => batch.set(any(), any())).thenReturn(null);
        when(() => batch.delete(invitationRef)).thenReturn(null);
        when(() => batch.commit()).thenAnswer((_) async {});

        await datasource.acceptInvitation(
          invitationId: 'crew_with_underscore_alice',
          userId: 'alice',
        );

        final membershipData =
            verify(
                  () => batch.set<Map<String, dynamic>>(
                    any(),
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(membershipData['id'], 'crew_actual_alice');
        expect(membershipData['crewId'], 'crew_actual');
        expect(membershipData['userId'], 'alice');
        expect(membershipData['role'], 'member');
        verify(() => batch.delete(invitationRef)).called(1);
        verify(() => batch.commit()).called(1);
      },
    );

    test('rejects invitation for a different user before writing', () async {
      final invitationRef = MockDocumentReference();
      final invitationSnap = MockDocumentSnapshot();

      when(() => invitations.doc('crew1_bob')).thenReturn(invitationRef);
      when(() => invitationRef.get()).thenAnswer((_) async => invitationSnap);
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

      expect(
        () => datasource.acceptInvitation(
          invitationId: 'crew1_bob',
          userId: 'alice',
        ),
        throwsException,
      );
      verifyNever(() => firestore.batch());
    });
  });

  group('deleteCrew', () {
    test('splits deletes across batches at Firestore write limit', () async {
      const crewId = 'crew1';
      final membershipsQuery = MockQuery();
      final invitationsQuery = MockQuery();
      final membershipsSnap = MockQuerySnapshot();
      final invitationsSnap = MockQuerySnapshot();
      final crewRef = MockDocumentReference();
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

      when(
        () => invitations.where('crewId', isEqualTo: crewId),
      ).thenReturn(invitationsQuery);
      when(
        () => invitationsQuery.get(),
      ).thenAnswer((_) async => invitationsSnap);
      when(() => invitationsSnap.docs).thenReturn([]);

      when(() => crews.doc(crewId)).thenReturn(crewRef);
      when(() => firestore.batch()).thenAnswer((_) {
        final batch = [failedBatch, retryBatch][batchIndex];
        batchIndex++;
        return batch;
      });
      when(() => failedBatch.delete(any())).thenReturn(null);
      when(() => retryBatch.delete(any())).thenReturn(null);
      when(() => failedBatch.commit()).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      when(() => retryBatch.commit()).thenAnswer((_) async {});

      await datasource.deleteCrew(crewId);

      verify(() => failedBatch.delete(membershipRef)).called(1);
      verify(() => failedBatch.delete(crewRef)).called(1);
      verify(() => failedBatch.commit()).called(1);
      verify(() => retryBatch.delete(membershipRef)).called(1);
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
                1,
              ),
        ),
      );
      verify(() => failedBatches.last.commit()).called(1);
    });
  });
}
