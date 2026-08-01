part of '../interactive_outing_card.dart';

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.outing,
    required this.participants,
    required this.actionButtonSpace,
    required this.trailing,
    required this.isStartingSoon,
    required this.minutesUntilStart,
  });

  final Outing outing;
  final List<OutingParticipant> participants;
  final Widget? actionButtonSpace;
  final Widget? trailing;
  final bool isStartingSoon;
  final int minutesUntilStart;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HostHeader(
          creator: _creatorParticipant(outing, participants),
          status: outing.status,
          trailing: trailing,
        ),
        if (isStartingSoon) ...[
          const SizedBox(height: 10),
          _StartingSoonBanner(minutesUntilStart: minutesUntilStart),
        ],
        const SizedBox(height: 10),
        _OutingTitle(title: outing.title),
        const SizedBox(height: 10),
        _LocationPanel(location: outing.locationText),
        const SizedBox(height: 12),
        _CardFooter(
          participants: participants,
          actionButtonSpace: actionButtonSpace,
        ),
      ],
    ),
  );
}
