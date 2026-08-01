part of '../../screens/outing_form_screen.dart';

class _LockedOutingMessage extends StatelessWidget {
  const _LockedOutingMessage();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Text(
      'This outing can no longer be edited.',
      style: TextStyle(color: ChillGoColors.inkMuted),
    ),
  );
}
