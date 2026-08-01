import 'package:chillgo/features/notifications/data/services/unsupported_device_alert_service.dart';
import 'package:chillgo/features/notifications/domain/entities/device_alert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsupported adapter never prompts or emits device state', () async {
    const service = UnsupportedDeviceAlertService();
    expect(await service.capability(), DeviceAlertCapability.unsupported);
    expect(
      await service.requestPermission(),
      DeviceAlertCapability.unsupported,
    );
    expect(await service.registrationTargets.toList(), isEmpty);
    expect(await service.foregroundAlerts.toList(), isEmpty);
    expect(await service.openedAlerts.toList(), isEmpty);
  });
}
