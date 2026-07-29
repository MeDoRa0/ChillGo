# Tasks: Live Meetup

**Input**: Design documents from `specs/006-live-meetup/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Automated domain, repository, Cubit, Functions, integration, and Firestore Rules coverage is mandatory under the feature specification and project constitution. Write each phase's tests first and verify they fail for the intended missing behavior.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently after the shared foundation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can proceed in parallel because it edits a different file and has no dependency on unfinished work in the phase
- **[Story]**: Maps the task to US1, US2, US3, or US4
- Every task names the exact target file or files

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add cross-platform dependencies, permissions, test scripts, and validation documentation.

- [X] T001 Add `geolocator`, `google_maps_flutter`, and `http` with the versions selected in the plan to `pubspec.yaml`
- [X] T002 [P] Add `test:live-meetup` and `test:live-meetup:integration` scripts that build before running Phase 6 suites in `functions/package.json`
- [X] T003 [P] Declare foreground fine/coarse location permissions without background or foreground-service permissions in `android/app/src/main/AndroidManifest.xml`
- [X] T004 [P] Add the when-in-use location explanation in `ios/Runner/Info.plist`
- [X] T005 [P] Configure the geolocator iOS build to bypass Always-location permission requirements in `ios/Podfile`
- [X] T006 [P] Document platform permission, restricted Google Maps build-key, and transition-emulator prerequisites in `specs/006-live-meetup/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish provider-neutral values, policies, online command transport, trusted time, authorization helpers, and indexes used by every story.

**⚠️ CRITICAL**: No user-story implementation begins until this phase is complete.

### Tests for Foundational Behavior

- [X] T007 [P] Add validation, equality, malformed-value, and deterministic-ordering tests for coordinates, device samples, locations, sessions, attendees, and snapshots in `test/features/live_meetup/domain/live_meetup_entities_test.dart`
- [X] T008 [P] Add Meeting, crew-membership, Accepted-attendance, deletion-pending, cleanup-pending, and organizer-preparation policy tests in `test/features/live_meetup/domain/live_meetup_access_policy_test.dart`
- [X] T009 [P] Add exact-boundary, canonical-acceptance-time, clock-drift, and timer-rescheduling tests for two-minute freshness in `test/features/live_meetup/domain/live_location_freshness_policy_test.dart`
- [X] T010 [P] Add online transaction, server-time offset, abandoned-probe, owner-isolation, and monotonic round-trip tests in `test/features/live_meetup/data/services/firestore_live_meetup_clock_test.dart`
- [X] T011 [P] Add common command-envelope, exact-key, trusted-time, purge-deadline, cleanup-pending, and payload-scrubbing tests in `functions/test/live_meetup/command_schema.test.ts`
- [X] T012 [P] Add Rules tests for eligibility helpers, cleanup-pending denial, requester-private command gets, denied command lists, exact-owner probes, and `deletionPending` denial in `firestore_tests/rules.test.js`

### Foundational Implementation

