import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/chat_command.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/chat_message_cursor.dart';
import '../../../domain/entities/chat_page.dart';
import '../../../domain/repositories/chat_repository.dart';

enum OutingChatStatus { initial, loading, ready, unavailable }

class OutingChatState extends Equatable {
  const OutingChatState({
    this.status = OutingChatStatus.initial,
    this.messages = const [],
    this.attempts = const [],
    this.hasMore = false,
    this.loadingOlder = false,
    this.isWritable = false,
    this.showNewMessages = false,
    this.firstUnreadMessageId,
    this.failure,
  });
  final OutingChatStatus status;
  final List<ChatMessage> messages;
  final List<ChatSendAttempt> attempts;
  final bool hasMore;
  final bool loadingOlder;
  final bool isWritable;
  final bool showNewMessages;
  final String? firstUnreadMessageId;
  final ChatFailure? failure;

  OutingChatState copyWith({
    OutingChatStatus? status,
    List<ChatMessage>? messages,
    List<ChatSendAttempt>? attempts,
    bool? hasMore,
    bool? loadingOlder,
    bool? isWritable,
    bool? showNewMessages,
    String? firstUnreadMessageId,
    bool clearFirstUnread = false,
    ChatFailure? failure,
    bool clearFailure = false,
  }) => OutingChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    attempts: attempts ?? this.attempts,
    hasMore: hasMore ?? this.hasMore,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    isWritable: isWritable ?? this.isWritable,
    showNewMessages: showNewMessages ?? this.showNewMessages,
    firstUnreadMessageId: clearFirstUnread
        ? null
        : firstUnreadMessageId ?? this.firstUnreadMessageId,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    messages,
    attempts,
    hasMore,
    loadingOlder,
    isWritable,
    showNewMessages,
    firstUnreadMessageId,
    failure,
  ];
}

class OutingChatCubit extends Cubit<OutingChatState> {
  OutingChatCubit({required this.repository}) : super(const OutingChatState());
  final ChatRepository repository;
  String? _outingId;
  StreamSubscription<ChatPage>? _messagesSubscription;
  StreamSubscription? _summarySubscription;
  StreamSubscription? _readStateSubscription;
  ChatMessageCursor? _readCursor;
  bool _accessRevoked = false;
  final Map<String, StreamSubscription<ChatCommand?>> _commandSubscriptions =
      {};

  Future<void> watch(String outingId) async {
    _outingId = outingId;
    _accessRevoked = false;
    emit(state.copyWith(status: OutingChatStatus.loading, clearFailure: true));
    await _messagesSubscription?.cancel();
    await _summarySubscription?.cancel();
    await _readStateSubscription?.cancel();
    _messagesSubscription = repository
        .watchLatestMessages(outingId)
        .listen(_mergeLatest, onError: _protect);
    _summarySubscription = repository
        .watchChatSummary(outingId)
        .listen(
          (summary) {
            if (!_accessRevoked) {
              emit(state.copyWith(isWritable: summary.isWritable));
            }
          },
          onError: _protect,
        );
    _readStateSubscription = repository.watchMyReadState(outingId).listen((
      readState,
    ) {
      if (_accessRevoked) return;
      _readCursor = readState?.cursor;
      _updateUnreadBoundary();
    }, onError: _protect);
  }

  void _mergeLatest(ChatPage page) {
    if (_accessRevoked) return;
    final previousNewest = state.messages.isEmpty
        ? null
        : state.messages.last.id;
    final merged = <String, ChatMessage>{
      for (final message in state.messages) message.id: message,
      for (final message in page.messages) message.id: message,
    }.values.toList()..sort((a, b) => a.cursor.compareTo(b.cursor));
    final hasNew =
        previousNewest != null &&
        merged.isNotEmpty &&
        merged.last.id != previousNewest;
    emit(
      state.copyWith(
        status: OutingChatStatus.ready,
        messages: merged,
        hasMore: page.hasMore,
        showNewMessages: state.showNewMessages || hasNew,
        clearFailure: true,
      ),
    );
    _updateUnreadBoundary();
  }

  void _updateUnreadBoundary() {
    final cursor = _readCursor;
    final unread = state.messages.where(
      (message) => cursor == null || message.cursor.isAfter(cursor),
    );
    emit(
      state.copyWith(
        firstUnreadMessageId: unread.isEmpty ? null : unread.first.id,
        clearFirstUnread: unread.isEmpty,
      ),
    );
  }

