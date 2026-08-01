part of '../interactive_outing_card.dart';

class _LiveMeetupButton extends StatelessWidget {
  const _LiveMeetupButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: const BoxDecoration(
      color: ChillGoColors.coral,
      shape: BoxShape.circle,
    ),
    child: IconButton(
      key: const Key('live-meetup-entry'),
      tooltip: 'Live Meetup',
      onPressed: onPressed,
      icon: const Icon(Icons.near_me_rounded),
      color: ChillGoColors.surface,
      iconSize: 21,
    ),
  );
}
