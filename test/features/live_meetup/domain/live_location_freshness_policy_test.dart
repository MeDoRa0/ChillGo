import 'package:chillgo/features/live_meetup/domain/entities/geo_coordinate.dart';
import 'package:chillgo/features/live_meetup/domain/entities/live_location.dart';
import 'package:chillgo/features/live_meetup/domain/services/live_location_freshness_policy.dart';
import 'package:chillgo/features/live_meetup/domain/services/trusted_clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _Clock implements TrustedClock {
  _Clock(this.value);
  DateTime value;
  @override
  bool get isEstablished => true;
  @override
  DateTime get now => value;
  @override
  Future<void> establish() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  test('location is excluded at the exact trusted-time boundary', () {
    final accepted = DateTime.utc(2026, 7, 27);
    final location = LiveLocation(
      outingId: 'outing',
      crewId: 'crew',
      userId: 'user',
      coordinate: GeoCoordinate(latitude: 30, longitude: 31),
      accuracyMeters: 10,
      acceptedAt: accepted,
      expiresAt: accepted.add(const Duration(minutes: 2)),
      acceptedCommandId: 'command',
    );
    final clock = _Clock(
      location.expiresAt.subtract(const Duration(microseconds: 1)),
    );
    final policy = LiveLocationFreshnessPolicy(clock);
    expect(policy.isFresh(location), isTrue);
    expect(
      policy.durationUntilNextExpiry([location]),
      const Duration(microseconds: 1),
    );
    clock.value = location.expiresAt;
    expect(policy.isFresh(location), isFalse);
    expect(policy.fresh([location]), isEmpty);
  });
}
