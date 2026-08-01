import 'package:equatable/equatable.dart';
import 'notification.dart';

enum DeviceAlertPlatform { android, ios }

enum DeviceAlertCapability { supported, notDetermined, unsupported, denied }

class DeviceRegistrationTarget extends Equatable {
  const DeviceRegistrationTarget({
    required this.installationId,
    required this.token,
    required this.platform,
  });
  final String installationId;
  final String token;
  final DeviceAlertPlatform platform;
  @override
  List<Object?> get props => [installationId, token, platform];
}

class DeviceAlertEvent extends Equatable {
  const DeviceAlertEvent({
    required this.notificationId,
    required this.category,
  });
  final String notificationId;
  final NotificationCategory category;
  @override
  List<Object?> get props => [notificationId, category];
}
