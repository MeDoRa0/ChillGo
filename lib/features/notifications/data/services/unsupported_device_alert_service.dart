import '../../domain/entities/device_alert.dart';
import '../../domain/services/device_alert_service.dart';

class UnsupportedDeviceAlertService implements DeviceAlertService {
  const UnsupportedDeviceAlertService();

  @override
  Future<DeviceAlertCapability> capability() async =>
      DeviceAlertCapability.unsupported;

  @override
  Future<DeviceAlertCapability> requestPermission() async =>
      DeviceAlertCapability.unsupported;

  @override
  Stream<DeviceRegistrationTarget> get registrationTargets =>
      const Stream.empty();

  @override
  Stream<DeviceAlertEvent> get foregroundAlerts => const Stream.empty();

  @override
  Stream<DeviceAlertEvent> get openedAlerts => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> clear() async {}
}
