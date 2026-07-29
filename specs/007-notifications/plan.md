# Implementation Plan: Notifications

**Branch**: `codex/007-notifications` | **Date**: 2026-07-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from [spec.md](./spec.md)

## Summary

Phase 7 adds a recipient-private notification center and best-effort device alerts for crew invitations, outing invitations, agreement activity, material outing changes, and a first arrival in Meeting. A trusted, idempotent outbox converts authoritative source changes into one record per eligible recipient. A separate worker revalidates access and preferences before fanning generic alerts to every currently registered, permission-granted Android, iOS, or Web target. Windows retains the full center and preferences but intentionally has no device-alert adapter.

Notification state is isolated in `notifications`; Flutter uses repository, device-alert, and transition interfaces. Existing direct source writes receive narrow Firestore-event adapters, while trusted Agreement and Live Meetup transactions create their outbox events atomically. Access loss is fail-closed in Rules immediately, followed by resumable delete-before-finalize cleanup. Exactly-once center records are required; platform alert delivery is best effort and can be delayed or duplicated.

## Technical Context

**Language/Version**: Dart 3.12.2 with Flutter; TypeScript 5.8.3 on Node.js 22 for Cloud Functions

**Primary Dependencies**: Existing `cloud_firestore: ^6.6.0`, `firebase_auth: ^6.5.4`, `firebase_core: ^4.11.0`, `cloud_functions: ^6.3.5`, `firebase_messaging: ^16.4.1`, `flutter_bloc: ^9.1.1`, `go_router: ^17.3.0`, `get_it: ^9.2.1`, and `equatable: ^2.1.0`; Functions use `firebase-functions: ^6.4.0` v2 APIs and `firebase-admin: ^13.4.0`.

**Storage**: Existing users, crews, memberships, invitations, outings, participants, agreement records, and live-meetup status; new `notifications`, `notification_summaries`, `notification_preferences`, `notification_devices`, short-lived `notification_commands`, trusted `notification_events`, recipient work, and resumable notification transitions. TTL policies cover backstop retention and short-lived work; scheduled cleanup enforces the product boundary.

**Testing**: `flutter_test`, `bloc_test`, `mocktail`; Functions TypeScript/Mocha unit and emulator integration tests; Firestore Rules emulator tests; Android/iOS/Web delivery smoke checks and Windows in-app fallback smoke check. Manual device-push validation requires user approval.

**Target Platform**: One Flutter codebase for Android, iOS, Web, and Windows. Notification center/preferences run everywhere; Firebase Messaging delivery runs only on Android, iOS, and Web behind a capability-safe adapter.

**Project Type**: Multi-platform Flutter application with Firestore and serverless Functions

**Performance Goals**: Meet SC-001 through SC-008: 95% of in-app records available within 5 seconds under the stated network profile; 95% of enabled supported-device alert attempts handed to the platform within 10 seconds; stable private pagination and unread state; zero authorization or duplicate-record failures in validation matrices.

**Constraints**: Source actions are authoritative before notification creation. Records are recipient-private, minimal, newest-first, expire exactly 30 days after creation, and are immediately denied and physically removed on source access loss. Server code revalidates recipient/preference before record creation and delivery. Raw device tokens are never exposed to the center. Device payloads contain generic copy plus an opaque notification ID. FCM is not delivery/read proof and is unavailable on Windows. TTL is never relied upon for timely expiry.

**Scale/Scope**: Seven source categories, one record per recipient and authoritative event, 30-day retention, newest-first pages of 50, up to 10 active alert registrations per user, 100-recipient outing fan-out, and provider sends batched at up to 500 targets.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First and Clean Architecture)**: PASS. Production code is isolated under `lib/features/notifications/{domain,data,presentation}`. Shared changes are limited to source lifecycle integration, DI, routes, bootstrap, platform config, Functions, Rules, indexes, and outing deletion.
- **Principle II (Crew-First Interaction Model)**: PASS. Every category is crew-owned and category-specific recipient authorization rechecks membership, participation, attendance, Meeting status, or invitation ownership. No social graph or activity feed is introduced.
- **Principle III (Decoupled Provider Interfaces)**: PASS. Cubits depend on `NotificationRepository`, `DeviceAlertService`, and `NotificationTransitionService`; Firestore, Messaging, permissions, and tokens remain in data/platform adapters. Windows has an unsupported adapter.
- **Principle IV (Mandatory Automated Testing)**: PASS. Domain, repository, Cubit, widget, Function, idempotency, cleanup, and Rules coverage are mandatory. Device push tests are explicit user-approved deployment smoke checks.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. Notification records have a 30-day product boundary enforced by trusted cleanup and TTL recovery. Phase 7 stores no precise location or presence data and retains existing live-data cleanup.
- **Architecture & Platform Constraints**: PASS. Trusted Functions own recipient fan-out, summary mutation, token handling, and cleanup; Rules are the immediate source-aware access boundary.
- **Development Workflow**: PASS. Work remains on `codex/007-notifications`, documentation links are repo-relative, model/contracts precede Cubits and UI, and manual E2E validation requires explicit approval.

