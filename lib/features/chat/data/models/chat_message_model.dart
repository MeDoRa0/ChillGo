import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.outingId,
    required super.crewId,
    required super.clientMessageId,
    required super.authorUserId,
    required super.authorUsername,
    required super.authorDisplayName,
    super.authorAvatarUrl,
    required super.text,
    required super.acceptedAt,
    required super.expiresAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    String requiredString(String key) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
      throw FormatException('Invalid chat message $key');
    }

    final acceptedAt = readFirestoreTimestamp(map['acceptedAt']);
    final expiresAt = readFirestoreTimestamp(map['expiresAt']);
    if (acceptedAt == null || expiresAt == null) {
      throw const FormatException('Invalid chat message timestamps');
    }
    final avatar = map['authorAvatarUrl'];
    if (avatar != null && avatar is! String) {
      throw const FormatException('Invalid chat message avatar');
    }
    return ChatMessageModel(
      id: id,
      outingId: requiredString('outingId'),
      crewId: requiredString('crewId'),
      clientMessageId: requiredString('clientMessageId'),
      authorUserId: requiredString('authorUserId'),
      authorUsername: requiredString('authorUsername'),
      authorDisplayName: requiredString('authorDisplayName'),
      authorAvatarUrl: avatar as String?,
      text: requiredString('text'),
      acceptedAt: acceptedAt,
      expiresAt: expiresAt,
    );
  }
}
