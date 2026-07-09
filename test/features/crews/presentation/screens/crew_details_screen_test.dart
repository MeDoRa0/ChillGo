import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/presentation/screens/crew_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCrewRepository extends Mock implements CrewRepository {}

void main() {
  late MockCrewRepository crewRepository;

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

    when(
      () => crewRepository.streamCrew('crew1'),
    ).thenAnswer((_) => Stream.value(crew));
    when(
      () => crewRepository.streamMembers('crew1'),
    ).thenAnswer((_) => Stream.value(members));

    sl.registerSingleton<CrewRepository>(crewRepository);
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
    expect(find.text('Crew Owner'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Trail Friend'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
  });

  testWidgets('create outing button is wired for the selected crew', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CrewDetailsScreen(crewId: 'crew1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create outing'));
    await tester.pump();

    expect(find.text('Create outing for Weekend Hikers'), findsOneWidget);
  });
}
