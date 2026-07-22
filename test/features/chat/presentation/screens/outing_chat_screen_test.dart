import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:chillgo/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart';
import 'package:chillgo/features/chat/presentation/screens/outing_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chat_test_helpers.dart';

class TestOutingChatCubit extends OutingChatCubit {
  TestOutingChatCubit() : super(repository: FakeChatRepository());
  void setState(OutingChatState next) => emit(next);
}

Future<TestOutingChatCubit> pumpChat(
  WidgetTester tester,
  OutingChatState state,
) async {
  final cubit = TestOutingChatCubit()..setState(state);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<OutingChatCubit>.value(
        value: cubit,
        child: const OutingChatScreen(outingId: 'outing-1'),
      ),
    ),
  );
  return cubit;
}

void main() {
  testWidgets('shows loading and an empty writable conversation', (
    tester,
  ) async {
    final cubit = await pumpChat(
      tester,
      const OutingChatState(status: OutingChatStatus.loading),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    cubit.setState(
      const OutingChatState(status: OutingChatStatus.ready, isWritable: true),
    );
    await tester.pump();
    expect(
      find.text('No messages yet. Start the conversation.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('chat-composer-field')),
      'hello',
    );
    await tester.pump();
    expect(find.text('5/2000'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('renders immutable attribution and a failed retry affordance', (
    tester,
  ) async {
    final cubit = await pumpChat(
      tester,
      OutingChatState(
        status: OutingChatStatus.ready,
        isWritable: true,
        messages: [buildChatMessage(text: 'مرحبا\nhttps://example.com')],
        attempts: const [
          ChatSendAttempt(
            clientMessageId: 'client-1',
            text: 'retry me',
            status: ChatSendAttemptStatus.failed,
            failure: ChatIdentityConflict(),
          ),
        ],
      ),
    );
    expect(find.text('Traveler'), findsOneWidget);
    expect(find.text('مرحبا\nhttps://example.com'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('new message'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('clears content and presents a safe reason after revocation', (
    tester,
  ) async {
    final cubit = await pumpChat(
      tester,
      OutingChatState(
        status: OutingChatStatus.ready,
        messages: [buildChatMessage()],
      ),
    );
    expect(find.text('Hello'), findsOneWidget);
    cubit.setState(
      const OutingChatState(
        status: OutingChatStatus.unavailable,
        failure: ChatAccessDenied(),
      ),
    );
    await tester.pump();
    expect(find.text('Hello'), findsNothing);
    expect(find.text('This chat is unavailable.'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('supports emoji, RTL, line breaks, links, and read-only status', (
    tester,
  ) async {
    final cubit = await pumpChat(
      tester,
      OutingChatState(
        status: OutingChatStatus.ready,
        messages: [buildChatMessage(text: '😀 مرحبا\nhttps://example.com')],
      ),
    );
    expect(find.text('😀 مرحبا\nhttps://example.com'), findsOneWidget);
    expect(
      find.text('This outing is finished. Available chat history is read-only.'),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets('renders a bounded 50-message newest page and history control', (
    tester,
  ) async {
    final cubit = await pumpChat(
      tester,
      OutingChatState(
        status: OutingChatStatus.ready,
        hasMore: true,
        messages: List.generate(
          50,
          (index) => buildChatMessage(
            id: 'message-$index',
            acceptedAt: chatTestNow.add(Duration(seconds: index)),
          ),
        ),
      ),
    );
    expect(find.text('Load older messages'), findsOneWidget);
    expect(find.byKey(const Key('chat-history-list')), findsOneWidget);
    await cubit.close();
  });

  testWidgets('opens at first unread and otherwise opens at newest', (
    tester,
  ) async {
    final messages = List.generate(
      60,
      (index) => buildChatMessage(
        id: 'position-$index',
        acceptedAt: chatTestNow.add(Duration(seconds: index)),
        text: 'Message $index with enough text to occupy a visible row',
      ),
    );
    final cubit = await pumpChat(
      tester,
      OutingChatState(
        status: OutingChatStatus.ready,
        messages: messages,
        firstUnreadMessageId: 'position-40',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-unread-message')), findsOneWidget);
    var list = tester.widget<ListView>(
      find.byKey(const Key('chat-history-list')),
    );
    expect(list.controller!.position.extentBefore, greaterThan(0));
    expect(list.controller!.position.extentAfter, greaterThan(0));

    cubit.setState(
      OutingChatState(status: OutingChatStatus.ready, messages: messages),
    );
    await tester.pumpAndSettle();
    // The same open session preserves the reader's viewport when state changes.
    expect(list.controller!.position.extentAfter, greaterThan(0));
    await cubit.close();
    await tester.pumpWidget(const SizedBox.shrink());

    final newestCubit = await pumpChat(
      tester,
      OutingChatState(status: OutingChatStatus.ready, messages: messages),
    );
    await tester.pumpAndSettle();
    list = tester.widget<ListView>(
      find.byKey(const Key('chat-history-list')),
    );
    expect(list.controller!.position.extentAfter, lessThanOrEqualTo(1));
    await newestCubit.close();
  });
}
