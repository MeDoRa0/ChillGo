import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../domain/repositories/config_repository.dart';
import '../domain/repositories/diagnostics_repository.dart';
import '../data/repositories/config_repository_impl.dart';
import '../data/repositories/diagnostics_repository_impl.dart';
import '../error/global_error_handler.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External Services
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(sharedPreferences);
  }
  
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  }
  if (!sl.isRegistered<FirebaseCrashlytics>()) {
    sl.registerLazySingleton<FirebaseCrashlytics>(() => FirebaseCrashlytics.instance);
  }
  if (!sl.isRegistered<FirebaseAnalytics>()) {
    sl.registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance);
  }

  // Repositories
  if (!sl.isRegistered<ConfigRepository>()) {
    sl.registerLazySingleton<ConfigRepository>(
      () => ConfigRepositoryImpl(
        sharedPreferences: sl(),
        firestore: sl(),
      ),
    );
  }
  if (!sl.isRegistered<DiagnosticsRepository>()) {
    sl.registerLazySingleton<DiagnosticsRepository>(
      () => DiagnosticsRepositoryImpl(
        crashlytics: sl(),
        analytics: sl(),
      ),
    );
  }

  // Global Error Handler
  if (!sl.isRegistered<GlobalErrorHandler>()) {
    sl.registerLazySingleton<GlobalErrorHandler>(
      () => GlobalErrorHandler(diagnosticsRepository: sl()),
    );
  }
}
