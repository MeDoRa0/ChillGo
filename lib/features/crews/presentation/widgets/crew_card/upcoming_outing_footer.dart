part of '../crew_card.dart';

class _UpcomingOutingFooter extends StatelessWidget {
  const _UpcomingOutingFooter({
    required this.outing,
    required this.now,
    required this.compact,
  });

  final Outing outing;
  final DateTime now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final countdown = _formatCountdown(outing.scheduledAt.difference(now));
    final schedule = _formatSchedule(context, outing.scheduledAt, now);

    return Semantics(
      label: 'Active outing',
      container: true,
      explicitChildNodes: true,
      child: Stack(
        children: [
          const Positioned.fill(child: _CreamWave()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                label: 'Starts in $countdown',
                child: _CountdownBadge(countdown: countdown, compact: compact),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: compact ? 40 : 52,
            bottom: compact ? 2 : 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  outing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 1 : 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        schedule,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ChillGoColors.inkMuted,
                          fontSize: compact ? 9 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(
                      Icons.location_on_rounded,
                      color: ChillGoColors.sky,
                      size: compact ? 11 : 14,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        outing.locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ChillGoColors.inkMuted,
                          fontSize: compact ? 9 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
