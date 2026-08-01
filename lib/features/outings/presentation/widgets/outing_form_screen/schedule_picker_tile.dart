part of '../../screens/outing_form_screen.dart';

class _SchedulePickerTile extends StatelessWidget {
  const _SchedulePickerTile({
    required this.icon,
    required this.label,
    required this.displayText,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String displayText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChillGoColors.canvas,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ChillGoColors.coral),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: ChillGoColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayText,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ChillGoColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
