import 'package:chillgo/core/data/models/app_configuration_model.dart';
import 'package:chillgo/core/data/repositories/config_repository_impl.dart';
import 'package:chillgo/core/domain/entities/app_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late ConfigRepositoryImpl repository;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    repository = ConfigRepositoryImpl(sharedPreferences: mockSharedPreferences);
  });

  final tConfig = AppConfigurationModel(
    id: 'global_config',
    isFirebaseInitialized: true,
    isCrashlyticsEnabled: true,
    isAnalyticsEnabled: true,
    isFcmEnabled: true,
    platform: SupportedPlatform.android,
    appVersion: '1.0.0',
    lastStartupTime: DateTime.parse('2026-06-29T00:00:00.000Z'),
  );

  test('returns cached configuration when present', () async {
    when(() => mockSharedPreferences.getString(any())).thenReturn(
      '{"id":"global_config","isFirebaseInitialized":true,'
      '"isCrashlyticsEnabled":true,"isAnalyticsEnabled":true,'
      '"isFcmEnabled":true,"platform":"android","appVersion":"1.0.0",'
      '"lastStartupTime":"2026-06-29T00:00:00.000Z"}',
    );

    final result = await repository.getConfiguration();

    expect(result.id, tConfig.id);
    verifyNever(() => mockSharedPreferences.setString(any(), any()));
  });

  test('creates and caches a local default when no cache exists', () async {
    when(() => mockSharedPreferences.getString(any())).thenReturn(null);
    when(
      () => mockSharedPreferences.setString(any(), any()),
    ).thenAnswer((_) async => true);

    final result = await repository.getConfiguration();

    expect(result.id, 'global_config');
    verify(
      () => mockSharedPreferences.setString('CACHED_APP_CONFIGURATION', any()),
    ).called(1);
  });

  test('saves configuration in local preferences', () async {
    when(
      () => mockSharedPreferences.setString(any(), any()),
    ).thenAnswer((_) async => true);

    await repository.saveConfiguration(tConfig);

    final encoded =
        verify(
              () => mockSharedPreferences.setString(
                'CACHED_APP_CONFIGURATION',
                captureAny(),
              ),
            ).captured.single
            as String;
    expect(encoded, contains('"id":"global_config"'));
  });
}
