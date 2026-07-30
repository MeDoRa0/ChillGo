# Environment and secret inventory

Release owner: **TBD before any store upload**. Store accounts and external
Android upload key / Apple signing ownership: **TBD and kept outside this repo**.

The permanent Android application ID is `com.chillgo.app`. The iOS identity
remains deferred until macOS signing work starts. Android release signing reads
an ignored `android/key.properties` file or these CI environment variables:
`CHILLGO_UPLOAD_KEYSTORE`, `CHILLGO_UPLOAD_STORE_PASSWORD`,
`CHILLGO_UPLOAD_KEY_ALIAS`, and `CHILLGO_UPLOAD_KEY_PASSWORD`. A release build
fails instead of falling back to the debug key when these values are absent.

Environments: local emulator, non-production Firebase validation, and
production Firebase. Firebase client identifiers are public metadata, but the
production-bound `google-services.json`, `GoogleService-Info.plist`, and
`firebase_options.dart` files remain untracked because this is a public
repository. Contributors generate them for a Firebase project they control.
Firebase Security Rules and App Check protect backend resources; hiding client
configuration is not an access-control mechanism.

Secrets include Firebase service-account credentials, Play upload keys, App
Store credentials, APNs credentials, Maps keys, and CI secrets. None may be
committed.
