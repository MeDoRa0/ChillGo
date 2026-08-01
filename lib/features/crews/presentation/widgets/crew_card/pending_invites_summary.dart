part of '../crew_card.dart';

class _PendingInvitesSummary extends StatelessWidget {
  final Stream<List<CrewInvitation>> stream;

  const _PendingInvitesSummary({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewInvitation>>(
      stream: stream,
      builder: (context, snapshot) {
        final invitations = snapshot.data ?? const <CrewInvitation>[];
        if (invitations.isEmpty) return const SizedBox.shrink();

        final usernames = invitations
            .map(_invitationLabel)
            .where((label) => label.isNotEmpty)
            .take(3)
            .toList();
        final overflow = invitations.length - usernames.length;
        final suffix = overflow > 0 ? ' +$overflow more' : '';

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: ChillGoColors.inkMuted,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Invited ${usernames.join(', ')}$suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _invitationLabel(CrewInvitation invitation) {
    final username = invitation.invitedUsername.trim();
    if (username.isNotEmpty) return '@$username';
    return invitation.invitedUserId.trim();
  }
}