## Project Structure

### Documentation (this feature)

```text
specs/007-notifications/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- notification_processing.md
|   |-- notification_repository.md
|   `-- firestore_rules.md
`-- tasks.md                 # Created later by /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/notifications/
|-- data/
|   |-- datasources/firestore_notifications_datasource.dart
|   |-- models/
|   |-- repositories/notification_repository_impl.dart
|   `-- services/
|       |-- firebase_messaging_device_alert_service.dart
|       |-- unsupported_device_alert_service.dart
|       `-- firestore_notification_transition_service.dart
|-- domain/
|   |-- entities/
|   |-- repositories/notification_repository.dart
|   `-- services/
|       |-- device_alert_service.dart
|       `-- notification_transition_service.dart
`-- presentation/
    |-- cubit/
    |-- screens/
    `-- widgets/

functions/src/notifications/
|-- cleanup.ts
|-- command_handler.ts
|-- command_schema.ts
|-- delivery.ts
|-- eligibility.ts
|-- event_handler.ts
|-- notification_transactions.ts
`-- transition_handler.ts

functions/src/{index.ts,agreement/agreement_transactions.ts,live_meetup/live_meetup_transactions.ts,outings/outing_deletion.ts}
test/features/notifications/
functions/test/notifications/
firestore_tests/rules.test.js
firestore.rules
firestore.indexes.json
firebase.json
android/app/src/main/AndroidManifest.xml
ios/Runner/{Info.plist,Runner.entitlements}
web/{index.html,firebase-messaging-sw.js}
lib/{main.dart,core/di/injection_container.dart,core/routes/app_router.dart}
lib/features/home/presentation/widgets/home_mobile_layout.dart
```

**Structure Decision**: The dedicated `notifications` feature owns notification-specific models, contracts, adapters, Cubits, and UI. Trusted Functions own event processing, source/recipient authorization, summary mutation, fan-out, delivery, expiry, and cleanup. Existing source features only emit events or invoke notification lifecycle cleanup. This maintains exactly-once records despite at-least-once function delivery and keeps FCM types/tokens outside domain code.

## Complexity Tracking

No constitution violations require justification. Notification lifecycle cleanup extends existing source transitions because trigger-only deletion cannot fulfil immediate, access-safe physical removal; the provider-neutral interface remains owned by `notifications`.

## Phase 0: Research

Research decisions and alternatives are recorded in [research.md](./research.md). All technical unknowns are resolved.

## Phase 1: Design & Contracts

Design outputs:

- [data-model.md](./data-model.md)
- [contracts/notification_processing.md](./contracts/notification_processing.md)
- [contracts/notification_repository.md](./contracts/notification_repository.md)
- [contracts/firestore_rules.md](./contracts/firestore_rules.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Principle I**: PASS. `notifications` contains notification contracts, adapters, Cubits, and UI; cross-feature changes only emit events or coordinate lifecycle cleanup.
- **Principle II**: PASS. Recipient checks re-evaluate the current crew/outing/invitation state, and generic alerts create no public interaction surface.
- **Principle III**: PASS. Messaging, permission, and Firestore types remain in adapters; Windows capability is a domain result rather than a UI platform branch.
- **Principle IV**: PASS. The quickstart requires focused/full Flutter, Functions, Rules, race, and user-approved device-delivery validation.
- **Principle V**: PASS. Trusted-time filtering, scheduled cleanup, and Rules enforce product expiry before asynchronous TTL. Records exclude live location and presence data.
- **Architecture & Platform Constraints**: PASS. Functions serialize sensitive fan-out/cleanup and Rules provide immediate denial. Android/iOS/Web setup is explicit; Windows uses the secure in-app fallback.
