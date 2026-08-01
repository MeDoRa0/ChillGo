part of '../interactive_outing_card.dart';

class _CardChatButton extends StatelessWidget {
  const _CardChatButton({required this.outingId, required this.onPressed});

  final String outingId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ChatSummaryCubit>()..watch(outingId),
    child: BlocBuilder<ChatSummaryCubit, ChatSummaryState>(
      builder: (context, state) {
        final summary = state is ChatSummaryReady ? state.summary : null;
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ChillGoColors.sunshineSoft,
            shape: BoxShape.circle,
            border: Border.all(color: ChillGoColors.plum, width: 1.5),
          ),
          child: IconButton(
            key: const Key('outing-chat-entry'),
            tooltip: 'Outing chat',
            onPressed: onPressed,
            icon: ChatUnreadBadge(count: summary?.unreadCount ?? 0),
            color: ChillGoColors.plum,
            iconSize: 21,
          ),
        );
      },
    ),
  );
}
