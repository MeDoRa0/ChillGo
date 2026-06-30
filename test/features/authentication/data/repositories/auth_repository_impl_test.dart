import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/authentication/domain/entities/user_profile.dart';
import 'package:chillgo/features/authentication/data/datasources/firebase_auth_datasource.dart';
import 'package:chillgo/features/profile/domain/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MockFirebaseAuthDatasource extends Mock implements FirebaseAuthDatasource {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockUser extends Mock implements firebase_auth.User {}
class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

void main() {
  late MockFirebaseAuthDatasource mockDatasource;
  late MockProfileRepository mockProfileRepository;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockFirebaseAuthDatasource();
    mockProfileRepository = MockProfileRepository();
  });

  group('AuthRepositoryImpl', () {
    test('emits unauthenticated when user is null', () async {
      when(() => mockDatasource.authStateChanges).thenAnswer((_) => Stream.value(null));
      when(() => mockDatasource.currentUser).thenReturn(null);

      repository = AuthRepositoryImpl(
        authDatasource: mockDatasource,
        profileRepository: mockProfileRepository,
      );

      expect(
        repository.status,
        emitsInOrder([AuthStatus.unauthenticated]),
      );
    });

    test('emits authenticatedNoProfile when user is logged in but has no profile', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test_uid');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.photoURL).thenReturn('photo_url');

      when(() => mockDatasource.authStateChanges).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockDatasource.currentUser).thenReturn(mockUser);
      when(() => mockProfileRepository.getProfile('test_uid')).thenAnswer((_) async => null);

      repository = AuthRepositoryImpl(
        authDatasource: mockDatasource,
        profileRepository: mockProfileRepository,
      );

      expect(
        repository.status,
        emitsInOrder([AuthStatus.authenticatedNoProfile]),
      );
    });

    test('emits authenticatedWithProfile when user is logged in and has profile', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test_uid');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.photoURL).thenReturn('photo_url');

      final userProfile = UserProfile(
        id: 'test_uid',
        username: 'testuser',
        displayName: 'Test User',
        createdAt: DateTime.now(),
      );

      when(() => mockDatasource.authStateChanges).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockDatasource.currentUser).thenReturn(mockUser);
      when(() => mockProfileRepository.getProfile('test_uid')).thenAnswer((_) async => userProfile);

      repository = AuthRepositoryImpl(
        authDatasource: mockDatasource,
        profileRepository: mockProfileRepository,
      );

      expect(
        repository.status,
        emitsInOrder([AuthStatus.authenticatedWithProfile]),
      );
    });
  });
}
