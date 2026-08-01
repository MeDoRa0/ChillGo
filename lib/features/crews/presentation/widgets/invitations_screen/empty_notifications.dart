part of '../../screens/invitations_screen.dart';

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: ChillGoColors.sunshineSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: ChillGoColors.coral,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No new notifications',
            style: TextStyle(
              color: ChillGoColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New crew invitations and outings will appear here.',
            style: TextStyle(color: ChillGoColors.inkMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
