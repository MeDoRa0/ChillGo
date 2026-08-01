part of '../crew_card.dart';

class _CrewMembersSummary extends StatelessWidget {
  final Stream<List<CrewMembership>> memberStream;
  final Stream<List<CrewInvitation>>? invitationStream;
  final double avatarDiameter;

  const _CrewMembersSummary({
    required this.memberStream,
    required this.invitationStream,
    required this.avatarDiameter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StreamBuilder<List<CrewMembership>>(
          stream: memberStream,
          initialData: const <CrewMembership>[],
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <CrewMembership>[];
            final acceptedMembers = members
                .where((member) => member.role == CrewRole.member)
                .toList();
            if (acceptedMembers.isEmpty) {
              return const Text(
                'No members yet',
                style: TextStyle(color: ChillGoColors.inkMuted, fontSize: 11),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MemberAvatarRow(
                  members: acceptedMembers,
                  avatarDiameter: avatarDiameter,
                ),
                const SizedBox(height: 2),
                Text(
                  acceptedMembers.length == 1
                      ? '1 member'
                      : '${acceptedMembers.length} members',
                  style: const TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        ),
        if (invitationStream != null)
          _PendingInvitesSummary(stream: invitationStream!),
      ],
    );
  }
}
