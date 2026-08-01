import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/device_location_sample.dart';
import '../../domain/entities/geo_coordinate.dart';
import '../../domain/repositories/live_meetup_repository.dart';
import '../../domain/services/device_location_service.dart';

class GeolocatorDeviceLocationService implements DeviceLocationService {
  GeolocatorDeviceLocationService({Stopwatch? monotonicClock})
    : _clock = monotonicClock ?? (Stopwatch()..start()),
      _positionStream = null,
      _currentPosition = null;

  GeolocatorDeviceLocationService.withPositionStream(
    this._positionStream, {
    Stopwatch? monotonicClock,
  }) : _clock = monotonicClock ?? (Stopwatch()..start()),
       _currentPosition = null;

  GeolocatorDeviceLocationService.withPositionProviders(
    this._positionStream,
    this._currentPosition, {
    Stopwatch? monotonicClock,
  }) : _clock = monotonicClock ?? (Stopwatch()..start());

  final Stopwatch _clock;
  final Stream<Position> Function()? _positionStream;
  final Future<Position> Function()? _currentPosition;
  StreamSubscription<Position>? _subscription;
  StreamController<DeviceLocationSample>? _controller;

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<DeviceLocationPermission> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  @override
  Future<DeviceLocationPermission> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  @override
  Future<DeviceLocationSample> currentPosition() async {
    try {
      return _sampleFrom(await _readCurrentPosition());
    } on ArgumentError catch (_, stack) {
      _throwServiceFailure(stack);
    } on PermissionDeniedException catch (_, stack) {
      _throwServiceFailure(stack);
    } on LocationServiceDisabledException catch (_, stack) {
      _throwServiceFailure(stack);
    } on TimeoutException catch (_, stack) {
      _throwServiceFailure(stack);
    }
  }

  Future<Position> _readCurrentPosition() =>
      _currentPosition?.call() ??
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

  Never _throwServiceFailure(StackTrace stack) =>
      Error.throwWithStackTrace(const LiveMeetupServiceFailure(), stack);

  @override
  Stream<DeviceLocationSample> watchPositions() {
    late StreamController<DeviceLocationSample> controller;
    var cancelled = false;
    controller = StreamController<DeviceLocationSample>(
      onListen: () {
        _controller = controller;
        final stream =
            _positionStream?.call() ??
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 0,
              ),
            );
        _subscription = stream.listen(
          (position) {
            if (cancelled || controller.isClosed) return;
            try {
              controller.add(_sampleFrom(position));
            } on ArgumentError {
              // Malformed provider samples are ignored and never published.
            }
          },
          onError: (Object _, StackTrace stack) {
            if (!cancelled) {
              controller.addError(const LiveMeetupServiceFailure(), stack);
            }
          },
        );
      },
      onCancel: () async {
        cancelled = true;
        await _subscription?.cancel();
        _subscription = null;
        if (identical(_controller, controller)) _controller = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) await controller.close();
  }

  DeviceLocationPermission _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.denied => DeviceLocationPermission.denied,
        LocationPermission.deniedForever =>
          DeviceLocationPermission.deniedForever,
        LocationPermission.whileInUse ||
        LocationPermission.always => DeviceLocationPermission.whileInUse,
        LocationPermission.unableToDetermine => DeviceLocationPermission.denied,
      };

  DeviceLocationSample _sampleFrom(Position position) => DeviceLocationSample(
    coordinate: GeoCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    ),
    accuracyMeters: position.accuracy,
    acquiredAtMonotonic: _clock.elapsed,
  );
}
