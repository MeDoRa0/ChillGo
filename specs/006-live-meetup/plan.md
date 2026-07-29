# Implementation Plan: Live Meetup

**Branch**: `codex/006-live-meetup` | **Date**: 2026-07-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from [spec.md](./spec.md)

## Summary

Phase 6 adds a Meeting-only coordination space for Accepted outing participants: one explicit current arrival status per attendee, opt-in foreground-only live location sharing, a shared meetup point and map, and a complete textual alternative. Flutter production code will live in `lib/features/live_meetup/` behind provider-neutral repository, location, map-search, trusted-clock, and privacy-transition interfaces. Clients submit status, sharing, location, stop, meetup-point, and privacy-transition attempts through online-only Firestore transactions; Node.js 22/TypeScript Functions revalidate eligibility, serialize session/control watermarks, reject stale or transferred-device updates, and replace the single current status/location documents idempotently.

`geolocator` supplies foreground location fixes on Android and iOS. The official Google Maps Flutter renderer and a Google Geocoding adapter provide map and search behavior on both supported targets; no provider type reaches the domain or Cubit contracts. Sharing credentials live only in the active application process. Backgrounding pauses the position stream, foregrounding the same process may resume it, and a restarted process must explicitly start or transfer again. A location command's Rules-validated `createdAt` is its one authoritative `acceptedAt`, and visibility ends exactly two minutes later without extension from processing or display delay. Outing completion, Accepted-attendance loss, and participant/membership removal use a trusted, resumable privacy-transition coordinator that denies access, deletes affected status/share/location records, and only then finalizes and acknowledges the transition; event triggers, minutely repair, deletion sweeps, and TTL remain recovery layers.

## Technical Context

**Language/Version**: Dart 3.12.2 with Flutter SDK; TypeScript 5.8.3 on Node.js 22 for Cloud Functions

**Primary Dependencies**: Existing `cloud_firestore: ^6.6.0`, `firebase_auth: ^6.5.4`, `firebase_core: ^4.11.0`, `flutter_bloc: ^9.1.1`, `go_router: ^17.3.0`, `get_it: ^9.2.1`, `equatable: ^2.1.0`, and `crypto: ^3.0.0`; add `geolocator: ^14.0.3`, `google_maps_flutter: ^2.18.0`, and `http: ^1.6.0`. Functions continue using `firebase-functions: ^6.4.0` v2 APIs and `firebase-admin: ^13.4.0`.

**Storage**: Existing top-level `outings`, `outing_participants`, `crew_memberships`, `crews`, and `users`; new top-level `live_meetup_statuses`, `live_meetup_shares`, `live_locations`, `meetup_points`, `live_meetup_commands`, resumable `live_meetup_transitions`, and short-lived `live_meetup_time_probes`. Composite indexes and TTL field policies are declared in `firestore.indexes.json`.

**Testing**: `flutter_test`, `bloc_test: ^10.0.0`, `mocktail: ^1.0.4`; Firestore Emulator Rules tests; TypeScript/Mocha Functions tests; integrated Auth, Firestore, and Functions emulator tests; transition-resume and delete-before-acknowledgment tests including Accepted-to-Declined attendance changes and Completed/Cancelled/Archived outing transitions; accepted-stop propagation measurements; deployment smoke checks for production indexes, scheduler, TTL, Google Maps key restrictions, and platform permission configuration

**Target Platform**: Android and iOS from one Flutter codebase with a Firebase Functions backend

**Project Type**: Multi-platform Flutter application plus serverless backend functions and an external map/search provider adapter

**Performance Goals**: Under the SC-002 network profile, at least 95% of accepted status and location updates reach another open eligible view within 5 seconds across 100 trials of each type. With 100 eligible attendees and 100 fresh shares, at least 95% of meetup opens show summary, destination state, and sharers within 3 seconds. Accepted stop removes the location document transactionally and propagates to supported views within 5 seconds.

