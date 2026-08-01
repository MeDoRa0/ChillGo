import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/presentation/widgets/crew_card.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCrewRepository extends Mock implements CrewRepository {}

class MockOutingRepository extends Mock implements OutingRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockCrewRepository crewRepository;
  late MockOutingRepository outingRepository;

  final crew = Crew(id: 'crew1', name: 'Weekend Hikers', ownerId: 'owner1');

  final members = List.generate(
    6,
    (index) => CrewMembership(
      id: 'crew1_user$index',
      crewId: 'crew1',
      userId: 'user$index',
      role: CrewRole.member,
      joinedAt: DateTime.utc(2026, 7, index + 1),
      username: 'user$index',
      displayName: 'User $index',
    ),
  );

  setUp(() async {
    await sl.reset();

    authRepository = MockAuthRepository();
    crewRepository = MockCrewRepository();
    outingRepository = MockOutingRepository();

    when(
      () => authRepository.currentCredentials,
    ).thenReturn(const UserCredentials(uid: 'owner1', username: 'owner'));
    when(
      () => crewRepository.streamMembers('crew1'),
    ).thenAnswer((_) => Stream.value(members));
    when(
      () => crewRepository.streamPendingInvitationsForCrew('crew1'),
    ).thenAnswer((_) => Stream.value(const <CrewInvitation>[]));
    when(
      () => outingRepository.streamCrewOutings('crew1'),
    ).thenAnswer((_) => Stream.value(const <Outing>[]));

    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<CrewRepository>(crewRepository);
    sl.registerSingleton<OutingRepository>(outingRepository);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders overlapping member avatars with bounded layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 160,
              child: CrewCard(crew: crew),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('6 members'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('crew-card-no-upcoming-outing')),
      findsOneWidget,
    );
    expect(find.text('No plans in the next 24h'), findsOneWidget);
  });

  testWidgets('invokes tap callback', (tester) async {
    var didTap = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CrewCard(crew: crew, onTap: () => didTap = true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CrewCard));

    expect(didTap, isTrue);
  });

  testWidgets('does not recreate Firestore streams on a same-crew rebuild', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrewCard(crew: crew)),
      ),
    );
    await tester.pump();

    final renamedCrew = Crew(
      id: crew.id,
      name: 'Renamed hikers',
      ownerId: crew.ownerId,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrewCard(crew: renamedCrew)),
      ),
    );
    await tester.pump();

    verify(() => crewRepository.streamMembers('crew1')).called(1);
    verify(
      () => crewRepository.streamPendingInvitationsForCrew('crew1'),
    ).called(1);
    verify(() => outingRepository.streamCrewOutings('crew1')).called(1);
  });

  testWidgets('shows the countdown design for an outing in the next 24 hours', (
    tester,
  ) async {
    final upcomingOuting = Outing(
      id: 'outing1',
      crewId: 'crew1',
      title: 'Ramen run',
      scheduledAt: DateTime.now().add(const Duration(hours: 4, minutes: 30)),
      locationText: 'Ramen shop',
      status: OutingStatus.draft,
      createdByUserId: 'owner1',
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
    when(
      () => outingRepository.streamCrewOutings('crew1'),
    ).thenAnswer((_) => Stream.value([upcomingOuting]));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 160,
              child: CrewCard(crew: crew),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('crew-card-upcoming-outing')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Active outing'), findsOneWidget);
    expect(find.text('Ramen run'), findsOneWidget);
    expect(find.text('Ramen shop'), findsOneWidget);
    expect(find.text('4h'), findsOneWidget);
  });

  testWidgets('uses the no-outing design for an outdated outing', (
    tester,
  ) async {
    final outdatedOuting = Outing(
      id: 'outing1',
      crewId: 'crew1',
      title: 'Old ramen run',
      scheduledAt: DateTime.now().subtract(
        outingCleanupDelay + const Duration(minutes: 1),
      ),
      locationText: 'Ramen shop',
      status: OutingStatus.draft,
      createdByUserId: 'owner1',
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
    when(
      () => outingRepository.streamCrewOutings('crew1'),
    ).thenAnswer((_) => Stream.value([outdatedOuting]));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrewCard(crew: crew)),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Active outing'), findsNothing);
    expect(
      find.byKey(const ValueKey('crew-card-no-upcoming-outing')),
      findsOneWidget,
    );
    expect(find.text('No plans in the next 24h'), findsOneWidget);
  });

  testWidgets('uses the no-outing design for an outing beyond 24 hours', (
    tester,
  ) async {
    final laterOuting = Outing(
      id: 'outing1',
      crewId: 'crew1',
      title: 'Next weekend',
      scheduledAt: DateTime.now().add(const Duration(hours: 25)),
      locationText: 'Ramen shop',
      status: OutingStatus.confirmed,
      createdByUserId: 'owner1',
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
    when(
      () => outingRepository.streamCrewOutings('crew1'),
    ).thenAnswer((_) => Stream.value([laterOuting]));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrewCard(crew: crew)),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Active outing'), findsNothing);
    expect(
      find.byKey(const ValueKey('crew-card-no-upcoming-outing')),
      findsOneWidget,
    );
    expect(find.text('Next weekend'), findsNothing);
  });

  testWidgets('shows the nearest outing when several are within 24 hours', (
    tester,
  ) async {
    Outing outing(String id, String title, Duration startsIn) => Outing(
      id: id,
      crewId: 'crew1',
      title: title,
      scheduledAt: DateTime.now().add(startsIn),
      locationText: 'Ramen shop',
      status: OutingStatus.confirmed,
      createdByUserId: 'owner1',
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
    when(() => outingRepository.streamCrewOutings('crew1')).thenAnswer(
      (_) => Stream.value([
        outing('later', 'Later plan', const Duration(hours: 9)),
        outing('nearest', 'Nearest plan', const Duration(hours: 3)),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CrewCard(crew: crew)),
      ),
    );
    await tester.pump();

    expect(find.text('Nearest plan'), findsOneWidget);
    expect(find.text('Later plan'), findsNothing);
  });
}
