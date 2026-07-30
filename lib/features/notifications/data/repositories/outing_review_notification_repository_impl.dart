import '../../domain/entities/outing_review_notification.dart';
import '../../domain/repositories/outing_review_notification_repository.dart';
import '../datasources/firestore_outing_review_notification_datasource.dart';

class OutingReviewNotificationRepositoryImpl
    implements OutingReviewNotificationRepository {
  const OutingReviewNotificationRepositoryImpl({
    required this.datasource,
    required this.currentUserId,
  });

  final FirestoreOutingReviewNotificationDatasource datasource;
  final String Function() currentUserId;

  @override
  Stream<List<OutingReviewNotification>> watchNotifications() {
    final userId = currentUserId();
    if (userId.isEmpty) return Stream.value(const []);
    return datasource.watchForUser(userId);
  }

  @override
  Future<void> markRead(String notificationId) {
    return datasource.markRead(notificationId);
  }
}
