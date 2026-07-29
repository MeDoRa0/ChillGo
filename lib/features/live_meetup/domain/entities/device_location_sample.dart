import 'package:equatable/equatable.dart';

import 'geo_coordinate.dart';

enum DeviceLocationPrecision { precise, reduced, unknown }

class DeviceLocationSample extends Equatable {
  const DeviceLocationSample._({
    required this.coordinate,
    required this.accuracyMeters,
    required this.acquiredAtMonotonic,
    required this.precision,
  });

  factory DeviceLocationSample({
    required GeoCoordinate coordinate,
    required double accuracyMeters,
    required Duration acquiredAtMonotonic,
    DeviceLocationPrecision precision = DeviceLocationPrecision.unknown,
  }) {
    if (!accuracyMeters.isFinite) {
      throw ArgumentError('Accuracy must be finite.');
    }
    if (accuracyMeters < 0 || accuracyMeters > 5000) {
      throw RangeError.range(accuracyMeters, 0, 5000, 'accuracyMeters');
    }
    if (acquiredAtMonotonic.isNegative) {
      throw ArgumentError.value(
        acquiredAtMonotonic,
        'acquiredAtMonotonic',
        'Monotonic time cannot be negative.',
      );
    }
    return DeviceLocationSample._(
      coordinate: coordinate,
      accuracyMeters: accuracyMeters,
      acquiredAtMonotonic: acquiredAtMonotonic,
      precision: precision,
    );
  }

  final GeoCoordinate coordinate;
  final double accuracyMeters;
  final Duration acquiredAtMonotonic;
  final DeviceLocationPrecision precision;

  Duration ageAt(Duration monotonicNow) => monotonicNow - acquiredAtMonotonic;

  bool isUsableAt(Duration monotonicNow) {
    final age = ageAt(monotonicNow);
    return !age.isNegative && age <= const Duration(seconds: 30);
  }

  @override
  List<Object> get props => [
    coordinate,
    accuracyMeters,
    acquiredAtMonotonic,
    precision,
  ];
}
