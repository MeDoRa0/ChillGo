part of '../interactive_outing_card.dart';

class _StartingSoonBanner extends StatelessWidget {
  const _StartingSoonBanner({required this.minutesUntilStart});

  final int minutesUntilStart;

  String get _countdownLabel {
    if (minutesUntilStart == 60) return 'STARTS IN 1 HOUR';
    if (minutesUntilStart == 1) return 'STARTING IN 1 MIN';
    return 'STARTS IN $minutesUntilStart MIN';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Outing $_countdownLabel. Time to get ready.',
    child: Container(
      key: const Key('outing-starting-soon-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ChillGoColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChillGoColors.coral.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: ChillGoColors.coral,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x3DC93F49), blurRadius: 8)],
            ),
            child: const Icon(
              Icons.alarm_rounded,
              size: 17,
              color: ChillGoColors.surface,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _countdownLabel,
                  key: const Key('outing-starting-soon-countdown'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChillGoColors.coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Time to get ready',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
