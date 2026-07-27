import 'package:flutter/material.dart';

class ChatUnreadBadge extends StatelessWidget {
  const ChatUnreadBadge({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Semantics(
      label: count > 0 ? '$count unread chat messages' : 'Outing chat',
      child: Badge(
        isLabelVisible: count > 0,
        label: Text(label),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
