import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chillgo/core/domain/entities/app_configuration.dart';
import 'package:chillgo/core/data/repositories/config_repository_impl.dart';
import 'package:chillgo/core/data/models/app_configuration_model.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late ConfigRepositoryImpl repository;
  late MockSharedPreferences mockSharedPreferences;
  late MockFirebaseFirestore mockFirebaseFirestore;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockFirebaseFirestore = MockFirebaseFirestore();
    repository = ConfigRepositoryImpl(
      sharedPreferences: mockSharedPreferences,
      firestore: mockFirebaseFirestore,
    );
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

  test('should return cached configuration when present', () async {
    when(() => mockSharedPreferences.getString(any())).thenReturn(
      '{"id":"global_config","isFirebaseInitialized":true,"isCrashlyticsEnabled":true,"isAnalyticsEnabled":true,"isFcmEnabled":true,"platform":"android","appVersion":"1.0.0","lastStartupTime":"2026-06-29T00:00:00.000Z"}',
    );

    final result = await repository.getConfiguration();

    expect(result.id, tConfig.id);
  });
}
