import 'dart:async';

import 'package:chillgo/features/live_meetup/data/services/geolocator_device_location_service.dart';
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _Position extends Mock implements Position {}

void main() {
  test('returns a validated one-shot current position', () async {
    final position = _Position();
    when(() => position.latitude).thenReturn(30);
    when(() => position.longitude).thenReturn(31);
    when(() => position.accuracy).thenReturn(10);
    final service = GeolocatorDeviceLocationService.withPositionProviders(
      () => const Stream<Position>.empty(),
      () async => position,
    );

    final sample = await service.currentPosition();

    expect(sample.coordinate.latitude, 30);
    expect(sample.coordinate.longitude, 31);
    expect(sample.accuracyMeters, 10);
  });

  test('maps an invalid one-shot position to a service failure', () async {
    final position = _Position();
    when(() => position.latitude).thenReturn(30);
    when(() => position.longitude).thenReturn(31);
    when(() => position.accuracy).thenReturn(5001);
    final service = GeolocatorDeviceLocationService.withPositionProviders(
      () => const Stream<Position>.empty(),
      () async => position,
    );

    expect(service.currentPosition(), throwsA(isA<LiveMeetupServiceFailure>()));
  });

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
