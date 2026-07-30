import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/outing_review_notification.dart';

class FirestoreOutingReviewNotificationDatasource {
  static const _limit = 100;

  const FirestoreOutingReviewNotificationDatasource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      firestore.collection('notifications');

  Stream<List<OutingReviewNotification>> watchForUser(String userId) {
    return _notifications
        .where('recipientUserId', isEqualTo: userId)
        .limit(_limit)
        .snapshots()
        .map((snapshot) {
          final notifications =
              snapshot.docs
                  .map((document) => _readNotification(document))
                  .whereType<OutingReviewNotification>()
                  .toList()
                ..sort(
                  (left, right) => right.createdAt.compareTo(left.createdAt),
                );
          return notifications;
        });
  }

  Future<void> markRead(String notificationId) {
    return _notifications.doc(notificationId).update({
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  OutingReviewNotification? _readNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data['category'] != 'outing_review') return null;
    final createdAt = readFirestoreTimestamp(data['createdAt']);
    if (createdAt == null) return null;
    final recipientUserId = data['recipientUserId'];
    final crewId = data['crewId'];
    final outingId = data['outingId'];
    final creatorDisplayName = data['creatorDisplayName'];
    final outingTitle = data['outingTitle'];
    if (recipientUserId is! String ||
        crewId is! String ||
        outingId is! String ||
        creatorDisplayName is! String ||
        outingTitle is! String) {
      return null;
    }
    return OutingReviewNotification(
      id: document.id,
      recipientUserId: recipientUserId,
      crewId: crewId,
      outingId: outingId,
      creatorDisplayName: creatorDisplayName,
      outingTitle: outingTitle,
      createdAt: createdAt,
      readAt: readFirestoreTimestamp(data['readAt']),
    );
  }
}
