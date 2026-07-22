import 'package:flutter/material.dart';

class ChatUnreadBadge extends StatelessWidget {
  const ChatUnreadBadge({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 99 ? '99+' : '$count';
    return Semantics(
      label: '$count unread chat messages',
      child: Badge(
        label: Text(label),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
