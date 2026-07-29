import '../entities/device_alert.dart';

abstract class DeviceAlertService {
  Future<DeviceAlertCapability> capability();
  Future<DeviceAlertCapability> requestPermission();
  Stream<DeviceRegistrationTarget> get registrationTargets;
  Stream<DeviceAlertEvent> get foregroundAlerts;
  Stream<DeviceAlertEvent> get openedAlerts;
  Future<void> start();
  Future<void> clear();
}
