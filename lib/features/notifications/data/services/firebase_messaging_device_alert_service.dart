import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/device_alert.dart';
import '../../domain/services/device_alert_service.dart';
import '../models/notification_model.dart';

class FirebaseMessagingDeviceAlertService implements DeviceAlertService {
  FirebaseMessagingDeviceAlertService(
    this._messaging,
    this._preferences,
    this._platform,
  );

  static const _installationKey = 'notification_installation_id';

  final FirebaseMessaging _messaging;
  final SharedPreferences _preferences;
  final DeviceAlertPlatform _platform;
  final _targets = StreamController<DeviceRegistrationTarget>.broadcast();
  final _foreground = StreamController<DeviceAlertEvent>.broadcast();
  final _opened = StreamController<DeviceAlertEvent>.broadcast();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _installationId;
  bool _started = false;

  String get installationId => _installationId ??=
      _preferences.getString(_installationKey) ?? _createInstallationId();

  @override
  Stream<DeviceRegistrationTarget> get registrationTargets => _targets.stream;

  @override
  Stream<DeviceAlertEvent> get foregroundAlerts => _foreground.stream;

  @override
  Stream<DeviceAlertEvent> get openedAlerts => _opened.stream;

  @override
  Future<DeviceAlertCapability> capability() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return _capability(settings.authorizationStatus);
    } on FirebaseException {
      return DeviceAlertCapability.unsupported;
    }
  }

  @override
  Future<DeviceAlertCapability> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final result = _capability(settings.authorizationStatus);
      if (result == DeviceAlertCapability.supported) {
        await _emitCurrentToken();
      }
      return result;
    } on FirebaseException {
      return DeviceAlertCapability.unsupported;
    }
  }

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _tokenSubscription = _messaging.onTokenRefresh.listen(_emitToken);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => _emitMessage(message, _foreground),
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _emitMessage(message, _opened),
    );
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _emitMessage(initial, _opened);
      if (await capability() == DeviceAlertCapability.supported) {
        await _emitCurrentToken();
      }
    } on FirebaseException {
      await _cancelSubscriptions();
      _started = false;
    }
  }

  @override
  Future<void> clear() async {
    _started = false;
    await _cancelSubscriptions();
    try {
      await _messaging.deleteToken();
    } on FirebaseException {
      // Local session teardown remains safe while offline.
    }
  }

  Future<void> _emitCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) _emitToken(token);
    } on FirebaseException {
      // Token registration is best effort; the in-app center remains available.
    }
  }

  void _emitToken(String token) {
    if (!_started) return;
    _targets.add(
      DeviceRegistrationTarget(
        installationId: installationId,
        token: token,
        platform: _platform,
      ),
    );
  }

  void _emitMessage(
    RemoteMessage message,
    StreamController<DeviceAlertEvent> controller,
  ) {
    final notificationId = message.data['notificationId'];
    final category = message.data['category'];
    if (notificationId == null || category == null) return;
    try {
      controller.add(
        DeviceAlertEvent(
          notificationId: notificationId,
          category: notificationCategoryFromWire(category),
        ),
      );
    } on FormatException {
      // Unknown future payload versions are ignored safely.
    }
  }

  DeviceAlertCapability _capability(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => DeviceAlertCapability.supported,
        AuthorizationStatus.notDetermined =>
          DeviceAlertCapability.notDetermined,
        AuthorizationStatus.denied => DeviceAlertCapability.denied,
      };

  String _createInstallationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final id = base64UrlEncode(bytes).replaceAll('=', '');
    unawaited(_preferences.setString(_installationKey, id));
    return id;
  }

  Future<void> _cancelSubscriptions() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
  }

  Future<void> dispose() async {
    await clear();
    await _targets.close();
    await _foreground.close();
    await _opened.close();
  }
}

DeviceAlertPlatform? currentDeviceAlertPlatform() {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => DeviceAlertPlatform.android,
    TargetPlatform.iOS => DeviceAlertPlatform.ios,
    _ => null,
  };
}
