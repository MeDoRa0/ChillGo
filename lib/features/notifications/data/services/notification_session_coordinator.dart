import 'dart:async';

import '../../domain/entities/device_alert.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/services/device_alert_service.dart';

class NotificationSessionCoordinator {
  NotificationSessionCoordinator(this._repository, this._deviceAlertService);

  final NotificationRepository _repository;
  final DeviceAlertService _deviceAlertService;
  final _foregroundController = StreamController<DeviceAlertEvent>.broadcast();
  final _openedController =
      StreamController<NotificationOpenResult>.broadcast();

  StreamSubscription<DeviceRegistrationTarget>? _registrationSubscription;
  StreamSubscription<DeviceAlertEvent>? _foregroundSubscription;
  StreamSubscription<DeviceAlertEvent>? _openedSubscription;
  String? _registeredInstallationId;
  bool _started = false;

  Stream<DeviceAlertEvent> get foregroundAlerts => _foregroundController.stream;
  Stream<NotificationOpenResult> get openedNotifications =>
      _openedController.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _registrationSubscription = _deviceAlertService.registrationTargets.listen((
      target,
    ) async {
      _registeredInstallationId = target.installationId;
      try {
        await _repository.registerDevice(target);
      } on NotificationFailure {
        // Registration is best effort and never blocks the in-app center.
      }
    });
    _foregroundSubscription = _deviceAlertService.foregroundAlerts.listen(
      _foregroundController.add,
    );
    _openedSubscription = _deviceAlertService.openedAlerts.listen((
      event,
    ) async {
      final result = await _repository.open(event.notificationId);
      _openedController.add(result);
    });
    await _deviceAlertService.start();
  }

  Future<DeviceAlertCapability> capability() =>
      _deviceAlertService.capability();

  Future<DeviceAlertCapability> requestPermission() =>
      _deviceAlertService.requestPermission();

  Future<void> stopBeforeSignOut() async {
    final installationId = _registeredInstallationId;
    if (installationId != null) {
      await Future.any<void>([
        _unregisterBestEffort(installationId),
        Future<void>.delayed(const Duration(seconds: 2)),
      ]);
    }
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    _started = false;
    await _registrationSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _registrationSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
    _registeredInstallationId = null;
    _repository.clearProtectedState();
    await _deviceAlertService.clear();
  }

  Future<void> _unregisterBestEffort(String installationId) async {
    try {
      await _repository.unregisterDevice(installationId);
    } on NotificationFailure {
      // Deleting the local token makes a stale server registration unusable.
    }
  }

  Future<void> dispose() async {
    await clearLocalSession();
    await _foregroundController.close();
    await _openedController.close();
  }
}
