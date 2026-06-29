import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../domain/entities/diagnostics_log.dart';
import '../../domain/repositories/diagnostics_repository.dart';
import '../models/diagnostics_log_model.dart';

class DiagnosticsRepositoryImpl implements DiagnosticsRepository {
  final FirebaseCrashlytics crashlytics;
  final FirebaseAnalytics analytics;
  final List<DiagnosticsLog> _localBuffer = [];

  DiagnosticsRepositoryImpl({
    required this.crashlytics,
    required this.analytics,
  });

  @override
  Future<void> logException(dynamic exception, StackTrace? stackTrace) async {
    // Local write happens first – always succeeds.
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
        // isOffline omitted – real connectivity state not yet available.
      },
    );
    _localBuffer.add(logEntry);

    // Best-effort remote report – SDK failures must not escape to the caller.
    try {
      await crashlytics.recordError(exception, stackTrace);
    } catch (_) {
      // Crashlytics SDK failure is non-critical; swallow silently.
    }
  }

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    // Best-effort analytics event – SDK failures must not escape to the caller.
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics SDK failure is non-critical; swallow silently.
    }
  }

  @override
  Future<List<DiagnosticsLog>> getLocalLogs() async {
    return _localBuffer;
  }
}