**Constraints**: Only authenticated current crew members who remain outing participants with Accepted attendance may access participant live data, and only while the outing is Meeting. Confirmed or Meeting allows exact-point preparation only to an outing creator who remains a current crew member or the current crew owner, regardless of that organizer's attendance; this exception exposes no participant live data. Location sharing is explicit, per outing, off by default, foreground-only, and limited to one application session/device token at a time. Commands fail offline and never queue for later application. Only the latest status and location are retained; `acceptedAt` equals the Rules-validated location-command `createdAt`, and `expiresAt` is exactly `acceptedAt + 2 minutes`. Device wall clocks, client lifecycle claims, coordinates, and command ordering are untrusted. Samples require finite latitude `-90..90`, finite longitude `-180..180`, finite accuracy `0..5000` meters, and monotonic acquisition-to-submit age no greater than 30 seconds. Stale/out-of-order triggers cannot overwrite newer state. Protected state is cleared within one second after observed access loss. An outing/eligibility transition, including an Accepted-to-Declined response change, is not reported successful until its affected status/share/location records are physically absent; a cleanup-pending state denies access while a resumable transition finishes. No location history, background service, geofence, route, navigation, automatic arrival, notification, or analytics payload containing precise coordinates is introduced.

**Scale/Scope**: Up to 100 eligible attendees and 100 simultaneous fresh locations per outing; one status, share-control record, and location per attendee/outing; one meetup point per outing; location refresh at most once every 15 seconds and only after a new usable fix, producing at most about 6.7 accepted updates/second for a fully sharing 100-person outing; bounded listener result sets of 100

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First and Clean Architecture)**: PASS. Production code is isolated under `lib/features/live_meetup/{domain,data,presentation}`. Shared changes are limited to routing, DI, the outing entry surface, platform permission files, Firebase configuration, Rules/indexes, and trusted cleanup/deletion integration.
- **Principle II (Crew-First Interaction Model)**: PASS. Every participant live-data read and write revalidates the outing's authoritative crew membership, deterministic outing participation, and Accepted attendance. The separate meetup-point preparation path revalidates current crew membership and organizer authority without requiring Accepted attendance and exposes no participant live data. No direct friendship, follower, or public-presence model is introduced.
- **Principle III (Decoupled Provider Interfaces)**: PASS. Cubits depend on `LiveMeetupRepository`, `DeviceLocationService`, `MapProvider`, and `TrustedClock` abstractions. Firestore, geolocator, Google Maps, and HTTP types remain in data/presentation adapters.
- **Principle IV (Mandatory Automated Testing)**: PASS. Domain policies, repository behavior, lifecycle/session control, Cubits/widgets, command transactions, cleanup, and Firestore Security Rules all receive automated coverage.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. Precise location has one authoritative two-minute product boundary. Outing completion and eligibility-removal operations, including Accepted-attendance loss, deny access at cleanup start, delete affected status/share/location records before finalizing or acknowledging the transition, and retain event-driven cleanup, minutely repair, and TTL only as recovery backstops. US1 is a development checkpoint only and is not releasable until US4 provides these cleanup guarantees for its status records.
- **Architecture & Platform Constraints**: PASS. The Firestore command transport and Google Maps renderer support Android and iOS. Sensitive acceptance and cleanup execute in trusted Functions; Rules protect every client-visible collection.
- **Development Workflow**: PASS. Work is on `codex/006-live-meetup`, documentation links are repo-relative, model/contracts and trusted transition services precede Cubits and UI, and manual E2E/usability execution remains an explicit user-approval gate.

## Project Structure

### Documentation (this feature)

