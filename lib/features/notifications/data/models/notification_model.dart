import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.recipientUserId,
    required super.category,
    required super.target,
    required super.display,
    required super.createdAt,
    required super.expiresAt,
    super.readAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    final recipientUserId = _requiredString(map, 'recipientUserId');
    final category = _categoryFromWire(_requiredString(map, 'category'));
    final targetMap = _requiredMap(map, 'target');
    final displayMap = _requiredMap(map, 'display');
    final createdAt = readFirestoreTimestamp(map['createdAt']);
    final expiresAt = readFirestoreTimestamp(map['expiresAt']);
    if (createdAt == null || expiresAt == null) {
      throw const FormatException('Notification timestamps are invalid.');
    }
    return NotificationModel(
      id: id,
      recipientUserId: recipientUserId,
      category: category,
      target: NotificationTarget(
        type: _targetFromWire(_requiredString(targetMap, 'type')),
        crewId: _requiredString(targetMap, 'crewId'),
        outingId: targetMap['outingId'] as String?,
      ),
      display: NotificationDisplay(
        title: _requiredString(displayMap, 'title'),
        body: _requiredString(displayMap, 'body'),
      ),
      createdAt: createdAt,
      expiresAt: expiresAt,
      readAt: readFirestoreTimestamp(map['readAt']),
    );
  }

  NotificationCursor get cursor =>
      NotificationCursor(createdAt: createdAt, notificationId: id);
}

NotificationCategory notificationCategoryFromWire(String value) =>
    _categoryFromWire(value);

String notificationCategoryToWire(NotificationCategory category) =>
    switch (category) {
      NotificationCategory.crewInvitation => 'crew_invitation',
      NotificationCategory.outingInvitation => 'outing_invitation',
      NotificationCategory.votingUpdate => 'voting_update',
      NotificationCategory.agreementConfirmed => 'agreement_confirmed',
      NotificationCategory.agreementReopened => 'agreement_reopened',
      NotificationCategory.outingChanged => 'outing_changed',
      NotificationCategory.attendeeArrived => 'attendee_arrived',
    };

NotificationTarget notificationTargetFromMap(Map<String, dynamic> map) =>
    NotificationTarget(
      type: _targetFromWire(_requiredString(map, 'type')),
      crewId: _requiredString(map, 'crewId'),
      outingId: map['outingId'] as String?,
    );

NotificationCategory _categoryFromWire(String value) => switch (value) {
  'crew_invitation' => NotificationCategory.crewInvitation,
  'outing_invitation' => NotificationCategory.outingInvitation,
  'voting_update' => NotificationCategory.votingUpdate,
  'agreement_confirmed' => NotificationCategory.agreementConfirmed,
  'agreement_reopened' => NotificationCategory.agreementReopened,
  'outing_changed' => NotificationCategory.outingChanged,
  'attendee_arrived' => NotificationCategory.attendeeArrived,
  _ => throw FormatException('Unknown notification category: $value'),
};

NotificationTargetType _targetFromWire(String value) => switch (value) {
  'invitations' => NotificationTargetType.invitations,
  'agreement' => NotificationTargetType.agreement,
  'live_meetup' => NotificationTargetType.liveMeetup,
  _ => throw FormatException('Unknown notification target: $value'),
};

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing notification field: $key');
  }
  return value;
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! Map) {
    throw FormatException('Missing notification map: $key');
  }
  return Map<String, dynamic>.from(value);
}
