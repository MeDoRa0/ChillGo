import '../entities/diagnostics_context.dart';

abstract class ReleaseMetadataRepository {
  String get releaseVersion;
  String get clientType;

  DiagnosticsContext diagnosticsContext(String failureCategory);
}
