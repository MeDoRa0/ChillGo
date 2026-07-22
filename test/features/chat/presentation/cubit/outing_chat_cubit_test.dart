import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:chillgo/features/chat/domain/entities/chat_page.dart';
import 'package:chillgo/features/chat/domain/entities/chat_read_state.dart';
import 'package:chillgo/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chat_test_helpers.dart';

void main() {
  late FakeChatRepository repository;
  late OutingChatCubit cubit;

  setUp(() {
    repository = FakeChatRepository();
    cubit = OutingChatCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('loads and merges realtime messages in stable order', () async {
    await cubit.watch('outing-1');
    expect(cubit.state.status, OutingChatStatus.loading);
    repository.summaries.add(
      const ChatSummary(unreadCount: 0, isWritable: true),
    );
    repository.latest.add(
      ChatPage(
        messages: [
          buildChatMessage(
            id: 'b',
            acceptedAt: chatTestNow.add(const Duration(seconds: 1)),
          ),
          buildChatMessage(id: 'a', acceptedAt: chatTestNow),
        ],
        hasMore: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, OutingChatStatus.ready);
    expect(cubit.state.messages.map((message) => message.id), ['a', 'b']);
    expect(cubit.state.isWritable, isTrue);
  });

  test('exposes sending, failed, and stable manual retry states', () async {
    await cubit.watch('outing-1');
    repository.summaries.add(
      const ChatSummary(unreadCount: 0, isWritable: true),
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.send('hello');
    expect(cubit.state.attempts.single.status, ChatSendAttemptStatus.sending);
    final commandId = cubit.state.attempts.single.commandId!;
    repository.commands[commandId]!.add(
      const ChatCommand(
        id: 'command-1',
        status: ChatCommandStatus.failed,
        failure: ChatNetworkFailure(),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final failed = cubit.state.attempts.single;
    expect(failed.status, ChatSendAttemptStatus.failed);
    await cubit.retry(failed);
    expect(repository.sent.map((item) => item.clientMessageId).toSet(), {
      'client-1',
    });
  });

  test('preserves safe rate-limit retry time', () async {
    await cubit.watch('outing-1');
    repository.summaries.add(
      const ChatSummary(unreadCount: 0, isWritable: true),
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.send('hello');
    final commandId = cubit.state.attempts.single.commandId!;
    final retryAt = chatTestNow.add(const Duration(seconds: 30));
    repository.commands[commandId]!.add(
      ChatCommand(
        id: commandId,
        status: ChatCommandStatus.failed,
        failure: ChatRateLimited(retryAt),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      (cubit.state.attempts.single.failure as ChatRateLimited).retryAt,
      retryAt,
    );
  });

  test('clears all protected state immediately on access error', () async {
    await cubit.watch('outing-1');
    repository.latest.add(
      ChatPage(messages: [buildChatMessage()], hasMore: false),
    );
    await Future<void>.delayed(Duration.zero);
    repository.latest.addError(const ChatAccessDenied());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, OutingChatStatus.unavailable);
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.attempts, isEmpty);

    repository.latest.add(
      ChatPage(messages: [buildChatMessage(id: 'stale')], hasMore: false),
    );
    repository.summaries.add(
      const ChatSummary(unreadCount: 1, isWritable: true),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, OutingChatStatus.unavailable);
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.isWritable, isFalse);
  });

  test('progressively loads older history and records exhaustion', () async {
    await cubit.watch('outing-1');
    repository.latest.add(
      ChatPage(
        messages: [buildChatMessage(id: 'newest')],
        hasMore: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    repository.older = ChatPage(
      messages: [
        buildChatMessage(
          id: 'older',
          acceptedAt: chatTestNow.subtract(const Duration(minutes: 1)),
        ),
      ],
      hasMore: false,
    );

    await cubit.loadOlder();

    expect(cubit.state.messages.map((message) => message.id), [
      'older',
      'newest',
    ]);
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.loadingOlder, isFalse);
  });

  test('exposes a new-message affordance without dropping older history', () async {
    await cubit.watch('outing-1');
    repository.latest.add(
      ChatPage(messages: [buildChatMessage(id: 'first')], hasMore: false),
    );
    await Future<void>.delayed(Duration.zero);
    repository.latest.add(
      ChatPage(
        messages: [
          buildChatMessage(id: 'first'),
          buildChatMessage(
            id: 'second',
            acceptedAt: chatTestNow.add(const Duration(seconds: 1)),
          ),
        ],
        hasMore: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.showNewMessages, isTrue);
    expect(cubit.state.messages.map((message) => message.id), [
      'first',
      'second',
    ]);
  });

  test(
    'identifies first unread and marks only through the newest message',
    () async {
      await cubit.watch('outing-1');
      repository.readStates.add(null);
      repository.latest.add(
        ChatPage(
          messages: [
            buildChatMessage(id: 'first', acceptedAt: chatTestNow),
            buildChatMessage(
              id: 'newest',
              acceptedAt: chatTestNow.add(const Duration(seconds: 1)),
            ),
          ],
          hasMore: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.firstUnreadMessageId, 'first');
      await cubit.markThroughNewest();
      expect(repository.marked.single.cursor.messageId, 'newest');
      expect(cubit.state.firstUnreadMessageId, isNull);
    },
  );
}
