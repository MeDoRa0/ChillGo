import 'package:chillgo/features/live_meetup/data/services/firestore_live_meetup_clock.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

void main() {
  test('uses midpoint of monotonic round trip for trusted offset', () async {
    final times = <DateTime>[
      DateTime.utc(2026, 7, 27, 10),
      DateTime.utc(2026, 7, 27, 10, 0, 2),
      DateTime.utc(2026, 7, 27, 10, 0, 2),
    ];
    final clock = FirestoreLiveMeetupClock(
      firestore: _Firestore(),
      currentUid: () => 'user',
      deviceNow: () => times.removeAt(0),
      serverTimeProbe: (_) async => DateTime.utc(2026, 7, 27, 10, 0, 11),
    );
    await clock.establish();
    expect(clock.now, DateTime.utc(2026, 7, 27, 10, 0, 12));
  });

  test('requires an authenticated probe owner', () async {
    final clock = FirestoreLiveMeetupClock(
      firestore: _Firestore(),
      currentUid: () => '',
    );
    expect(clock.establish, throwsA(isA<LiveMeetupAuthenticationFailure>()));
  });
}
