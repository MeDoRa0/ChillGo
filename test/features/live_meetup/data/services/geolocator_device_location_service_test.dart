import 'dart:async';

import 'package:chillgo/features/live_meetup/data/services/geolocator_device_location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _Position extends Mock implements Position {}

void main() {
  test('maps valid provider fixes and ignores invalid accuracy', () async {
    final positions = StreamController<Position>();
    final service = GeolocatorDeviceLocationService.withPositionStream(
      () => positions.stream,
    );
    final valid = _Position();
    when(() => valid.latitude).thenReturn(30);
    when(() => valid.longitude).thenReturn(31);
    when(() => valid.accuracy).thenReturn(10);
    final values = <Object>[];
    final subscription = service.watchPositions().listen(values.add);
    positions.add(valid);
    final invalid = _Position();
    when(() => invalid.latitude).thenReturn(30);
    when(() => invalid.longitude).thenReturn(31);
    when(() => invalid.accuracy).thenReturn(5001);
    positions.add(invalid);
    await Future<void>.delayed(Duration.zero);
    expect(values, hasLength(1));
    await subscription.cancel();
    await positions.close();
  });

  test('cancellation ignores late callbacks', () async {
    final positions = StreamController<Position>();
    final service = GeolocatorDeviceLocationService.withPositionStream(
      () => positions.stream,
    );
    final values = <Object>[];
    final subscription = service.watchPositions().listen(values.add);
    await subscription.cancel();
    final late = _Position();
    when(() => late.latitude).thenReturn(30);
    when(() => late.longitude).thenReturn(31);
    when(() => late.accuracy).thenReturn(10);
    positions.add(late);
    await Future<void>.delayed(Duration.zero);
    expect(values, isEmpty);
    await positions.close();
  });
}
