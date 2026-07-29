import '../entities/diagnostics_log.dart';
import '../entities/diagnostics_context.dart';

abstract class DiagnosticsRepository {
  Future<void> logException(
    Object exception,
    StackTrace? stackTrace, {
    DiagnosticsContext? context,
  });
  Future<void> logEvent(String name, Map<String, Object>? parameters);
  Future<List<DiagnosticsLog>> getLocalLogs();
}
