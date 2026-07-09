import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/presentation/widgets/crew_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCrewRepository extends Mock implements CrewRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockCrewRepository crewRepository;

  final crew = Crew(
    id: 'crew1',
    name: 'Weekend Hikers',
    ownerId: 'owner1',
    createdAt: DateTime.utc(2026, 7, 1),
  );

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

    when(
      () => authRepository.currentCredentials,
    ).thenReturn(const UserCredentials(uid: 'owner1', username: 'owner'));
    when(
      () => crewRepository.streamMembers('crew1'),
    ).thenAnswer((_) => Stream.value(members));
    when(
      () => crewRepository.streamPendingInvitationsForCrew('crew1'),
    ).thenAnswer((_) => Stream.value(const <CrewInvitation>[]));

    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<CrewRepository>(crewRepository);
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
            child: SizedBox(width: 320, child: CrewCard(crew: crew)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('6 members'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
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
}