```text
specs/006-live-meetup/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- command_processing.md
|   |-- cleanup.md
|   |-- firestore_rules.md
|   |-- live_meetup_repository.md
|   `-- map_location_services.md
`-- tasks.md                 # Created later by /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/live_meetup/
|-- data/
|   |-- datasources/
|   |   `-- firestore_live_meetup_datasource.dart
|   |-- models/
|   |   |-- live_meetup_command_model.dart
|   |   |-- live_meetup_status_model.dart
|   |   |-- live_location_model.dart
|   |   `-- meetup_point_model.dart
|   |-- repositories/
|   |   `-- live_meetup_repository_impl.dart
|   `-- services/
|       |-- geolocator_device_location_service.dart
|       |-- firestore_live_meetup_clock.dart
|       |-- firestore_live_meetup_transition_service.dart
|       |-- live_location_sharing_coordinator.dart
|       `-- google_maps_map_provider.dart
|-- domain/
|   |-- entities/
|   |   |-- attendee_meetup_state.dart
|   |   |-- device_location_sample.dart
|   |   |-- geo_coordinate.dart
|   |   |-- live_location.dart
|   |   |-- live_location_session.dart
|   |   |-- live_meetup_snapshot.dart
|   |   |-- live_meetup_status.dart
|   |   `-- meetup_point.dart
|   |-- repositories/
|   |   `-- live_meetup_repository.dart
|   `-- services/
|       |-- device_location_service.dart
|       |-- live_meetup_access_policy.dart
|       |-- live_location_freshness_policy.dart
|       |-- live_meetup_transition_service.dart
|       |-- map_provider.dart
|       `-- trusted_clock.dart
`-- presentation/
    |-- cubit/
    |   |-- live_meetup/
    |   |   `-- live_meetup_cubit.dart
    |   |-- location_sharing/
    |   |   `-- location_sharing_cubit.dart
    |   `-- meetup_point_editor/
    |       `-- meetup_point_editor_cubit.dart
    |-- screens/
    |   `-- live_meetup_screen.dart
    `-- widgets/
        |-- attendee_status_summary.dart
        |-- location_sharing_control.dart
        |-- meetup_map.dart
        |-- meetup_point_editor.dart
        |-- meetup_text_alternative.dart
        `-- status_selector.dart

functions/
|-- src/
|   |-- index.ts
|   |-- live_meetup/
|   |   |-- cleanup.ts
|   |   |-- command_handler.ts
|   |   |-- command_schema.ts
|   |   |-- live_meetup_transactions.ts
|   |   |-- privacy_transition_coordinator.ts
|   |   |-- transition_handler.ts
|   |   `-- transition_schema.ts
|   |-- agreement/
|   |   `-- agreement_transactions.ts   # Invalidate stale point and delegate terminal transitions
|   `-- outings/
|       `-- outing_deletion.ts          # Extend cascade for Phase 6 records
|-- test/live_meetup/
|   |-- cleanup.test.ts
|   |-- command_handler.test.ts
|   |-- command_schema.test.ts
|   |-- live_meetup_integration.test.ts
|   |-- live_meetup_transactions.test.ts
|   |-- privacy_transition_coordinator.test.ts
|   |-- transition_handler.test.ts
|   `-- outing_deletion.test.ts
`-- package.json

test/features/live_meetup/
|-- data/
|   |-- models/live_meetup_models_test.dart
|   |-- repositories/live_meetup_repository_impl_test.dart
|   `-- services/
|       |-- firestore_live_meetup_clock_test.dart
|       |-- firestore_live_meetup_transition_service_test.dart
|       |-- geolocator_device_location_service_test.dart
|       `-- google_maps_map_provider_test.dart
|-- domain/
|   |-- live_meetup_entities_test.dart
|   |-- live_location_freshness_policy_test.dart
|   `-- live_meetup_access_policy_test.dart
`-- presentation/
    |-- cubit/
    |   |-- live_meetup_cubit_test.dart
    |   |-- location_sharing_cubit_test.dart
    |   `-- meetup_point_editor_cubit_test.dart
    `-- screens/live_meetup_screen_test.dart

