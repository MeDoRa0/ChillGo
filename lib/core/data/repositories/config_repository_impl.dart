import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_configuration.dart';
import '../../domain/repositories/config_repository.dart';
import '../models/app_configuration_model.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  ConfigRepositoryImpl({required this.sharedPreferences});

  static const String _configKey = 'CACHED_APP_CONFIGURATION';

  final SharedPreferences sharedPreferences;

  @override
  Future<AppConfiguration> getConfiguration() async {
    final jsonString = sharedPreferences.getString(_configKey);
    if (jsonString != null) {
      return AppConfigurationModel.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
    }

    final defaultConfig = AppConfigurationModel(
      id: 'global_config',
      isFirebaseInitialized: true,
      isCrashlyticsEnabled: true,
      isAnalyticsEnabled: true,
      isFcmEnabled: true,
      platform: SupportedPlatform.android,
      appVersion: '1.0.0',
      lastStartupTime: DateTime.now(),
    );
    await saveConfiguration(defaultConfig);
    return defaultConfig;
  }

  @override
  Future<void> saveConfiguration(AppConfiguration config) async {
    final model = AppConfigurationModel(
      id: config.id,
      isFirebaseInitialized: config.isFirebaseInitialized,
      isCrashlyticsEnabled: config.isCrashlyticsEnabled,
      isAnalyticsEnabled: config.isAnalyticsEnabled,
      isFcmEnabled: config.isFcmEnabled,
      platform: config.platform,
      appVersion: config.appVersion,
      lastStartupTime: config.lastStartupTime,
    );

    await sharedPreferences.setString(_configKey, json.encode(model.toJson()));
  }
}
