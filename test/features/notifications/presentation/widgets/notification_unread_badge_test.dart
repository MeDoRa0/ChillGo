import 'dart:async';

import 'package:chillgo/features/notifications/domain/entities/device_alert.dart';
import 'package:chillgo/features/notifications/domain/entities/notification.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_page.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_preferences.dart';
import 'package:chillgo/features/notifications/domain/repositories/notification_repository.dart';
import 'package:chillgo/features/notifications/presentation/widgets/notification_unread_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('announces the exact unread count', (tester) async {
    final repository = _SummaryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NotificationUnreadBadge(repository: repository)),
      ),
    );
    repository.summaries.add(const UnreadNotificationSummary(4));
    await tester.pump();

    expect(find.text('4'), findsOneWidget);
    expect(find.bySemanticsLabel('4 unread notifications'), findsOneWidget);
    await repository.summaries.close();
  });
}

class _SummaryRepository implements NotificationRepository {
  final summaries = StreamController<UnreadNotificationSummary>.broadcast();

  @override
  Stream<UnreadNotificationSummary> watchUnreadSummary() => summaries.stream;

  @override
  void clearProtectedState() {}

  @override
  Future<NotificationPage> loadOlder(NotificationCursor cursor) =>
      throw UnimplementedError();

  @override
  Future<void> markRead(String notificationId) => throw UnimplementedError();

  @override
  Future<NotificationOpenResult> open(String notificationId) =>
      throw UnimplementedError();

  @override
  Future<void> registerDevice(DeviceRegistrationTarget target) =>
      throw UnimplementedError();

  @override
  Future<void> unregisterDevice(String installationId) =>
      throw UnimplementedError();

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) =>
      throw UnimplementedError();

  @override
  Stream<NotificationPage> watchNewest() => throw UnimplementedError();

  @override
  Stream<NotificationPreferences> watchPreferences() =>
      throw UnimplementedError();
}