- [X] T013 Implement validated `GeoCoordinate`, `DeviceLocationSample`, and `LiveLocationSession` values in `lib/features/live_meetup/domain/entities/geo_coordinate.dart`, `lib/features/live_meetup/domain/entities/device_location_sample.dart`, and `lib/features/live_meetup/domain/entities/live_location_session.dart`
- [X] T014 Implement `LiveLocation`, `AttendeeMeetupState`, and `LiveMeetupSnapshot` aggregates with deterministic attendee ordering in `lib/features/live_meetup/domain/entities/live_location.dart`, `lib/features/live_meetup/domain/entities/attendee_meetup_state.dart`, and `lib/features/live_meetup/domain/entities/live_meetup_snapshot.dart`
- [X] T015 Define provider-neutral repository streams, online command results, and safe failure types in `lib/features/live_meetup/domain/repositories/live_meetup_repository.dart`
- [X] T016 Define device-location, map-provider, and trusted-clock interfaces with provider-neutral values in `lib/features/live_meetup/domain/services/device_location_service.dart`, `lib/features/live_meetup/domain/services/map_provider.dart`, and `lib/features/live_meetup/domain/services/trusted_clock.dart`
- [X] T017 Implement authoritative Meeting/eligibility, cleanup-pending denial, and organizer-preparation decisions in `lib/features/live_meetup/domain/services/live_meetup_access_policy.dart`
- [X] T018 Implement exact trusted-time expiry filtering and expiry-timer calculation in `lib/features/live_meetup/domain/services/live_location_freshness_policy.dart`
- [X] T019 Implement owner-private Firestore time-probe synchronization with monotonic round-trip offset calculation in `lib/features/live_meetup/data/services/firestore_live_meetup_clock.dart`
- [X] T020 Implement the exact pending/terminal command envelope and safe result mapping in `lib/features/live_meetup/data/models/live_meetup_command_model.dart`
- [X] T021 Implement online-only command creation, exact known-command observation, timeout handling, and no automatic retry in `lib/features/live_meetup/data/datasources/firestore_live_meetup_datasource.dart`
- [X] T022 [P] Implement common/type-specific command parsing, cleanup-pending validation inputs, conservative bounds, and terminal payload scrubbing in `functions/src/live_meetup/command_schema.ts`
- [X] T023 Implement trigger claiming, trusted authorization revalidation, cleanup-pending rejection, terminal outcomes, safe logging, and dispatch in `functions/src/live_meetup/command_handler.ts`
- [X] T024 Export the Live Meetup command trigger from `functions/src/index.ts`
- [X] T025 [P] Add reusable Meeting eligibility, cleanup-pending, organizer preparation, bounded-query, exact-command, and time-probe helpers in `firestore.rules`
- [X] T026 [P] Add Phase 6 query/repair indexes plus TTL field policies for `live_locations.expiresAt`, `live_meetup_commands.purgeAt`, and `live_meetup_transitions.purgeAt` in `firestore.indexes.json`

**Checkpoint**: Provider-neutral foundations, online command transport, trusted time, Rules helpers, and indexes are ready.

---

## Phase 3: User Story 1 - Share Arrival Status (Priority: P1) 🎯 MVP

**Goal**: Eligible attendees explicitly publish one current arrival status and see a correctly attributed, status-grouped attendee summary.

**Independent Test**: Move a Confirmed outing into Meeting, update statuses for Accepted crew members, verify exactly one current status per attendee plus Not Updated entries, and prove ineligible/offline attempts cannot alter the summary.

### Tests for User Story 1

- [X] T027 [P] [US1] Add status enum, accepted-time, Firestore conversion, malformed-data, and no-history model tests in `test/features/live_meetup/data/models/live_meetup_models_test.dart`
- [X] T028 [P] [US1] Add status schema, invalid-value, eligibility, cleanup-pending, replacement-ordering, superseded-command, and duplicate-delivery tests in `functions/test/live_meetup/live_meetup_transactions.test.ts`
- [X] T029 [P] [US1] Add Rules tests for bounded Meeting status reads and rejection of Invited, Declined, removed, former-crew, cleanup-pending, cross-crew, non-Meeting, unscoped, over-limit, and client-write attempts in `firestore_tests/rules.test.js`
- [X] T030 [P] [US1] Add roster/status join, Not Updated, trusted ordering, permission-loss purge, offline failure, and no-retry repository tests in `test/features/live_meetup/data/repositories/live_meetup_repository_impl_test.dart`
- [X] T031 [P] [US1] Add initial-load, status-submission, superseded-success, retryable-display-failure, and protected-state-clearing Cubit tests in `test/features/live_meetup/presentation/cubit/live_meetup_cubit_test.dart`
- [X] T032 [P] [US1] Add accessible three-state selection, pending/success/failure, grouping, identity, and trusted-time widget tests in `test/features/live_meetup/presentation/screens/live_meetup_screen_test.dart`
- [X] T033 [P] [US1] Add Meeting-only entry visibility and ineligible-state regression tests in `test/features/outings/presentation/widgets/interactive_outing_card_test.dart`
- [X] T034 [P] [US1] Add Live Meetup route-guard and protected-route redirect tests in `test/core/routes/app_router_test.dart`

### Implementation for User Story 1

