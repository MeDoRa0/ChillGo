# Tasks: Production Readiness

**Input**: Design documents from `specs/008-production-readiness/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), and [contracts/](./contracts/)

**Tests**: Automated tests are mandatory under FR-001 through FR-004 and the project constitution. Physical-device, beta, store, and public-release validation are approval-gated.

**Organization**: Tasks are grouped by user story so each release-readiness increment can be validated independently.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add reproducible release-validation and evidence scaffolding.

- [X] T001 Create the release-evidence directory structure and candidate/incident Markdown templates in `docs/release/candidates/README.md` and `docs/release/incidents/README.md`
- [X] T002 [P] Add the canonical release-quality workflow for analyze, Flutter tests, Functions tests, and Rules tests in `.github/workflows/release-quality.yml`
- [X] T003 [P] Add a release validation command runner with documented inputs, artifact paths, and non-zero failure behavior in `tool/run_release_validation.dart`
- [X] T004 [P] Record the release owner, permanent Android/iOS identifier decision, store-account ownership, external signing ownership, environment inventory, and secret inventory in `docs/release/environment-and-secrets.md`
- [X] T005 [P] Add Android/iOS store listing, privacy, support, asset, and review-material inventory in `docs/release/store-submission-checklist.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the quality, privacy, and release foundations that every story depends on.

**CRITICAL**: Complete this phase before starting any user-story phase.

- [X] T006 Implement a release-safe diagnostics context model with fixed release/client/failure fields in `lib/core/domain/entities/diagnostics_context.dart`
- [X] T007 [P] Define the allowlisted MVP journey-event schema and prohibited-field guard in `lib/core/domain/entities/release_telemetry_event.dart`
- [X] T008 Add a platform-neutral release/version provider interface in `lib/core/domain/repositories/release_metadata_repository.dart`
- [X] T009 Implement release metadata retrieval without secrets in `lib/core/data/repositories/release_metadata_repository_impl.dart`
- [X] T010 Update dependency injection to register release metadata and safe diagnostics collaborators in `lib/core/di/injection_container.dart`
- [X] T011 Replace raw diagnostics forwarding with sanitized Crashlytics and Analytics submission in `lib/core/data/repositories/diagnostics_repository_impl.dart`
- [X] T012 Update global framework, platform, and async error handling to pass controlled context only in `lib/core/error/global_error_handler.dart`
- [X] T013 [P] Add unit tests for release metadata and diagnostics context in `test/core/data/repositories/release_metadata_repository_impl_test.dart`
- [X] T014 [P] Add privacy/redaction and allowlisted-event tests in `test/core/data/repositories/diagnostics_repository_impl_test.dart`
- [X] T015 Add testable app bootstrap configuration for release versus emulator validation in `lib/main.dart`
- [X] T016 Create a full protected-resource/actor authorization matrix in `docs/release/security-validation-matrix.md`
- [ ] T017 Expand shared Rules test fixtures and helpers for anonymous, outsider, removed, revoked, expired, and authorized actors in `firestore_tests/rules.test.js`

**Checkpoint**: Shared release validation, privacy-safe telemetry, and security-matrix infrastructure are ready.

---

## Phase 3: User Story 1 - Complete Core Workflows Reliably (Priority: P1)

**Goal**: Validate every MVP workflow through reliable automated unit, widget, integration, and recoverable-error coverage.

**Independent Test**: A release candidate passes two consecutive runs of its full automated suite and Android/iOS MVP journeys cover valid, offline, and interrupted outcomes without falsely reporting completion.

- [X] T018 [P] [US1] Inventory existing feature unit/state/data-mapping coverage and record missing mandatory cases in `docs/release/test-coverage-matrix.md`
- [X] T019 [P] [US1] Add deterministic seeded test identities and MVP data builders in `integration_test/support/mvp_test_fixture.dart`
- [X] T020 [P] [US1] Add a network/interruption test double for recoverable action failures in `integration_test/support/network_condition_controller.dart`
- [ ] T021 [US1] Add Android MVP end-to-end coverage for sign-in/profile, Crew invite, Outing, agreement, meetup, and notification-center paths in `integration_test/mvp_android_e2e_test.dart`
- [ ] T022 [US1] Add iOS MVP end-to-end coverage mirroring the Android journey in `integration_test/mvp_ios_e2e_test.dart`
- [ ] T023 [P] [US1] Add widget/interface regression tests for loading, empty, validation, and recoverable-error states across MVP feature screens in `test/features/release_readiness/mvp_interface_states_test.dart`
- [ ] T024 [P] [US1] Add Functions emulator tests for duplicate command/event delivery, interrupted cleanup, and lifecycle races in `functions/test/release_readiness/reliability_integration.test.ts`
- [X] T025 [US1] Verify that completed Phase 7 notification client, Function, and Rules artefacts satisfy the MVP journey; fail the candidate and record a prerequisite blocker rather than implementing notification capability in `docs/release/phase-prerequisites.md`
- [ ] T026 [US1] Add release runner steps that execute all Flutter, Functions, Rules, and Android/iOS integration suites twice and preserve sanitized artifacts in `tool/run_release_validation.dart`
- [X] T027 [US1] Document candidate-run evidence and flaky-test handling in `docs/release/candidates/README.md`

