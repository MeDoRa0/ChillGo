import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/diagnostics_log.dart';
import '../../domain/entities/diagnostics_context.dart';
import '../../domain/entities/release_telemetry_event.dart';
import '../../domain/repositories/diagnostics_repository.dart';
import '../../domain/repositories/release_metadata_repository.dart';
import '../models/diagnostics_log_model.dart';

class DiagnosticsRepositoryImpl implements DiagnosticsRepository {
  final FirebaseCrashlytics? crashlytics;
  final FirebaseAnalytics? analytics;
  final ReleaseMetadataRepository? releaseMetadata;
  final List<DiagnosticsLog> _localBuffer = [];

  DiagnosticsRepositoryImpl({
    this.crashlytics,
    this.analytics,
    this.releaseMetadata,
  });

  @override
  Future<void> logException(
    Object exception,
    StackTrace? stackTrace, {
    DiagnosticsContext? context,
  }) async {
    final safeContext =
        context ??
        releaseMetadata?.diagnosticsContext('unexpected_failure') ??
        const DiagnosticsContext(
          releaseVersion: 'unknown',
          clientType: 'unsupported',
          failureCategory: 'unexpected_failure',
        );
    final logEntry = DiagnosticsLogModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      errorMessage: safeContext.failureCategory,
      stackTrace: null,
      severity: 'error',
      timestamp: DateTime.now(),
      deviceMetadata: safeContext.toSafeMap(),
    );
    _localBuffer.add(logEntry);

    try {
      for (final entry in safeContext.toSafeMap().entries) {
        await crashlytics?.setCustomKey(entry.key, entry.value);
      }
      await crashlytics?.recordError(
        StateError('diagnostics.${safeContext.failureCategory}'),
        null,
        reason: safeContext.failureCategory,
      );
    } catch (_) {
      // Remote diagnostics are best-effort only.
    }
  }

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      final context =
          releaseMetadata?.diagnosticsContext('journey_completed') ??
          const DiagnosticsContext(
            releaseVersion: 'unknown',
            clientType: 'unsupported',
            failureCategory: 'journey_completed',
          );
      final outcome = parameters?['outcome_category'];
      final event = ReleaseTelemetryEvent.create(
        name: name,
        context: context,
        outcome: outcome is String ? outcome : 'completed',
      );
      await analytics?.logEvent(
        name: event.name,
        parameters: event.toParameters(),
      );
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
