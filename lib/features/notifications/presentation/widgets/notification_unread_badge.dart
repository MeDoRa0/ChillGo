import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/notification_page.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationUnreadBadge extends StatelessWidget {
  const NotificationUnreadBadge({super.key, required this.repository});

  final NotificationRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UnreadNotificationSummary>(
      stream: repository.watchUnreadSummary(),
      initialData: const UnreadNotificationSummary(0),
      builder: (context, snapshot) {
        final count = snapshot.data?.count ?? 0;
        final label = count == 0
            ? 'Notifications'
            : '$count unread notification${count == 1 ? '' : 's'}';
        return Semantics(
          button: true,
          label: label,
          child: IconButton(
            key: const Key('notifications-button'),
            tooltip: label,
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              key: const Key('notification-unread-badge'),
              isLabelVisible: count > 0,
              label: Text(count > 99 ? '99+' : '$count'),
              child: Icon(
                count > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_outlined,
              ),
            ),
          ),
        );
      },
    );
  }
}
