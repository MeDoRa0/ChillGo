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
import 'package:chillgo/features/live_meetup/domain/repositories/live_meetup_repository.dart';
import 'package:chillgo/features/live_meetup/domain/services/device_location_service.dart';
import 'package:chillgo/features/live_meetup/domain/services/live_meetup_transition_service.dart';
import 'package:chillgo/features/live_meetup/domain/services/map_provider.dart';
import 'package:chillgo/features/live_meetup/domain/services/trusted_clock.dart';
import 'package:chillgo/features/live_meetup/data/services/live_location_sharing_coordinator.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/live_meetup/live_meetup_cubit.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/location_sharing/location_sharing_cubit.dart';
import 'package:chillgo/features/live_meetup/presentation/cubit/meetup_point_editor/meetup_point_editor_cubit.dart';

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
    expect(di.sl.isRegistered<TrustedClock>(), isTrue);
    expect(di.sl.isRegistered<LiveMeetupRepository>(), isTrue);
    expect(di.sl.isRegistered<LiveMeetupTransitionService>(), isTrue);
    expect(di.sl.isRegistered<DeviceLocationService>(), isTrue);
    expect(di.sl.isRegistered<LiveLocationSharingCoordinator>(), isTrue);
    expect(di.sl.isRegistered<MapProvider>(), isTrue);
    expect(di.sl.isRegistered<LiveMeetupCubit>(), isTrue);
    expect(di.sl.isRegistered<LocationSharingCubit>(), isTrue);
    expect(di.sl.isRegistered<MeetupPointEditorCubit>(), isTrue);
  });
}
