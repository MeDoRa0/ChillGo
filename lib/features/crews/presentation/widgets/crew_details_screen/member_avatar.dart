part of '../../screens/crew_details_screen.dart';

class _MemberAvatar extends StatelessWidget {
  final CrewMembership member;

  static const _itemWidth = 72.0;
  static const _avatarRadius = 30.0;

  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final label = member.displayName.trim().isNotEmpty
        ? member.displayName.trim()
        : member.username.trim().isNotEmpty
        ? '@${member.username.trim()}'
        : 'Member';
    final hasPhoto = member.avatarUrl?.isNotEmpty == true;

    return SizedBox(
      width: _itemWidth,
      child: Column(
        children: [
          Semantics(
            label: '$label avatar',
            child: CircleAvatar(
              key: Key('crew-member-avatar-${member.userId}'),
              radius: _avatarRadius,
              backgroundColor: ChillGoColors.coralSoft,
              backgroundImage: hasPhoto
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: hasPhoto
                  ? null
                  : Text(
                      label[0].toUpperCase(),
                      style: const TextStyle(
                        color: ChillGoColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ChillGoColors.ink, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
