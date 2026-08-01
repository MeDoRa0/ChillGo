part of '../interactive_outing_card.dart';

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.outing,
    required this.participants,
    required this.actionButtonSpace,
    required this.isStartingSoon,
    required this.minutesUntilStart,
    this.trailing,
  });
  final Outing outing;
  final List<OutingParticipant> participants;
  final Widget? actionButtonSpace;
  final bool isStartingSoon;
  final int minutesUntilStart;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dateRailWidth = (constraints.maxWidth * 0.24)
          .clamp(84.0, 112.0)
          .toDouble();
      return AnimatedContainer(
        key: const Key('outing-card-surface'),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: _cardDecoration,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: dateRailWidth,
              child: _DateRail(
                scheduledAt: outing.scheduledAt,
                isStartingSoon: isStartingSoon,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: dateRailWidth),
              child: _CardContent(
                outing: outing,
                participants: participants,
                actionButtonSpace: actionButtonSpace,
                trailing: trailing,
                isStartingSoon: isStartingSoon,
                minutesUntilStart: minutesUntilStart,
              ),
            ),
          ],
        ),
      );
    },
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isStartingSoon
          ? const [Color(0xFFFFF1A9), Color(0xFFFFD6C8)]
          : const [ChillGoColors.sunshineSoft, ChillGoColors.sunshineSoft],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: isStartingSoon ? ChillGoColors.coral : ChillGoColors.outline,
      width: isStartingSoon ? 1.5 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: isStartingSoon
            ? const Color(0x40C93F49)
            : const Color(0x186D3A72),
        blurRadius: isStartingSoon ? 24 : 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
