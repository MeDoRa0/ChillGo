import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/core/domain/entities/app_configuration.dart';
import 'package:chillgo/core/data/models/app_configuration_model.dart';

void main() {
  final tModel = AppConfigurationModel(
    id: 'global_config',
    isFirebaseInitialized: true,
    isCrashlyticsEnabled: true,
    isAnalyticsEnabled: true,
    isFcmEnabled: true,
    platform: SupportedPlatform.android,
    appVersion: '1.0.0',
    lastStartupTime: DateTime.parse('2026-06-29T00:00:00.000Z'),
  );

  test('fromJson should return a valid model', () {
    final Map<String, dynamic> jsonMap = {
      'id': 'global_config',
      'isFirebaseInitialized': true,
      'isCrashlyticsEnabled': true,
      'isAnalyticsEnabled': true,
      'isFcmEnabled': true,
      'platform': 'android',
      'appVersion': '1.0.0',
      'lastStartupTime': '2026-06-29T00:00:00.000Z',
    };
    final result = AppConfigurationModel.fromJson(jsonMap);
    expect(result.id, tModel.id);
  });

  test('fromRemoteJson should merge shared config with runtime fields', () {
    final result = AppConfigurationModel.fromRemoteJson(
      {
        'id': 'global_config',
        'isFirebaseInitialized': true,
        'isCrashlyticsEnabled': false,
        'isAnalyticsEnabled': true,
        'isFcmEnabled': false,
      },
      platform: SupportedPlatform.android,
      appVersion: '1.0.0',
      lastStartupTime: DateTime.parse('2026-06-29T00:00:00.000Z'),
    );

    expect(result.id, 'global_config');
    expect(result.isCrashlyticsEnabled, isFalse);
    expect(result.platform, SupportedPlatform.android);
    expect(result.appVersion, '1.0.0');
  });

  test('toJson should return a JSON map containing proper data', () {
    final result = tModel.toJson();
    expect(result['id'], 'global_config');
  });
}
