import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_configuration.dart';
import '../../domain/repositories/config_repository.dart';
import '../models/app_configuration_model.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final SharedPreferences sharedPreferences;
  final FirebaseFirestore firestore;

  static const String _configKey = 'CACHED_APP_CONFIGURATION';

  ConfigRepositoryImpl({
    required this.sharedPreferences,
    required this.firestore,
  });

  @override
  Future<AppConfiguration> getConfiguration() async {
    // 1. Check local cache first for performance.
    final jsonString = sharedPreferences.getString(_configKey);
    if (jsonString != null) {
      return AppConfigurationModel.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
    }

    // 2. Attempt Firestore fetch. Only treat offline/network errors as a
    //    non-fatal fallback; re-throw permission, rules, or data-shape errors
    //    so they are not silently swallowed.
    try {
      final doc = await firestore
          .collection('config')
          .doc('global_config')
          .get();
      if (doc.exists && doc.data() != null) {
        final remote = AppConfigurationModel.fromRemoteJson(
          doc.data()!,
          platform: SupportedPlatform.android,
          appVersion: '1.0.0',
          lastStartupTime: DateTime.now(),
        );
        // Cache remotely fetched config locally (full JSON for local use).
        await sharedPreferences.setString(
          _configKey,
          json.encode(remote.toJson()),
        );
        return remote;
      }
    } on FirebaseException catch (e) {
      // Suppress only genuine offline / network failures; surface everything else.
      if (e.code != 'unavailable' && e.code != 'network-request-failed') {
        rethrow;
      }
      // Offline — fall through to local default below.
    }
    // FormatException from parsing (bad shape / bad semver / bad platform) is
    // intentionally NOT caught here; it propagates to the caller.

    // 3. Nothing exists remotely or locally – create and persist default.
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

    // Write to Firestore first using only the shared (non-runtime) fields so
    // platform, appVersion, and lastStartupTime are not overwritten across
    // different client installs.
    try {
      await firestore
          .collection('config')
          .doc(config.id)
          .set(model.toJsonRemote());
    } on FirebaseException catch (e) {
      // Suppress unavailable/network errors (offline-first fallback).
      // Let permission, rules, or schema errors propagate so they are visible.
      if (e.code != 'unavailable' && e.code != 'network-request-failed') {
        rethrow;
      }
    }

    // Update local cache only after the Firestore write has either succeeded or
    // been confirmed as an offline-only failure. This prevents stale local state
    // when a non-network FirebaseException causes an early rethrow above.
    await sharedPreferences.setString(_configKey, json.encode(model.toJson()));
  }
}
