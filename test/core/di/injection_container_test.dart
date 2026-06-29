import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chillgo/core/di/injection_container.dart' as di;
import 'package:chillgo/core/domain/repositories/config_repository.dart';
import 'package:chillgo/core/domain/repositories/diagnostics_repository.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}
class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  setUp(() {
    di.sl.reset();
  });

  test('Service Locator should register and resolve repositories', () async {
    final mockPrefs = MockSharedPreferences();
    di.sl.registerSingleton<SharedPreferences>(mockPrefs);
    di.sl.registerLazySingleton<FirebaseFirestore>(() => MockFirebaseFirestore());
    di.sl.registerLazySingleton<FirebaseCrashlytics>(() => MockFirebaseCrashlytics());
    di.sl.registerLazySingleton<FirebaseAnalytics>(() => MockFirebaseAnalytics());

    await di.init();
    
    final configRepo = di.sl<ConfigRepository>();
    final diagnosticsRepo = di.sl<DiagnosticsRepository>();
    
    expect(configRepo, isNotNull);
    expect(diagnosticsRepo, isNotNull);
  });
}
