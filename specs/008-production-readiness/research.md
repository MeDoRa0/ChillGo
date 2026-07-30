# Research: Production Readiness

## Repeatable release evidence

**Decision**: Keep one candidate-evidence document per immutable app version/build and require two consecutive complete automated validation runs before approval.

**Rationale**: A single green run cannot distinguish a release candidate from a flaky test environment and does not satisfy SC-001.

**Alternatives considered**: Informal release notes are not auditable; a new Firestore collection would add access and retention risk without improving approval evidence.

## Privacy-safe Firebase observability

**Decision**: Retain the installed Firebase Analytics and Crashlytics packages behind `DiagnosticsRepository`. Add an allowlist of aggregate MVP journey events and sanitize diagnostics before sending them. Reports carry only release version, Android/iOS client type, and controlled failure category.

**Rationale**: The project already initializes these providers. A fixed schema permits health monitoring without collecting chat, location, votes, device tokens, credentials, or arbitrary exception text.

**Alternatives considered**: Free-form logging risks private-data disclosure; adding a different telemetry provider expands the privacy and operational scope.

## Android and iOS release identity and signing

**Decision**: Replace the placeholder `com.example.chillgo` package/bundle IDs with the final reverse-domain ID before any production upload. Use a signed Android App Bundle with Play App Signing and an externally stored upload key; configure matching iOS bundle ID, production Firebase app, App Store signing, APNs, and required symbols.

**Rationale**: The current Android release build uses debug signing and both platforms use placeholder identity, which blocks public distribution. Package/bundle IDs are effectively permanent after the first upload.

**Alternatives considered**: Committing keys is unsafe; retaining development identity/debug signing is not store-ready.

## Practical staged first release

**Decision**: Use invited Android/iOS beta cohorts representing 10% then 50% of the intended initial tester audience before a 100% public store release. Later Android updates use Play staged percentage rollout; later iOS updates use Apple phased release and manual promotion review.

**Rationale**: Exact public 10/50 percentage rollout is not a first-release capability on both stores. Controlled beta cohorts give a new publisher the same blast-radius control and release evidence without making an unsupported platform promise.

**Alternatives considered**: Immediate public release exposes all users before operational evidence; pretending a platform-native percentage control exists would make the checklist misleading.

## Sources

- [Flutter testing overview](https://docs.flutter.dev/testing/overview)
- [Firebase Crashlytics for Flutter](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter)
- [Firebase Analytics events](https://firebase.google.com/docs/analytics/events)
- [Google Play App Bundles](https://support.google.com/googleplay/android-developer/answer/9844679)
- [Google Play staged rollouts](https://support.google.com/googleplay/android-developer/answer/6346149)
- [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [App Store privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Store phased release](https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases)
