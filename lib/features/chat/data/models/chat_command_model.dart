import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/chat_command.dart';

class ChatCommandModel {
  const ChatCommandModel._();

  static String trimUnicodeWhitespace(String text) =>
      text.replaceAll(RegExp(r'^\s+|\s+$', unicode: true), '');

  static String validateText(String text) {
    final trimmed = trimUnicodeWhitespace(text);
    final length = trimmed.runes.length;
    if (length < 1 || length > 2000) {
      throw const ChatValidationFailure();
    }
    return trimmed;
  }

  static Map<String, Object?> pendingMap({
    required String outingId,
    required String crewId,
    required String userId,
    required String clientMessageId,
    required String text,
    required Object createdAt,
  }) => {
    'type': 'send_message',
    'outingId': outingId,
    'crewId': crewId,
    'requestedByUserId': userId,
    'clientMessageId': clientMessageId,
    'payload': {'text': validateText(text)},
    'status': 'pending',
    'createdAt': createdAt,
  };

  static ChatCommand fromMap(Map<String, dynamic> map, String id) {
    final status = switch (map['status']) {
      'pending' => ChatCommandStatus.pending,
      'processing' => ChatCommandStatus.processing,
      'succeeded' => ChatCommandStatus.succeeded,
      'failed' => ChatCommandStatus.failed,
      _ => throw const FormatException('Invalid chat command status'),
    };
    final result = map['result'] is Map
        ? Map<String, dynamic>.from(map['result'] as Map)
        : const <String, dynamic>{};
    return ChatCommand(
      id: id,
      status: status,
      messageId: result['messageId'] as String?,
      acceptedAt: readFirestoreTimestamp(result['acceptedAt']),
      expiresAt: readFirestoreTimestamp(result['expiresAt']),
      failure: status == ChatCommandStatus.failed ? failureFromMap(map) : null,
    );
  }

  static ChatFailure failureFromMap(Map<String, dynamic> map) {
    return switch (map['errorCode']) {
      'unauthenticated' => const ChatAuthenticationFailure(),
      'permission_denied' || 'outing_deleting' => const ChatAccessDenied(),
      'invalid_outing_state' => const ChatReadOnly(),
      'invalid_command' || 'invalid_message' => const ChatValidationFailure(),
      'rate_limited' => ChatRateLimited(
        readFirestoreTimestamp(map['retryAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
      'message_identity_conflict' => const ChatIdentityConflict(),
      'not_found' => const ChatNotFound(),
      _ => const ChatServiceFailure(),
    };
  }
}
