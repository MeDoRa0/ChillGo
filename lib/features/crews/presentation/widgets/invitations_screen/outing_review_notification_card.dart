part of '../../screens/invitations_screen.dart';

class _OutingReviewNotificationCard extends StatelessWidget {
  const _OutingReviewNotificationCard({
    required this.notification,
    required this.repository,
  });

  final OutingReviewNotification notification;
  final OutingReviewNotificationRepository repository;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('outing-notification-${notification.id}'),
      onTap: () => _openReview(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ChillGoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? ChillGoColors.outline
                : ChillGoColors.coral,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available, color: ChillGoColors.coral),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${notification.creatorDisplayName} created a new outing',
                    style: const TextStyle(
                      color: ChillGoColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.outingTitle,
                    style: const TextStyle(color: ChillGoColors.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to review',
                    style: TextStyle(
                      color: ChillGoColors.coral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ChillGoColors.inkMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openReview(BuildContext context) async {
    try {
      await repository.markRead(notification.id);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark the notification as read.'),
        ),
      );
      return;
    }
    if (context.mounted) {
      context.push('/outings/${notification.outingId}/review');
    }
  }
}
