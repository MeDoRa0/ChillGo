import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/geo_coordinate.dart';
import '../../domain/entities/live_location.dart';

class LiveLocationModel {
  const LiveLocationModel._();

  static LiveLocation fromMap(Map<String, dynamic> map) {
    final point = map['point'];
    final acceptedAt = readFirestoreTimestamp(map['acceptedAt']);
    final expiresAt = readFirestoreTimestamp(map['expiresAt']);
    if (point is! GeoPoint || acceptedAt == null || expiresAt == null) {
      throw const FormatException('Invalid live location.');
    }
    String requiredString(String key) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
      throw FormatException('Invalid live location $key.');
    }

    final accuracy = map['accuracyMeters'];
    if (accuracy is! num) {
      throw const FormatException('Invalid location accuracy.');
    }
    return LiveLocation(
      outingId: requiredString('outingId'),
      crewId: requiredString('crewId'),
      userId: requiredString('userId'),
      coordinate: GeoCoordinate(
        latitude: point.latitude,
        longitude: point.longitude,
      ),
      accuracyMeters: accuracy.toDouble(),
      acceptedAt: acceptedAt,
      expiresAt: expiresAt,
      acceptedCommandId: requiredString('acceptedCommandId'),
    );
  }
}
