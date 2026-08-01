import '../../domain/entities/notification_page.dart';

class NotificationSummaryModel extends UnreadNotificationSummary {
  const NotificationSummaryModel(super.count);

  factory NotificationSummaryModel.fromMap(Map<String, dynamic>? map) {
    final count = map?['unreadCount'];
    return NotificationSummaryModel(count is int ? count.clamp(0, 100000) : 0);
  }
}
