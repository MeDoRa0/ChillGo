import 'package:equatable/equatable.dart';

class GeoCoordinate extends Equatable {
  const GeoCoordinate._({required this.latitude, required this.longitude});

  factory GeoCoordinate({required double latitude, required double longitude}) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError('Coordinates must be finite.');
    }
    if (latitude < -90 || latitude > 90) {
      throw RangeError.range(latitude, -90, 90, 'latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw RangeError.range(longitude, -180, 180, 'longitude');
    }
    return GeoCoordinate._(latitude: latitude, longitude: longitude);
  }

  final double latitude;
  final double longitude;

  @override
  List<Object> get props => [latitude, longitude];
}
