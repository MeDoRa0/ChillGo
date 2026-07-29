import 'package:equatable/equatable.dart';

/// Non-identifying context that is safe to attach to a diagnostics report.
class DiagnosticsContext extends Equatable {
  const DiagnosticsContext({
    required this.releaseVersion,
    required this.clientType,
    required this.failureCategory,
  });

  final String releaseVersion;
  final String clientType;
  final String failureCategory;

  Map<String, String> toSafeMap() => {
    'release_version': releaseVersion,
    'client_type': clientType,
    'failure_category': failureCategory,
  };

  @override
  List<Object> get props => [releaseVersion, clientType, failureCategory];
}