  Future<void> loadOlder() async {
    final outingId = _outingId;
    if (outingId == null ||
        state.loadingOlder ||
        !state.hasMore ||
        state.messages.isEmpty) {
      return;
    }
    emit(state.copyWith(loadingOlder: true, clearFailure: true));
    try {
      final page = await repository.loadOlderMessages(
        outingId,
        before: state.messages.first.cursor,
      );
      if (_accessRevoked) return;
      final merged = <String, ChatMessage>{
        for (final message in page.messages) message.id: message,
        for (final message in state.messages) message.id: message,
      }.values.toList()..sort((a, b) => a.cursor.compareTo(b.cursor));
      emit(
        state.copyWith(
          messages: merged,
          hasMore: page.hasMore,
          loadingOlder: false,
        ),
      );
      _updateUnreadBoundary();
    } on ChatFailure catch (failure) {
      emit(state.copyWith(loadingOlder: false, failure: failure));
    }
  }

  Future<void> send(String text, {String? clientMessageId}) async {
    final outingId = _outingId;
    if (outingId == null || !state.isWritable) return;
    final id = clientMessageId ?? repository.newClientMessageId();
    final trimmed = text.trim();
    _upsertAttempt(
      ChatSendAttempt(
        clientMessageId: id,
        text: trimmed,
        status: ChatSendAttemptStatus.sending,
      ),
    );
    try {
      final commandId = await repository.sendMessage(outingId, id, trimmed);
      _upsertAttempt(
        ChatSendAttempt(
          clientMessageId: id,
          text: trimmed,
          status: ChatSendAttemptStatus.sending,
          commandId: commandId,
        ),
      );
      await _commandSubscriptions[id]?.cancel();
      _commandSubscriptions[id] = repository.watchCommand(commandId).listen((
        command,
      ) {
        if (command?.status == ChatCommandStatus.succeeded) {
          _upsertAttempt(
            ChatSendAttempt(
              clientMessageId: id,
              text: trimmed,
              status: ChatSendAttemptStatus.sent,
              commandId: commandId,
            ),
          );
        } else if (command?.status == ChatCommandStatus.failed) {
          _upsertAttempt(
            ChatSendAttempt(
              clientMessageId: id,
              text: trimmed,
              status: ChatSendAttemptStatus.failed,
              commandId: commandId,
              failure: command?.failure ?? const ChatServiceFailure(),
            ),
          );
        }
      }, onError: (Object error) => _failAttempt(id, trimmed, error));
    } on Object catch (error) {
      _failAttempt(id, trimmed, error);
    }
  }

  Future<void> retry(ChatSendAttempt attempt) =>
      send(attempt.text, clientMessageId: attempt.clientMessageId);

  void _failAttempt(String id, String text, Object error) {
    _upsertAttempt(
      ChatSendAttempt(
        clientMessageId: id,
        text: text,
        status: ChatSendAttemptStatus.failed,
        failure: error is ChatFailure ? error : const ChatServiceFailure(),
      ),
    );
  }

  void _upsertAttempt(ChatSendAttempt attempt) {
    if (_accessRevoked) return;
    final attempts = [...state.attempts];
    final index = attempts.indexWhere(
      (item) => item.clientMessageId == attempt.clientMessageId,
    );
    if (index < 0) {
      attempts.add(attempt);
    } else {
      attempts[index] = attempt;
    }
    emit(state.copyWith(attempts: attempts));
  }

  Future<void> markThroughNewest() async {
    final outingId = _outingId;
    if (outingId == null || state.messages.isEmpty) return;
    await repository.markReadThrough(outingId, state.messages.last.cursor);
    emit(state.copyWith(showNewMessages: false, clearFirstUnread: true));
  }

  void _protect(Object error) {
    _accessRevoked = true;
    _readCursor = null;
    final failure = error is ChatFailure ? error : const ChatServiceFailure();
    emit(
      OutingChatState(
        status: OutingChatStatus.unavailable,
        failure: failure,
        isWritable: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    await _summarySubscription?.cancel();
    await _readStateSubscription?.cancel();
    for (final subscription in _commandSubscriptions.values) {
      await subscription.cancel();
    }
    return super.close();
  }
}
