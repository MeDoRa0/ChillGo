import 'package:equatable/equatable.dart';

enum NotificationCategory {
  crewInvitation,
  crewMemberJoined,
  outingInvitation,
  votingUpdate,
  agreementConfirmed,
  agreementReopened,
  outingChanged,
  attendeeArrived,
}

enum NotificationTargetType { invitations, crew, agreement, liveMeetup }

class NotificationTarget extends Equatable {
  const NotificationTarget({
    required this.type,
    required this.crewId,
    this.outingId,
  });

  final NotificationTargetType type;
  final String crewId;
  final String? outingId;

  @override
  List<Object?> get props => [type, crewId, outingId];
}

class NotificationDisplay extends Equatable {
  const NotificationDisplay({
    required this.title,
    required this.body,
    this.avatarUrl,
  });

  final String title;
  final String body;
  final String? avatarUrl;

  @override
  List<Object?> get props => [title, body, avatarUrl];
}

class NotificationCursor extends Equatable {
  const NotificationCursor({
    required this.createdAt,
    required this.notificationId,
  });

  final DateTime createdAt;
  final String notificationId;

  @override
  List<Object?> get props => [createdAt, notificationId];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.category,
    required this.target,
    required this.display,
    required this.createdAt,
    required this.expiresAt,
    this.readAt,
  });

  final String id;
  final String recipientUserId;
  final NotificationCategory category;
  final NotificationTarget target;
  final NotificationDisplay display;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
  bool isExpiredAt(DateTime time) => !expiresAt.isAfter(time);

  @override
  List<Object?> get props => [
    id,
    recipientUserId,
    category,
    target,
    display,
    createdAt,
    expiresAt,
    readAt,
  ];
}

enum NotificationUnavailableReason {
  signInRequired,
  unavailable,
  expired,
  serviceUnavailable,
}

class NotificationOpenResult extends Equatable {
  const NotificationOpenResult._({this.target, this.unavailableReason});
  const NotificationOpenResult.opened(NotificationTarget target)
    : this._(target: target);
  const NotificationOpenResult.unavailable(NotificationUnavailableReason reason)
    : this._(unavailableReason: reason);

  final NotificationTarget? target;
  final NotificationUnavailableReason? unavailableReason;
  bool get isOpened => target != null;

  @override
  List<Object?> get props => [target, unavailableReason];
}

sealed class NotificationFailure implements Exception {
  const NotificationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NotificationAuthenticationFailure extends NotificationFailure {
  const NotificationAuthenticationFailure()
    : super('Sign in to view notifications.');
}

final class NotificationUnavailableFailure extends NotificationFailure {
  const NotificationUnavailableFailure()
    : super('This notification is no longer available.');
}

final class NotificationExpiredFailure extends NotificationFailure {
  const NotificationExpiredFailure() : super('This notification has expired.');
}

final class NotificationServiceFailure extends NotificationFailure {
  const NotificationServiceFailure()
    : super('Notifications are temporarily unavailable.');
}
