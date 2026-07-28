import '../entities/live_location.dart';
import 'trusted_clock.dart';

class LiveLocationFreshnessPolicy {
  const LiveLocationFreshnessPolicy(this.clock);
  final TrustedClock clock;

  bool isFresh(LiveLocation location) => location.expiresAt.isAfter(clock.now);

  List<LiveLocation> fresh(Iterable<LiveLocation> locations) =>
      locations.where(isFresh).toList(growable: false);

  DateTime? nextExpiry(Iterable<LiveLocation> locations) {
    DateTime? next;
    for (final location in locations) {
      if (!isFresh(location)) continue;
      if (next == null || location.expiresAt.isBefore(next)) {
        next = location.expiresAt;
      }
    }
    return next;
  }

  Duration? durationUntilNextExpiry(Iterable<LiveLocation> locations) =>
      nextExpiry(locations)?.difference(clock.now);
}
