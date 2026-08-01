part of '../interactive_outing_card.dart';

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.outing,
    required this.participants,
    required this.actionButtonSpace,
    this.trailing,
  });
  final Outing outing;
  final List<OutingParticipant> participants;
  final Widget? actionButtonSpace;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dateRailWidth = (constraints.maxWidth * 0.24)
          .clamp(84.0, 112.0)
          .toDouble();
      return Container(
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
              child: _DateRail(scheduledAt: outing.scheduledAt),
            ),
            Padding(
              padding: EdgeInsets.only(left: dateRailWidth),
              child: _CardContent(
                outing: outing,
                participants: participants,
                actionButtonSpace: actionButtonSpace,
                trailing: trailing,
              ),
            ),
          ],
        ),
      );
    },
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: ChillGoColors.sunshineSoft,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: ChillGoColors.outline),
    boxShadow: const [
      BoxShadow(color: Color(0x186D3A72), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}