- [X] T035 [US1] Implement the exact `gettingReady`, `onMyWay`, and `arrived` domain enum and display semantics in `lib/features/live_meetup/domain/entities/live_meetup_status.dart`
- [X] T036 [US1] Implement deterministic status-document conversion and accepted tuple validation in `lib/features/live_meetup/data/models/live_meetup_status_model.dart`
- [X] T037 [US1] Implement idempotent set-status replacement using `(createdAt, commandId)` ordering in `functions/src/live_meetup/live_meetup_transactions.ts`
- [X] T038 [US1] Implement status queries, roster joining, orphan rejection, attendee sorting, access watches, one-second protected-state purge, and `setStatus` command handling in `lib/features/live_meetup/data/repositories/live_meetup_repository_impl.dart`
- [X] T039 [US1] Implement snapshot subscription, status mutation state, safe error guidance, and access-revocation handling in `lib/features/live_meetup/presentation/cubit/live_meetup/live_meetup_cubit.dart`
- [X] T040 [US1] Implement the explicit accessible status picker with pending and outcome feedback in `lib/features/live_meetup/presentation/widgets/status_selector.dart`
- [X] T041 [US1] Implement grouped Getting Ready, On My Way, Arrived, and Not Updated attendee summaries in `lib/features/live_meetup/presentation/widgets/attendee_status_summary.dart`
- [X] T042 [US1] Compose the independently usable status-only loading, empty, failure, and access-lost views in `lib/features/live_meetup/presentation/screens/live_meetup_screen.dart`
- [X] T043 [US1] Register repository, clock, and status-Cubit dependencies in `lib/core/di/injection_container.dart`
- [X] T044 [US1] Add the guarded `/outings/:outingId/live-meetup` route in `lib/core/routes/app_router.dart`
- [X] T045 [US1] Add the Meeting-only Live Meetup entry action without exposing it to ineligible attendees in `lib/features/outings/presentation/widgets/interactive_outing_card.dart`

**Checkpoint**: US1 is a complete status-only development MVP with authorization and offline-failure behavior. It is not deployable or releasable until US4 cleanup is complete for Live Meetup status records.

---

## Phase 4: User Story 2 - Share Live Location Voluntarily (Priority: P2)

**Goal**: Eligible participants explicitly start, transfer, publish, pause/resume, and stop foreground-only live location sharing with exact freshness and sample bounds.

**Independent Test**: Grant/deny permission, start and stop sharing, background/resume/relaunch the process, transfer between devices, submit boundary samples, and verify only one fresh latest location exists and expires exactly two minutes after canonical acceptance.

### Tests for User Story 2

- [X] T046 [P] [US2] Add permission-state, service-disabled, approximate-accuracy, coordinate/accuracy bounds, invalid-sample, stream-cancellation, and late-callback tests in `test/features/live_meetup/data/services/geolocator_device_location_service_test.dart`
- [X] T047 [P] [US2] Add opt-in, process-only secret, 15-second cadence, 30-second monotonic-age, lifecycle pause/resume, detach, stop, transfer-away, and access-loss tests in `test/features/live_meetup/presentation/cubit/location_sharing_cubit_test.dart`
- [X] T048 [P] [US2] Add start/transfer/publish/stop schema, hashing, exact bounds, canonical `acceptedAt`, exact `expiresAt`, tuple-ordering, idempotency, and update/stop race tests in `functions/test/live_meetup/live_meetup_transactions.test.ts`
- [X] T049 [P] [US2] Add command-handler tests for transfer-required, old-session rejection, cleanup-pending rejection, lifecycle loss, terminal payload scrubbing, and coordinate-free logging in `functions/test/live_meetup/command_handler.test.ts`
- [X] T050 [P] [US2] Add Rules tests for fresh direct gets, bounded outing lists, denied share reads, exact publish bounds, cleanup-pending denial, and the blocking drift/listener/expiry proof in `firestore_tests/rules.test.js`
- [X] T051 [P] [US2] Add repository tests for latest-only mapping, canonical accepted time, exact trusted expiry timer, session failures, no retry, stop deletion, permission loss, and 100-item bounds in `test/features/live_meetup/data/repositories/live_meetup_repository_impl_test.dart`
- [X] T052 [P] [US2] Add consent copy, off-by-default state, permission guidance, transfer confirmation, stop control, accuracy, freshness, and non-location status availability widget tests in `test/features/live_meetup/presentation/screens/live_meetup_screen_test.dart`

### Implementation for User Story 2

