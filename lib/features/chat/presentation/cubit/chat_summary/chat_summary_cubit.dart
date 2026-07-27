import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_command.dart';
import '../../../domain/entities/chat_read_state.dart';
import '../../../domain/repositories/chat_repository.dart';

sealed class ChatSummaryState {
  const ChatSummaryState();
}

class ChatSummaryLoading extends ChatSummaryState {
  const ChatSummaryLoading();
}

class ChatSummaryReady extends ChatSummaryState {
  const ChatSummaryReady(this.summary);
  final ChatSummary summary;
}

class ChatSummaryUnavailable extends ChatSummaryState {
  const ChatSummaryUnavailable(this.failure);
  final ChatFailure failure;
}

class ChatSummaryCubit extends Cubit<ChatSummaryState> {
  ChatSummaryCubit({required this.repository})
    : super(const ChatSummaryLoading());
  final ChatRepository repository;
  StreamSubscription<ChatSummary>? _subscription;
  Future<void> watch(String outingId) async {
    await _subscription?.cancel();
    emit(const ChatSummaryLoading());
    _subscription = repository
        .watchChatSummary(outingId)
        .listen(
          (summary) => emit(ChatSummaryReady(summary)),
          onError: (Object error) => emit(
            ChatSummaryUnavailable(
              error is ChatFailure ? error : const ChatServiceFailure(),
            ),
          ),
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
