import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'package:chillgo/features/home/presentation/widgets/sign_out_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('dispatches sign out through AuthBloc when tapped', (
    tester,
  ) async {
    final authRepository = MockAuthRepository();

    when(() => authRepository.status).thenAnswer((_) => const Stream.empty());
    when(
      () => authRepository.currentStatus,
    ).thenReturn(AuthStatus.authenticatedWithProfile);
    when(() => authRepository.currentCredentials).thenReturn(
      const UserCredentials(
        uid: 'user-id',
        email: 'user@example.com',
        displayName: 'Test User',
        username: 'testuser',
      ),
    );
    when(() => authRepository.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository),
          child: const Scaffold(body: SignOutIconButton()),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pump();

    verify(() => authRepository.signOut()).called(1);
  });
}
