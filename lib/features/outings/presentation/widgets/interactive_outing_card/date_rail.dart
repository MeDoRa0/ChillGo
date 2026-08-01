part of '../interactive_outing_card.dart';

class _DateRail extends StatelessWidget {
  const _DateRail({required this.scheduledAt, required this.isStartingSoon});

  final DateTime scheduledAt;
  final bool isStartingSoon;

  @override
  Widget build(BuildContext context) {
    final localDate = scheduledAt.toLocal();
    final foregroundColor = isStartingSoon
        ? ChillGoColors.surface
        : ChillGoColors.ink;
    return AnimatedContainer(
      key: const Key('outing-date-rail'),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      color: isStartingSoon
          ? ChillGoColors.coral
          : ChillGoColors.coralSoft.withValues(alpha: 0.58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isStartingSoon) ...[
            Container(
              key: const Key('outing-starting-soon-badge'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ChillGoColors.surface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: ChillGoColors.surface.withValues(alpha: 0.7),
                ),
              ),
              child: const Text(
                'SOON',
                style: TextStyle(
                  color: ChillGoColors.surface,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            localDate.day.toString().padLeft(2, '0'),
            style: TextStyle(
              color: foregroundColor,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _monthLabel(localDate.month),
            style: TextStyle(
              color: foregroundColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: isStartingSoon
                  ? ChillGoColors.surface.withValues(alpha: 0.65)
                  : ChillGoColors.coral,
            ),
          ),
          Text(
            _timeLabel(localDate),
            maxLines: 1,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
