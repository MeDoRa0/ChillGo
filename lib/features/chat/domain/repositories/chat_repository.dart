import '../entities/chat_command.dart';
import '../entities/chat_message_cursor.dart';
import '../entities/chat_page.dart';
import '../entities/chat_read_state.dart';

abstract interface class ChatRepository {
  Stream<ChatPage> watchLatestMessages(String outingId, {int limit = 50});
  Future<ChatPage> loadOlderMessages(
    String outingId, {
    required ChatMessageCursor before,
    int limit = 50,
  });
  String newClientMessageId();
  Future<String> sendMessage(
    String outingId,
    String clientMessageId,
    String text,
  );
  Stream<ChatCommand?> watchCommand(String commandId);
  Stream<ChatReadState?> watchMyReadState(String outingId);
  Future<void> markReadThrough(String outingId, ChatMessageCursor cursor);
  Future<int> getUnreadCount(String outingId);
  Stream<ChatSummary> watchChatSummary(String outingId);
}
