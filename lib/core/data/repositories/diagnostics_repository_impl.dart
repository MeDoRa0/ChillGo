import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/diagnostics_log.dart';
import '../../domain/repositories/diagnostics_repository.dart';
import '../models/diagnostics_log_model.dart';

class DiagnosticsRepositoryImpl implements DiagnosticsRepository {
  final FirebaseCrashlytics? crashlytics;
  final FirebaseAnalytics? analytics;
  final List<DiagnosticsLog> _localBuffer = [];

  DiagnosticsRepositoryImpl({this.crashlytics, this.analytics});

  @override
  Future<void> logException(dynamic exception, StackTrace? stackTrace) async {
    final logEntry = DiagnosticsLogModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      errorMessage: exception.toString(),
      stackTrace: stackTrace?.toString(),
      severity: 'error',
      timestamp: DateTime.now(),
      deviceMetadata: const {
        'osVersion': 'unknown',
        'deviceModel': 'unknown',
        'screenSize': 'unknown',
      },
    );
    _localBuffer.add(logEntry);

    try {
      await crashlytics?.recordError(exception, stackTrace);
    } catch (_) {
      // Remote diagnostics are best-effort only.
    }
  }

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await analytics?.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Remote analytics are best-effort only.
    }
  }

  @override
  Future<List<DiagnosticsLog>> getLocalLogs() async {
    return _localBuffer;
  }
}

bool get isCrashlyticsSupportedPlatform {
  if (kIsWeb) return false;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => false,
  };
}

bool get isAnalyticsSupportedPlatform {
  if (kIsWeb) return true;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => false,
  };
}
