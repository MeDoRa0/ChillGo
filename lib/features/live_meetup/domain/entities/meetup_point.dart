import 'package:equatable/equatable.dart';

import 'geo_coordinate.dart';

class MeetupPoint extends Equatable {
  MeetupPoint({
    required this.outingId,
    required this.crewId,
    required this.coordinate,
    required this.locationTextSnapshot,
    required this.setByUserId,
    required DateTime acceptedAt,
    required this.acceptedCommandId,
  }) : acceptedAt = acceptedAt.toUtc() {
    if ([
      outingId,
      crewId,
      locationTextSnapshot,
      setByUserId,
      acceptedCommandId,
    ].any((value) => value.isEmpty)) {
      throw ArgumentError('Meetup point fields must not be empty.');
    }
  }

  final String outingId;
  final String crewId;
  final GeoCoordinate coordinate;
  final String locationTextSnapshot;
  final String setByUserId;
  final DateTime acceptedAt;
  final String acceptedCommandId;

  @override
  List<Object> get props => [
    outingId,
    crewId,
    coordinate,
    locationTextSnapshot,
    setByUserId,
    acceptedAt,
    acceptedCommandId,
  ];
}
