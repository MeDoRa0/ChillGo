part of '../home_mobile_layout.dart';

class _InvitationNotificationButton extends StatelessWidget {
  final CrewRepository repository;

  const _InvitationNotificationButton({required this.repository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewInvitation>>(
      stream: repository.streamReceivedInvitations(),
      builder: (context, snapshot) {
        final hasCrewInvitations = snapshot.data?.isNotEmpty ?? false;
        return _NotificationBell(hasUnread: hasCrewInvitations);
      },
    );
  }
}