**Checkpoint**: The MVP journey is automated and independently verifiable without manual device/store activity.

---

## Phase 4: User Story 2 - Keep Personal and Crew Data Protected (Priority: P1)

**Goal**: Prove that every protected read/write is denied after access loss while valid workflows remain available.

**Independent Test**: The full authorization matrix passes in the Emulator: all unauthorized reads/writes are denied and all authorized control cases succeed.

- [ ] T028 [US2] Add profile, username, Crew, membership, and invitation actor-matrix cases in `firestore_tests/rules.test.js`
- [ ] T029 [US2] Add Outing, participant, agreement, and command actor-matrix cases in `firestore_tests/rules.test.js`
- [ ] T030 [US2] Add chat, read-state, expiry, and command actor-matrix cases in `firestore_tests/rules.test.js`
- [ ] T031 [US2] Add live-meetup status, location, share, transition, and cleanup actor-matrix cases in `firestore_tests/rules.test.js`
- [ ] T032 [US2] Add notification recipient, preference, unread-count, access-revocation, and direct-write-denial cases in `firestore_tests/rules.test.js`
- [ ] T033 [US2] Add Storage avatar authorization/revocation cases in `firestore_tests/storage.rules.test.js`
- [ ] T034 [US2] Correct any Rules, indexes, or trusted transition behavior exposed by the matrix in `firestore.rules`, `storage.rules`, `firestore.indexes.json`, and `functions/src/`
- [ ] T035 [US2] Add the complete Rules matrix and expected-result summary to the release runner in `tool/run_release_validation.dart`

**Checkpoint**: Security validation independently demonstrates FR-004 and SC-002.

---

## Phase 5: User Story 3 - Operate a Stable, Observable Service (Priority: P2)

**Goal**: Give the release owner privacy-safe evidence of crashes, key journey completion, and Android/iOS performance.

**Independent Test**: Injected controlled failures and each allowlisted journey signal are observable with version/client metadata and no prohibited content; performance artifacts show the required trial counts and percentiles.

- [ ] T036 [P] [US3] Add release version/client-type and redaction behavior tests for global errors in `test/core/error/global_error_handler_test.dart`
- [X] T037 [P] [US3] Add tests that assert every allowlisted journey event uses only approved parameters in `test/core/data/repositories/diagnostics_repository_impl_test.dart`
- [ ] T038 [US3] Instrument the seven allowlisted journey completions through `DiagnosticsRepository` in `lib/features/authentication/`, `lib/features/crews/`, `lib/features/outings/`, `lib/features/agreement/`, `lib/features/live_meetup/`, and `lib/features/notifications/`
- [X] T039 [US3] Add controlled error categories and remove unsafe exception/log payloads from Firebase diagnostics calls in `lib/core/data/repositories/diagnostics_repository_impl.dart`
- [ ] T040 [US3] Add a deterministic Android/iOS performance measurement harness for first-run and MVP usable-view timings in `integration_test/release_performance_test.dart`
- [X] T041 [US3] Define the fixed launch network profile, trial method, p50/p95 calculation, and 1,000-MAU scope in `docs/release/performance-validation.md`
- [ ] T042 [US3] Add automated release-artifact collection and threshold evaluation for performance and telemetry evidence in `tool/run_release_validation.dart`
- [X] T043 [US3] Document Crashlytics dashboard, Analytics review, alert ownership, and 30-day crash-free monitoring procedure in `docs/release/monitoring-runbook.md`

**Checkpoint**: The release owner can identify a safe failure, confirm journey instrumentation, and assess performance before approving a candidate.

---

## Phase 6: User Story 4 - Install a Clear, Compliant Release (Priority: P2)

**Goal**: Produce Android/iOS release packages and materials that are accurate, signed, privacy-reviewed, and ready for controlled beta/public distribution.

**Independent Test**: A release checklist review finds complete non-secret Android/iOS metadata/configuration, and an approval-gated device/store validation can install and complete first run on both platforms.

