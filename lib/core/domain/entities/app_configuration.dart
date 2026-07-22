/// Closed set of platforms the application supports.
enum SupportedPlatform { android, ios, web, windows }

class AppConfiguration {
  final String id;
  final bool isFirebaseInitialized;
  final bool isCrashlyticsEnabled;
  final bool isAnalyticsEnabled;
  final bool isFcmEnabled;

  /// One of the supported runtime platforms.
  final SupportedPlatform platform;

  /// Semantic-version string, e.g. "1.2.3" or "1.2.3-beta+001".
  final String appVersion;
  final DateTime lastStartupTime;

  // Strict SemVer 2.0.0: MAJOR.MINOR.PATCH with no leading zeroes in numeric
  // identifiers, optional pre-release (numeric ids no leading zero, alphanum ids
  // unrestricted), and optional build metadata (no leading-zero restriction).
  static final _semverPattern = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(-(0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)'
    r'(\.(0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*)?'
    r'(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$',
  );

  AppConfiguration({
    required this.id,
    required this.isFirebaseInitialized,
    required this.isCrashlyticsEnabled,
    required this.isAnalyticsEnabled,
    required this.isFcmEnabled,
    required this.platform,
    required this.appVersion,
    required this.lastStartupTime,
  }) {
    if (!_semverPattern.hasMatch(appVersion)) {
      throw ArgumentError(
        'appVersion must be a valid semver string (e.g. "1.0.0" or "1.0.0-beta+001"), got: "$appVersion"',
      );
    }
  }
}
