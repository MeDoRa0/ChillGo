import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_router.dart';
import 'core/error/global_error_handler.dart';

const _useFirebaseEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChillGo',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      ),
      routerConfig: appRouter,
    );
  }
}
