// Non-production placeholders for compile-only CI checks.
// Run `flutterfire configure` to generate a usable local firebase_options.dart.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.windows => windows,
      _ => throw UnsupportedError(
        'Firebase placeholders are unavailable for this platform.',
      ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'replace-with-local-firebase-api-key',
    appId: '1:000000000000:web:replace-with-local-app-id',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-local-project-id',
    authDomain: 'replace-with-local-project-id.firebaseapp.com',
    storageBucket: 'replace-with-local-project-id.firebasestorage.app',
    measurementId: 'G-REPLACE-ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'replace-with-local-firebase-api-key',
    appId: '1:000000000000:android:replace-with-local-app-id',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-local-project-id',
    storageBucket: 'replace-with-local-project-id.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'replace-with-local-firebase-api-key',
    appId: '1:000000000000:ios:replace-with-local-app-id',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-local-project-id',
    storageBucket: 'replace-with-local-project-id.firebasestorage.app',
    iosBundleId: 'com.example.chillgo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'replace-with-local-firebase-api-key',
    appId: '1:000000000000:web:replace-with-local-app-id',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-local-project-id',
    authDomain: 'replace-with-local-project-id.firebaseapp.com',
    storageBucket: 'replace-with-local-project-id.firebasestorage.app',
    measurementId: 'G-REPLACE-ME',
  );
}
