import 'package:chillgo/features/chat/domain/services/chat_expiry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chat_test_helpers.dart';

void main() {
  test('message is available before but not at exact expiry', () {
    final message = buildChatMessage(expiresAt: chatTestNow);
    final clock = FakeChatClock(
      chatTestNow.subtract(const Duration(microseconds: 1)),
    );
    final policy = ChatExpiryPolicy(clock);
    expect(policy.isAvailable(message), isTrue);
    clock.value = chatTestNow;
    expect(policy.isAvailable(message), isFalse);
  });

  test('next expiry ignores already expired messages', () {
    final policy = ChatExpiryPolicy(FakeChatClock(chatTestNow));
    final next = chatTestNow.add(const Duration(minutes: 2));
    expect(
      policy.nextExpiry([
        buildChatMessage(id: 'old', expiresAt: chatTestNow),
        buildChatMessage(id: 'next', expiresAt: next),
      ]),
      next,
    );
  });
}
