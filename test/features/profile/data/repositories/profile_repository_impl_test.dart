import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:chillgo/features/profile/data/datasources/firestore_profile_datasource.dart';
import 'package:chillgo/features/authentication/domain/entities/user_profile.dart';

class MockFirestoreProfileDatasource extends Mock implements FirestoreProfileDatasource {}

void main() {
  late MockFirestoreProfileDatasource mockDatasource;
  late ProfileRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockFirestoreProfileDatasource();
    repository = ProfileRepositoryImpl(profileDatasource: mockDatasource);
  });

  group('ProfileRepositoryImpl', () {
    test('getProfile returns UserProfile when profile exists', () async {
      final userProfile = UserProfile(
        id: 'test_uid',
        username: 'testuser',
        displayName: 'Test User',
        createdAt: DateTime.now(),
      );

      when(() => mockDatasource.getProfile('test_uid')).thenAnswer((_) async => userProfile);

      final result = await repository.getProfile('test_uid');
      expect(result, equals(userProfile));
    });

    test('isUsernameAvailable returns true when username is unique', () async {
      when(() => mockDatasource.isUsernameAvailable('unique_user')).thenAnswer((_) async => true);

      final result = await repository.isUsernameAvailable('unique_user');
      expect(result, isTrue);
    });

    test('createProfile calls datasource createProfile', () async {
      when(() => mockDatasource.createProfile(
        uid: 'test_uid',
        username: 'testuser',
        displayName: 'Test User',
      )).thenAnswer((_) async {});

      await repository.createProfile(
        uid: 'test_uid',
        username: 'testuser',
        displayName: 'Test User',
      );

      verify(() => mockDatasource.createProfile(
        uid: 'test_uid',
        username: 'testuser',
        displayName: 'Test User',
      )).called(1);
    });
  });
}
