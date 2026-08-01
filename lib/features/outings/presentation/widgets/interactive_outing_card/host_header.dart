part of '../interactive_outing_card.dart';

class _HostHeader extends StatelessWidget {
  const _HostHeader({
    required this.creator,
    required this.status,
    required this.trailing,
  });

  final OutingParticipant? creator;
  final OutingStatus status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _CreatorAvatar(creator: creator),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          creator == null ? 'Crew outing' : '${creator!.displayName}’s outing',
          key: const Key('outing-host'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ChillGoColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      ?trailing,
      const SizedBox(width: 8),
      _StatusPill(status: status),
    ],
  );
}
