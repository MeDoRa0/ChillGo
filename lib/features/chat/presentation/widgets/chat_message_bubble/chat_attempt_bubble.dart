part of '../chat_message_bubble.dart';

class ChatAttemptBubble extends StatelessWidget {
  const ChatAttemptBubble({
    super.key,
    required this.attempt,
    required this.onRetry,
  });
  final ChatSendAttempt attempt;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(attempt.text),
            Text(switch (attempt.status) {
              ChatSendAttemptStatus.sending => 'Sending…',
              ChatSendAttemptStatus.sent => 'Sent',
              ChatSendAttemptStatus.failed =>
                attempt.failure?.message ?? 'Failed',
            }),
            if (attempt.status == ChatSendAttemptStatus.failed)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}

String _time(DateTime value) =>
    '${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';
