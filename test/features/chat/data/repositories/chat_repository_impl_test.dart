import 'package:chillgo/features/chat/data/datasources/firestore_chat_datasource.dart';
import 'package:chillgo/features/chat/data/models/chat_message_model.dart';
import 'package:chillgo/features/chat/data/models/chat_read_state_model.dart';
import 'package:chillgo/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:chillgo/features/chat/domain/entities/chat_message_cursor.dart';
import 'package:chillgo/features/chat/domain/services/chat_clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../chat_test_helpers.dart';

class MockChatDatasource extends Mock implements FirestoreChatDatasource {}

class MockChatClock extends Mock implements ChatClock {}

ChatMessageModel model({
  required String id,
  required DateTime acceptedAt,
  DateTime? expiresAt,
}) => ChatMessageModel(
  id: id,
  outingId: 'outing-1',
  crewId: 'crew-1',
  clientMessageId: 'client-$id',
  authorUserId: 'bob',
  authorUsername: 'bob',
  authorDisplayName: 'Bob',
  text: 'Message $id',
  acceptedAt: acceptedAt,
  expiresAt: expiresAt ?? acceptedAt.add(const Duration(hours: 24)),
);

void main() {
  late MockChatDatasource datasource;
  late MockChatClock clock;
  late ChatRepositoryImpl repository;

  setUp(() {
    datasource = MockChatDatasource();
    clock = MockChatClock();
    when(() => clock.isEstablished).thenReturn(true);
    when(() => clock.now).thenReturn(chatTestNow);
    repository = ChatRepositoryImpl(datasource: datasource, clock: clock);
  });

  test(
    'latest snapshot is bounded, chronological, and expiry filtered',
    () async {
      when(() => datasource.watchLatest('outing-1', 50)).thenAnswer(
        (_) => Stream.value([
          model(
            id: 'new',
            acceptedAt: chatTestNow.add(const Duration(minutes: 2)),
          ),
          model(
            id: 'expired',
            acceptedAt: chatTestNow.subtract(const Duration(days: 2)),
            expiresAt: chatTestNow,
          ),
          model(
            id: 'old',
            acceptedAt: chatTestNow.add(const Duration(minutes: 1)),
          ),
        ]),
      );
      final page = await repository.watchLatestMessages('outing-1').first;
      expect(page.messages.map((message) => message.id), ['old', 'new']);
    },
  );

  test(
    'online-only transaction failure maps to manual network failure',
    () async {
      when(
        () => datasource.createSendCommand(
          outingId: 'outing-1',
          clientMessageId: 'client-1',
          text: 'Hello',
        ),
      ).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await expectLater(
        repository.sendMessage('outing-1', 'client-1', ' Hello '),
        throwsA(isA<ChatNetworkFailure>()),
      );
    },
  );

  test(
    'manual retry preserves stable message identity and trimmed text',
    () async {
      when(
        () => datasource.createSendCommand(
          outingId: 'outing-1',
          clientMessageId: 'client-1',
          text: 'Hello',
        ),
      ).thenAnswer((_) async => 'command');
      await repository.sendMessage('outing-1', 'client-1', '  Hello  ');
      await repository.sendMessage('outing-1', 'client-1', 'Hello');
      verify(
        () => datasource.createSendCommand(
          outingId: 'outing-1',
          clientMessageId: 'client-1',
          text: 'Hello',
        ),
      ).called(2);
    },
  );

  test(
    'older page uses two-field cursor, deduplicates IDs, and sorts ties',
    () async {
      final cursor = model(id: 'z', acceptedAt: chatTestNow).cursor;
      when(() => datasource.loadOlder('outing-1', cursor, 50)).thenAnswer(
        (_) async => [
          model(
            id: 'b',
            acceptedAt: chatTestNow.subtract(const Duration(minutes: 1)),
          ),
          model(
            id: 'a',
            acceptedAt: chatTestNow.subtract(const Duration(minutes: 1)),
          ),
          model(
            id: 'a',
            acceptedAt: chatTestNow.subtract(const Duration(minutes: 1)),
          ),
        ],
      );
      final page = await repository.loadOlderMessages(
        'outing-1',
        before: cursor,
      );
      expect(page.messages.map((message) => message.id), ['a', 'b']);
    },
  );

  test('invalid content is rejected before touching Firestore', () async {
    await expectLater(
      repository.sendMessage('outing-1', 'client-1', '   '),
      throwsA(isA<ChatValidationFailure>()),
    );
    verifyNever(
      () => datasource.createSendCommand(
        outingId: any(named: 'outingId'),
        clientMessageId: any(named: 'clientMessageId'),
        text: any(named: 'text'),
      ),
    );
  });

  test(
    'expired private cursor falls back to the trusted retention cutoff',
    () async {
      final expired = ChatReadStateModel(
        outingId: 'outing-1',
        crewId: 'crew-1',
        userId: 'alice',
        cursor: ChatMessageCursor(
          acceptedAt: chatTestNow.subtract(const Duration(hours: 25)),
          messageId: 'expired',
        ),
        cursorExpiresAt: chatTestNow,
        updatedAt: chatTestNow,
      );
      when(
        () => datasource.watchMyReadState('outing-1'),
      ).thenAnswer((_) => Stream.value(expired));
      when(
        () => datasource.unreadCount(outingId: 'outing-1', after: null),
      ).thenAnswer((_) async => 3);
      expect(await repository.getUnreadCount('outing-1'), 3);
    },
  );

  test(
    'valid cursor is used for bounded all-author minus own-author count',
    () async {
      final cursor = ChatMessageCursor(
        acceptedAt: chatTestNow,
        messageId: 'cursor',
      );
      final state = ChatReadStateModel(
        outingId: 'outing-1',
        crewId: 'crew-1',
        userId: 'alice',
        cursor: cursor,
        cursorExpiresAt: chatTestNow.add(const Duration(hours: 1)),
        updatedAt: chatTestNow,
      );
      when(
        () => datasource.watchMyReadState('outing-1'),
      ).thenAnswer((_) => Stream.value(state));
      when(
        () => datasource.unreadCount(outingId: 'outing-1', after: cursor),
      ).thenAnswer((_) async => 2);
      expect(await repository.getUnreadCount('outing-1'), 2);
    },
  );
}
