part of '../sunshine_background.dart';

class _BackgroundSpot extends StatelessWidget {
  const _BackgroundSpot({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
