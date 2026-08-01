part of '../../screens/outing_form_screen.dart';

class _SelectedMapLabel extends StatelessWidget {
  const _SelectedMapLabel(this.mapLocation);

  final String mapLocation;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 12,
    right: 12,
    bottom: 10,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChillGoColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        mapLocation,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ChillGoColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
