import 'dart:async';

import 'package:chillgo/features/notifications/data/services/notification_session_coordinator.dart';
import 'package:chillgo/features/notifications/domain/entities/device_alert.dart';
import 'package:chillgo/features/notifications/domain/entities/notification.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_page.dart';
import 'package:chillgo/features/notifications/domain/entities/notification_preferences.dart';
import 'package:chillgo/features/notifications/domain/repositories/notification_repository.dart';
import 'package:chillgo/features/notifications/domain/services/device_alert_service.dart';
import 'package:chillgo/features/notifications/presentation/cubit/notification_preferences/notification_preferences_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saves optional preferences and requests permission explicitly',
    () async {
      final repository = _PreferencesRepository();
      final deviceAlerts = _DeviceAlerts();
      final coordinator = NotificationSessionCoordinator(
        repository,
        deviceAlerts,
      );
      final cubit = NotificationPreferencesCubit(
        repository: repository,
        sessionCoordinator: coordinator,
      );

      await cubit.watch();
      repository.preferences.add(const NotificationPreferences());
      await Future<void>.delayed(Duration.zero);
      await cubit.setOutingChanges(false);
      await cubit.requestDeviceAlerts();

      expect(repository.saved.single.outingChangesEnabled, isFalse);
      expect(deviceAlerts.permissionRequests, 1);
      expect(cubit.state.capability, DeviceAlertCapability.supported);

      await cubit.close();
      await coordinator.dispose();
      await repository.preferences.close();
    },
  );
}

class _DeviceAlerts implements DeviceAlertService {
  int permissionRequests = 0;

  @override
  Future<DeviceAlertCapability> capability() async =>
      DeviceAlertCapability.notDetermined;

  @override
  Future<DeviceAlertCapability> requestPermission() async {
    permissionRequests++;
    return DeviceAlertCapability.supported;
  }

  @override
  Stream<DeviceAlertEvent> get foregroundAlerts => const Stream.empty();

  @override
  Stream<DeviceAlertEvent> get openedAlerts => const Stream.empty();

  @override
  Stream<DeviceRegistrationTarget> get registrationTargets =>
      const Stream.empty();

  @override
  Future<void> clear() async {}

  @override
  Future<void> start() async {}
}

class _PreferencesRepository implements NotificationRepository {
  final preferences = StreamController<NotificationPreferences>.broadcast();
  final saved = <NotificationPreferences>[];

  @override
  Stream<NotificationPreferences> watchPreferences() => preferences.stream;

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    saved.add(preferences);
  }

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
  Future<void> registerDevice(DeviceRegistrationTarget target) async {}

  @override
  Future<void> unregisterDevice(String installationId) async {}

  @override
  Stream<NotificationPage> watchNewest() => throw UnimplementedError();

  @override
  Stream<UnreadNotificationSummary> watchUnreadSummary() =>
      throw UnimplementedError();
}
