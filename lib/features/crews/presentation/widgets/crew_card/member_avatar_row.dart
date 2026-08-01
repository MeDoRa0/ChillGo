part of '../crew_card.dart';

class _MemberAvatarRow extends StatelessWidget {
  final List<CrewMembership> members;
  final double avatarDiameter;

  static const int _maxVisible = 5;

  const _MemberAvatarRow({required this.members, required this.avatarDiameter});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(_maxVisible).toList();
    final overflow = members.length - _maxVisible;
    final avatarCount = visible.length + (overflow > 0 ? 1 : 0);
    final avatarOffset = avatarDiameter * 0.72;
    final width = avatarCount <= 1
        ? avatarDiameter
        : avatarDiameter + ((avatarCount - 1) * avatarOffset);

    return SizedBox(
      width: width,
      height: avatarDiameter,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(left: i * avatarOffset, child: _buildAvatar(visible[i])),
          if (overflow > 0)
            Positioned(
              left: visible.length * avatarOffset,
              child: _buildOverflowCircle(overflow),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(CrewMembership member) {
    final hasPhoto = member.avatarUrl != null && member.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: avatarDiameter / 2,
      backgroundColor: ChillGoColors.coral,
      backgroundImage: hasPhoto ? NetworkImage(member.avatarUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildOverflowCircle(int count) {
    return CircleAvatar(
      radius: avatarDiameter / 2,
      backgroundColor: ChillGoColors.plum,
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