- [X] T053 [US2] Implement finite coordinate, `0..5000` accuracy, canonical `acceptedAt`, exact `expiresAt`, and deterministic Firestore conversion in `lib/features/live_meetup/data/models/live_location_model.dart`
- [X] T054 [US2] Implement when-in-use permission handling and cancellable foreground position streaming without background modes in `lib/features/live_meetup/data/services/geolocator_device_location_service.dart`
- [X] T055 [US2] Implement cryptographically secure process-memory sessions, lifecycle ownership, 15-second cadence, 30-second monotonic-age gating, stream cancellation, and same-process resume in `lib/features/live_meetup/data/services/live_location_sharing_coordinator.dart`
- [X] T056 [US2] Implement atomic start/transfer/publish/stop transactions, SHA-256 credential checks, exact sample bounds, canonical timestamps, control watermarks, point deletion, and stale-command rejection in `functions/src/live_meetup/live_meetup_transactions.ts`
- [X] T057 [US2] Add fresh-location mapping, exact trusted expiry timers, start/publish/stop outcomes, and immediate local-session clearing to `lib/features/live_meetup/data/repositories/live_meetup_repository_impl.dart`
- [X] T058 [US2] Implement consent, permission, active-sharing, transfer-confirmation, lifecycle, publishing, stopping, and terminal-session states in `lib/features/live_meetup/presentation/cubit/location_sharing/location_sharing_cubit.dart`
- [X] T059 [US2] Implement the off-by-default explanation, start/transfer confirmation, stop action, permission correction, accuracy, and freshness UI in `lib/features/live_meetup/presentation/widgets/location_sharing_control.dart`
- [X] T060 [US2] Keep the process-scoped sharing coordinator alive across foreground ChillGo routes and dispose it on detach/sign-out in `lib/main.dart`
- [X] T061 [US2] Register device-location, sharing-coordinator, and location-sharing-Cubit dependencies without persistent session storage in `lib/core/di/injection_container.dart`
- [X] T062 [US2] Integrate consent and sharing controls while preserving the independently usable status experience in `lib/features/live_meetup/presentation/screens/live_meetup_screen.dart`

**Checkpoint**: US2 independently proves explicit consent, one-device sharing, foreground-only collection, exact expiry, and sample rejection.

---

## Phase 5: User Story 3 - Coordinate on a Shared Meetup Map (Priority: P3)

**Goal**: Authorized organizers prepare an exact meetup point and eligible attendees use an accessible map plus complete textual alternative.

**Independent Test**: Prepare/change a point, open Meeting with zero or multiple sharers, expire a marker, overlap coordinates, simulate provider failure, and verify destination/participant distinction and map/text parity on supported inputs.

### Tests for User Story 3

- [X] T063 [P] [US3] Add meetup-point validation, location-text snapshot, accepted-tuple, and Firestore conversion tests in `test/features/live_meetup/data/models/live_meetup_models_test.dart`
- [X] T064 [P] [US3] Add Google Geocoding configuration, search/reverse-label mapping, timeout, malformed-response, restricted-header, and secret-redaction tests in `test/features/live_meetup/data/services/google_maps_map_provider_test.dart`
- [X] T065 [P] [US3] Add Confirmed/Meeting authority, current-crew organizer access regardless of attendance, former-crew creator denial, explicit confirmation, changed-location mismatch, replacement-ordering, cleanup-pending, and duplicate-delivery tests in `functions/test/live_meetup/live_meetup_transactions.test.ts`
- [X] T066 [P] [US3] Add Rules tests for current-crew creator/owner Confirmed preparation regardless of attendance, former-crew creator and non-organizer denial, Meeting attendee reads, deterministic get-only access, cleanup-pending denial, and no pre-Meeting participant-data leakage in `firestore_tests/rules.test.js`
- [X] T067 [P] [US3] Add search, selection, confirmation, stale-text conflict, replacement, and recoverable provider-failure Cubit tests in `test/features/live_meetup/presentation/cubit/meetup_point_editor_cubit_test.dart`
- [X] T068 [P] [US3] Add destination/attendee distinction, overlapping-marker discovery, and per-sharer name, avatar fallback, current-status, freshness, and accuracy detail tests plus expiry removal, attribution, keyboard controls, no-point state, tile failure, and map/text parity tests in `test/features/live_meetup/presentation/screens/live_meetup_screen_test.dart`

### Implementation for User Story 3

