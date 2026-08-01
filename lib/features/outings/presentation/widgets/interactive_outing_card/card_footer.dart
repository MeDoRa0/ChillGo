part of '../interactive_outing_card.dart';

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.participants,
    required this.actionButtonSpace,
  });

  final List<OutingParticipant> participants;
  final Widget? actionButtonSpace;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Expanded(child: _AcceptedAvatars(participants: participants)),
        ?actionButtonSpace,
      ],
    ),
  );
}
