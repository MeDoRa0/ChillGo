import 'package:flutter/foundation.dart';
import '../domain/repositories/diagnostics_repository.dart';
import '../domain/repositories/release_metadata_repository.dart';
import '../domain/entities/diagnostics_context.dart';

class GlobalErrorHandler {
  final DiagnosticsRepository diagnosticsRepository;
  final ReleaseMetadataRepository? releaseMetadataRepository;

  GlobalErrorHandler({
    required this.diagnosticsRepository,
    this.releaseMetadataRepository,
  });

  void initialize() {
    // Intercept Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      diagnosticsRepository.logException(
        details.exception,
        details.stack,
        context: _context('framework_error'),
      );
    };

    // Intercept uncaught platform/async errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      diagnosticsRepository.logException(
        error,
        stack,
        context: _context('platform_error'),
      );
      return true;
    };
  }

  DiagnosticsContext _context(String category) =>
      releaseMetadataRepository?.diagnosticsContext(category) ??
      DiagnosticsContext(
        releaseVersion: 'unknown',
        clientType: 'unsupported',
        failureCategory: category,
      );
}
