import 'package:equatable/equatable.dart';

import 'geo_coordinate.dart';

class LiveLocation extends Equatable {
  LiveLocation({
    required this.outingId,
    required this.crewId,
    required this.userId,
    required this.coordinate,
    required this.accuracyMeters,
    required DateTime acceptedAt,
    required DateTime expiresAt,
    required this.acceptedCommandId,
  }) : acceptedAt = acceptedAt.toUtc(),
       expiresAt = expiresAt.toUtc() {
    if (!accuracyMeters.isFinite ||
        accuracyMeters < 0 ||
        accuracyMeters > 5000) {
      throw RangeError.range(accuracyMeters, 0, 5000, 'accuracyMeters');
    }
    if (this.expiresAt != this.acceptedAt.add(const Duration(minutes: 2))) {
      throw ArgumentError(
        'expiresAt must be exactly two minutes after acceptedAt.',
      );
    }
    if ([
      outingId,
      crewId,
      userId,
      acceptedCommandId,
    ].any((value) => value.isEmpty)) {
      throw ArgumentError('Live location identity fields must not be empty.');
    }
  }

  final String outingId;
  final String crewId;
  final String userId;
  final GeoCoordinate coordinate;
  final double accuracyMeters;
  final DateTime acceptedAt;
  final DateTime expiresAt;
  final String acceptedCommandId;

  @override
  List<Object> get props => [
    outingId,
    crewId,
    userId,
    coordinate,
    accuracyMeters,
    acceptedAt,
    expiresAt,
    acceptedCommandId,
  ];
}
