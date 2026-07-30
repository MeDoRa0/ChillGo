# ChillGo

ChillGo is a Flutter application backed by Firebase.

## Local Firebase setup

Production Firebase client configuration is intentionally excluded from this
public repository. After installing the
[FlutterFire CLI](https://firebase.google.com/docs/flutter/setup), configure
the app against a Firebase project that you control:

```sh
flutter pub get
flutterfire configure
git restore firebase.json
```

The command must create these ignored local files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist` when configuring iOS

The final `git restore` keeps the repository's provider-neutral Firebase
emulator and deployment settings after FlutterFire records local app IDs.

The adjacent `.example` Firebase files contain non-production placeholders used
only to compile CI checks. They do not connect to a usable Firebase backend.

Local Google Maps SDK keys belong in:

- `android/maps-secrets.properties`
- `ios/Flutter/GoogleMapsSecrets.xcconfig`

Do not commit production client configuration, service-account files, signing
keys, tokens, or store credentials.
