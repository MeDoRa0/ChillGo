import '../entities/chat_message.dart';
import 'chat_clock.dart';

class ChatExpiryPolicy {
  const ChatExpiryPolicy(this.clock);
  final ChatClock clock;

  bool isAvailable(ChatMessage message) => message.expiresAt.isAfter(clock.now);

  List<ChatMessage> available(Iterable<ChatMessage> messages) =>
      messages.where(isAvailable).toList(growable: false);

  DateTime? nextExpiry(Iterable<ChatMessage> messages) {
    DateTime? next;
    for (final message in messages) {
      if (!isAvailable(message)) continue;
      if (next == null || message.expiresAt.isBefore(next)) {
        next = message.expiresAt;
      }
    }
    return next;
  }

  Duration? durationUntilNextExpiry(Iterable<ChatMessage> messages) {
    final expiry = nextExpiry(messages);
    return expiry?.difference(clock.now);
  }
}
