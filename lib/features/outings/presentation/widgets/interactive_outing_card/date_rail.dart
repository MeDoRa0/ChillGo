part of '../interactive_outing_card.dart';

class _DateRail extends StatelessWidget {
  const _DateRail({required this.scheduledAt});

  final DateTime scheduledAt;

  @override
  Widget build(BuildContext context) {
    final localDate = scheduledAt.toLocal();
    return Container(
      key: const Key('outing-date-rail'),
      color: ChillGoColors.coralSoft.withValues(alpha: 0.58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localDate.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _monthLabel(localDate.month),
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: ChillGoColors.coral),
          ),
          Text(
            _timeLabel(localDate),
            maxLines: 1,
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
