import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/core/routes/app_router.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockBuildContext extends Mock implements BuildContext {}
class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    mockAuthRepository = MockAuthRepository();
    // Default fallback status stream and current status
    when(() => mockAuthRepository.status).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.unknown);

    // Guard against duplicate registration when tests share the same process.
    if (sl.isRegistered<AuthRepository>()) {
      sl.unregister<AuthRepository>();
    }
    sl.registerSingleton<AuthRepository>(mockAuthRepository);
  });

  tearDownAll(() async {
    // Restore sl to a clean state so other test files are not affected.
    if (sl.isRegistered<AuthRepository>()) {
      await sl.unregister<AuthRepository>();
    }
  });

  test('AppRouter configuration should be initialized', () {
    expect(appRouter, isNotNull);
    expect(appRouter.configuration.routes.length, greaterThanOrEqualTo(2));
  });

  group('AppRouter Redirect Logic', () {
    late MockBuildContext mockContext;
    late MockGoRouterState mockState;

    setUp(() {
      mockContext = MockBuildContext();
      mockState = MockGoRouterState();
    });

    test('should redirect to /loading when status is AuthStatus.unknown and path is not /loading', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.unknown);
      when(() => mockState.uri).thenReturn(Uri.parse('/'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, '/loading');
    });

    test('should return null when status is AuthStatus.unknown and path is already /loading', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.unknown);
      when(() => mockState.uri).thenReturn(Uri.parse('/loading'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, isNull);
    });

    test('should redirect to /login when status is AuthStatus.unauthenticated and path is not /login', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.unauthenticated);
      when(() => mockState.uri).thenReturn(Uri.parse('/'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, '/login');
    });

    test('should return null when status is AuthStatus.unauthenticated and path is already /login', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.unauthenticated);
      when(() => mockState.uri).thenReturn(Uri.parse('/login'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, isNull);
    });

    test('should redirect to /onboarding when status is AuthStatus.authenticatedNoProfile and path is not /onboarding', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.authenticatedNoProfile);
      when(() => mockState.uri).thenReturn(Uri.parse('/'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, '/onboarding');
    });

    test('should return null when status is AuthStatus.authenticatedNoProfile and path is already /onboarding', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.authenticatedNoProfile);
      when(() => mockState.uri).thenReturn(Uri.parse('/onboarding'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, isNull);
    });

    test('should redirect to / when status is AuthStatus.authenticatedWithProfile and path is /loading, /login, or /onboarding', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.authenticatedWithProfile);

      for (final path in ['/loading', '/login', '/onboarding']) {
        when(() => mockState.uri).thenReturn(Uri.parse(path));
        final result = guardRedirect(mockContext, mockState);
        expect(result, '/');
      }
    });

    test('should return null when status is AuthStatus.authenticatedWithProfile and path is not /loading, /login, or /onboarding', () {
      when(() => mockAuthRepository.currentStatus).thenReturn(AuthStatus.authenticatedWithProfile);
      when(() => mockState.uri).thenReturn(Uri.parse('/'));

      final result = guardRedirect(mockContext, mockState);
      expect(result, isNull);
    });
  });
}
