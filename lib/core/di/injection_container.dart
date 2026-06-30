import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../domain/repositories/config_repository.dart';
import '../domain/repositories/diagnostics_repository.dart';
import '../data/repositories/config_repository_impl.dart';
import '../data/repositories/diagnostics_repository_impl.dart';
import '../error/global_error_handler.dart';

// Feature Imports
import '../../features/authentication/data/datasources/firebase_auth_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/blocs/auth/auth_bloc.dart';
import '../../features/profile/data/datasources/firestore_profile_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/blocs/onboarding/onboarding_cubit.dart';
import '../../features/profile/presentation/blocs/profile/profile_cubit.dart';

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
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  if (!sl.isRegistered<FirebaseStorage>()) {
    sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  }
  if (!sl.isRegistered<GoogleSignIn>()) {
    sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  }
  if (!sl.isRegistered<FirebaseCrashlytics>()) {
    sl.registerLazySingleton<FirebaseCrashlytics>(() => FirebaseCrashlytics.instance);
  }
  if (!sl.isRegistered<FirebaseAnalytics>()) {
    sl.registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance);
  }

  // Datasources
  if (!sl.isRegistered<FirebaseAuthDatasource>()) {
    sl.registerLazySingleton<FirebaseAuthDatasource>(
      () => FirebaseAuthDatasource(
        firebaseAuth: sl(),
        googleSignIn: sl(),
      ),
    );
  }
  if (!sl.isRegistered<FirestoreProfileDatasource>()) {
    sl.registerLazySingleton<FirestoreProfileDatasource>(
      () => FirestoreProfileDatasource(
        firestore: sl(),
        storage: sl(),
      ),
    );
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
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        authDatasource: sl(),
        profileRepository: sl(),
      ),
    );
  }
  if (!sl.isRegistered<ProfileRepository>()) {
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        profileDatasource: sl(),
      ),
    );
  }

  // Blocs & Cubits
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(authRepository: sl()));
  }
  if (!sl.isRegistered<OnboardingCubit>()) {
    sl.registerFactory(() => OnboardingCubit(profileRepository: sl(), authRepository: sl()));
  }
  if (!sl.isRegistered<ProfileCubit>()) {
    sl.registerFactory(() => ProfileCubit(profileRepository: sl()));
  }

  // Global Error Handler
  if (!sl.isRegistered<GlobalErrorHandler>()) {
    sl.registerLazySingleton<GlobalErrorHandler>(
      () => GlobalErrorHandler(diagnosticsRepository: sl()),
    );
  }
}
