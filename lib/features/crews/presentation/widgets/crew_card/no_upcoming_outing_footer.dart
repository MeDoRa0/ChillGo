part of '../crew_card.dart';

class _NoUpcomingOutingFooter extends StatelessWidget {
  const _NoUpcomingOutingFooter({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _CreamWave()),
        Positioned(
          left: 16,
          right: compact ? 54 : 64,
          top: compact ? 16 : 22,
          bottom: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: ChillGoColors.sky,
                size: compact ? 18 : 22,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'No plans in the next 24h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: compact ? 8 : 12,
          bottom: compact ? 6 : 10,
          child: _CalendarAction(compact: compact),
        ),
      ],
    );
  }
}
