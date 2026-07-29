import 'package:flutter/material.dart';

import '../../domain/entities/attendee_meetup_state.dart';
import '../../domain/entities/live_meetup_status.dart';

class AttendeeStatusSummary extends StatelessWidget {
  const AttendeeStatusSummary({super.key, required this.attendees});
  final List<AttendeeMeetupState> attendees;

  @override
  Widget build(BuildContext context) {
    final groups = <LiveMeetupStatus?, List<AttendeeMeetupState>>{
      LiveMeetupStatus.gettingReady: [],
      LiveMeetupStatus.onMyWay: [],
      LiveMeetupStatus.arrived: [],
      null: [],
    };
    for (final attendee in attendees) {
      groups[attendee.status]!.add(attendee);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries)
          Semantics(
            container: true,
            label:
                '${entry.key?.label ?? 'Not Updated'}: '
                '${entry.value.map((item) => item.displayName).join(', ')}',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key?.label ?? 'Not Updated',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (entry.value.isEmpty)
                      const Text('No attendees')
                    else
                      for (final attendee in entry.value)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            child: Text(
                              attendee.displayName.trim().isEmpty
                                  ? '?'
                                  : attendee.displayName
                                        .trim()[0]
                                        .toUpperCase(),
                            ),
                          ),
                          title: Text(attendee.displayName),
                          subtitle: attendee.statusAcceptedAt == null
                              ? null
                              : Text(
                                  'Updated ${attendee.statusAcceptedAt!.toLocal()}',
                                ),
                        ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
