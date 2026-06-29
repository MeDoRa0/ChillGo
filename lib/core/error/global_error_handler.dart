import 'package:flutter/foundation.dart';
import '../domain/repositories/diagnostics_repository.dart';

class GlobalErrorHandler {
  final DiagnosticsRepository diagnosticsRepository;

  GlobalErrorHandler({required this.diagnosticsRepository});

  void initialize() {
    // Intercept Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      diagnosticsRepository.logException(
        details.exception,
        details.stack,
      );
    };

    // Intercept uncaught platform/async errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      diagnosticsRepository.logException(error, stack);
      return true;
    };
  }
}