- [X] T069 [US3] Implement the exact meetup-point domain entity with finalized-location snapshot and accepted tuple in `lib/features/live_meetup/domain/entities/meetup_point.dart`
- [X] T070 [US3] Implement deterministic meetup-point Firestore conversion and authority-safe mapping in `lib/features/live_meetup/data/models/meetup_point_model.dart`
- [X] T071 [US3] Implement Google Geocoding forward search, reverse labels, restricted application headers, timeouts, and safe failure adaptation in `lib/features/live_meetup/data/services/google_maps_map_provider.dart`
- [X] T072 [US3] Implement organizer-authorized meetup-point replacement and finalized-text equality validation in `functions/src/live_meetup/live_meetup_transactions.ts`
- [X] T073 [US3] Add isolated preparation watching, deterministic point reads, and `setMeetupPoint` handling without pre-Meeting attendee queries in `lib/features/live_meetup/data/repositories/live_meetup_repository_impl.dart`
- [X] T074 [US3] Implement point search, selection, explicit location-text confirmation, save outcomes, and conflict recovery in `lib/features/live_meetup/presentation/cubit/meetup_point_editor/meetup_point_editor_cubit.dart`
- [X] T075 [US3] Implement the organizer point search/selection/confirmation interface in `lib/features/live_meetup/presentation/widgets/meetup_point_editor.dart`
- [X] T076 [US3] Implement Google Maps destination and attendee markers with discoverable per-sharer name, current status, accuracy details, native attribution, zoom, and recenter controls in `lib/features/live_meetup/presentation/widgets/meetup_map.dart`
- [X] T077 [US3] Implement the always-reachable non-map location, point, attendee-status, sharer, accuracy, and freshness representation in `lib/features/live_meetup/presentation/widgets/meetup_text_alternative.dart`
- [X] T078 [US3] Compose point preparation, destination state, shared map, tile/search failure fallback, and textual parity in `lib/features/live_meetup/presentation/screens/live_meetup_screen.dart`
- [X] T079 [US3] Register the Google Maps adapter and meetup-point-editor Cubit with platform-restricted build-supplied keys only in `lib/core/di/injection_container.dart`

**Checkpoint**: US3 independently supports exact-point preparation and accessible visual/textual coordination.

---

## Phase 6: User Story 4 - End Live Coordination Safely (Priority: P4)

**Goal**: Deny access at cleanup start, physically delete protected presence before acknowledging lifecycle/eligibility transitions, and prevent delayed recreation.

**Independent Test**: Change an Accepted participant to Declined through both response entry points, move outings to Completed, Cancelled, and Archived, remove a participant/membership, pause processing between deletion batches, retry the transition, overlap live commands, and verify no success is reported until all affected status/share/location records are absent and the authoritative transition is finalized.

### Tests for User Story 4

- [X] T080 [P] [US4] Add online creation, exact shapes including self-targeted Accepted-to-Declined attendance change, requester-private observation, timeout, no-retry, and safe-result tests for the transition service in `test/features/live_meetup/data/services/firestore_live_meetup_transition_service_test.dart`
- [X] T081 [P] [US4] Add exact type-specific transition schema, Accepted-attendance-change authority, explicit Completed/Cancelled/Archived targets, terminal scrubbing, lease, and safe-error tests in `functions/test/live_meetup/transition_handler.test.ts`
- [X] T082 [P] [US4] Add cleanup-pending, Accepted-attendance loss, Completed/Cancelled/Archived transitions, bounded-batch cursor, empty-set verification, delete-before-finalize, retry/resume, idempotency, and command-race tests in `functions/test/live_meetup/privacy_transition_coordinator.test.ts`
- [X] T083 [P] [US4] Add transition-command privacy, forged attendance/terminal target denial, direct-destructive-write denial, cleanup-pending access denial, and non-recreation Rules tests in `firestore_tests/rules.test.js`
- [X] T084 [P] [US4] Add both attendance-response repositories' Accepted-to-Declined delegation, Completed/Cancelled/Archived outing and participant-removal delegation, pending/failure semantics, and no-success-before-finalization tests in `test/features/outings/data/repositories/outing_repository_impl_test.dart` and `test/features/voting/data/repositories/agreement_repository_impl_test.dart`
- [X] T085 [P] [US4] Add membership-removal/crew-deletion delegation, pending/failure semantics, and no-success-before-finalization tests in `test/features/crews/data/repositories/crew_repository_impl_test.dart`
- [X] T086 [P] [US4] Add unexpected outing/participant/membership/attendance changes, expired points, abandoned transitions, duplicate repair, and overlapping-cleanup tests in `functions/test/live_meetup/cleanup.test.ts`
- [X] T087 [P] [US4] Add Phase 6 collection sweep, transition termination, command scrubbing, second sweep, missing-data success, and delayed-command non-recreation tests in `functions/test/live_meetup/outing_deletion.test.ts`
- [X] T088 [P] [US4] Add Auth/Firestore/Functions emulator flows for Accepted-to-Declined changes through both response entry points, Completed/Cancelled/Archived transitions, pending denial, paused/resumed deletion, terminal acknowledgment, transfer/stop races, expiry, and non-recreation in `functions/test/live_meetup/live_meetup_integration.test.ts`
- [X] T089 [P] [US4] Add open-screen access-loss tests proving protected UI state clears within one second and before any later state in `test/features/live_meetup/presentation/screens/live_meetup_screen_test.dart`

