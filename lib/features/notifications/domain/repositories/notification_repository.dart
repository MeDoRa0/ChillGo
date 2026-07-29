import '../entities/device_alert.dart';
import '../entities/notification.dart';
import '../entities/notification_page.dart';
import '../entities/notification_preferences.dart';

abstract class NotificationRepository {
  Stream<NotificationPage> watchNewest();
  Future<NotificationPage> loadOlder(NotificationCursor cursor);
  Stream<UnreadNotificationSummary> watchUnreadSummary();
  Future<void> markRead(String notificationId);
  Future<NotificationOpenResult> open(String notificationId);
  Stream<NotificationPreferences> watchPreferences();
  Future<void> updatePreferences(NotificationPreferences preferences);
  Future<void> registerDevice(DeviceRegistrationTarget target);
  Future<void> unregisterDevice(String installationId);
  void clearProtectedState();
}
