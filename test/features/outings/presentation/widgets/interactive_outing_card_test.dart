import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/features/outings/presentation/widgets/interactive_outing_card.dart';
import 'package:chillgo/features/voting/domain/repositories/agreement_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/chat/domain/repositories/chat_repository.dart';
import 'package:chillgo/features/chat/presentation/cubit/chat_summary/chat_summary_cubit.dart';
import 'package:chillgo/features/chat/domain/entities/chat_read_state.dart';

import '../../outing_repository_fake.dart';
import '../../../chat/chat_test_helpers.dart';

class MockAgreementRepository extends Mock implements AgreementRepository {}

void main() {
  testWidgets('every current participant sees chat independent of attendance', (
    tester,
  ) async {
    final chatRepository = FakeChatRepository();
    if (sl.isRegistered<ChatSummaryCubit>()) {
      await sl.unregister<ChatSummaryCubit>();
    }
    if (sl.isRegistered<ChatRepository>()) {
      await sl.unregister<ChatRepository>();
    }
    sl.registerSingleton<ChatRepository>(chatRepository);
    sl.registerFactory(() => ChatSummaryCubit(repository: sl()));
    addTearDown(() async {
      if (sl.isRegistered<ChatSummaryCubit>()) {
        await sl.unregister<ChatSummaryCubit>();
      }
      if (sl.isRegistered<ChatRepository>()) {
        await sl.unregister<ChatRepository>();
      }
    });
    final outing = FakeOutingRepository.sampleOuting();
    final participant = FakeOutingRepository.sampleParticipant(
      userId: 'user-2',
      isCreatorParticipant: false,
      attendanceStatus: AttendanceStatus.declined,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveOutingCard(
            outing: outing,
            outingRepository: FakeOutingRepository(
              detail: OutingDetail(outing: outing, participants: [participant]),
            ),
            currentUserId: 'user-2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outing-chat-entry')), findsOneWidget);
    expect(find.text('Outing chat'), findsOneWidget);
    chatRepository.summaries.add(
      const ChatSummary(unreadCount: 3, isWritable: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Read-only history'), findsOneWidget);
  });

  testWidgets('creator sees only cancel and change actions', (tester) async {
    final outing = FakeOutingRepository.sampleOuting();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveOutingCard(
            outing: outing,
            outingRepository: FakeOutingRepository(
              detail: OutingDetail(outing: outing, participants: const []),
            ),
            currentUserId: 'user-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Cancel outing'), findsOneWidget);
    expect(find.byTooltip('Change date and location'), findsOneWidget);
    expect(find.text('Cancel outing'), findsOneWidget);
    expect(find.text('Change date and location'), findsOneWidget);
    expect(find.byTooltip('Accept outing'), findsNothing);
    expect(find.byTooltip('Reject outing'), findsNothing);
    expect(find.byTooltip('Suggest new time'), findsNothing);
  });

  testWidgets('creator can cancel an outing with a reason', (tester) async {
    final outing = FakeOutingRepository.sampleOuting();
    final repository = FakeOutingRepository(
      detail: OutingDetail(outing: outing, participants: const []),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveOutingCard(
            outing: outing,
            outingRepository: repository,
            currentUserId: 'user-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cancel outing'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bad weather');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel outing'));
    await tester.pumpAndSettle();

    expect(repository.cancelledOutingId, outing.id);
    expect(repository.cancelledReason, 'Bad weather');
  });

  testWidgets('creator can open date and location editing', (tester) async {
    final outing = FakeOutingRepository.sampleOuting();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: InteractiveOutingCard(
              outing: outing,
              outingRepository: FakeOutingRepository(
                detail: OutingDetail(outing: outing, participants: const []),
              ),
              currentUserId: 'user-1',
            ),
          ),
        ),
        GoRoute(
          path: '/outings/:outingId/edit',
          builder: (_, state) => Text(
            'Editing ${state.pathParameters['outingId']} in '
            '${state.uri.queryParameters['crewId']}',
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Change date and location'));
    await tester.pumpAndSettle();

    expect(find.text('Editing outing-1 in crew-1'), findsOneWidget);
  });

  testWidgets('accepted user sees decline and plan change actions', (
    tester,
  ) async {
    final outing = FakeOutingRepository.sampleOuting();
    final participant = FakeOutingRepository.sampleParticipant(
      userId: 'user-2',
      isCreatorParticipant: false,
      attendanceStatus: AttendanceStatus.accepted,
    );
    final repository = FakeOutingRepository(
      detail: OutingDetail(outing: outing, participants: [participant]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveOutingCard(
            outing: outing,
            outingRepository: repository,
            currentUserId: 'user-2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Decline outing'), findsOneWidget);
    expect(find.byTooltip('Change date and location'), findsOneWidget);
    expect(find.byTooltip('Accept outing'), findsNothing);
    expect(find.byTooltip('Cancel outing'), findsNothing);

    await tester.tap(find.byTooltip('Decline outing'));
    await tester.pumpAndSettle();
    expect(repository.attendanceStatus, AttendanceStatus.declined);
  });

  testWidgets('declined user sees accept and plan change actions', (
    tester,
  ) async {
    final outing = FakeOutingRepository.sampleOuting();
    final participant = FakeOutingRepository.sampleParticipant(
      userId: 'user-2',
      isCreatorParticipant: false,
      attendanceStatus: AttendanceStatus.declined,
    );
    final repository = FakeOutingRepository(
      detail: OutingDetail(outing: outing, participants: [participant]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveOutingCard(
            outing: outing,
            outingRepository: repository,
            currentUserId: 'user-2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Accept outing'), findsOneWidget);
    expect(find.byTooltip('Change date and location'), findsOneWidget);
    expect(find.byTooltip('Decline outing'), findsNothing);

    await tester.tap(find.byTooltip('Accept outing'));
    await tester.pumpAndSettle();
    expect(repository.attendanceStatus, AttendanceStatus.accepted);
  });

  testWidgets('accepted user can open the change date picker', (tester) async {
    final outing = FakeOutingRepository.sampleOuting();
    final participant = FakeOutingRepository.sampleParticipant(
      userId: 'user-2',
      isCreatorParticipant: false,
      attendanceStatus: AttendanceStatus.accepted,
    );
    final outingRepository = FakeOutingRepository(
      detail: OutingDetail(outing: outing, participants: [participant]),
    );
    final agreementRepository = MockAgreementRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveOutingCard(
            outing: outing,
            outingRepository: outingRepository,
            agreementRepository: agreementRepository,
            currentUserId: 'user-2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Change date and location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Date and time'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('declined user can suggest a new location', (tester) async {
    final outing = FakeOutingRepository.sampleOuting();
    final participant = FakeOutingRepository.sampleParticipant(
      userId: 'user-2',
      isCreatorParticipant: false,
      attendanceStatus: AttendanceStatus.declined,
    );
    final outingRepository = FakeOutingRepository(
      detail: OutingDetail(outing: outing, participants: [participant]),
    );
    final agreementRepository = MockAgreementRepository();
    when(
      () => agreementRepository.createLocationProposal(outing.id, 'The park'),
    ).thenAnswer((_) async => 'proposal-1');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveOutingCard(
            outing: outing,
            outingRepository: outingRepository,
            agreementRepository: agreementRepository,
            currentUserId: 'user-2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('outing-card-${outing.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Change date and location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'The park');
    await tester.tap(find.widgetWithText(FilledButton, 'Suggest location'));
    await tester.pumpAndSettle();

    verify(
      () => agreementRepository.createLocationProposal(outing.id, 'The park'),
    ).called(1);
  });
}
