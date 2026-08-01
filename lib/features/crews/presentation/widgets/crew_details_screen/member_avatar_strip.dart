part of '../../screens/crew_details_screen.dart';

class _MemberAvatarStrip extends StatelessWidget {
  final List<CrewMembership> members;
  final VoidCallback? onInvite;

  static const _itemSpacing = 12.0;

  const _MemberAvatarStrip({required this.members, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('crew-members-strip'),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final member in members) ...[
            _MemberAvatar(member: member),
            const SizedBox(width: _itemSpacing),
          ],
          if (onInvite != null) _InviteMemberControl(onPressed: onInvite!),
        ],
      ),
    );
  }
}
