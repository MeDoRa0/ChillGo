import 'package:chillgo/features/live_meetup/data/models/live_meetup_status_model.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/live_meetup/data/models/live_location_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chillgo/features/live_meetup/data/models/meetup_point_model.dart';

void main() {
  test('status model accepts exact values and trusted tuple', () {
    final acceptedAt = DateTime.utc(2026, 7, 27);
    final model = LiveMeetupStatusModel.fromMap({
      'outingId': 'outing',
      'crewId': 'crew',
      'userId': 'user',
      'value': 'getting_ready',
      'acceptedAt': acceptedAt,
      'acceptedCommandId': 'command',
    });
    expect(model.value, LiveMeetupStatus.gettingReady);
    expect(model.acceptedAt, acceptedAt);
  });

  test('status model rejects malformed values and missing timestamps', () {
    expect(
      () => LiveMeetupStatusModel.fromMap({
        'outingId': 'outing',
        'crewId': 'crew',
        'userId': 'user',
        'value': 'nearby',
        'acceptedCommandId': 'command',
      }),
      throwsFormatException,
    );
  });

  test('location model enforces exact canonical expiry and finite bounds', () {
    final acceptedAt = DateTime.utc(2026, 7, 27);
    final location = LiveLocationModel.fromMap({
      'outingId': 'outing',
      'crewId': 'crew',
      'userId': 'user',
      'point': const GeoPoint(30, 31),
      'accuracyMeters': 8,
      'acceptedAt': acceptedAt,
      'expiresAt': acceptedAt.add(const Duration(minutes: 2)),
      'acceptedCommandId': 'command',
    });
    expect(location.acceptedAt, acceptedAt);
    expect(
      location.expiresAt.difference(location.acceptedAt),
      const Duration(minutes: 2),
    );
    expect(
      () => LiveLocationModel.fromMap({
        'outingId': 'outing',
        'crewId': 'crew',
        'userId': 'user',
        'point': const GeoPoint(30, 31),
        'accuracyMeters': 5001,
        'acceptedAt': acceptedAt,
        'expiresAt': acceptedAt.add(const Duration(minutes: 2)),
        'acceptedCommandId': 'command',
      }),
      throwsRangeError,
    );
  });

  test('meetup point preserves finalized location text and accepted tuple', () {
    final acceptedAt = DateTime.utc(2026, 7, 27);
    final point = MeetupPointModel.fromMap({
      'outingId': 'outing',
      'crewId': 'crew',
      'point': const GeoPoint(30, 31),
      'locationTextSnapshot': 'Cafe',
      'setByUserId': 'owner',
      'acceptedAt': acceptedAt,
      'acceptedCommandId': 'command',
    });
    expect(point.locationTextSnapshot, 'Cafe');
    expect(point.acceptedAt, acceptedAt);
  });
}