- [ ] T044 [US4] Select and configure the permanent non-placeholder Android application ID, release versioning, target SDK, and external signing configuration in `android/app/build.gradle.kts`
- [ ] T045 [US4] Configure the permanent iOS bundle ID, signing/capabilities, Firebase app configuration, APNs prerequisites, and release versioning in `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Runner.entitlements`, and `ios/Runner/Info.plist`
- [ ] T046 [P] [US4] Add Android permission explanations, notification behavior, App Check, and production configuration validation in `android/app/src/main/AndroidManifest.xml`
- [ ] T047 [P] [US4] Add iOS permission explanations, notification behavior, App Check, and production configuration validation in `ios/Runner/Info.plist`
- [X] T048 [US4] Create public support and privacy-policy content consistent with shipped Firebase SDKs, permissions, retention, deletion controls, and notification behavior in `docs/release/privacy-policy.md` and `docs/release/support.md`
- [ ] T049 [US4] Complete Android/iOS listing metadata, screenshots/icons, review instructions, data-safety/privacy declarations, and account-deletion review in `docs/release/store-submission-checklist.md`
- [X] T050 [US4] Add a non-secret release-build verification workflow for Android App Bundle and iOS archive metadata in `.github/workflows/release-quality.yml`
- [X] T051 [US4] Create the release candidate checklist, approval fields, known-limitations record, beta 10%/50% gates, public-release gate, and rollback criteria in `docs/release/candidates/README.md`
- [X] T052 [US4] Create the least-disclosing incident triage, containment, corrective-release, and follow-up template in `docs/release/incidents/README.md`
- [ ] T053 [US4] With explicit user approval, validate signed Android/iOS installs, launch, sign-in, first-run profile setup, permission denied/settings recovery, notification fallback, and readable crash symbols using `docs/release/candidates/README.md`
- [ ] T054 [US4] With explicit user approval, run timed representative-user usability validation for sign-in/profile setup, Crew creation or joining, and finding an active Outing; record aggregate completion and five-minute results in `docs/release/candidates/<build-name>+<build-number>.md`
- [ ] T055 [US4] With explicit user approval, invite the 10% and 50% Android/iOS beta cohorts, review monitoring windows, and approve/pause progression using `docs/release/candidates/README.md`

**Checkpoint**: Android/iOS are ready for an approval-gated controlled beta and then public store release.

---

## Phase 7: Polish and Cross-Cutting Release Validation

**Purpose**: Verify all contracts together, prevent regressions, and prepare an auditable handoff.

- [ ] T056 [P] Run formatting and static analysis, then correct production-code findings in `analysis_options.yaml` and affected `lib/` files
- [ ] T057 Run the full candidate validation twice and attach sanitized results to `docs/release/candidates/<build-name>+<build-number>.md`
- [ ] T058 Verify the release checklist against [quality gates](./contracts/quality_gates.md), [telemetry privacy](./contracts/telemetry_privacy.md), and [release operations](./contracts/release_operations.md) in `docs/release/candidates/<build-name>+<build-number>.md`
- [ ] T059 Re-run the constitution check and record Phase 8 compliance/known limitations in `specs/008-production-readiness/plan.md`
- [ ] T060 Update the project release entry points and contributor instructions in `README.md` and `docs/release/README.md`

---

## Dependencies and Execution Order

### Phase dependencies

- **Setup (Phase 1)**: Starts immediately.
- **Foundational (Phase 2)**: Depends on Setup and blocks all stories.
- **US1 and US2 (Phases 3-4)**: Start after Foundational; both are P1. US1 cannot claim complete MVP coverage until completed Phase 7 notification artefacts pass the prerequisite check.
- **US3 (Phase 5)**: Depends on Foundational and benefits from US1's integration harness.
- **US4 (Phase 6)**: Depends on Foundational; its approval-gated manual tasks also depend on all automated quality gates.
- **Polish (Phase 7)**: Depends on every desired story phase.

### User-story dependencies

- **US1**: Depends on shared diagnostics/configuration foundations; independently validates the automated MVP journey.
- **US2**: Depends on shared Rules fixtures; independently validates access control and may run in parallel with US1.
- **US3**: Depends on safe diagnostics foundations and uses US1 journeys as instrumentation targets.
- **US4**: Depends on release evidence/configuration foundations and cannot perform manual/store tasks without explicit approval.

### Parallel opportunities

- T002-T005 can run in parallel after T001.
- T007, T013, T014, T016, and T017 can run in parallel where file ownership does not overlap.
- T018-T020 and T023-T024 can run in parallel within US1.
- T028-T032 are sequential because they update the common Rules suite; T033 may proceed in parallel after T017.
- T036-T037 can run in parallel within US3.
- T046-T047 can run in parallel within US4 after platform identity choices in T044-T045.

## Parallel Example: User Story 3

```text
Task: "T036 release-version and redaction tests in test/core/error/global_error_handler_test.dart"
Task: "T037 allowlisted telemetry tests in test/core/data/repositories/diagnostics_repository_impl_test.dart"
```

## Implementation Strategy

### MVP first

1. Finish Setup and Foundational work.
2. Complete US1 automated MVP coverage and validate it independently.
3. Complete US2 protected-access validation before treating any candidate as releasable.

### Incremental delivery

1. Add US1 and US2 to establish reliable, protected MVP operation.
2. Add US3 to make the candidate observable and measurable.
3. Add US4 configuration/materials, then request approval for physical-device, beta, and store steps.
4. Complete Phase 7 only when candidate evidence is complete and all gates pass twice.

## Notes

- Every task follows the required checkbox, ID, optional parallel marker, story label, and exact-path format.
- T053-T055 intentionally require explicit user approval under the constitution; do not execute them as ordinary implementation work.
- The 10%/50% first-release stages are invited beta cohorts; subsequent Android/iOS updates use store-native staged/phased release controls.
