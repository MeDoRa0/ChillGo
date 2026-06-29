import '../entities/diagnostics_log.dart';

abstract class DiagnosticsRepository {
  Future<void> logException(dynamic exception, StackTrace? stackTrace);
  Future<void> logEvent(String name, Map<String, Object>? parameters);
  Future<List<DiagnosticsLog>> getLocalLogs();
}
