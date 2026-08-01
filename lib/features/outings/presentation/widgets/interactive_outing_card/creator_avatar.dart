part of '../interactive_outing_card.dart';

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.creator});

  final OutingParticipant? creator;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 17,
    backgroundColor: ChillGoColors.coralSoft,
    backgroundImage: creator?.avatarUrl?.isNotEmpty == true
        ? NetworkImage(creator!.avatarUrl!)
        : null,
    child: creator == null
        ? const Icon(Icons.group_outlined, size: 18, color: ChillGoColors.ink)
        : creator!.avatarUrl?.isNotEmpty == true
        ? null
        : Text(
            creator!.displayName.characters.first.toUpperCase(),
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
  );
}