### Implementation for User Story 4

- [X] T090 [US4] Define provider-neutral end-outing, change-attendance, participant-removal, membership-removal, and crew-deletion transition operations with progress-safe results and failures in `lib/features/live_meetup/domain/services/live_meetup_transition_service.dart`
- [X] T091 [US4] Implement exact transition envelopes with `targetAttendanceStatus == declined` for self-targeted attendance changes plus exact Completed/Cancelled/Archived targets, processing leases, phases, cursors, and terminal scrubbing in `functions/src/live_meetup/transition_schema.ts`
- [X] T092 [US4] Implement resumable authorization, cleanup-pending writes, bounded presence deletion, empty-set verification, final authoritative attendance/lifecycle/removal mutation, and idempotent resume in `functions/src/live_meetup/privacy_transition_coordinator.ts`
- [X] T093 [US4] Implement transition trigger claiming, coordinator dispatch, retry-safe outcomes, and safe logging in `functions/src/live_meetup/transition_handler.ts`
- [X] T094 [US4] Implement online-only transition creation including `declineAttendance`, exact known-transition observation, timeout handling, and safe result mapping in `lib/features/live_meetup/data/services/firestore_live_meetup_transition_service.dart`
- [X] T095 [US4] Route Completed/Cancelled/Archived outing transitions, participant removal, and Accepted-to-Declined responses from both existing entry points through `LiveMeetupTransitionService` instead of direct destructive writes in `lib/features/outings/data/repositories/outing_repository_impl.dart`, `lib/features/outings/data/datasources/firestore_outings_datasource.dart`, `lib/features/voting/data/repositories/agreement_repository_impl.dart`, and `lib/features/voting/data/datasources/firestore_agreement_datasource.dart`
- [X] T096 [US4] Route membership removal and crew deletion through `LiveMeetupTransitionService` instead of direct destructive writes in `lib/features/crews/data/repositories/crew_repository_impl.dart` and `lib/features/crews/data/datasources/firestore_crews_datasource.dart`
- [X] T097 [US4] Implement transition-create authorization including self-targeted Accepted-to-Declined attendance changes with `targetAttendanceStatus == declined` and exact terminal statuses, requester-private gets, cleanup-pending helpers, direct-destructive-write denial, and protected collection denial in `firestore.rules`
- [X] T098 [US4] Implement idempotent recovery triggers, expired-location cleanup, abandoned-transition resume, command/probe cleanup, and minutely bounded repair in `functions/src/live_meetup/cleanup.ts`
- [X] T099 [US4] Export transition, recovery-cleanup, lifecycle, membership, and minutely repair triggers in `functions/src/index.ts`
- [X] T100 [US4] Extend the explicit outing-owned cascade with transition termination, command scrubbing, Phase 6 sweeps, and post-delete resweep in `functions/src/outings/outing_deletion.ts`
- [X] T101 [US4] Delegate terminal Agreement lifecycle work to the privacy-transition coordinator and invalidate stale meetup points during finalized-location changes in `functions/src/agreement/agreement_transactions.ts`
- [X] T102 [US4] Make repository subscriptions cancel timers/listeners and erase cached protected aggregates before emitting any cleanup-pending or access failure in `lib/features/live_meetup/data/repositories/live_meetup_repository_impl.dart`
- [X] T103 [US4] Make all Live Meetup Cubits discard protected state and local sharing capability before emitting access-lost navigation state in `lib/features/live_meetup/presentation/cubit/live_meetup/live_meetup_cubit.dart`, `lib/features/live_meetup/presentation/cubit/location_sharing/location_sharing_cubit.dart`, and `lib/features/live_meetup/presentation/cubit/meetup_point_editor/meetup_point_editor_cubit.dart`
- [X] T104 [US4] Register the transition service and cross-feature Outing/Agreement/Crew repository adapters in `lib/core/di/injection_container.dart`

**Checkpoint**: US4 proves constitution-compliant delete-before-acknowledgment transitions and recovery without recreation.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Complete shared test infrastructure, regression validation, performance evidence, privacy audit, and authorized manual/deployment gates.

