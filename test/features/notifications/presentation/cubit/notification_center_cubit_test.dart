import 'dart:async';

import 'package:chillgo/features/notifications/domain/entities/device_alert.dart';
import 'package:chillgo/features/notifications/domain/entities/notification.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_page.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_preferences.dart';
import 'package:chillgo/features/notifications/domain/repositories/notification_repository.dart';
import 'package:chillgo/features/notifications/presentation/cubit/notification_center/notification_center_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeNotificationRepository repository;
  late NotificationCenterCubit cubit;

  setUp(() {
    repository = _FakeNotificationRepository();
    cubit = NotificationCenterCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('watches newest private page and clears protected state', () async {
    await cubit.watch();
    repository.pages.add(NotificationPage(items: [_notification()]));
    await expectLater(
      cubit.stream,
      emitsThrough(
        isA<NotificationCenterState>().having(
          (state) => state.items.length,
          'item count',
          1,
        ),
      ),
    );

    cubit.clear();
    expect(repository.cleared, isTrue);
    expect(cubit.state.status, NotificationCenterStatus.initial);
  });

  test('opens through repository reauthorization', () async {
    final result = await cubit.open('notification-1');
    expect(result.target?.type, NotificationTargetType.invitations);
    expect(repository.opened, ['notification-1']);
  });
}

AppNotification _notification() {
  final createdAt = DateTime.utc(2026, 7, 1);
  return AppNotification(
    id: 'notification-1',
    recipientUserId: 'user-1',
    category: NotificationCategory.crewInvitation,
    target: const NotificationTarget(
      type: NotificationTargetType.invitations,
      crewId: 'crew-1',
    ),
    display: const NotificationDisplay(title: 'Invitation', body: 'Open it.'),
    createdAt: createdAt,
    expiresAt: createdAt.add(const Duration(days: 30)),
  );
}

class _FakeNotificationRepository implements NotificationRepository {
  final pages = StreamController<NotificationPage>.broadcast();
  final opened = <String>[];
  bool cleared = false;

  @override
  Stream<NotificationPage> watchNewest() => pages.stream;

  @override
  Future<NotificationOpenResult> open(String notificationId) async {
    opened.add(notificationId);
    return const NotificationOpenResult.opened(
      NotificationTarget(
        type: NotificationTargetType.invitations,
        crewId: 'crew-1',
      ),
    );
  }

  @override
  void clearProtectedState() => cleared = true;

  @override
  Future<NotificationPage> loadOlder(NotificationCursor cursor) async =>
      const NotificationPage(items: []);

  @override
  Future<void> markRead(String notificationId) async {}

  @override
  Future<void> registerDevice(DeviceRegistrationTarget target) async {}

  @override
  Future<void> unregisterDevice(String installationId) async {}

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {}

  @override
  Stream<NotificationPreferences> watchPreferences() => const Stream.empty();

  @override
  Stream<UnreadNotificationSummary> watchUnreadSummary() =>
      const Stream.empty();

  Future<void> dispose() => pages.close();
}
