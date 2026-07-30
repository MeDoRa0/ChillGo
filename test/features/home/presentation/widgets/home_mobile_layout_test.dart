import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/home/presentation/widgets/home_mobile_layout.dart';
import 'package:chillgo/features/notifications/domain/entities/outing_review_notification.dart';
import 'package:chillgo/features/notifications/domain/repositories/outing_review_notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCrewRepository extends Mock implements CrewRepository {}

class MockOutingReviewNotificationRepository extends Mock
    implements OutingReviewNotificationRepository {}

void main() {
  late MockCrewRepository crewRepository;
  late MockOutingReviewNotificationRepository outingNotificationRepository;
  late CrewsListCubit crewsListCubit;

  setUp(() {
    crewRepository = MockCrewRepository();
    outingNotificationRepository = MockOutingReviewNotificationRepository();
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

  testWidgets('highlights the notification bell for an unread outing review', (
    tester,
  ) async {
    final notification = OutingReviewNotification(
      id: 'outing1_user1',
      recipientUserId: 'user1',
      crewId: 'crew1',
      outingId: 'outing1',
      creatorDisplayName: 'Crew Owner',
      outingTitle: 'Outing at the cafe',
      createdAt: DateTime.utc(2026, 7, 31),
    );
    when(
      () => crewRepository.streamReceivedInvitations(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => outingNotificationRepository.watchNotifications(),
    ).thenAnswer((_) => Stream.value([notification]));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: crewsListCubit,
          child: HomeMobileLayout(
            outingNotificationRepository: outingNotificationRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unread-invitations-badge')), findsOneWidget);
  });
}
