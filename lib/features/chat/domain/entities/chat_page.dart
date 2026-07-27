import 'package:equatable/equatable.dart';

import 'chat_message.dart';
import 'chat_message_cursor.dart';

const chatPageLimit = 50;

class ChatPage extends Equatable {
  ChatPage({required List<ChatMessage> messages, required this.hasMore})
    : messages = List.unmodifiable(messages) {
    if (messages.length > chatPageLimit) {
      throw ArgumentError.value(messages.length, 'messages', 'Maximum is 50');
    }
  }

  final List<ChatMessage> messages;
  final bool hasMore;

  ChatMessageCursor? get oldestCursor =>
      messages.isEmpty ? null : messages.first.cursor;
  ChatMessageCursor? get newestCursor =>
      messages.isEmpty ? null : messages.last.cursor;

  static ChatPage empty() => ChatPage(messages: const [], hasMore: false);

  @override
  List<Object?> get props => [messages, hasMore];
}
