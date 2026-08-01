part of '../crew_card.dart';

class _CrewCardLayout extends StatelessWidget {
  const _CrewCardLayout({
    required this.crewName,
    required this.memberStream,
    required this.invitationStream,
    required this.outingState,
  });

  final String crewName;
  final Stream<List<CrewMembership>> memberStream;
  final Stream<List<CrewInvitation>>? invitationStream;
  final _UpcomingOutingState outingState;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 210;
        final upcomingOuting = outingState.outing;
        final hasUpcomingOuting = upcomingOuting != null;
        final footerHeight = hasUpcomingOuting
            ? (compact ? 76.0 : constraints.maxHeight * 0.42)
            : (compact ? 56.0 : constraints.maxHeight * 0.32);
        final identityBottom = footerHeight - (hasUpcomingOuting ? 12 : 8);

        return Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: ChillGoColors.skySoft),
            ),
            Positioned(
              top: compact ? 6 : 14,
              left: 16,
              right: 16,
              bottom: identityBottom,
              child: _CrewIdentity(
                crewName: crewName,
                memberStream: memberStream,
                invitationStream: invitationStream,
                dense: compact && hasUpcomingOuting,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: footerHeight,
              child: upcomingOuting == null
                  ? KeyedSubtree(
                      key: const ValueKey('crew-card-no-upcoming-outing'),
                      child: _NoUpcomingOutingFooter(compact: compact),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('crew-card-upcoming-outing'),
                      child: _UpcomingOutingFooter(
                        outing: upcomingOuting,
                        now: outingState.observedAt,
                        compact: compact,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
