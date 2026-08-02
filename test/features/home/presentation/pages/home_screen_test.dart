import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/domain/entities/user_profile.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/home/presentation/pages/home_screen.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_page.dart';
import 'package:chillgo/features/notifications/domain/repositories/notification_repository.dart';
import 'package:chillgo/features/profile/domain/repositories/profile_repository.dart';
import 'package:chillgo/features/profile/presentation/blocs/profile/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCrewRepository extends Mock implements CrewRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  testWidgets('loads the selected avatar from the saved user profile', (
    tester,
  ) async {
    final authRepository = MockAuthRepository();
    final crewRepository = MockCrewRepository();
    final notificationRepository = MockNotificationRepository();
    final profileRepository = MockProfileRepository();
    final profile = UserProfile(
      id: 'user-id',
      username: 'newuser',
      displayName: 'New User',
      avatarUrl: 'https://example.com/selected-avatar.jpg',
      createdAt: DateTime.utc(2026, 8, 2),
    );

    when(() => authRepository.status).thenAnswer((_) => const Stream.empty());
    when(
      () => authRepository.currentStatus,
    ).thenReturn(AuthStatus.authenticatedWithProfile);
    when(
      () => authRepository.currentCredentials,
    ).thenReturn(
      const UserCredentials(
        uid: 'user-id',
        photoUrl: 'https://example.com/provider-avatar.jpg',
      ),
    );
    when(
      () => crewRepository.streamCrews(),
    ).thenAnswer((_) => Stream.value(const <Crew>[]));
    when(
      () => notificationRepository.watchUnreadSummary(),
    ).thenAnswer((_) => Stream.value(const UnreadNotificationSummary(0)));
    when(
      () => profileRepository.getProfile('user-id'),
    ).thenAnswer((_) async => profile);

    sl.registerFactory(() => CrewsListCubit(crewRepository: crewRepository));
    sl.registerFactory(
      () => ProfileCubit(profileRepository: profileRepository),
    );
    sl.registerSingleton<NotificationRepository>(notificationRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository),
          child: const Offstage(child: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const Key('home-user-avatar'), skipOffstage: false),
    );
    expect(
      avatar.backgroundImage,
      const NetworkImage('https://example.com/selected-avatar.jpg'),
    );
  });
}
