// ignore_for_file: subtype_of_sealed_class

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chillgo/features/profile/data/datasources/firestore_profile_datasource.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

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
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseStorage mockStorage;
  late FirestoreProfileDatasource datasource;

  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    datasource = FirestoreProfileDatasource(
      firestore: mockFirestore,
      storage: mockStorage,
    );
  });

  group('FirestoreProfileDatasource Username Validation', () {
    test(
      'isUsernameAvailable returns false for invalid usernames containing spaces',
      () async {
        final result1 = await datasource.isUsernameAvailable('user name');
        final result2 = await datasource.isUsernameAvailable('  user name  ');
        final result3 = await datasource.isUsernameAvailable('');

        expect(result1, isFalse);
        expect(result2, isFalse);
        expect(result3, isFalse);
      },
    );

    test(
      'isUsernameAvailable calls firestore for valid usernames after normalizing',
      () async {
        final mockCollection = MockCollectionReference();
        final mockDoc = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(
          () => mockFirestore.collection('usernames'),
        ).thenReturn(mockCollection);
        when(() => mockCollection.doc('validuser')).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        final result = await datasource.isUsernameAvailable(' ValidUser  ');
        expect(result, isTrue);

        verify(() => mockFirestore.collection('usernames')).called(1);
        verify(() => mockCollection.doc('validuser')).called(1);
      },
    );

    test(
      'createProfile throws ArgumentError for usernames containing internal spaces',
      () async {
        expect(
          () => datasource.createProfile(
            uid: 'uid',
            username: 'user name',
            displayName: 'Display Name',
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => datasource.createProfile(
            uid: 'uid',
            username: '',
            displayName: 'Display Name',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  test('getProfile reads native Firestore timestamps', () async {
    final users = MockCollectionReference();
    final userRef = MockDocumentReference();
    final userSnapshot = MockDocumentSnapshot();
    final createdAt = DateTime.utc(2026, 7, 1, 12);

    when(() => mockFirestore.collection('users')).thenReturn(users);
    when(() => users.doc('alice')).thenReturn(userRef);
    when(() => userRef.get()).thenAnswer((_) async => userSnapshot);
    when(() => userSnapshot.exists).thenReturn(true);
    when(() => userSnapshot.data()).thenReturn({
      'username': 'alice',
      'displayName': 'Alice',
      'createdAt': Timestamp.fromDate(createdAt),
    });

    final profile = await datasource.getProfile('alice');

    expect(profile?.createdAt, createdAt);
  });

  test(
    'updateProfile synchronizes membership and participant caches',
    () async {
      final users = MockCollectionReference();
      final memberships = MockCollectionReference();
      final participants = MockCollectionReference();
      final membershipsQuery = MockQuery();
      final participantsQuery = MockQuery();
      final membershipsSnapshot = MockQuerySnapshot();
      final participantsSnapshot = MockQuerySnapshot();
      final membershipDocument = MockQueryDocumentSnapshot();
      final participantDocument = MockQueryDocumentSnapshot();
      final userRef = MockDocumentReference();
      final membershipRef = MockDocumentReference();
      final participantRef = MockDocumentReference();
      final batch = MockWriteBatch();

      when(() => mockFirestore.collection('users')).thenReturn(users);
      when(
        () => mockFirestore.collection('crew_memberships'),
      ).thenReturn(memberships);
      when(
        () => mockFirestore.collection('outing_participants'),
      ).thenReturn(participants);
      when(() => users.doc('alice')).thenReturn(userRef);
      when(
        () => memberships.where('userId', isEqualTo: 'alice'),
      ).thenReturn(membershipsQuery);
      when(
        () => participants.where('userId', isEqualTo: 'alice'),
      ).thenReturn(participantsQuery);
      when(
        () => membershipsQuery.get(),
      ).thenAnswer((_) async => membershipsSnapshot);
      when(
        () => participantsQuery.get(),
      ).thenAnswer((_) async => participantsSnapshot);
      when(() => membershipsSnapshot.docs).thenReturn([membershipDocument]);
      when(() => participantsSnapshot.docs).thenReturn([participantDocument]);
      when(() => membershipDocument.reference).thenReturn(membershipRef);
      when(() => participantDocument.reference).thenReturn(participantRef);
      when(() => mockFirestore.batch()).thenReturn(batch);
      when(() => batch.update(any(), any())).thenReturn(null);
      when(() => batch.commit()).thenAnswer((_) async {});

      await datasource.updateProfile(
        uid: 'alice',
        displayName: 'Alice Updated',
      );

      const expectedUpdate = {'displayName': 'Alice Updated'};
      verify(() => batch.update(userRef, expectedUpdate)).called(1);
      verify(() => batch.update(membershipRef, expectedUpdate)).called(1);
      verify(() => batch.update(participantRef, expectedUpdate)).called(1);
      verify(() => batch.commit()).called(1);
    },
  );
}
