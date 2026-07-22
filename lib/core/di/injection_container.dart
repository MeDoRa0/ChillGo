import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../features/crews/data/datasources/firestore_crews_datasource.dart';
import '../../features/crews/data/repositories/crew_repository_impl.dart';
import '../../features/crews/domain/repositories/crew_repository.dart';
import '../../features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import '../../features/crews/presentation/blocs/invitations/invitations_cubit.dart';
import '../../features/outings/data/datasources/firestore_outings_datasource.dart';
import '../../features/outings/data/repositories/outing_repository_impl.dart';
import '../../features/outings/domain/repositories/outing_repository.dart';
import '../../features/outings/presentation/cubit/outing_detail/outing_detail_cubit.dart';
import '../../features/outings/presentation/cubit/outing_form/outing_form_cubit.dart';
import '../../features/outings/presentation/cubit/outings_list/outings_list_cubit.dart';
import '../../features/voting/data/datasources/firestore_agreement_datasource.dart';
import '../../features/voting/data/repositories/agreement_repository_impl.dart';
import '../../features/voting/domain/repositories/agreement_repository.dart';
import '../../features/voting/presentation/cubit/agreement_detail/agreement_detail_cubit.dart';
import '../../features/voting/presentation/cubit/agreement_command/agreement_command_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External Services
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(sharedPreferences);
  }

  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  if (!sl.isRegistered<FirebaseStorage>()) {
    sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  }
  if (!sl.isRegistered<GoogleSignIn>()) {
    final googleSignIn = GoogleSignIn.instance;
    if (!kIsWeb) {
      await googleSignIn.initialize();
    }
    sl.registerSingleton<GoogleSignIn>(googleSignIn);
  }
  if (!sl.isRegistered<FirebaseCrashlytics>()) {
    sl.registerLazySingleton<FirebaseCrashlytics>(
      () => FirebaseCrashlytics.instance,
    );
  }
  if (!sl.isRegistered<FirebaseAnalytics>()) {
    sl.registerLazySingleton<FirebaseAnalytics>(
      () => FirebaseAnalytics.instance,
    );
  }

  // Datasources
  if (!sl.isRegistered<FirebaseAuthDatasource>()) {
    sl.registerLazySingleton<FirebaseAuthDatasource>(
      () => FirebaseAuthDatasource(firebaseAuth: sl(), googleSignIn: sl()),
    );
  }
  if (!sl.isRegistered<FirestoreProfileDatasource>()) {
    sl.registerLazySingleton<FirestoreProfileDatasource>(
      () => FirestoreProfileDatasource(firestore: sl(), storage: sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<ConfigRepository>()) {
    sl.registerLazySingleton<ConfigRepository>(
      () => ConfigRepositoryImpl(sharedPreferences: sl(), firestore: sl()),
    );
  }
  if (!sl.isRegistered<DiagnosticsRepository>()) {
    sl.registerLazySingleton<DiagnosticsRepository>(
      () => DiagnosticsRepositoryImpl(
        crashlytics: isCrashlyticsSupportedPlatform
            ? sl<FirebaseCrashlytics>()
            : null,
        analytics: isAnalyticsSupportedPlatform
            ? sl<FirebaseAnalytics>()
            : null,
      ),
    );
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(authDatasource: sl(), profileRepository: sl()),
    );
  }
  if (!sl.isRegistered<ProfileRepository>()) {
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(profileDatasource: sl()),
    );
  }

  // Crew Feature
  if (!sl.isRegistered<FirestoreCrewsDatasource>()) {
    sl.registerLazySingleton<FirestoreCrewsDatasource>(
      () => FirestoreCrewsDatasource(firestore: sl()),
    );
  }
  if (!sl.isRegistered<CrewRepository>()) {
    sl.registerLazySingleton<CrewRepository>(
      () => CrewRepositoryImpl(
        datasource: sl<FirestoreCrewsDatasource>(),
        currentUid: () => sl<AuthRepository>().currentCredentials?.uid ?? '',
      ),
    );
  }
  if (!sl.isRegistered<FirestoreOutingsDatasource>()) {
    sl.registerLazySingleton<FirestoreOutingsDatasource>(
      () => FirestoreOutingsDatasource(firestore: sl()),
    );
  }
  if (!sl.isRegistered<OutingRepository>()) {
    sl.registerLazySingleton<OutingRepository>(
      () => OutingRepositoryImpl(
        datasource: sl<FirestoreOutingsDatasource>(),
        currentUid: () => sl<AuthRepository>().currentCredentials?.uid ?? '',
        agreementCancel: (outingId, reason) async {
          await sl<AgreementRepository>().cancelOuting(outingId, reason);
        },
        agreementDelete: (outingId) async {
          await sl<AgreementRepository>().deleteOuting(outingId);
        },
        agreementExpiryCleanup: (outingId) async {
          await sl<AgreementRepository>().requestOutingExpiry(outingId);
        },
      ),
    );
  }
  if (!sl.isRegistered<FirestoreAgreementDatasource>()) {
    sl.registerLazySingleton(
      () => FirestoreAgreementDatasource(firestore: sl()),
    );
  }
  if (!sl.isRegistered<AgreementRepository>()) {
    sl.registerLazySingleton<AgreementRepository>(
      () => AgreementRepositoryImpl(
        datasource: sl(),
        currentUid: () => sl<AuthRepository>().currentCredentials?.uid ?? '',
      ),
    );
  }

  // Blocs & Cubits
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(authRepository: sl()));
  }
  if (!sl.isRegistered<OnboardingCubit>()) {
    sl.registerFactory(
      () => OnboardingCubit(profileRepository: sl(), authRepository: sl()),
    );
  }
  if (!sl.isRegistered<ProfileCubit>()) {
    sl.registerFactory(() => ProfileCubit(profileRepository: sl()));
  }
  if (!sl.isRegistered<CrewsListCubit>()) {
    sl.registerFactory(() => CrewsListCubit(crewRepository: sl()));
  }
  if (!sl.isRegistered<InvitationsCubit>()) {
    sl.registerFactory(() => InvitationsCubit(crewRepository: sl()));
  }
  if (!sl.isRegistered<OutingsListCubit>()) {
    sl.registerFactory(() => OutingsListCubit(outingRepository: sl()));
  }
  if (!sl.isRegistered<OutingDetailCubit>()) {
    sl.registerFactory(() => OutingDetailCubit(outingRepository: sl()));
  }
  if (!sl.isRegistered<OutingFormCubit>()) {
    sl.registerFactory(() => OutingFormCubit(outingRepository: sl()));
  }
  if (!sl.isRegistered<AgreementDetailCubit>()) {
    sl.registerFactory(() => AgreementDetailCubit(repository: sl()));
  }
  if (!sl.isRegistered<AgreementCommandCubit>()) {
    sl.registerFactory(() => AgreementCommandCubit(repository: sl()));
  }

  // Global Error Handler
  if (!sl.isRegistered<GlobalErrorHandler>()) {
    sl.registerLazySingleton<GlobalErrorHandler>(
      () => GlobalErrorHandler(diagnosticsRepository: sl()),
    );
  }
}
