import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/home/presentation/widgets/home_mobile_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCrewRepository extends Mock implements CrewRepository {}

void main() {
  late MockCrewRepository crewRepository;
  late CrewsListCubit crewsListCubit;

  setUp(() {
    crewRepository = MockCrewRepository();
    crewsListCubit = CrewsListCubit(crewRepository: crewRepository);
  });

  tearDown(() => crewsListCubit.close());

  testWidgets('highlights the notification bell for pending invitations', (
    tester,
  ) async {
    final invitation = CrewInvitation(
      id: 'crew1_user1',
      crewId: 'crew1',
      invitedUserId: 'user1',
      invitedByUserId: 'owner1',
      crewName: 'Weekend Hikers',
      invitedByUsername: 'owner',
      invitedByDisplayName: 'Crew Owner',
      createdAt: DateTime.utc(2026, 7, 31),
    );
    when(
      () => crewRepository.streamReceivedInvitations(),
    ).thenAnswer((_) => Stream.value([invitation]));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: crewsListCubit,
          child: const HomeMobileLayout(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unread-invitations-badge')), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
  });

  testWidgets('shows the selected profile avatar', (tester) async {
    when(
      () => crewRepository.streamReceivedInvitations(),
    ).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: crewsListCubit,
          child: const Offstage(
            child: HomeMobileLayout(
              avatarUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const Key('home-user-avatar'), skipOffstage: false),
    );
    expect(
      avatar.backgroundImage,
      const NetworkImage('https://example.com/avatar.jpg'),
    );
    expect(avatar.child, isNull);
  });

  testWidgets('shows the change avatar option when the avatar is tapped', (
    tester,
  ) async {
    when(
      () => crewRepository.streamReceivedInvitations(),
    ).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: crewsListCubit,
          child: const HomeMobileLayout(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('home-user-avatar-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('change-avatar-option')), findsOneWidget);
    expect(find.text('Change avatar'), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-preset-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('avatar-preset-0')), findsOneWidget);
    expect(find.text('Photo library'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
  });
}
