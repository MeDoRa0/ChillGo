# Implementation Plan: Production Readiness

**Branch**: `codex/008-production-readiness` | **Date**: 2026-07-29 | **Spec**: [spec.md](./spec.md)

## Summary

Phase 8 makes the existing MVP releasable on Android and iOS. It establishes repeatable automated quality gates, completes the security and end-to-end validation matrix, hardens the existing Firebase Analytics/Crashlytics diagnostics against privacy leakage, measures core performance, and prepares signed mobile store packages and controlled release operations. It verifies Phases 0-7, including Notifications, as completed prerequisites and does not add new end-user capabilities.

For the first release, the 10% and 50% stages are controlled Android/iOS beta cohorts, followed by a 100% public store release. This is the safest equivalent of a staged launch: neither store provides an exact percentage-based public rollout for a brand-new app. Android updates can use Play staged rollout; iOS updates can use Apple's phased release.

## Technical Context

**Language/Version**: Dart 3.12.2 with Flutter; TypeScript 5.8.3 on Node.js 22 for Cloud Functions.

**Primary Dependencies**: Existing Firebase Core, Auth, Firestore, Storage, Functions, Messaging, App Check, Analytics, and Crashlytics; `flutter_bloc`, `go_router`, `get_it`, and `equatable`.

**Storage**: Existing Firestore MVP collections; Firebase Crashlytics reports and Firebase Analytics aggregate events. Release evidence is version-controlled documentation, not a new client-accessible Firestore collection.

**Testing**: `flutter analyze`, `flutter test`, Android/iOS `integration_test`, Mocha/TypeScript Functions tests, Firebase Emulator Rules/integration tests, and deterministic release-performance runs. Physical-device and store checks require approval.

**Target Platform**: Android and iOS public distribution. Web and Windows remain development-supported but deferred from this release.

**Project Type**: Flutter mobile application with Firebase serverless backend.

**Performance Goals**: Meet SC-003 and SC-006 under one documented launch network profile: 95% of each primary journey completes without unhandled error across 100 trials; p95 of specified usable views is at most 3 seconds; first launch supports up to 1,000 MAU.

**Constraints**: Two consecutive complete clean candidate runs; 99.5% crash-free production sessions in the first 30 days; no critical/high security, privacy, data-loss, or core-workflow defect; telemetry must exclude product-private content; store actions need explicit approval.

**Scale/Scope**: All MVP features, Android/iOS only, beta cohorts at 10% and 50%, then public 100% availability. Android/iOS update rollouts use their native staged/phased facilities.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First and Clean Architecture)**: PASS. Core diagnostics remain behind existing domain interfaces; changes to features are test coverage and safe error handling only.
- **Principle II (Crew-First Interaction Model)**: PASS. No contacts, direct messages, social graph, feed, or marketing workflow is introduced.
- **Principle III (Decoupled Provider Interfaces)**: PASS. Firebase Analytics and Crashlytics remain data-layer adapters of `DiagnosticsRepository`.
- **Principle IV (Mandatory Automated Testing)**: PASS. Unit, interface/widget, integration, Functions, and Rules validation become candidate gates.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. Existing chat/live-meetup/notification retention tests remain required; release telemetry captures no protected content.
- **Architecture & Platform Constraints**: PASS. Android/iOS signing/configuration is platform-scoped; core behavior and fallbacks remain cross-platform.
- **Development Workflow**: PASS. Manual physical-device, beta, store, and public-release activities are explicitly approval-gated.

## Project Structure

### Documentation

```text
specs/008-production-readiness/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- quality_gates.md
|   |-- telemetry_privacy.md
|   `-- release_operations.md
`-- tasks.md                 # Created later by /speckit-tasks
```

### Source and release work

```text
lib/core/{data,domain,error}/
lib/main.dart
test/{core,features}/
integration_test/
functions/{src,test}/
firestore_tests/rules.test.js
android/app/{build.gradle.kts,src/main/AndroidManifest.xml}
ios/Runner/{Info.plist,Runner.entitlements}
.github/workflows/
docs/release/
firebase.json
firestore.rules
```

**Structure Decision**: Preserve the current feature-first app and Functions layout. Phase 8 adds narrow diagnostics/error-sanitization changes, test harnesses, mobile release configuration, CI, and repository release/runbook documents. Signing keys, tokens, store credentials, and user evidence remain external secrets.

## Complexity Tracking

No constitution violations require justification. Version-controlled aggregate release evidence is preferred over a new production collection because it is auditable without adding a user-data surface.

## Phase 0: Research

Research decisions and alternatives are recorded in [research.md](./research.md).

## Phase 1: Design and Contracts

- [data-model.md](./data-model.md)
- [contracts/quality_gates.md](./contracts/quality_gates.md)
- [contracts/telemetry_privacy.md](./contracts/telemetry_privacy.md)
- [contracts/release_operations.md](./contracts/release_operations.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Principle I**: PASS. Changes are isolated to core diagnostics, tests, and release support.
- **Principle II**: PASS. Aggregate diagnostics create no interaction model.
- **Principle III**: PASS. Provider dependencies remain behind interfaces.
- **Principle IV**: PASS. Contracts require reproducible automated evidence.
- **Principle V**: PASS. Private data is prohibited from operational signals and existing lifecycle boundaries are retained.
- **Architecture & Platform Constraints**: PASS. Production Android/iOS setup is separate from platform-neutral application behavior.
