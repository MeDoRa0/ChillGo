part of '../crew_card.dart';

class _CalendarAction extends StatelessWidget {
  const _CalendarAction({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 50.0;
    final circleSize = compact ? 34.0 : 42.0;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: ChillGoColors.sunshine,
                shape: BoxShape.circle,
                border: Border.all(color: ChillGoColors.surface, width: 2),
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: compact ? 17 : 21,
                color: ChillGoColors.ink,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.arrow_outward_rounded,
                color: ChillGoColors.ink,
                size: compact ? 17 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCountdown(Duration remaining) {
  if (remaining.inMinutes < 60) {
    return '${remaining.inMinutes.clamp(1, 59)}m';
  }
  return '${remaining.inHours.clamp(1, 24)}h';
}

String _formatSchedule(
  BuildContext context,
  DateTime scheduledAt,
  DateTime now,
) {
  final localScheduledAt = scheduledAt.toLocal();
  final localNow = now.toLocal();
  final scheduledDate = DateUtils.dateOnly(localScheduledAt);
  final today = DateUtils.dateOnly(localNow);
  final dayLabel = scheduledDate == today ? 'Today' : 'Tomorrow';
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(localScheduledAt));
  return '$dayLabel آ· $time';
}
