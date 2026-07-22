class DiagnosticsLog {
  /// Allowed diagnostic severity levels.
  static const allowedSeverities = {
    'debug',
    'info',
    'warning',
    'error',
    'fatal',
  };

  final String id;
  final String errorMessage;
  final String? stackTrace;

  /// Must be one of: debug, info, warning, error, fatal.
  final String severity;

  /// Must not be in the future.
  final DateTime timestamp;
  final Map<String, dynamic> deviceMetadata;

  DiagnosticsLog({
    required this.id,
    required this.errorMessage,
    this.stackTrace,
    required this.severity,
    required this.timestamp,
    required this.deviceMetadata,
  }) {
    if (!allowedSeverities.contains(severity)) {
      throw ArgumentError(
        'severity must be one of $allowedSeverities, got: "$severity"',
      );
    }
    if (timestamp.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      throw ArgumentError(
        'timestamp must not be in the future, got: $timestamp',
      );
    }
  }
}
