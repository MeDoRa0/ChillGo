import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chillgo/features/profile/data/datasources/firestore_profile_datasource.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseStorage mockStorage;
  late FirestoreProfileDatasource datasource;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    datasource = FirestoreProfileDatasource(
      firestore: mockFirestore,
      storage: mockStorage,
    );
  });

  group('FirestoreProfileDatasource Username Validation', () {
    test('isUsernameAvailable returns false for invalid usernames containing spaces', () async {
      final result1 = await datasource.isUsernameAvailable('user name');
      final result2 = await datasource.isUsernameAvailable('  user name  ');
      final result3 = await datasource.isUsernameAvailable('');

      expect(result1, isFalse);
      expect(result2, isFalse);
      expect(result3, isFalse);
    });

    test('isUsernameAvailable calls firestore for valid usernames after normalizing', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('usernames')).thenReturn(mockCollection);
      when(() => mockCollection.doc('validuser')).thenReturn(mockDoc);
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      final result = await datasource.isUsernameAvailable(' ValidUser  ');
      expect(result, isTrue);

      verify(() => mockFirestore.collection('usernames')).called(1);
      verify(() => mockCollection.doc('validuser')).called(1);
    });

    test('createProfile throws ArgumentError for usernames containing internal spaces', () async {
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
    });
  });
}
