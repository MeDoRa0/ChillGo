part of '../../screens/crew_details_screen.dart';

class _CrewDetailsContent extends StatelessWidget {
  const _CrewDetailsContent({
    required this.crew,
    required this.repository,
    required this.canInviteMembers,
  });

  final Crew crew;
  final CrewRepository repository;
  final bool canInviteMembers;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewMembership>>(
      stream: repository.streamMembers(crew.id),
      initialData: const <CrewMembership>[],
      builder: _crewContent,
    );
  }

  Widget _crewContent(
    BuildContext context,
    AsyncSnapshot<List<CrewMembership>> snapshot,
  ) {
    final members = snapshot.data ?? const <CrewMembership>[];
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 760
        ? 24.0
        : 16.0;
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      children: [
        _planPanel(members.length),
        const SizedBox(height: 24),
        _membersPanel(members, snapshot.error),
      ],
    );
  }

  Widget _planPanel(int memberCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CrewHeader(crew: crew, memberCount: memberCount),
        const SizedBox(height: 16),
        _CreateOutingButton(crewId: crew.id),
        const SizedBox(height: 20),
        _CrewOutings(crewId: crew.id),
      ],
    );
  }

  Widget _membersPanel(List<CrewMembership> members, Object? streamError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Crew members',
          style: TextStyle(
            color: ChillGoColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (streamError != null)
          _InlineMessage(message: streamError.toString())
        else
          _MembersList(
            members: members,
            repository: repository,
            crewId: crew.id,
            canInviteMembers: canInviteMembers,
          ),
      ],
    );
  }
}
