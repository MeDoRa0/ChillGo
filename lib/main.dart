import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_router.dart';
import 'core/error/global_error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

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
