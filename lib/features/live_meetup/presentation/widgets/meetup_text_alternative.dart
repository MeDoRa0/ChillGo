import 'package:flutter/material.dart';

import '../../domain/entities/live_meetup_snapshot.dart';

class MeetupTextAlternative extends StatelessWidget {
  const MeetupTextAlternative({
    super.key,
    required this.snapshot,
    required this.trustedNow,
  });
  final LiveMeetupSnapshot snapshot;
  final DateTime trustedNow;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('meetup-text-alternative'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('Confirmed location: ${snapshot.locationText}'),
          Text(
            snapshot.meetupPoint == null
                ? 'No exact meetup point has been set.'
                : 'Exact meetup point: '
                      '${snapshot.meetupPoint!.coordinate.latitude.toStringAsFixed(5)}, '
                      '${snapshot.meetupPoint!.coordinate.longitude.toStringAsFixed(5)}',
          ),
          const SizedBox(height: 8),
          if (snapshot.attendees.every((attendee) => attendee.location == null))
            const Text('No attendees are sharing a fresh location.')
          else
            for (final attendee in snapshot.attendees.where(
              (item) => item.location != null,
            ))
              ListTile(
                title: Text(attendee.displayName),
                subtitle: Text(
                  '${attendee.status?.label ?? 'Not Updated'} • '
                  '${attendee.location!.accuracyMeters.round()} m accuracy • '
                  '${trustedNow.difference(attendee.location!.acceptedAt).inSeconds.clamp(0, 9999)} seconds old',
                ),
              ),
        ],
      ),
    ),
  );
}