test/features/outings/presentation/widgets/interactive_outing_card_test.dart
test/features/outings/data/repositories/outing_repository_impl_test.dart
test/features/voting/data/repositories/agreement_repository_impl_test.dart
test/features/crews/data/repositories/crew_repository_impl_test.dart
test/core/routes/app_router_test.dart
test/core/di/injection_container_test.dart
lib/features/outings/data/datasources/firestore_outings_datasource.dart
lib/features/outings/data/repositories/outing_repository_impl.dart
lib/features/voting/data/datasources/firestore_agreement_datasource.dart
lib/features/voting/data/repositories/agreement_repository_impl.dart
lib/features/crews/data/datasources/firestore_crews_datasource.dart
lib/features/crews/data/repositories/crew_repository_impl.dart
firestore.rules
firestore.indexes.json
firestore_tests/rules.test.js
firebase.json
android/app/src/main/AndroidManifest.xml
ios/Runner/Info.plist
ios/Podfile
lib/core/di/injection_container.dart
lib/core/routes/app_router.dart
lib/features/outings/presentation/widgets/interactive_outing_card.dart
pubspec.yaml
```

**Structure Decision**: Use the constitution's dedicated `live_meetup` feature boundary. Keep provider-neutral coordinates, permissions, statuses, freshness, repository, and privacy-transition contracts in the domain layer. Firestore commands match the proven Phase 4/5 transport, while trusted Functions own concurrency, session-token hashing, canonical acceptance times, and destructive privacy transitions. Existing Outing, Agreement, and Crew repositories receive the provider-neutral transition service so completion, Accepted-attendance loss, and participant/membership removal no longer perform direct destructive client writes when protected live data may exist. Use the official Google Maps Flutter renderer on Android/iOS and keep Google Geocoding behind `MapProvider`. Keep the exact meetup point in a separately authorized document rather than on the broadly readable outing record.

## Complexity Tracking

No constitution violations require justification. The resumable privacy-transition coordinator adds cross-feature integration to existing Outing, Agreement, and Crew repositories because direct client mutations cannot delete trusted-only presence records before acknowledging eligibility loss; the interface remains owned by `live_meetup` and provider-neutral.

## Phase 0: Research

Research decisions and rejected alternatives are recorded in [research.md](./research.md). All technical unknowns are resolved; no `NEEDS CLARIFICATION` markers remain.

## Phase 1: Design & Contracts

Design outputs:

- [data-model.md](./data-model.md)
- [contracts/command_processing.md](./contracts/command_processing.md)
- [contracts/cleanup.md](./contracts/cleanup.md)
- [contracts/firestore_rules.md](./contracts/firestore_rules.md)
- [contracts/live_meetup_repository.md](./contracts/live_meetup_repository.md)
- [contracts/map_location_services.md](./contracts/map_location_services.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Principle I**: PASS. Data-model and repository contracts preserve the `live_meetup` boundary; only shared platform wiring and existing outing deletion/lifecycle integration change outside it.
- **Principle II**: PASS. Participant live-data contracts use current crew membership, deterministic outing participation, Accepted attendance, and authoritative outing lifecycle as eligibility inputs. The isolated meetup-point preparation contract instead requires current crew membership and organizer authority and never grants participant live-data access.
- **Principle III**: PASS. Domain contracts contain no Firestore `GeoPoint`, geolocator `Position`, Google Maps `LatLng`, Geocoding response, or Functions transport type.
- **Principle IV**: PASS. Quickstart requires focused/full Flutter tests, Functions unit/integration tests, Rules emulator coverage, race tests, and platform/deployment gates.
- **Principle V**: PASS. Canonical `acceptedAt`/`expiresAt` fields enforce the exact freshness boundary, while cleanup-pending authorization denial plus resumable delete-before-finalize transitions ensure outing completion, Accepted-attendance loss, and eligibility removal are not acknowledged with protected presence records retained. Event cleanup, minutely repair, TTL, and outing cascades remain defense-in-depth.
- **Architecture & Platform Constraints**: PASS. One Firestore and Google Maps path serves Android and iOS, while trusted Functions serialize sensitive changes and Rules provide the client boundary.
