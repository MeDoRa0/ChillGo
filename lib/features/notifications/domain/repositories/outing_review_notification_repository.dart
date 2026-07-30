import '../entities/outing_review_notification.dart';

abstract class OutingReviewNotificationRepository {
  Stream<List<OutingReviewNotification>> watchNotifications();
  Future<void> markRead(String notificationId);
}
