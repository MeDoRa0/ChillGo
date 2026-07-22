import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:chillgo/features/chat/domain/entities/chat_read_state.dart';
import 'package:chillgo/features/chat/presentation/cubit/chat_summary/chat_summary_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chat_test_helpers.dart';

void main() {
  test('emits private unread and writable summary updates', () async {
    final repository = FakeChatRepository();
    final cubit = ChatSummaryCubit(repository: repository);
    await cubit.watch('outing-1');
    repository.summaries.add(
      const ChatSummary(unreadCount: 4, isWritable: false),
    );
    await Future<void>.delayed(Duration.zero);
    final state = cubit.state as ChatSummaryReady;
    expect(state.summary.unreadCount, 4);
    expect(state.summary.isWritable, isFalse);
    await cubit.close();
  });

  test('maps access loss without exposing protected details', () async {
    final repository = FakeChatRepository();
    final cubit = ChatSummaryCubit(repository: repository);
    await cubit.watch('outing-1');
    repository.summaries.addError(const ChatAccessDenied());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<ChatSummaryUnavailable>());
    await cubit.close();
  });
}
