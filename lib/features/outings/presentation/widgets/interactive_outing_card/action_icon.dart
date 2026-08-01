part of '../interactive_outing_card.dart';

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    child: Tooltip(
      message: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkResponse(
            onTap: onPressed,
            radius: 40,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.7)),
              ),
              child: Icon(icon, size: 38, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ChillGoColors.inkMuted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
