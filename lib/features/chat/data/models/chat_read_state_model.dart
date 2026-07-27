import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/chat_message_cursor.dart';
import '../../domain/entities/chat_read_state.dart';

class ChatReadStateModel extends ChatReadState {
  const ChatReadStateModel({
    required super.outingId,
    required super.crewId,
    required super.userId,
    required super.cursor,
    required super.cursorExpiresAt,
    required super.updatedAt,
  });

  factory ChatReadStateModel.fromMap(Map<String, dynamic> map) {
    final acceptedAt = readFirestoreTimestamp(map['readThroughAcceptedAt']);
    final expiresAt = readFirestoreTimestamp(map['cursorExpiresAt']);
    final updatedAt = readFirestoreTimestamp(map['updatedAt']);
    if (acceptedAt == null || expiresAt == null || updatedAt == null) {
      throw const FormatException('Invalid chat read-state timestamps');
    }
    return ChatReadStateModel(
      outingId: map['outingId'] as String,
      crewId: map['crewId'] as String,
      userId: map['userId'] as String,
      cursor: ChatMessageCursor(
        acceptedAt: acceptedAt,
        messageId: map['readThroughMessageId'] as String,
      ),
      cursorExpiresAt: expiresAt,
      updatedAt: updatedAt,
    );
  }
}
