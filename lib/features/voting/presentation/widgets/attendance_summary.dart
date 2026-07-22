import 'package:flutter/material.dart';
import '../../../outings/domain/entities/attendance_status.dart';
import '../../../outings/domain/entities/outing_participant.dart';

class AttendanceSummary extends StatelessWidget {
  const AttendanceSummary({
    super.key,
    required this.participants,
    required this.currentUserId,
    required this.canRespond,
    required this.onRespond,
  });
  final List<OutingParticipant> participants;
  final String currentUserId;
  final bool canRespond;
  final ValueChanged<AttendanceStatus> onRespond;
  @override
  Widget build(BuildContext context) {
    int count(AttendanceStatus s) =>
        participants.where((p) => p.attendanceStatus == s).length;
    final me = participants.where((p) => p.userId == currentUserId).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                Text('Invited ${count(AttendanceStatus.invited)}'),
                Text('Accepted ${count(AttendanceStatus.accepted)}'),
                Text('Declined ${count(AttendanceStatus.declined)}'),
              ],
            ),
            if (me != null) ...[
              const SizedBox(height: 12),
              Text('Your response: ${me.attendanceStatus.value}'),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: canRespond
                        ? () => onRespond(AttendanceStatus.accepted)
                        : null,
                    child: const Text('Accept'),
                  ),
                  OutlinedButton(
                    onPressed: canRespond
                        ? () => onRespond(AttendanceStatus.declined)
                        : null,
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ],
            if (!canRespond) const Text('Attendance responses are closed.'),
          ],
        ),
      ),
    );
  }
}
