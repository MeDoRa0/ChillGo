import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_command.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_message_cursor.dart';
import '../../domain/entities/chat_page.dart';
import '../../domain/entities/chat_read_state.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/chat_access_policy.dart';
import '../../domain/services/chat_clock.dart';
import '../../domain/services/chat_expiry_policy.dart';
import '../datasources/firestore_chat_datasource.dart';
import '../models/chat_command_model.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required this.datasource,
    required this.clock,
    this.accessPolicy = const ChatAccessPolicy(),
  }) : expiryPolicy = ChatExpiryPolicy(clock);

  final FirestoreChatDatasource datasource;
  final ChatClock clock;
  final ChatAccessPolicy accessPolicy;
  final ChatExpiryPolicy expiryPolicy;
  final Map<String, ChatMessageModel> _knownMessages = {};

  Future<void> _ensureClock() async {
    if (!clock.isEstablished) await clock.establish();
  }

  @override
  Stream<ChatPage> watchLatestMessages(String outingId, {int limit = 50}) {
    late StreamController<ChatPage> controller;
    StreamSubscription<List<ChatMessageModel>>? subscription;
    Timer? expiryTimer;
    List<ChatMessageModel> raw = const [];

    void emitAvailable() {
      expiryTimer?.cancel();
      final available = expiryPolicy.available(raw).cast<ChatMessageModel>()
        ..sort((left, right) => left.cursor.compareTo(right.cursor));
      for (final message in available) {
        _knownMessages[message.id] = message;
      }
      controller.add(
        ChatPage(messages: available, hasMore: raw.length >= limit),
      );
      final duration = expiryPolicy.durationUntilNextExpiry(available);
      if (duration != null) expiryTimer = Timer(duration, emitAvailable);
    }

    controller = StreamController<ChatPage>(
      onListen: () async {
        try {
          await _ensureClock();
          subscription = datasource
              .watchLatest(outingId, limit)
              .listen(
                (messages) {
                  raw = messages;
                  emitAvailable();
                },
                onError: (Object error, StackTrace stack) {
                  _knownMessages.clear();
                  controller.addError(_mapError(error), stack);
                },
              );
        } catch (error, stack) {
          controller.addError(_mapError(error), stack);
        }
      },
      onCancel: () async {
        expiryTimer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<ChatPage> loadOlderMessages(
    String outingId, {
    required ChatMessageCursor before,
    int limit = 50,
  }) async {
    try {
      await _ensureClock();
      final raw = await datasource.loadOlder(outingId, before, limit);
      final unique = <String, ChatMessage>{};
      for (final message in expiryPolicy.available(raw)) {
        unique[message.id] = message;
        _knownMessages[message.id] = message as ChatMessageModel;
      }
      final messages = unique.values.toList()
        ..sort((left, right) => left.cursor.compareTo(right.cursor));
      return ChatPage(messages: messages, hasMore: raw.length >= limit);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  String newClientMessageId() => datasource.newDocumentId();

  @override
  Future<String> sendMessage(
    String outingId,
    String clientMessageId,
    String text,
  ) async {
    try {
      final validated = ChatCommandModel.validateText(text);
      return await datasource.createSendCommand(
        outingId: outingId,
        clientMessageId: clientMessageId,
        text: validated,
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Stream<ChatCommand?> watchCommand(String commandId) => datasource
      .watchCommand(commandId)
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stack, sink) {
            sink.addError(_mapError(error), stack);
          },
        ),
      );

  @override
  Stream<ChatReadState?> watchMyReadState(String outingId) => datasource
      .watchMyReadState(outingId)
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stack, sink) {
            sink.addError(_mapError(error), stack);
          },
        ),
      );

  @override
  Future<void> markReadThrough(
    String outingId,
    ChatMessageCursor cursor,
  ) async {
    final message = _knownMessages[cursor.messageId];
    if (message == null || !expiryPolicy.isAvailable(message)) {
      throw const ChatNotFound();
    }
    try {
      await datasource.markReadThrough(
        outingId: outingId,
        crewId: message.crewId,
        message: message,
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<int> getUnreadCount(String outingId) async {
    await _ensureClock();
    ChatReadState? state;
    try {
      state = await watchMyReadState(outingId).first;
      final effective =
          state != null && state.cursorExpiresAt.isAfter(clock.now)
          ? state.cursor
          : null;
      return await datasource.unreadCount(outingId: outingId, after: effective);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Stream<ChatSummary> watchChatSummary(String outingId) {
    late StreamController<ChatSummary> controller;
    StreamSubscription? accessSubscription;
    StreamSubscription? messageSubscription;
    StreamSubscription? readStateSubscription;
    ChatAccessSnapshot? access;

    Future<void> refresh() async {
      final current = access;
      if (current == null) return;
      final decision = accessPolicy.evaluate(
        status: current.status,
        isCrewMember: current.isCrewMember,
        isParticipant: current.isParticipant,
        deletionPending: current.deletionPending,
      );
      if (decision == ChatAccess.inaccessible) {
        _knownMessages.clear();
        controller.addError(const ChatAccessDenied());
        return;
      }
      try {
        final count = await getUnreadCount(outingId);
        controller.add(
          ChatSummary(
            unreadCount: count,
            isWritable: decision == ChatAccess.writable,
          ),
        );
      } on ChatFailure catch (failure, stack) {
        controller.addError(failure, stack);
      }
    }

    controller = StreamController<ChatSummary>(
      onListen: () {
        accessSubscription = datasource.watchAccess(outingId).listen((value) {
          access = value;
          unawaited(refresh());
        }, onError: controller.addError);
        messageSubscription = watchLatestMessages(
          outingId,
          limit: 1,
        ).listen((_) => unawaited(refresh()), onError: controller.addError);
        readStateSubscription = watchMyReadState(
          outingId,
        ).listen((_) => unawaited(refresh()), onError: controller.addError);
      },
      onCancel: () async {
        await accessSubscription?.cancel();
        await messageSubscription?.cancel();
        await readStateSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  ChatFailure _mapError(Object error) {
    if (error is ChatFailure) return error;
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' || 'unauthenticated' => const ChatAccessDenied(),
        'not-found' => const ChatNotFound(),
        'unavailable' ||
        'deadline-exceeded' ||
        'aborted' => const ChatNetworkFailure(),
        _ => const ChatServiceFailure(),
      };
    }
    return const ChatServiceFailure();
  }
}
