import 'package:equatable/equatable.dart';
import 'notification.dart';

class NotificationPage extends Equatable {
  const NotificationPage({required this.items, this.nextCursor});
  final List<AppNotification> items;
  final NotificationCursor? nextCursor;
  bool get hasMore => nextCursor != null;
  @override
  List<Object?> get props => [items, nextCursor];
}

class UnreadNotificationSummary extends Equatable {
  const UnreadNotificationSummary(this.count);
  final int count;
  @override
  List<Object?> get props => [count];
}
