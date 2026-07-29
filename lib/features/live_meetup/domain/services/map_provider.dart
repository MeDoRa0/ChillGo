import 'package:equatable/equatable.dart';

import '../entities/geo_coordinate.dart';

class PlaceCandidate extends Equatable {
  const PlaceCandidate({
    required this.id,
    required this.label,
    this.coordinate,
  });
  final String id;
  final String label;
  final GeoCoordinate? coordinate;

  PlaceCandidate withCoordinate(GeoCoordinate value) =>
      PlaceCandidate(id: id, label: label, coordinate: value);

  @override
  List<Object?> get props => [id, label, coordinate];
}

abstract interface class MapProvider {
  bool get isConfigured;
  Future<List<PlaceCandidate>> search(
    String query, {
    required String sessionToken,
    GeoCoordinate? bias,
  });
  Future<PlaceCandidate> resolvePlace(
    PlaceCandidate candidate, {
    required String sessionToken,
  });
  Future<String?> reverseLabel(GeoCoordinate coordinate);
}