- [X] T105 [P] Add DI registration and lifecycle-disposal regression coverage for every Live Meetup dependency in `test/core/di/injection_container_test.dart`
- [X] T106 [P] Add common test builders and fakes for attendees, trusted time, map services, device location, commands, transitions, and snapshots in `test/features/live_meetup/live_meetup_test_helpers.dart`
- [X] T107 [P] Add Functions fixtures for 100 attendees, trusted command tuples, active sessions, transition cursors, partial cleanup, and race scenarios in `functions/test/live_meetup/live_meetup_test_utils.ts`
- [X] T108 Run the focused Flutter tests from the automated validation section and record platform-neutral caveats in `specs/006-live-meetup/quickstart.md`
- [X] T109 Run the full Flutter test suite and Dart analyzer, fix regressions, and record verified commands in `specs/006-live-meetup/quickstart.md`
- [X] T110 Run Functions unit/integration suites and Firestore Emulator Rules tests, fix regressions, and record outcomes in `specs/006-live-meetup/quickstart.md`
- [X] T111 Execute the 100-attendee SC-002/SC-008 emulator performance profile plus at least 100 SC-004 accepted-stop trials with another eligible view open, require every accepted stop to disappear from the observer within five seconds, and record command, observer, opening, and stop-to-removal latency results in `specs/006-live-meetup/quickstart.md`
- [X] T112 Audit source, logs, analytics, crash reporting, terminal commands/transitions, and tests for retained coordinates, session secrets, geocoding text, or route history and record the result in `specs/006-live-meetup/quickstart.md`
- [ ] T113 After obtaining explicit user authorization, run Android and iOS manual E2E/accessibility checks and the 20-participant SC-001/SC-007 usability protocol, then record evidence in `specs/006-live-meetup/quickstart.md`
- [ ] T114 After deployment authorization, verify production Rules, Functions, transition delete-before-success behavior, scheduler, indexes, TTL policies, Google Maps restrictions/attribution/quota, platform permissions, and smoke flows in `specs/006-live-meetup/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 — Setup**: Starts immediately.
- **Phase 2 — Foundational**: Depends on Phase 1 and blocks every user story.
- **Phase 3 — US1**: Starts after Phase 2 and is the recommended development MVP, but it is not deployable or releasable until US4 cleanup covers its status records.
- **Phase 4 — US2**: Starts after Phase 2; it reuses the aggregate/repository foundation but remains testable without the map.
- **Phase 5 — US3**: Starts after Phase 2; point preparation and the textual/map shell are testable with fixed status/location fixtures, while final composition consumes available US1/US2 state.
- **Phase 6 — US4**: Starts after Phase 2; its transition coordinator is independently testable with seeded protected records and is mandatory for every release containing any Live Meetup presence feature.
- **Phase 7 — Polish**: Starts after all user stories selected for release and mandatory US4 cleanup are complete.

### User Story Dependency Graph

```text
Setup -> Foundational -> US1 (MVP)
                      -> US2
                      -> US3 preparation/text/map shell
                      -> US4 privacy transitions

