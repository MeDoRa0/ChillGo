import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:chillgo/features/chat/domain/entities/chat_message_cursor.dart';
import 'package:chillgo/features/chat/domain/entities/chat_page.dart';
import 'package:chillgo/features/chat/domain/entities/chat_read_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chat_test_helpers.dart';

void main() {
  test('message values compare structurally', () {
    expect(buildChatMessage(), buildChatMessage());
  });

  test('cursor uses message id as stable timestamp tie breaker', () {
    final first = ChatMessageCursor(acceptedAt: chatTestNow, messageId: 'a');
    final second = ChatMessageCursor(acceptedAt: chatTestNow, messageId: 'b');
    expect(first.compareTo(second), lessThan(0));
    expect(second.isAfter(first), isTrue);
  });

  test('page enforces the 50-message bound', () {
    expect(
      () => ChatPage(
        messages: List.generate(51, (i) => buildChatMessage(id: '$i')),
        hasMore: true,
      ),
      throwsArgumentError,
    );
  });

  test('send attempts, summaries, and failures compare safely', () {
    const first = ChatSendAttempt(
      clientMessageId: 'client-1',
      text: 'hello',
      status: ChatSendAttemptStatus.failed,
      failure: ChatNetworkFailure(),
    );
    expect(first, first);
    expect(
      const ChatSummary(unreadCount: 2, isWritable: true).hasUnread,
      isTrue,
    );
    expect(const ChatAccessDenied().message, isNot(contains('membership')));
  });
}
