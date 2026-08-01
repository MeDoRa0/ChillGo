part of '../../screens/crew_details_screen.dart';

class _InlineMessage extends StatelessWidget {
  final String message;

  const _InlineMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: Text(
        message,
        style: const TextStyle(color: ChillGoColors.inkMuted),
      ),
    );
  }
}
