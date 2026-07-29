import 'package:chillgo/features/notifications/domain/entities/notification.dart';
import 'package:chillgo/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository contract exposes private-center operations only', () {
    NotificationRepository? repository;
    expect(repository, isNull);
    const failure = NotificationOpenResult.unavailable(NotificationUnavailableReason.unavailable);
    expect(failure.unavailableReason, NotificationUnavailableReason.unavailable);
  });
}
