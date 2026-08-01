part of '../home_mobile_layout.dart';

class _NotificationBell extends StatelessWidget {
  final bool hasUnread;

  const _NotificationBell({required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('invitations-button'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            hasUnread ? Icons.notifications_active : Icons.notifications,
            color: ChillGoColors.ink,
          ),
          if (hasUnread)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                key: const Key('unread-invitations-badge'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ChillGoColors.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: ChillGoColors.canvas, width: 2),
                ),
              ),
            ),
        ],
      ),
      tooltip: hasUnread ? 'New notifications' : 'Notifications',
      onPressed: () => context.push('/invitations'),
    );
  }
}
