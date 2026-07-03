// ignore_for_file: subtype_of_sealed_class

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
            verify(() => batch.set(membershipRef, captureAny())).captured.single
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
}
