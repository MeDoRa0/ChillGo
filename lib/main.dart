import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart' as di;
import 'core/presentation/theme/chillgo_theme.dart';
import 'core/routes/app_router.dart';
import 'core/error/global_error_handler.dart';
import 'features/authentication/presentation/blocs/auth/auth_bloc.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/live_meetup/data/services/live_location_sharing_coordinator.dart';
import 'features/notifications/data/services/notification_session_coordinator.dart';
import 'features/notifications/domain/entities/device_alert.dart';
import 'features/notifications/domain/entities/notification.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/presentation/notification_navigation.dart';
import 'dart:async';

const _useFirebaseEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // The OS displays the generic provider alert. Navigation and protected reads
  // occur only after the user opens the app and the repository reauthorizes it.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (_useFirebaseEmulators) {
      await _connectFirebaseEmulators();
    }

    // Initialize Service Locator
    await di.init();

    // Initialize Global Error Handler – now safe, DI is ready
    di.sl<GlobalErrorHandler>().initialize();
  } catch (error, stack) {
    // Bootstrap failed before GlobalErrorHandler was installed.
    // Log via the Flutter framework error pipeline as a best-effort fallback.
    debugPrint('[ChillGo] Fatal bootstrap error: $error\n$stack');
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    // Rethrow so the process terminates and the crash is surfaced.
    rethrow;
  }

  runApp(const MyApp());
}

Future<void> _connectFirebaseEmulators() async {
  final host = defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthStatus>? _authSubscription;
  StreamSubscription<DeviceAlertEvent>? _foregroundAlertSubscription;
  StreamSubscription<NotificationOpenResult>? _openedAlertSubscription;

  @override
  void initState() {
    super.initState();
    final coordinator = di.sl<LiveLocationSharingCoordinator>();
    final notificationCoordinator = di.sl<NotificationSessionCoordinator>();
    _foregroundAlertSubscription = notificationCoordinator.foregroundAlerts
        .listen(_showForegroundAlert);
    _openedAlertSubscription = notificationCoordinator.openedNotifications
        .listen(_navigateToNotificationTarget);
    _authSubscription = di.sl<AuthRepository>().status.listen((status) {
      if (status == AuthStatus.unauthenticated) {
        unawaited(coordinator.clearLocalSessions());
        unawaited(notificationCoordinator.clearLocalSession());
      } else if (status == AuthStatus.authenticatedNoProfile ||
          status == AuthStatus.authenticatedWithProfile) {
        unawaited(notificationCoordinator.start());
      }
    });
    final currentStatus = di.sl<AuthRepository>().currentStatus;
    if (currentStatus == AuthStatus.authenticatedNoProfile ||
        currentStatus == AuthStatus.authenticatedWithProfile) {
      unawaited(notificationCoordinator.start());
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_foregroundAlertSubscription?.cancel());
    unawaited(_openedAlertSubscription?.cancel());
    super.dispose();
  }

  void _showForegroundAlert(DeviceAlertEvent event) {
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('You have a new ChillGo notification.'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () async {
            final result = await di.sl<NotificationRepository>().open(
              event.notificationId,
            );
            _navigateToNotificationTarget(result);
          },
        ),
      ),
    );
  }

  void _navigateToNotificationTarget(NotificationOpenResult result) {
    final target = result.target;
    if (target == null) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('This notification is no longer available.'),
        ),
      );
      return;
    }
    final route = notificationRoute(target);
    if (route != null) appRouter.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'ChillGo',
        debugShowCheckedModeBanner: false,
        theme: ChillGoTheme.sunshine,
        scaffoldMessengerKey: _messengerKey,
        routerConfig: appRouter,
      ),
    );
  }
}
