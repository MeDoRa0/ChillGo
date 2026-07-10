import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_event.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_state.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // Default fallback stub for the status stream during setup.
    when(
      () => mockAuthRepository.status,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAuthRepository.currentStatus,
    ).thenReturn(AuthStatus.unknown);
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthState.unauthenticated] when status changes to unauthenticated',
      build: () {
        when(
          () => mockAuthRepository.status,
        ).thenAnswer((_) => Stream.value(AuthStatus.unauthenticated));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      expect: () => const <AuthState>[
        AuthState.unknown(),
        AuthState.unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthState.authenticatedNoProfile] when status changes to authenticatedNoProfile',
      build: () {
        when(
          () => mockAuthRepository.status,
        ).thenAnswer((_) => Stream.value(AuthStatus.authenticatedNoProfile));
        when(() => mockAuthRepository.currentCredentials).thenReturn(
          const UserCredentials(uid: 'test_uid', email: 'test@example.com'),
        );
        return AuthBloc(authRepository: mockAuthRepository);
      },
      expect: () => const <AuthState>[
        AuthState.unknown(),
        AuthState.authenticatedNoProfile(
          UserCredentials(uid: 'test_uid', email: 'test@example.com'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'triggers signOut on AuthLogoutRequested',
      build: () {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      verify: (_) {
        verify(() => mockAuthRepository.signOut()).called(1);
      },
    );
  });
}
