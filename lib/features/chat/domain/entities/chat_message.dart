import 'package:equatable/equatable.dart';

import 'chat_message_cursor.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.outingId,
    required this.crewId,
    required this.clientMessageId,
    required this.authorUserId,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    required this.text,
    required this.acceptedAt,
    required this.expiresAt,
  });

  final String id;
  final String outingId;
  final String crewId;
  final String clientMessageId;
  final String authorUserId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime acceptedAt;
  final DateTime expiresAt;

  ChatMessageCursor get cursor =>
      ChatMessageCursor(acceptedAt: acceptedAt, messageId: id);

  @override
  List<Object?> get props => [
    id,
    outingId,
    crewId,
    clientMessageId,
    authorUserId,
    authorUsername,
    authorDisplayName,
    authorAvatarUrl,
    text,
    acceptedAt.toUtc(),
    expiresAt.toUtc(),
  ];
}
