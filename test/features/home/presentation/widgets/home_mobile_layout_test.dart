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
}
