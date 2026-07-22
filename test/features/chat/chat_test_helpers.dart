import 'dart:async';

import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:chillgo/features/chat/domain/entities/chat_message.dart';
import 'package:chillgo/features/chat/domain/entities/chat_message_cursor.dart';
import 'package:chillgo/features/chat/domain/entities/chat_page.dart';
import 'package:chillgo/features/chat/domain/entities/chat_read_state.dart';
import 'package:chillgo/features/chat/domain/repositories/chat_repository.dart';
import 'package:chillgo/features/chat/domain/services/chat_clock.dart';

final chatTestNow = DateTime.utc(2026, 7, 22, 12);

ChatMessage buildChatMessage({
  String id = 'message-1',
  String authorUserId = 'user-2',
  DateTime? acceptedAt,
  DateTime? expiresAt,
  String text = 'Hello',
}) {
  final accepted = acceptedAt ?? chatTestNow;
  return ChatMessage(
    id: id,
    outingId: 'outing-1',
    crewId: 'crew-1',
    clientMessageId: 'client-$id',
    authorUserId: authorUserId,
    authorUsername: 'traveler',
    authorDisplayName: 'Traveler',
    text: text,
    acceptedAt: accepted,
    expiresAt: expiresAt ?? accepted.add(const Duration(hours: 24)),
  );
}

class FakeChatClock extends FixedChatClock {
  FakeChatClock(super.value);
}

class FakeChatRepository implements ChatRepository {
  final latest = StreamController<ChatPage>.broadcast();
  final commands = <String, StreamController<ChatCommand?>>{};
  final readStates = StreamController<ChatReadState?>.broadcast();
  final summaries = StreamController<ChatSummary>.broadcast();
  final sent = <({String outingId, String clientMessageId, String text})>[];
  final marked = <({String outingId, ChatMessageCursor cursor})>[];
  ChatPage older = ChatPage.empty();
  int unreadCount = 0;
  int idSequence = 0;

  @override
  Future<int> getUnreadCount(String outingId) async => unreadCount;
  @override
  Future<ChatPage> loadOlderMessages(
    String outingId, {
    required ChatMessageCursor before,
    int limit = 50,
  }) async => older;
  @override
  Future<void> markReadThrough(
    String outingId,
    ChatMessageCursor cursor,
  ) async {
    marked.add((outingId: outingId, cursor: cursor));
  }

  @override
  String newClientMessageId() => 'client-${++idSequence}';
  @override
  Future<String> sendMessage(
    String outingId,
    String clientMessageId,
    String text,
  ) async {
    sent.add((
      outingId: outingId,
      clientMessageId: clientMessageId,
      text: text,
    ));
    return 'command-${sent.length}';
  }

  @override
  Stream<ChatCommand?> watchCommand(String commandId) => commands
      .putIfAbsent(commandId, StreamController<ChatCommand?>.broadcast)
      .stream;
  @override
  Stream<ChatPage> watchLatestMessages(String outingId, {int limit = 50}) =>
      latest.stream;
  @override
  Stream<ChatSummary> watchChatSummary(String outingId) => summaries.stream;
  @override
  Stream<ChatReadState?> watchMyReadState(String outingId) => readStates.stream;
}
