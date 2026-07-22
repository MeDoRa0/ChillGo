import 'package:chillgo/features/chat/data/models/chat_command_model.dart';
import 'package:chillgo/features/chat/data/models/chat_message_model.dart';
import 'package:chillgo/features/chat/data/models/chat_read_state_model.dart';
import 'package:chillgo/features/chat/domain/entities/chat_command.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 22);

  test('text validation trims Unicode whitespace and counts scalar values', () {
    expect(ChatCommandModel.validateText('\u2003hello\u2003'), 'hello');
    expect(ChatCommandModel.validateText('😀'), '😀');
    expect(
      () => ChatCommandModel.validateText(List.filled(2001, '😀').join()),
      throwsA(isA<ChatValidationFailure>()),
    );
  });

  test('message maps timestamps and author snapshots', () {
    final model = ChatMessageModel.fromMap({
      'outingId': 'outing',
      'crewId': 'crew',
      'clientMessageId': 'client',
      'authorUserId': 'user',
      'authorUsername': 'name',
      'authorDisplayName': 'Name',
      'text': 'hello',
      'acceptedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    }, 'message');
    expect(model.acceptedAt, now);
    expect(model.authorDisplayName, 'Name');
  });

  test('terminal command maps only sanitized result and stable failure', () {
    final success = ChatCommandModel.fromMap({
      'status': 'succeeded',
      'result': {
        'messageId': 'message',
        'acceptedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      },
    }, 'command');
    expect(success.messageId, 'message');
    final failure = ChatCommandModel.fromMap({
      'status': 'failed',
      'errorCode': 'permission_denied',
    }, 'failed');
    expect(failure.failure, isA<ChatAccessDenied>());
  });

  test('read-state cursor maps monotonically ordered values', () {
    final model = ChatReadStateModel.fromMap({
      'outingId': 'outing',
      'crewId': 'crew',
      'userId': 'user',
      'readThroughAcceptedAt': Timestamp.fromDate(now),
      'readThroughMessageId': 'message',
      'cursorExpiresAt': Timestamp.fromDate(now.add(const Duration(hours: 1))),
      'updatedAt': Timestamp.fromDate(now),
    });
    expect(model.cursor.messageId, 'message');
  });
}
