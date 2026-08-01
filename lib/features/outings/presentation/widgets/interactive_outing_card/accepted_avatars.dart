part of '../interactive_outing_card.dart';

class _AcceptedAvatars extends StatelessWidget {
  const _AcceptedAvatars({required this.participants});
  final List<OutingParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final accepted = participants
        .where(
          (participant) =>
              participant.attendanceStatus == AttendanceStatus.accepted,
        )
        .take(3)
        .toList();
    if (accepted.isEmpty) {
      return const Text(
        'No one’s locked in yet ✨',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: ChillGoColors.inkMuted),
      );
    }
    return SizedBox(
      height: 38,
      child: Stack(
        children: [
          for (var index = 0; index < accepted.length; index++)
            Positioned(
              left: index * 25,
              child: CircleAvatar(
                radius: 19,
                backgroundColor: ChillGoColors.coralSoft,
                backgroundImage: accepted[index].avatarUrl?.isNotEmpty == true
                    ? NetworkImage(accepted[index].avatarUrl!)
                    : null,
                child: accepted[index].avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        accepted[index].displayName.characters.first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: ChillGoColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

OutingParticipant? _creatorParticipant(
  Outing outing,
  List<OutingParticipant> participants,
) {
  for (final participant in participants) {
    if (participant.isCreatorParticipant ||
        participant.userId == outing.createdByUserId) {
      return participant;
    }
  }
  return null;
}

String _monthLabel(int month) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][month - 1];

String _statusLabel(OutingStatus status) => switch (status) {
  OutingStatus.draft => 'DRAFT',
  OutingStatus.planning => 'PLANNING',
  OutingStatus.confirmed => 'UPCOMING',
  OutingStatus.meeting => 'LIVE',
  OutingStatus.completed => 'COMPLETED',
  OutingStatus.archived => 'ARCHIVED',
  OutingStatus.cancelled => 'CANCELLED',
};

String _timeLabel(DateTime localDate) {
  final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
  final period = localDate.hour < 12 ? 'AM' : 'PM';
  return '$hour:${localDate.minute.toString().padLeft(2, '0')} $period';
}

String _scheduleLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day} • ${_timeLabel(local)}';
}
