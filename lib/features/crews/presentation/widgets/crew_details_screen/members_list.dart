part of '../../screens/crew_details_screen.dart';

class _MembersList extends StatelessWidget {
  final List<CrewMembership> members;
  final CrewRepository repository;
  final String crewId;
  final bool canInviteMembers;

  const _MembersList({
    required this.members,
    required this.repository,
    required this.crewId,
    required this.canInviteMembers,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty && !canInviteMembers) {
      return const _InlineMessage(message: 'No members yet.');
    }

    return _MemberAvatarStrip(
      members: _ownerFirstMembers,
      onInvite: canInviteMembers ? () => _openInviteDialog(context) : null,
    );
  }

  List<CrewMembership> get _ownerFirstMembers => [
    ...members,
  ]..sort((a, b) => a.role == b.role ? 0 : (a.role == CrewRole.owner ? -1 : 1));

  void _openInviteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _InviteMemberDialog(crewId: crewId, repository: repository),
    );
  }
}
