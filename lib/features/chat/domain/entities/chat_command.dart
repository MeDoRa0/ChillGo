import 'package:equatable/equatable.dart';

enum ChatCommandStatus { pending, processing, succeeded, failed }

enum ChatSendAttemptStatus { sending, sent, failed }

sealed class ChatFailure extends Equatable implements Exception {
  const ChatFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ChatAuthenticationFailure extends ChatFailure {
  const ChatAuthenticationFailure() : super('Sign in before trying again.');
}

class ChatAccessDenied extends ChatFailure {
  const ChatAccessDenied() : super('This chat is unavailable.');
}

class ChatReadOnly extends ChatFailure {
  const ChatReadOnly() : super('This outing chat is read-only.');
}

class ChatValidationFailure extends ChatFailure {
  const ChatValidationFailure([super.message = 'Enter 1–2,000 characters.']);
}

class ChatNetworkFailure extends ChatFailure {
  const ChatNetworkFailure()
    : super('Connection failed. Nothing was queued; retry manually.');
}

class ChatRateLimited extends ChatFailure {
  const ChatRateLimited(this.retryAt) : super('Too many messages.');
  final DateTime retryAt;
  @override
  List<Object?> get props => [...super.props, retryAt.toUtc()];
}

class ChatIdentityConflict extends ChatFailure {
  const ChatIdentityConflict()
    : super('This message could not be retried. Send it as a new message.');
}

class ChatNotFound extends ChatFailure {
  const ChatNotFound() : super('This message is no longer available.');
}

class ChatServiceFailure extends ChatFailure {
  const ChatServiceFailure() : super('Chat is temporarily unavailable.');
}

class ChatCommand extends Equatable {
  const ChatCommand({
    required this.id,
    required this.status,
    this.messageId,
    this.acceptedAt,
    this.expiresAt,
    this.failure,
  });
  final String id;
  final ChatCommandStatus status;
  final String? messageId;
  final DateTime? acceptedAt;
  final DateTime? expiresAt;
  final ChatFailure? failure;
  bool get isTerminal =>
      status == ChatCommandStatus.succeeded ||
      status == ChatCommandStatus.failed;
  @override
  List<Object?> get props => [
    id,
    status,
    messageId,
    acceptedAt,
    expiresAt,
    failure,
  ];
}

class ChatSendAttempt extends Equatable {
  const ChatSendAttempt({
    required this.clientMessageId,
    required this.text,
    required this.status,
    this.commandId,
    this.failure,
  });
  final String clientMessageId;
  final String text;
  final ChatSendAttemptStatus status;
  final String? commandId;
  final ChatFailure? failure;
  @override
  List<Object?> get props => [
    clientMessageId,
    text,
    status,
    commandId,
    failure,
  ];
}
