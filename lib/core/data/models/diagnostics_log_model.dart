import '../../domain/entities/diagnostics_log.dart';

class DiagnosticsLogModel extends DiagnosticsLog {
  DiagnosticsLogModel({
    required super.id,
    required super.errorMessage,
    super.stackTrace,
    required super.severity,
    required super.timestamp,
    required super.deviceMetadata,
  });

  factory DiagnosticsLogModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticsLogModel(
      id: json['id'] as String,
      errorMessage: json['errorMessage'] as String,
      stackTrace: json['stackTrace'] as String?,
      severity: json['severity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceMetadata: Map<String, dynamic>.from(json['deviceMetadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'deviceMetadata': Map<String, dynamic>.from(deviceMetadata),
    };
  }
}
