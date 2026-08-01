part of '../../screens/invitations_screen.dart';

class _NotificationSectionTitle extends StatelessWidget {
  const _NotificationSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ChillGoColors.ink,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );
}
