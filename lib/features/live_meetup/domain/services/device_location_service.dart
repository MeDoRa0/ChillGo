import '../entities/device_location_sample.dart';

enum DeviceLocationPermission {
  denied,
  deniedForever,
  whileInUse,
  reducedWhileInUse,
}

abstract interface class DeviceLocationService {
  Future<bool> isServiceEnabled();
  Future<DeviceLocationPermission> checkPermission();
  Future<DeviceLocationPermission> requestPermission();
  Future<DeviceLocationSample> currentPosition();
  Stream<DeviceLocationSample> watchPositions();
  Future<void> stop();
}
