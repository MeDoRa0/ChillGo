import 'package:equatable/equatable.dart';

import '../entities/geo_coordinate.dart';

class PlaceCandidate extends Equatable {
  const PlaceCandidate({
    required this.id,
    required this.label,
    required this.coordinate,
  });
  final String id;
  final String label;
  final GeoCoordinate coordinate;
  @override
  List<Object> get props => [id, label, coordinate];
}

abstract interface class MapProvider {
  bool get isConfigured;
  Future<List<PlaceCandidate>> search(String query);
  Future<String?> reverseLabel(GeoCoordinate coordinate);
}
