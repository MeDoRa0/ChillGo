import 'package:chillgo/features/notifications/data/models/notification_command_model.dart';
import 'package:chillgo/features/notifications/data/models/notification_model.dart';
import 'package:chillgo/features/notifications/data/models/notification_preferences_model.dart';
import 'package:chillgo/features/notifications/data/models/notification_summary_model.dart';
import 'package:chillgo/features/notifications/domain/entities/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 1);

  test('notification model maps the trusted wire shape', () {
    final model = NotificationModel.fromMap({
      'recipientUserId': 'user-1',
      'category': 'agreement_confirmed',
      'target': {
        'type': 'agreement',
        'crewId': 'crew-1',
        'outingId': 'outing-1',
      },
      'display': {'title': 'Confirmed', 'body': 'Open the outing.'},
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(createdAt.add(const Duration(days: 30))),
      'readAt': null,
    }, 'notification-1');

    expect(model.category, NotificationCategory.agreementConfirmed);
    expect(model.target.outingId, 'outing-1');
    expect(model.isRead, isFalse);
    expect(model.cursor.notificationId, 'notification-1');
  });

  test('notification model rejects unknown categories', () {
    expect(
      () => NotificationModel.fromMap({
        'recipientUserId': 'user-1',
        'category': 'marketing_campaign',
        'target': {'type': 'invitations', 'crewId': 'crew-1'},
        'display': {'title': 'Title', 'body': 'Body'},
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(
          createdAt.add(const Duration(days: 30)),
        ),
      }, 'notification-1'),
      throwsFormatException,
    );
  });

  test('notification model reads a joining member avatar', () {
    final model = NotificationModel.fromMap({
      'recipientUserId': 'user-1',
      'category': 'crew_member_joined',
      'target': {'type': 'crew', 'crewId': 'crew-1'},
      'display': {
        'title': 'New crew member',
        'body': 'Adam Hank joined the crew.',
        'avatarUrl': 'https://example.com/adam.jpg',
      },
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(createdAt.add(const Duration(days: 30))),
      'readAt': null,
    }, 'notification-2');

    expect(model.category, NotificationCategory.crewMemberJoined);
    expect(model.display.avatarUrl, 'https://example.com/adam.jpg');
    expect(model.target.type, NotificationTargetType.crew);
  });

  test('summary and preferences apply safe defaults', () {
    expect(NotificationSummaryModel.fromMap(null).count, 0);
    const defaults = NotificationPreferencesModel();
    expect(defaults.votingUpdatesEnabled, isTrue);
    expect(defaults.outingChangesEnabled, isTrue);
    expect(defaults.arrivalAlertsEnabled, isTrue);
  });

  test('command model exposes only terminal result state', () {
    final command = NotificationCommandModel.fromMap({
      'status': 'succeeded',
      'result': {
        'target': {'type': 'invitations', 'crewId': 'crew-1'},
      },
    }, 'command-1');
    expect(command.isTerminal, isTrue);
    expect(command.errorCode, isNull);
  });
}
