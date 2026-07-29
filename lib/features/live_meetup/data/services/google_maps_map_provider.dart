import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/geo_coordinate.dart';
import '../../domain/repositories/live_meetup_repository.dart';
import '../../domain/services/map_provider.dart';

class GoogleMapsMapProvider implements MapProvider {
  GoogleMapsMapProvider({required FirebaseFunctions functions})
    : call = _firebaseInvoker(functions);

  GoogleMapsMapProvider.forTesting({required this.call});

  final CallableFunction call;

  static CallableFunction _firebaseInvoker(FirebaseFunctions functions) =>
      (name, payload) async =>
          (await functions.httpsCallable(name).call<Object?>(payload)).data;

  @override
  bool get isConfigured => true;

  @override
  Future<List<PlaceCandidate>> search(
    String query, {
    required String sessionToken,
    GeoCoordinate? bias,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];
    final response = await _invoke('searchMapPlace', {
      'query': trimmedQuery,
      'sessionToken': sessionToken,
      if (bias != null) ...{
        'biasLatitude': bias.latitude,
        'biasLongitude': bias.longitude,
      },
    });
    final source = _object(response);
    final results = source['results'];
    if (results is! List) throw const LiveMeetupServiceFailure();
    return results.map(_placeCandidate).toList(growable: false);
  }

  @override
  Future<PlaceCandidate> resolvePlace(
    PlaceCandidate candidate, {
    required String sessionToken,
  }) async {
    final response = await _invoke('resolveMapPlace', {
      'placeId': candidate.id,
      'sessionToken': sessionToken,
    });
    final source = _object(response);
    final latitude = source['latitude'];
    final longitude = source['longitude'];
    if (latitude is! num || longitude is! num) {
      throw const LiveMeetupServiceFailure();
    }
    return candidate.withCoordinate(
      GeoCoordinate(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      ),
    );
  }

  @override
  Future<String?> reverseLabel(GeoCoordinate coordinate) async {
    final response = await _invoke('reverseGeocode', {
      'latitude': coordinate.latitude,
      'longitude': coordinate.longitude,
    });
    final label = _object(response)['label'];
    if (label == null) return null;
    if (label is! String || label.trim().isEmpty) {
      throw const LiveMeetupServiceFailure();
    }
    return label;
  }

  Future<Object?> _invoke(String name, Map<String, Object?> payload) async {
    try {
      return await call(name, payload);
    } on FirebaseFunctionsException {
      throw const LiveMeetupServiceFailure();
    }
  }

  PlaceCandidate _placeCandidate(Object? rawResult) {
    final result = _object(rawResult);
    return PlaceCandidate(
      id: _requiredString(result, 'id'),
      label: _requiredString(result, 'label'),
    );
  }

  Map<String, Object?> _object(Object? value) {
    if (value is! Map) throw const LiveMeetupServiceFailure();
    return Map<String, Object?>.from(value);
  }

  String _requiredString(Map<String, Object?> source, String field) {
    final fieldValue = source[field];
    if (fieldValue is! String || fieldValue.trim().isEmpty) {
      throw const LiveMeetupServiceFailure();
    }
    return fieldValue;
  }
}

typedef CallableFunction =
    Future<Object?> Function(String name, Map<String, Object?> payload);
