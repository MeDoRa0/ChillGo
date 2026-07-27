import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../domain/entities/chat_command.dart';
import '../cubit/outing_chat/outing_chat_cubit.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_history_list.dart';

class OutingChatScreen extends StatelessWidget {
  const OutingChatScreen({super.key, required this.outingId});
  final String outingId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Outing chat'),
    ),
    body: BlocBuilder<OutingChatCubit, OutingChatState>(
      builder: (context, state) {
        if (state.status == OutingChatStatus.initial ||
            state.status == OutingChatStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == OutingChatStatus.unavailable) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.failure?.message ?? 'Chat is unavailable.'),
                  if (state.failure is ChatNetworkFailure ||
                      state.failure is ChatServiceFailure) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.read<OutingChatCubit>().watch(outingId),
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        final cubit = context.read<OutingChatCubit>();
        final uid = sl.isRegistered<AuthRepository>()
            ? sl<AuthRepository>().currentCredentials?.uid ?? ''
            : '';
        return Column(
          children: [
            if (!state.isWritable)
              const MaterialBanner(
                content: Text(
                  'This outing is finished. Available chat history is read-only.',
                ),
                actions: [SizedBox.shrink()],
              ),
            Expanded(
              child: ChatHistoryList(
                messages: state.messages,
                attempts: state.attempts,
                currentUserId: uid,
                hasMore: state.hasMore,
                loadingOlder: state.loadingOlder,
                showNewMessages: state.showNewMessages,
                firstUnreadMessageId: state.firstUnreadMessageId,
                onLoadOlder: cubit.loadOlder,
                onRetry: cubit.retry,
                onJumpToNewest: cubit.markThroughNewest,
              ),
            ),
            if (state.failure != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(state.failure!.message),
              ),
            ChatComposer(enabled: state.isWritable, onSend: cubit.send),
          ],
        );
      },
    ),
  );
}
