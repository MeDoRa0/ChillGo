import 'package:chillgo/features/chat/data/services/firestore_chat_clock.dart';
import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late MockFirestore firestore;

  setUp(() => firestore = MockFirestore());

  test('uses the round-trip midpoint to establish a server offset', () async {
    final deviceTimes = <DateTime>[
      DateTime.utc(2020, 1, 1, 10),
      DateTime.utc(2020, 1, 1, 10, 0, 2),
      DateTime.utc(2020, 1, 1, 10, 0, 3),
    ];
    var index = 0;
    final clock = FirestoreChatClock(
      firestore: firestore,
      currentUid: () => 'alice',
      deviceNow: () => deviceTimes[index++],
      serverTimeProbe: (_) async => DateTime.utc(2026, 7, 22, 12),
    );

    await clock.establish();

    expect(clock.isEstablished, isTrue);
    expect(clock.now, DateTime.utc(2026, 7, 22, 12, 0, 2));
  });

  test(
    'new offline session fails closed instead of exposing history',
    () async {
      final clock = FirestoreChatClock(
        firestore: firestore,
        currentUid: () => 'alice',
        serverTimeProbe: (_) async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      );
      await expectLater(clock.establish(), throwsA(isA<ChatNetworkFailure>()));
      expect(clock.isEstablished, isFalse);
      expect(() => clock.now, throwsA(isA<ChatNetworkFailure>()));
    },
  );

  test('refresh replaces the prior server offset', () async {
    var server = DateTime.utc(2026, 7, 22, 12);
    final device = DateTime.utc(2020, 1, 1, 10);
    final clock = FirestoreChatClock(
      firestore: firestore,
      currentUid: () => 'alice',
      deviceNow: () => device,
      serverTimeProbe: (_) async => server,
    );
    await clock.establish();
    expect(clock.now, server);
    server = server.add(const Duration(minutes: 5));
    await clock.refresh();
    expect(clock.now, server);
  });
}
