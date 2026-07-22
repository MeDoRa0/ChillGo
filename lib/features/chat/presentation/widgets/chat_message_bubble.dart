import 'package:flutter/material.dart';
import '../../domain/entities/chat_command.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });
  final ChatMessage message;
  final bool isMine;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${message.authorDisplayName}, ${message.text}',
    child: Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: isMine ? Theme.of(context).colorScheme.primaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.authorDisplayName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              SelectableText(message.text, textDirection: TextDirection.ltr),
              const SizedBox(height: 4),
              Text(
                _time(message.acceptedAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

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