US1 + US2 + US3 -> integrated shared meetup development experience (not releasable)
US1 + US2 + US3 + US4 -> full Phase 6 release validation
```

### Within Each User Story

1. Write the story's tests and verify they fail for the intended missing behavior.
2. Implement domain entities/interfaces before data models, repositories, or Cubits.
3. Implement trusted schemas/transactions and Rules before connecting client commands.
4. Implement data services/repositories before presentation state.
5. Implement Cubits before widgets and screens.
6. Complete DI/routing/integration after the underlying services and presenters.
7. Run the story's focused checkpoint tests.

### Parallel Opportunities

- Setup tasks T002-T006 edit distinct platform/configuration files.
- Foundational test tasks T007-T012 can be authored in parallel.
- After Phase 2, US1-US4 can begin in parallel with separate owners.
- Test tasks marked `[P]` within each story edit independent test files or independent sections of shared suites.
- Polish fixtures and DI coverage T105-T107 can proceed in parallel.
- Implementation tasks are intentionally not marked `[P]` where constitution-mandated model → service/repository → Cubit → UI ordering applies.

---

## Parallel Example: User Story 1

```text
Task T027: Add status model tests in test/features/live_meetup/data/models/live_meetup_models_test.dart
Task T028: Add trusted status transaction tests in functions/test/live_meetup/live_meetup_transactions.test.ts
Task T029: Add status authorization tests in firestore_tests/rules.test.js
Task T031: Add status Cubit tests in test/features/live_meetup/presentation/cubit/live_meetup_cubit_test.dart
Task T034: Add route-guard tests in test/core/routes/app_router_test.dart
```

## Parallel Example: User Story 2

```text
Task T046: Add geolocator adapter tests in test/features/live_meetup/data/services/geolocator_device_location_service_test.dart
Task T047: Add sharing lifecycle/Cubit tests in test/features/live_meetup/presentation/cubit/location_sharing_cubit_test.dart
Task T048: Add trusted sharing/location transaction tests in functions/test/live_meetup/live_meetup_transactions.test.ts
Task T050: Add freshness and publish-bound Rules tests in firestore_tests/rules.test.js
Task T052: Add consent/control widget tests in test/features/live_meetup/presentation/screens/live_meetup_screen_test.dart
```

## Parallel Example: User Story 3

```text
Task T063: Add meetup-point model tests in test/features/live_meetup/data/models/live_meetup_models_test.dart
Task T064: Add Google Maps adapter tests in test/features/live_meetup/data/services/google_maps_map_provider_test.dart
Task T065: Add trusted point transaction tests in functions/test/live_meetup/live_meetup_transactions.test.ts
Task T067: Add point-editor Cubit tests in test/features/live_meetup/presentation/cubit/meetup_point_editor_cubit_test.dart
Task T068: Add map/text parity tests in test/features/live_meetup/presentation/screens/live_meetup_screen_test.dart
```

## Parallel Example: User Story 4

```text
Task T080: Add client transition-service tests in test/features/live_meetup/data/services/firestore_live_meetup_transition_service_test.dart
Task T081: Add transition handler/schema tests in functions/test/live_meetup/transition_handler.test.ts
Task T082: Add resumable coordinator tests in functions/test/live_meetup/privacy_transition_coordinator.test.ts
Task T083: Add transition and cleanup-pending Rules tests in firestore_tests/rules.test.js
Task T084: Add Outing repository delegation tests in test/features/outings/data/repositories/outing_repository_impl_test.dart
Task T085: Add Crew repository delegation tests in test/features/crews/data/repositories/crew_repository_impl_test.dart
```

---

## Implementation Strategy

### MVP First: User Story 1

1. Complete Phase 1 setup.
2. Complete the Phase 2 foundation.
3. Complete US1 tests, domain/data/backend work, Cubit, and UI in dependency order.
4. Run the US1 checkpoint and verify authorization/offline behavior.
5. Stop for development MVP review before adding precise location; do not deploy or release until US4 cleanup is complete.

### Incremental Delivery

1. Setup + Foundational → trusted provider-neutral base.
2. US1 → status-only coordination development MVP; non-releasable until US4.
3. US2 → voluntary foreground live location.
4. US3 → exact point, shared map, and textual parity.
5. US4 → delete-before-acknowledgment privacy transitions and recovery.
6. Polish → full validation, performance, privacy, and authorized gates.

### Parallel Team Strategy

After Setup and Foundational are complete:

- Developer A: US1 status slice.
- Developer B: US2 location-sharing slice.
- Developer C: US3 map/point slice.
- Developer D: US4 privacy-transition slice.

Shared-file tasks in `firestore.rules`, `functions/src/index.ts`, `lib/core/di/injection_container.dart`, repository implementations, and combined test suites must be serialized or coordinated explicitly.

---

## Notes

- `[P]` means the task has no dependency on unfinished work in its phase and edits a distinct file or independently coordinated test section.
- Tests precede implementation because automated coverage is mandatory.
- Exact `acceptedAt`, `expiresAt`, sample bounds, cleanup-pending denial, and delete-before-success semantics are blocking assertions rather than optional polish.
- UI implementation tasks are ordered after their Cubits and are not marked parallel.
- Precise coordinates, session secrets, search text, and provider keys must never enter source-controlled fixtures, logs, analytics, or terminal command/transition payloads.
- T113 and T114 are explicit authorization gates; do not start or mark them complete without user approval.
- US4 privacy transitions are a constitution-mandated release dependency for every increment that stores Live Meetup status, sharing, or location data; an earlier story checkpoint may be reviewed but not deployed without US4.
- Commit after each task or cohesive task group and run the relevant checkpoint before moving to the next story.
