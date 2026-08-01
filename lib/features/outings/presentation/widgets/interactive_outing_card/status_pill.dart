part of '../interactive_outing_card.dart';

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OutingStatus status;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('outing-status'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: ChillGoColors.coral,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      _statusLabel(status),
      style: const TextStyle(
        color: ChillGoColors.surface,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    ),
  );
}
