import 'package:chillgo/features/live_meetup/domain/entities/attendee_meetup_state.dart';
import 'package:chillgo/features/live_meetup/domain/entities/device_location_sample.dart';
import 'package:chillgo/features/live_meetup/domain/entities/geo_coordinate.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_location.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_location_session.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_meetup_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coordinates reject non-finite and out-of-range values', () {
    expect(() => GeoCoordinate(latitude: 91, longitude: 0), throwsRangeError);
    expect(
      () => GeoCoordinate(latitude: double.nan, longitude: 0),
      throwsArgumentError,
    );
    expect(
      GeoCoordinate(latitude: -90, longitude: 180),
      GeoCoordinate(latitude: -90, longitude: 180),
    );
  });

  test('device samples enforce accuracy and monotonic age bounds', () {
    final coordinate = GeoCoordinate(latitude: 30, longitude: 31);
    expect(
      () => DeviceLocationSample(
        coordinate: coordinate,
        accuracyMeters: 5001,
        acquiredAtMonotonic: Duration.zero,
      ),
      throwsRangeError,
    );
    final sample = DeviceLocationSample(
      coordinate: coordinate,
      accuracyMeters: 12,
      acquiredAtMonotonic: const Duration(seconds: 2),
    );
    expect(sample.isUsableAt(const Duration(seconds: 32)), isTrue);
    expect(
      sample.isUsableAt(const Duration(seconds: 32, milliseconds: 1)),
      isFalse,
    );
  });

  test('sessions validate non-empty process-only credentials', () {
    expect(
      () => LiveLocationSession(
        outingId: '',
        sessionId: 'session',
        sessionToken: 'secret',
        deviceSessionId: 'device',
      ),
      throwsArgumentError,
    );
  });

  test('snapshots sort attendees by normalized display name then user id', () {
    final attendees = [
      const AttendeeMeetupState(
        userId: 'b',
        displayName: ' zoe ',
        username: 'zoe',
      ),
      const AttendeeMeetupState(
        userId: 'c',
        displayName: 'Alice',
        username: 'alice-c',
      ),
      const AttendeeMeetupState(
        userId: 'a',
        displayName: 'alice',
        username: 'alice-a',
      ),
    ];
    final snapshot = LiveMeetupSnapshot(
      outingId: 'outing',
      crewId: 'crew',
      locationText: 'Cafe',
      attendees: attendees,
    );
    expect(snapshot.attendees.map((item) => item.userId), ['a', 'c', 'b']);
  });

  test('location requires expiry exactly two minutes after acceptance', () {
    final accepted = DateTime.utc(2026, 7, 27);
    expect(
      () => LiveLocation(
        outingId: 'outing',
        crewId: 'crew',
        userId: 'user',
        coordinate: GeoCoordinate(latitude: 30, longitude: 31),
        accuracyMeters: 10,
        acceptedAt: accepted,
        expiresAt: accepted.add(const Duration(minutes: 3)),
        acceptedCommandId: 'command',
      ),
      throwsArgumentError,
    );
  });
}
