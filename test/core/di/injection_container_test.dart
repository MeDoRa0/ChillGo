import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chillgo/core/di/injection_container.dart' as di;
import 'package:chillgo/core/domain/repositories/config_repository.dart';
import 'package:chillgo/core/domain/repositories/diagnostics_repository.dart';
import 'package:chillgo/features/chat/domain/repositories/chat_repository.dart';
import 'package:chillgo/features/chat/domain/services/chat_clock.dart';
import 'package:chillgo/features/chat/presentation/cubit/chat_summary/chat_summary_cubit.dart';
import 'package:chillgo/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  setUp(() {
    di.sl.reset();
  });

  test('Service Locator should register and resolve repositories', () async {
    final mockPrefs = MockSharedPreferences();
    di.sl.registerSingleton<SharedPreferences>(mockPrefs);
    di.sl.registerLazySingleton<FirebaseFirestore>(
      () => MockFirebaseFirestore(),
    );
    di.sl.registerLazySingleton<FirebaseCrashlytics>(
      () => MockFirebaseCrashlytics(),
    );
    di.sl.registerLazySingleton<FirebaseAnalytics>(
      () => MockFirebaseAnalytics(),
    );
    di.sl.registerLazySingleton<GoogleSignIn>(() => MockGoogleSignIn());

    await di.init();

    final configRepo = di.sl<ConfigRepository>();
    final diagnosticsRepo = di.sl<DiagnosticsRepository>();

    expect(configRepo, isNotNull);
    expect(diagnosticsRepo, isNotNull);
    expect(di.sl.isRegistered<ChatClock>(), isTrue);
    expect(di.sl.isRegistered<ChatRepository>(), isTrue);
    expect(di.sl.isRegistered<OutingChatCubit>(), isTrue);
    expect(di.sl.isRegistered<ChatSummaryCubit>(), isTrue);
  });
}
