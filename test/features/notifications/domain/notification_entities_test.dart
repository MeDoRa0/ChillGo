import 'package:chillgo/features/notifications/domain/entities/notification.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 29);
  final notification = AppNotification(
    id: 'notification',
    recipientUserId: 'recipient',
    category: NotificationCategory.crewInvitation,
    target: const NotificationTarget(
      type: NotificationTargetType.invitations,
      crewId: 'crew',
    ),
    display: const NotificationDisplay(
      title: 'Invitation',
      body: 'Open ChillGo',
    ),
    createdAt: createdAt,
    expiresAt: createdAt.add(const Duration(days: 30)),
  );

  test('notification is unread and expires exactly at its boundary', () {
    expect(notification.isRead, isFalse);
    expect(notification.isExpiredAt(notification.expiresAt), isTrue);
    expect(
      notification.isExpiredAt(
        notification.expiresAt.subtract(const Duration(microseconds: 1)),
      ),
      isFalse,
    );
  });

  test('page identifies a following cursor', () {
    final cursor = NotificationCursor(
      createdAt: DateTime.utc(2026, 7, 28),
      notificationId: 'older',
    );
    expect(
      NotificationPage(items: [notification], nextCursor: cursor).hasMore,
      isTrue,
    );
    expect(const NotificationPage(items: []).hasMore, isFalse);
  });

  test('unavailable results never expose a target', () {
    const result = NotificationOpenResult.unavailable(
      NotificationUnavailableReason.expired,
    );
    expect(result.isOpened, isFalse);
    expect(result.target, isNull);
  });
}
