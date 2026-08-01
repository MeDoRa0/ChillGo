import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/core/routes/app_router.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/welcome/domain/repositories/welcome_onboarding_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockWelcomeOnboardingRepository extends Mock
    implements WelcomeOnboardingRepository {}

class MockBuildContext extends Mock implements BuildContext {}

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockWelcomeOnboardingRepository mockWelcomeRepository;

  setUpAll(() {
    mockAuthRepository = MockAuthRepository();
    mockWelcomeRepository = MockWelcomeOnboardingRepository();
    // Default fallback status stream and current status
    when(
      () => mockAuthRepository.status,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.unknown);
    when(() => mockWelcomeRepository.isComplete).thenReturn(true);
    when(
      () => mockWelcomeRepository.completionChanges,
    ).thenAnswer((_) => const Stream.empty());

    // Guard against duplicate registration when tests share the same process.
    if (sl.isRegistered<AuthRepository>()) {
      sl.unregister<AuthRepository>();
    }
    sl.registerSingleton<AuthRepository>(mockAuthRepository);
    if (sl.isRegistered<WelcomeOnboardingRepository>()) {
      sl.unregister<WelcomeOnboardingRepository>();
    }
    sl.registerSingleton<WelcomeOnboardingRepository>(mockWelcomeRepository);
  });

  tearDownAll(() async {
    // Restore sl to a clean state so other test files are not affected.
    if (sl.isRegistered<AuthRepository>()) {
      await sl.unregister<AuthRepository>();
    }
    if (sl.isRegistered<WelcomeOnboardingRepository>()) {
      await sl.unregister<WelcomeOnboardingRepository>();
    }
  });

  test('AppRouter configuration should be initialized', () {
    expect(appRouter, isNotNull);
    expect(appRouter.configuration.routes.length, greaterThanOrEqualTo(2));
  });

  test('AppRouter exposes a crew details route', () {
    final paths = appRouter.configuration.routes.whereType<GoRoute>().map(
      (route) => route.path,
    );

    expect(paths, contains('/crews/:crewId'));
  });

  test('AppRouter exposes the scoped outing chat route', () {
    final paths = appRouter.configuration.routes.whereType<GoRoute>().map(
      (route) => route.path,
    );

    expect(paths, contains('/outings/:outingId/chat'));
  });

  test('AppRouter exposes the protected Live Meetup route', () {
    final paths = appRouter.configuration.routes.whereType<GoRoute>().map(
      (route) => route.path,
    );
    expect(paths, contains('/outings/:outingId/live-meetup'));
  });

  test('AppRouter exposes the first-launch welcome route', () {
    final paths = appRouter.configuration.routes.whereType<GoRoute>().map(
      (route) => route.path,
    );
    expect(paths, contains('/welcome'));
  });

  group('AppRouter Redirect Logic', () {
    late MockBuildContext mockContext;
    late MockGoRouterState mockState;

    setUp(() {
      mockContext = MockBuildContext();
      mockState = MockGoRouterState();
      when(() => mockWelcomeRepository.isComplete).thenReturn(true);
    });

    test('redirects first-time users to /welcome before auth routing', () {
      when(() => mockWelcomeRepository.isComplete).thenReturn(false);
      when(
        () => mockAuthRepository.currentStatus,
      ).thenReturn(AuthStatus.unauthenticated);
      when(() => mockState.uri).thenReturn(Uri.parse('/'));

      final result = guardRedirect(mockContext, mockState);

      expect(result, '/welcome');
    });

    test('keeps first-time users on /welcome', () {
      when(() => mockWelcomeRepository.isComplete).thenReturn(false);
      when(() => mockState.uri).thenReturn(Uri.parse('/welcome'));

      final result = guardRedirect(mockContext, mockState);

      expect(result, isNull);
    });

    test(
      'should redirect to /login when auth repository is not registered yet',
      () {
        if (sl.isRegistered<AuthRepository>()) {
          sl.unregister<AuthRepository>();
        }

        when(() => mockState.uri).thenReturn(Uri.parse('/'));

        final result = guardRedirect(mockContext, mockState);
        expect(result, '/login');
      },
    );

    test('should redirect to /loading when auth status is unknown', () {
      sl.registerSingleton<AuthRepository>(mockAuthRepository);
      when(
        () => mockAuthRepository.currentStatus,
      ).thenReturn(AuthStatus.unknown);
      when(() => mockState.uri).thenReturn(Uri.parse('/'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, '/loading');
    });

    test('should remain on /loading when auth status is unknown', () {
      when(
        () => mockAuthRepository.currentStatus,
      ).thenReturn(AuthStatus.unknown);
      when(() => mockState.uri).thenReturn(Uri.parse('/loading'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, isNull);
    });

    test(
      'should redirect to /login when status is AuthStatus.unauthenticated and path is not /login',
      () {
        when(
          () => mockAuthRepository.currentStatus,
        ).thenReturn(AuthStatus.unauthenticated);
        when(() => mockState.uri).thenReturn(Uri.parse('/'));

        final result = guardRedirect(mockContext, mockState);
        expect(result, '/login');
      },
    );

    test(
      'should return null when status is AuthStatus.unauthenticated and path is already /login',
      () {
        when(
          () => mockAuthRepository.currentStatus,
        ).thenReturn(AuthStatus.unauthenticated);
        when(() => mockState.uri).thenReturn(Uri.parse('/login'));

        final result = guardRedirect(mockContext, mockState);
        expect(result, isNull);
      },
    );

    test(
      'should redirect to /onboarding when status is AuthStatus.authenticatedNoProfile and path is not /onboarding',
      () {
        when(
          () => mockAuthRepository.currentStatus,
        ).thenReturn(AuthStatus.authenticatedNoProfile);
        when(() => mockState.uri).thenReturn(Uri.parse('/'));

        final result = guardRedirect(mockContext, mockState);
        expect(result, '/onboarding');
      },
    );

    test(
      'should return null when status is AuthStatus.authenticatedNoProfile and path is already /onboarding',
      () {
        when(
          () => mockAuthRepository.currentStatus,
        ).thenReturn(AuthStatus.authenticatedNoProfile);
        when(() => mockState.uri).thenReturn(Uri.parse('/onboarding'));

        final result = guardRedirect(mockContext, mockState);
        expect(result, isNull);
      },
    );

    test(
      'should redirect to / when an authenticated profile opens a startup route',
      () {
        when(
          () => mockAuthRepository.currentStatus,
        ).thenReturn(AuthStatus.authenticatedWithProfile);

        for (final path in ['/loading', '/login', '/onboarding', '/welcome']) {
          when(() => mockState.uri).thenReturn(Uri.parse(path));
          final result = guardRedirect(mockContext, mockState);
          expect(result, '/');
        }
      },
    );

    test(
      'should return null when status is AuthStatus.authenticatedWithProfile and path is not /loading, /login, or /onboarding',
      () {
        when(
          () => mockAuthRepository.currentStatus,
        ).thenReturn(AuthStatus.authenticatedWithProfile);
        when(() => mockState.uri).thenReturn(Uri.parse('/'));

        final result = guardRedirect(mockContext, mockState);
        expect(result, isNull);
      },
    );
  });
}
