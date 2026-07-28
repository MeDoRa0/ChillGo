import 'package:equatable/equatable.dart';

import 'live_location.dart';
import 'live_meetup_status.dart';

class AttendeeMeetupState extends Equatable {
  const AttendeeMeetupState({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.status,
    this.statusAcceptedAt,
    this.location,
  });

  final String userId;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final LiveMeetupStatus? status;
  final DateTime? statusAcceptedAt;
  final LiveLocation? location;

  @override
  List<Object?> get props => [
    userId,
    displayName,
    username,
    avatarUrl,
    status,
    statusAcceptedAt,
    location,
  ];
}
