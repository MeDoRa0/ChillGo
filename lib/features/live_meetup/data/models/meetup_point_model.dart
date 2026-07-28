import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/geo_coordinate.dart';
import '../../domain/entities/meetup_point.dart';

class MeetupPointModel {
  const MeetupPointModel._();

  static MeetupPoint fromMap(Map<String, dynamic> map) {
    final point = map['point'];
    final acceptedAt = readFirestoreTimestamp(map['acceptedAt']);
    if (point is! GeoPoint || acceptedAt == null) {
      throw const FormatException('Invalid meetup point.');
    }
    String requiredString(String key) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
      throw FormatException('Invalid meetup point $key.');
    }

    return MeetupPoint(
      outingId: requiredString('outingId'),
      crewId: requiredString('crewId'),
      coordinate: GeoCoordinate(
        latitude: point.latitude,
        longitude: point.longitude,
      ),
      locationTextSnapshot: requiredString('locationTextSnapshot'),
      setByUserId: requiredString('setByUserId'),
      acceptedAt: acceptedAt,
      acceptedCommandId: requiredString('acceptedCommandId'),
    );
  }
}
