import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/presentation/screens/crew_details_screen.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockCrewRepository extends Mock implements CrewRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOutingRepository extends Mock implements OutingRepository {}

void main() {
  late MockCrewRepository crewRepository;
  late MockAuthRepository authRepository;
  late MockOutingRepository outingRepository;

  final crew = Crew(
    id: 'crew1',
    name: 'Weekend Hikers',
    ownerId: 'owner1',
    createdAt: DateTime.utc(2026, 7, 1),
  );

  final members = [
    CrewMembership(
      id: 'crew1_owner1',
      crewId: 'crew1',
      userId: 'owner1',
      role: CrewRole.owner,
      joinedAt: DateTime.utc(2026, 7),
      username: 'owner',
      displayName: 'Crew Owner',
    ),
    CrewMembership(
      id: 'crew1_user1',
      crewId: 'crew1',
      userId: 'user1',
      role: CrewRole.member,
      joinedAt: DateTime.utc(2026, 7, 2),
      username: 'friend',
      displayName: 'Trail Friend',
    ),
  ];

  setUp(() async {
    await sl.reset();
    crewRepository = MockCrewRepository();
    authRepository = MockAuthRepository();
    outingRepository = MockOutingRepository();

    when(
      () => crewRepository.streamCrew('crew1'),
    ).thenAnswer((_) => Stream.value(crew));
    when(
      () => crewRepository.streamMembers('crew1'),
    ).thenAnswer((_) => Stream.value(members));
    when(
      () => crewRepository.inviteUser('crew1', any()),
    ).thenAnswer((_) async {});
    when(
      () => crewRepository.usernameExists(any()),
    ).thenAnswer((_) async => true);
    when(
      () => authRepository.currentCredentials,
    ).thenReturn(const UserCredentials(uid: 'owner1', username: 'owner'));
    when(
      () => outingRepository.streamCrewOutings('crew1'),
    ).thenAnswer((_) => Stream.value(const <Outing>[]));

    sl.registerSingleton<CrewRepository>(crewRepository);
    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<OutingRepository>(outingRepository);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders crew details and create outing button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CrewDetailsScreen(crewId: 'crew1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekend Hikers'), findsOneWidget);
    expect(find.text('Create outing'), findsOneWidget);
    expect(find.byKey(const Key('crew-member-avatar-owner1')), findsOneWidget);
    expect(find.byKey(const Key('crew-member-avatar-user1')), findsOneWidget);
    expect(find.text('Crew Owner'), findsNothing);
    expect(find.text('Trail Friend'), findsNothing);
    expect(find.byKey(const Key('add-crew-member-button')), findsOneWidget);
  });

  testWidgets('owner can invite a member by username', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CrewDetailsScreen(crewId: 'crew1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-crew-member-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('invite-member-username-field')),
      'newfriend',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('matching-member-account')), findsOneWidget);
    expect(find.text('@newfriend'), findsOneWidget);
    await tester.tap(find.byKey(const Key('send-member-invite-button')));
    await tester.pumpAndSettle();

    verify(() => crewRepository.inviteUser('crew1', 'newfriend')).called(1);
    expect(find.text('Invitation sent to @newfriend.'), findsOneWidget);
  });

  testWidgets('shows an all-members control when avatars exceed the width', (
    tester,
  ) async {
    final extraMembers = List.generate(
      7,
      (index) => CrewMembership(
        id: 'crew1_user$index',
        crewId: 'crew1',
        userId: 'user$index',
        role: CrewRole.member,
        joinedAt: DateTime.utc(2026, 7, 2),
        username: 'friend$index',
        displayName: 'Trail Friend $index',
      ),
    );
    when(
      () => crewRepository.streamMembers('crew1'),
    ).thenAnswer((_) => Stream.value([members.first, ...extraMembers]));
    await tester.binding.setSurfaceSize(const Size(300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: CrewDetailsScreen(crewId: 'crew1')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('see-all-members-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('see-all-members-button')));
    await tester.pumpAndSettle();

    expect(find.text('Crew Owner'), findsOneWidget);
  });

  testWidgets('create outing button is wired for the selected crew', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const CrewDetailsScreen(crewId: 'crew1'),
        ),
        GoRoute(
          path: '/crews/:crewId/outings/new',
          builder: (_, state) =>
              Text('Create ${state.pathParameters['crewId']}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create outing'));
    await tester.pumpAndSettle();

    expect(find.text('Create crew1'), findsOneWidget);
  });

  testWidgets('does not show outdated outings in crew plans', (tester) async {
    final outdatedOuting = Outing(
      id: 'outing1',
      crewId: 'crew1',
      title: 'Outdated picnic',
      scheduledAt: DateTime.now().subtract(
        outingCleanupDelay + const Duration(minutes: 1),
      ),
      locationText: 'Old park',
      status: OutingStatus.draft,
      createdByUserId: 'owner1',
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
    when(
      () => outingRepository.streamCrewOutings('crew1'),
    ).thenAnswer((_) => Stream.value([outdatedOuting]));

    await tester.pumpWidget(
      const MaterialApp(home: CrewDetailsScreen(crewId: 'crew1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Outdated picnic'), findsNothing);
    expect(find.text('No plans yet — start the vibe.'), findsOneWidget);
  });
}
