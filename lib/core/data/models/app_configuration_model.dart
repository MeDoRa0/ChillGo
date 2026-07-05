import '../../domain/entities/app_configuration.dart';

class AppConfigurationModel extends AppConfiguration {
  AppConfigurationModel({
    required super.id,
    required super.isFirebaseInitialized,
    required super.isCrashlyticsEnabled,
    required super.isAnalyticsEnabled,
    required super.isFcmEnabled,
    required super.platform,
    required super.appVersion,
    required super.lastStartupTime,
  });

  factory AppConfigurationModel.fromJson(Map<String, dynamic> json) {
    return AppConfigurationModel(
      id: json['id'] as String,
      isFirebaseInitialized: json['isFirebaseInitialized'] as bool,
      isCrashlyticsEnabled: json['isCrashlyticsEnabled'] as bool,
      isAnalyticsEnabled: json['isAnalyticsEnabled'] as bool,
      isFcmEnabled: json['isFcmEnabled'] as bool,
      platform: _parsePlatform(json['platform'] as String?),
      appVersion: json['appVersion'] as String,
      lastStartupTime: DateTime.parse(json['lastStartupTime'] as String),
    );
  }

  factory AppConfigurationModel.fromRemoteJson(
    Map<String, dynamic> json, {
    required SupportedPlatform platform,
    required String appVersion,
    required DateTime lastStartupTime,
  }) {
    return AppConfigurationModel(
      id: json['id'] as String,
      isFirebaseInitialized: json['isFirebaseInitialized'] as bool,
      isCrashlyticsEnabled: json['isCrashlyticsEnabled'] as bool,
      isAnalyticsEnabled: json['isAnalyticsEnabled'] as bool,
      isFcmEnabled: json['isFcmEnabled'] as bool,
      platform: platform,
      appVersion: appVersion,
      lastStartupTime: lastStartupTime,
    );
  }

  static SupportedPlatform _parsePlatform(String? platformName) {
    if (platformName == null) {
      throw const FormatException(
        "Missing required field 'platform' in AppConfigurationModel JSON.",
      );
    }
    for (final platform in SupportedPlatform.values) {
      if (platform.name == platformName) return platform;
    }
    throw FormatException(
      "Invalid platform value '$platformName'. "
      "Expected one of: ${SupportedPlatform.values.map((p) => p.name).join(', ')}.",
    );
  }

  /// Full JSON for local cache (SharedPreferences). Includes runtime fields.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isFirebaseInitialized': isFirebaseInitialized,
      'isCrashlyticsEnabled': isCrashlyticsEnabled,
      'isAnalyticsEnabled': isAnalyticsEnabled,
      'isFcmEnabled': isFcmEnabled,
      'platform': platform.name,
      'appVersion': appVersion,
      'lastStartupTime': lastStartupTime.toIso8601String(),
    };
  }

  /// Shared-config JSON for Firestore. Excludes per-installation runtime fields
  /// (platform, appVersion, lastStartupTime) so they are not overwritten across
  /// different client installs.
  Map<String, dynamic> toJsonRemote() {
    return {
      'id': id,
      'isFirebaseInitialized': isFirebaseInitialized,
      'isCrashlyticsEnabled': isCrashlyticsEnabled,
      'isAnalyticsEnabled': isAnalyticsEnabled,
      'isFcmEnabled': isFcmEnabled,
    };
  }
}
