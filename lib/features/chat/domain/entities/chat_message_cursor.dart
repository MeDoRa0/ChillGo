import 'package:equatable/equatable.dart';

class ChatMessageCursor extends Equatable
    implements Comparable<ChatMessageCursor> {
  const ChatMessageCursor({required this.acceptedAt, required this.messageId});

  final DateTime acceptedAt;
  final String messageId;

  @override
  int compareTo(ChatMessageCursor other) {
    final time = acceptedAt.compareTo(other.acceptedAt);
    return time != 0 ? time : messageId.compareTo(other.messageId);
  }

  bool isAfter(ChatMessageCursor other) => compareTo(other) > 0;

  @override
  List<Object> get props => [acceptedAt.toUtc(), messageId];
}
