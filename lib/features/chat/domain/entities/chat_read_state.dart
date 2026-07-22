import 'package:equatable/equatable.dart';

import 'chat_message_cursor.dart';

class ChatReadState extends Equatable {
  const ChatReadState({
    required this.outingId,
    required this.crewId,
    required this.userId,
    required this.cursor,
    required this.cursorExpiresAt,
    required this.updatedAt,
  });
  final String outingId;
  final String crewId;
  final String userId;
  final ChatMessageCursor cursor;
  final DateTime cursorExpiresAt;
  final DateTime updatedAt;
  @override
  List<Object?> get props => [
    outingId,
    crewId,
    userId,
    cursor,
    cursorExpiresAt,
    updatedAt,
  ];
}

class ChatSummary extends Equatable {
  const ChatSummary({required this.unreadCount, required this.isWritable});
  final int unreadCount;
  final bool isWritable;
  bool get hasUnread => unreadCount > 0;
  @override
  List<Object?> get props => [unreadCount, isWritable];
}
