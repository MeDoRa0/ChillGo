import 'package:equatable/equatable.dart';

import 'attendee_meetup_state.dart';
import 'meetup_point.dart';

class LiveMeetupSnapshot extends Equatable {
  LiveMeetupSnapshot({
    required this.outingId,
    required this.crewId,
    required this.locationText,
    required Iterable<AttendeeMeetupState> attendees,
    this.meetupPoint,
  }) : attendees = [...attendees]..sort(_compareAttendees);

  final String outingId;
  final String crewId;
  final String locationText;
  final MeetupPoint? meetupPoint;
  final List<AttendeeMeetupState> attendees;

  static int _compareAttendees(
    AttendeeMeetupState left,
    AttendeeMeetupState right,
  ) {
    final byName = left.displayName.trim().toLowerCase().compareTo(
      right.displayName.trim().toLowerCase(),
    );
    return byName != 0 ? byName : left.userId.compareTo(right.userId);
  }

  @override
  List<Object?> get props => [
    outingId,
    crewId,
    locationText,
    meetupPoint,
    attendees,
  ];
}
