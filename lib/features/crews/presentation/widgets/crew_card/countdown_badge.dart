part of '../crew_card.dart';

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.countdown, required this.compact});

  final String countdown;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 52.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ChillGoColors.sunshine,
        shape: BoxShape.circle,
        border: Border.all(color: ChillGoColors.surface, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33FFC83D), blurRadius: 8)],
      ),
      child: Text(
        countdown,
        style: TextStyle(
          color: ChillGoColors.ink,
          fontSize: compact ? 15 : 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
