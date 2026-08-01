part of '../../screens/crew_details_screen.dart';

class OutingCard extends StatelessWidget {
  final Outing outing;
  final OutingRepository repository;
  final String? currentUserId;

  const OutingCard({
    super.key,
    required this.outing,
    required this.repository,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingDetail?>(
      stream: repository.streamOutingDetail(outing.id),
      builder: (context, snapshot) {
        final participants =
            snapshot.data?.participants ?? const <OutingParticipant>[];
        final hasAccepted =
            currentUserId != null &&
            participants.any((member) => member.userId == currentUserId);
        return InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChillGoColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ChillGoColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        outing.locationText,
                        style: const TextStyle(
                          color: ChillGoColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (outing.createdByUserId == currentUserId)
                      IconButton(
                        tooltip: 'Delete outing',
                        onPressed: () => _confirmDeletion(context),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: ChillGoColors.inkMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _scheduleLabel(outing.scheduledAt),
                  style: const TextStyle(
                    color: ChillGoColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AcceptedAvatars(participants: participants),
                    ),
                    if (currentUserId != null && !hasAccepted)
                      FilledButton(
                        onPressed: () =>
                            repository.acceptOuting(outingId: outing.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: ChillGoColors.coral,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('I’m in'),
                      )
                    else if (hasAccepted)
                      const Text(
                        'You’re in ✨',
                        style: TextStyle(color: ChillGoColors.inkMuted),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletion(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete outing?'),
        content: const Text(
          'This permanently removes the outing for every crew member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await repository.deleteOuting(outingId: outing.id);
    }
  }

  String _scheduleLabel(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.month}/${local.day} • $hour:${local.minute.toString().padLeft(2, '0')} $period';
  }
}
