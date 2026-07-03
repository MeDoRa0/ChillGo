import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/authentication/domain/entities/user_profile.dart';
import 'package:chillgo/features/authentication/data/datasources/firebase_auth_datasource.dart';
import 'package:chillgo/features/profile/domain/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MockFirebaseAuthDatasource extends Mock
    implements FirebaseAuthDatasource {}

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

  tearDown(() async {
    await repository.dispose();
  });

  group('AuthRepositoryImpl', () {
    test('emits unauthenticated when user is null', () async {
      when(
        () => mockDatasource.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));
      when(() => mockDatasource.currentUser).thenReturn(null);

      repository = AuthRepositoryImpl(
        authDatasource: mockDatasource,
        profileRepository: mockProfileRepository,
      );

      expect(repository.status, emitsInOrder([AuthStatus.unauthenticated]));
    });

    test(
      'emits unauthenticated when no auth state arrives and no user is restored',
      () async {
        when(
          () => mockDatasource.authStateChanges,
        ).thenAnswer((_) => const Stream<firebase_auth.User?>.empty());
        when(() => mockDatasource.currentUser).thenReturn(null);

        repository = AuthRepositoryImpl(
          authDatasource: mockDatasource,
          profileRepository: mockProfileRepository,
        );

        await Future.delayed(const Duration(milliseconds: 400));

        expect(repository.currentStatus, AuthStatus.unauthenticated);
      },
    );

    test(
      'emits authenticatedNoProfile when user is logged in but has no profile',
      () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test_uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn('photo_url');

        when(
          () => mockDatasource.authStateChanges,
        ).thenAnswer((_) => Stream.value(mockUser));
        when(() => mockDatasource.currentUser).thenReturn(mockUser);
        when(
          () => mockProfileRepository.getProfile('test_uid'),
        ).thenAnswer((_) async => null);

        repository = AuthRepositoryImpl(
          authDatasource: mockDatasource,
          profileRepository: mockProfileRepository,
        );

        expect(
          repository.status,
          emitsInOrder([AuthStatus.authenticatedNoProfile]),
        );
      },
    );

    test(
      'emits authenticatedWithProfile when user is logged in and has profile',
      () async {
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

        when(
          () => mockDatasource.authStateChanges,
        ).thenAnswer((_) => Stream.value(mockUser));
        when(() => mockDatasource.currentUser).thenReturn(mockUser);
        when(
          () => mockProfileRepository.getProfile('test_uid'),
        ).thenAnswer((_) async => userProfile);

        repository = AuthRepositoryImpl(
          authDatasource: mockDatasource,
          profileRepository: mockProfileRepository,
        );

        expect(
          repository.status,
          emitsInOrder([AuthStatus.authenticatedWithProfile]),
        );
      },
    );

    test(
      'currentCredentials uses profile display name after profile is loaded',
      () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test_uid');
        when(() => mockUser.email).thenReturn('ahmed@example.com');
        when(() => mockUser.displayName).thenReturn('Ahmed');
        when(() => mockUser.photoURL).thenReturn('photo_url');

        final userProfile = UserProfile(
          id: 'test_uid',
          username: 'omar_user',
          displayName: 'Omar',
          createdAt: DateTime.now(),
        );

        when(
          () => mockDatasource.authStateChanges,
        ).thenAnswer((_) => Stream.value(mockUser));
        when(() => mockDatasource.currentUser).thenReturn(mockUser);
        when(
          () => mockProfileRepository.getProfile('test_uid'),
        ).thenAnswer((_) async => userProfile);

        repository = AuthRepositoryImpl(
          authDatasource: mockDatasource,
          profileRepository: mockProfileRepository,
        );

        await expectLater(
          repository.status,
          emits(AuthStatus.authenticatedWithProfile),
        );

        final credentials = repository.currentCredentials;

        expect(credentials?.displayName, 'Omar');
        expect(credentials?.username, 'omar_user');
      },
    );

    test(
      'cancels restore fallback when auth stream emits user before profile resolves',
      () async {
        final authController = StreamController<firebase_auth.User?>();
        final profileCompleter = Completer<UserProfile?>();
        final mockUser = MockUser();
        var profileFetchCount = 0;

        when(() => mockUser.uid).thenReturn('test_uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn('photo_url');
        when(
          () => mockDatasource.authStateChanges,
        ).thenAnswer((_) => authController.stream);
        when(() => mockDatasource.currentUser).thenReturn(mockUser);
        when(() => mockProfileRepository.getProfile('test_uid')).thenAnswer((
          _,
        ) {
          profileFetchCount++;
          return profileCompleter.future;
        });

        repository = AuthRepositoryImpl(
          authDatasource: mockDatasource,
          profileRepository: mockProfileRepository,
        );

        authController.add(mockUser);
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(profileFetchCount, 1);

        profileCompleter.complete(null);
        await Future<void>.delayed(Duration.zero);

        expect(repository.currentStatus, AuthStatus.authenticatedNoProfile);

        await authController.close();
      },
    );

    test('forceRefreshStatus waits for stream-driven update', () async {
      final authController = StreamController<firebase_auth.User?>();
      final profileCompleters = [
        Completer<UserProfile?>(),
        Completer<UserProfile?>(),
      ];
      final mockUser = MockUser();
      var profileFetchCount = 0;

      when(() => mockUser.uid).thenReturn('test_uid');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.photoURL).thenReturn('photo_url');
      when(
        () => mockDatasource.authStateChanges,
      ).thenAnswer((_) => authController.stream);
      when(() => mockDatasource.currentUser).thenReturn(mockUser);
      when(() => mockProfileRepository.getProfile('test_uid')).thenAnswer((_) {
        final completer = profileCompleters[profileFetchCount];
        profileFetchCount++;
        return completer.future;
      });

      repository = AuthRepositoryImpl(
        authDatasource: mockDatasource,
        profileRepository: mockProfileRepository,
      );

      authController.add(mockUser);
      await Future<void>.delayed(Duration.zero);

      final refreshFuture = repository.forceRefreshStatus();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(profileFetchCount, 1);

      profileCompleters.first.complete(null);
      await Future<void>.delayed(Duration.zero);

      expect(profileFetchCount, 2);

      profileCompleters.last.complete(null);
      await refreshFuture;

      expect(repository.currentStatus, AuthStatus.authenticatedNoProfile);

      await authController.close();
    });

    test(
      'refreshCurrentUserToken returns refreshed current credentials',
      () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test_uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn('photo_url');
        when(
          () => mockDatasource.authStateChanges,
        ).thenAnswer((_) => const Stream<firebase_auth.User?>.empty());
        when(() => mockDatasource.currentUser).thenReturn(mockUser);
        when(
          () => mockDatasource.refreshCurrentUserToken(),
        ).thenAnswer((_) async => mockUser);

        repository = AuthRepositoryImpl(
          authDatasource: mockDatasource,
          profileRepository: mockProfileRepository,
        );

        final credentials = await repository.refreshCurrentUserToken();

        expect(credentials?.uid, 'test_uid');
        expect(credentials?.email, 'test@example.com');
        verify(() => mockDatasource.refreshCurrentUserToken()).called(1);
      },
    );

    test(
      'refreshCurrentUserToken returns null when no user is signed in',
      () async {
        when(
          () => mockDatasource.authStateChanges,
        ).thenAnswer((_) => const Stream<firebase_auth.User?>.empty());
        when(() => mockDatasource.currentUser).thenReturn(null);
        when(
          () => mockDatasource.refreshCurrentUserToken(),
        ).thenAnswer((_) async => null);

        repository = AuthRepositoryImpl(
          authDatasource: mockDatasource,
          profileRepository: mockProfileRepository,
        );

        final credentials = await repository.refreshCurrentUserToken();

        expect(credentials, isNull);
        verify(() => mockDatasource.refreshCurrentUserToken()).called(1);
      },
    );
  });
}
