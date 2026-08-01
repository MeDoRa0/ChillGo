part of '../home_mobile_layout.dart';

class _InvitationNotificationButton extends StatelessWidget {
  final CrewRepository repository;
  final OutingReviewNotificationRepository? outingNotificationRepository;

  const _InvitationNotificationButton({
    required this.repository,
    required this.outingNotificationRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewInvitation>>(
      stream: repository.streamReceivedInvitations(),
      builder: (context, snapshot) {
        final hasCrewInvitations = snapshot.data?.isNotEmpty ?? false;
        final outingRepository = outingNotificationRepository;
        if (outingRepository == null) {
          return _NotificationBell(hasUnread: hasCrewInvitations);
        }
        return StreamBuilder<List<OutingReviewNotification>>(
          stream: outingRepository.watchNotifications(),
          builder: (context, outingSnapshot) {
            final hasUnreadOutings = (outingSnapshot.data ?? const []).any(
              (notification) => !notification.isRead,
            );
            return _NotificationBell(
              hasUnread: hasCrewInvitations || hasUnreadOutings,
            );
          },
        );
      },
    );
  }
}
