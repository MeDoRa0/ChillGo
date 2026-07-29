import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/entities/device_location_sample.dart';
import '../../domain/entities/live_location_session.dart';
import '../../domain/repositories/live_meetup_repository.dart';
import '../../domain/services/device_location_service.dart';

enum SharingEventType {
  starting,
  active,
  paused,
  published,
  transferRequired,
  stopped,
  failed,
  accessLost,
}

class SharingEvent {
  const SharingEvent(this.type, {this.failure});
  final SharingEventType type;
  final LiveMeetupFailure? failure;
}

class LiveLocationSharingCoordinator with WidgetsBindingObserver {
  LiveLocationSharingCoordinator({
    required this.repository,
    required this.locationService,
    Stopwatch? monotonicClock,
    Random? secureRandom,
  }) : _clock = monotonicClock ?? (Stopwatch()..start()),
       _random = secureRandom ?? Random.secure(),
       _deviceSessionId = _randomString(secureRandom ?? Random.secure()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final LiveMeetupRepository repository;
  final DeviceLocationService locationService;
  final Stopwatch _clock;
  final Random _random;
  final String _deviceSessionId;
  final _events = StreamController<SharingEvent>.broadcast();
  final Map<String, LiveLocationSession> _sessions = {};
  StreamSubscription<DeviceLocationSample>? _positions;
  Duration? _lastPublishedAt;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  bool _disposed = false;

  Stream<SharingEvent> get events => _events.stream;
  bool isSharing(String outingId) => _sessions.containsKey(outingId);

  Future<void> start(String outingId, {bool transferExisting = false}) async {
    _events.add(const SharingEvent(SharingEventType.starting));
    if (!await locationService.isServiceEnabled()) {
      _fail(
        const LiveMeetupValidationFailure('Location services are disabled.'),
      );
      return;
    }
    var permission = await locationService.checkPermission();
    if (permission == DeviceLocationPermission.denied) {
      permission = await locationService.requestPermission();
    }
    if (permission == DeviceLocationPermission.deniedForever) {
      _fail(
        const LiveMeetupValidationFailure(
          'Location permission is permanently denied. Open system settings.',
        ),
      );
      return;
    }
    if (permission == DeviceLocationPermission.denied) {
      _fail(
        const LiveMeetupValidationFailure('Location permission was denied.'),
      );
      return;
    }
    final session = LiveLocationSession(
      outingId: outingId,
      sessionId: _randomString(_random),
      sessionToken: _randomString(_random, bytes: 32),
      deviceSessionId: _deviceSessionId,
    );
    try {
      final result = await repository.startSharing(
        outingId,
        session,
        transferExisting: transferExisting,
      );
      if (result.status == LiveMeetupCommandStatus.failed) {
        throw result.failure ?? const LiveMeetupServiceFailure();
      }
      _sessions[outingId] = session;
      _lastPublishedAt = null;
      _events.add(const SharingEvent(SharingEventType.active));
      if (_lifecycle == AppLifecycleState.resumed) _resume(outingId);
    } on LiveMeetupTransferRequired catch (failure) {
      _events.add(
        SharingEvent(SharingEventType.transferRequired, failure: failure),
      );
    } on LiveMeetupFailure catch (failure) {
      _fail(failure);
    }
  }

  Future<void> stop(String outingId) async {
    final session = _sessions.remove(outingId);
    await _positions?.cancel();
    _positions = null;
    await locationService.stop();
    if (session == null) {
      _events.add(const SharingEvent(SharingEventType.stopped));
      return;
    }
    try {
      await repository.stopSharing(outingId, session);
      _events.add(const SharingEvent(SharingEventType.stopped));
    } on LiveMeetupFailure catch (failure) {
      _fail(failure);
    }
  }

  void _resume(String outingId) {
    final session = _sessions[outingId];
    if (session == null || _disposed) return;
    unawaited(_positions?.cancel());
    _positions = locationService.watchPositions().listen(
      (sample) async {
        final now = _clock.elapsed;
        if (!sample.isUsableAt(now)) return;
        final last = _lastPublishedAt;
        if (last != null && now - last < const Duration(seconds: 15)) return;
        _lastPublishedAt = now;
        try {
          await repository.publishLocation(outingId, session, sample);
          _events.add(const SharingEvent(SharingEventType.published));
        } on LiveMeetupSessionEnded catch (failure) {
          await _clear(outingId);
          _events.add(
            SharingEvent(SharingEventType.accessLost, failure: failure),
          );
        } on LiveMeetupAccessDenied catch (failure) {
          await _clear(outingId);
          _events.add(
            SharingEvent(SharingEventType.accessLost, failure: failure),
          );
        } on LiveMeetupFailure catch (failure) {
          _fail(failure);
        }
      },
      onError: (Object error) {
        _fail(
          error is LiveMeetupFailure ? error : const LiveMeetupServiceFailure(),
        );
      },
    );
  }

  Future<void> _clear(String outingId) async {
    _sessions.remove(outingId);
    await _positions?.cancel();
    _positions = null;
    await locationService.stop();
  }

  Future<void> clearLocalSessions() async {
    _sessions.clear();
    await _positions?.cancel();
    _positions = null;
    await locationService.stop();
    if (!_events.isClosed) {
      _events.add(const SharingEvent(SharingEventType.stopped));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      for (final outingId in _sessions.keys) {
        _resume(outingId);
      }
      return;
    }
    unawaited(_positions?.cancel());
    _positions = null;
    unawaited(locationService.stop());
    if (state == AppLifecycleState.detached) {
      _sessions.clear();
    }
    _events.add(const SharingEvent(SharingEventType.paused));
  }

  void _fail(LiveMeetupFailure failure) {
    if (!_events.isClosed) {
      _events.add(SharingEvent(SharingEventType.failed, failure: failure));
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await clearLocalSessions();
    unawaited(_events.close());
  }

  static String _randomString(Random random, {int bytes = 24}) => base64Url
      .encode(List<int>.generate(bytes, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}
