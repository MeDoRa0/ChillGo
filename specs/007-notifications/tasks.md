# Tasks: Notifications

**Input**: Design documents from `specs/007-notifications/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`

**Tests**: Automated tests are required by the specification and constitution. User-approved device-push smoke checks are deliberately separate from automated work.

## Phase 1: Setup

**Purpose**: Add the feature's shared project and deployment configuration.

- [X] T001 [P] Verify and configure the existing Firebase Messaging dependency for platform-safe notification use in `pubspec.yaml`
- [X] T002 [P] Add notification-specific Functions test scripts and verify existing Firebase Admin support in `functions/package.json`
- [X] T003 [P] Configure notification collection indexes, TTL policies, and scheduled cleanup deployment settings in `firestore.indexes.json` and `firebase.json`
- [X] T004 [P] Configure Android notification permission, channel metadata, and Messaging receiver requirements in `android/app/src/main/AndroidManifest.xml`
- [X] T005 [P] Configure iOS Push Notifications and background remote-notification capabilities in `ios/Runner/Info.plist` and `ios/Runner/Runner.entitlements`
- [X] T006 [P] Add the Firebase Messaging web service worker and Web notification bootstrap settings in `web/firebase-messaging-sw.js` and `web/index.html`

---

## Phase 2: Foundational

**Purpose**: Build the private data model, authorization boundary, trusted outbox, and client interfaces that every story needs.

- [X] T007 [P] Define notification category, target, display, cursor, and unavailable-outcome entities in `lib/features/notifications/domain/entities/notification.dart`
- [X] T008 [P] Define notification page, unread summary, and optional-alert preference entities in `lib/features/notifications/domain/entities/notification_page.dart` and `lib/features/notifications/domain/entities/notification_preferences.dart`
- [X] T009 [P] Define platform-neutral device registration, capability, and foreground/opened alert entities in `lib/features/notifications/domain/entities/device_alert.dart`
- [X] T010 [P] Define the private center, command, preference, and device-registration contract in `lib/features/notifications/domain/repositories/notification_repository.dart`
- [X] T011 [P] Define provider-neutral alert and cleanup-transition interfaces in `lib/features/notifications/domain/services/device_alert_service.dart` and `lib/features/notifications/domain/services/notification_transition_service.dart`
- [ ] T012 [P] Add entity, repository-contract, and failure-category unit tests in `test/features/notifications/domain/notification_entities_test.dart` and `test/features/notifications/domain/notification_repository_contract_test.dart`
- [ ] T013 [P] Add notification DTO serialization and cursor/query tests in `test/features/notifications/data/models/notification_models_test.dart`
- [ ] T014 Implement Firestore notification, summary, preference, command, and device DTOs in `lib/features/notifications/data/models/notification_model.dart`, `lib/features/notifications/data/models/notification_summary_model.dart`, `lib/features/notifications/data/models/notification_preferences_model.dart`, and `lib/features/notifications/data/models/notification_command_model.dart`
- [ ] T015 Implement recipient-scoped newest-first paging, summaries, preferences, and requester-private command submission in `lib/features/notifications/data/datasources/firestore_notifications_datasource.dart`
- [ ] T016 Implement the repository with reauthorization-safe open/read behavior and protected-state clearing in `lib/features/notifications/data/repositories/notification_repository_impl.dart`
- [ ] T017 Implement supported Android/iOS/Web permission, token, foreground, opened-message, and sign-out handling in `lib/features/notifications/data/services/firebase_messaging_device_alert_service.dart`
- [ ] T018 Implement the Windows no-device-alert adapter in `lib/features/notifications/data/services/unsupported_device_alert_service.dart`
- [ ] T019 Implement the client command bridge for marking read, opening, registering, and unregistering targets in `lib/features/notifications/data/services/firestore_notification_transition_service.dart`
- [ ] T020 Add datasource, repository, and device-adapter tests in `test/features/notifications/data/datasources/firestore_notifications_datasource_test.dart`, `test/features/notifications/data/repositories/notification_repository_impl_test.dart`, and `test/features/notifications/data/services/device_alert_service_test.dart`
- [ ] T021 Define trusted event, recipient-work, command, and transition validation schemas in `functions/src/notifications/command_schema.ts` and `functions/src/notifications/notification_transactions.ts`
- [ ] T022 Implement category-specific recipient/source eligibility rechecks and generic display construction in `functions/src/notifications/eligibility.ts`
- [ ] T023 Implement idempotent outbox claims, deterministic notification IDs, transactional unread-summary mutation, and safe repair helpers in `functions/src/notifications/event_handler.ts`
- [ ] T024 Implement command processing with payload scrubbing, bounded device registration, and stable failures in `functions/src/notifications/command_handler.ts`
- [ ] T025 Implement recipient revalidation, preference filtering, <=500-target generic FCM fan-out, and invalid-token removal in `functions/src/notifications/delivery.ts`
- [ ] T026 Implement minutely expiry cleanup, invalidation cleanup, and resumable delete-verify-finalize transitions in `functions/src/notifications/cleanup.ts` and `functions/src/notifications/transition_handler.ts`
- [ ] T027 Wire notification Functions triggers, callable/HTTP command handling, schedules, and exports in `functions/src/index.ts`
- [ ] T028 Add Function unit and emulator integration coverage for schemas, claims, summary races, delivery, expiry, and cleanup in `functions/test/notifications/command_handler.test.ts`, `functions/test/notifications/event_handler.test.ts`, `functions/test/notifications/delivery.test.ts`, and `functions/test/notifications/cleanup.test.ts`
- [ ] T029 Implement recipient-private, source-aware reads; strict preference/command validation; direct-write denial; and bounded query enforcement in `firestore.rules`
- [ ] T030 Add emulator Rules coverage for cross-user isolation, revocation, expiry, invalid payloads, denied mutations, and query bounds in `firestore_tests/rules.test.js`
- [ ] T031 Register notification repository, alert adapters, and transition service in `lib/core/di/injection_container.dart`

**Checkpoint**: The data boundary and trusted pipeline can create, read, invalidate, and clean private records without exposing protected source data.

---

## Phase 3: User Story 1 - Receive Invitations Promptly (Priority: P1)

**Goal**: Create exactly one recipient-private notification for each valid crew or outing invitation, with an authorized invitation destination.

**Independent Test**: Create crew and outing invitations, retry their triggers, then accept, decline, revoke, or expire them and verify exactly one eligible record, accurate unread count, and removal after invalidation.

- [ ] T032 [P] [US1] Add crew- and outing-invitation eligibility, display, and deterministic-event unit tests in `functions/test/notifications/invitation_events.test.ts`
- [ ] T033 [P] [US1] Add invitation creation, retry, access-loss, and Rules emulator integration coverage in `functions/test/notifications/invitation_integration.test.ts` and `firestore_tests/rules.test.js`
- [ ] T034 [US1] Emit a deterministic pending crew-invitation outbox event from legacy invitation writes in `functions/src/notifications/event_handler.ts`
- [ ] T035 [US1] Emit a deterministic non-creator outing-invitation outbox event from invited participant writes in `functions/src/notifications/event_handler.ts`
- [ ] T036 [US1] Start a resumable notification cleanup transition before invitation revocation, consumption, expiry, or source removal finalization in `functions/src/notifications/transition_handler.ts`
- [ ] T037 [US1] Add semantic crew/outing invitation destinations and unavailable mapping to `lib/features/notifications/data/repositories/notification_repository_impl.dart`
- [ ] T038 [US1] Add invitation notification widget and authorized open-flow tests in `test/features/notifications/presentation/widgets/invitation_notification_test.dart`

**Checkpoint**: Crew and outing invitations independently produce one safe notification and never leave stale invitation information after invalidation.

---

## Phase 4: User Story 2 - Stay Current on an Outing (Priority: P1)

**Goal**: Notify eligible outing participants about safe voting, agreement, and consolidated material-outing changes.

**Independent Test**: Accept a proposal, confirm/reopen an agreement, and edit multiple material outing fields; verify correct recipients, no ballot leakage, one consolidated change record, and optional-alert preference behavior.

- [ ] T039 [P] [US2] Add proposal, agreement, and material-outing-change source-mapping and privacy unit tests in `functions/test/notifications/outing_events.test.ts`
- [ ] T040 [P] [US2] Add idempotency, recipient-recheck, multi-field consolidation, and preference-delivery integration tests in `functions/test/notifications/outing_integration.test.ts`
- [ ] T041 [US2] Write voting-update and agreement-confirmed outbox events atomically with successful agreement transactions in `functions/src/agreement/agreement_transactions.ts`
- [ ] T042 [US2] Write agreement-reopened outbox events atomically with successful reopening transactions in `functions/src/agreement/agreement_transactions.ts`
- [ ] T043 [US2] Detect material outing deltas and emit one deterministic consolidated change event per successful edit in `functions/src/notifications/event_handler.ts`
- [ ] T044 [US2] Extend category eligibility and generic display shaping to exclude ballots, totals, voter identity, and invalid lifecycle states in `functions/src/notifications/eligibility.ts`
- [ ] T045 [US2] Add voting and agreement semantic destinations with reauthorization-safe unavailable states in `lib/features/notifications/data/repositories/notification_repository_impl.dart`
- [ ] T046 [US2] Add voting/agreement/change item rendering and safe changed-field copy tests in `test/features/notifications/presentation/widgets/outing_notification_test.dart`

**Checkpoint**: Outing coordination events independently create private, idempotent records and honor optional device-alert settings without muting the center.

---

## Phase 5: User Story 3 - Know When Attendees Arrive (Priority: P2)

**Goal**: Notify only the other eligible Accepted attendees when someone explicitly arrives during a Meeting outing.

**Independent Test**: Toggle arrival alerts and submit all live statuses during a Meeting period, verifying a single location-free record only for first explicit Arrived and only for eligible peers.

- [ ] T047 [P] [US3] Add first-arrival marker, eligible-recipient, repeated-status, and location-redaction unit tests in `functions/test/notifications/arrival_events.test.ts`
- [ ] T048 [P] [US3] Add Meeting/Accepted/access-loss and preference-suppression emulator integration tests in `functions/test/notifications/arrival_integration.test.ts`
- [ ] T049 [US3] Write the deterministic first-explicit-Arrived outbox event atomically with successful live-meetup status transitions in `functions/src/live_meetup/live_meetup_transactions.ts`
- [ ] T050 [US3] Enforce Meeting, Accepted-attendance, non-actor recipient, and one-per-meeting-period arrival eligibility in `functions/src/notifications/eligibility.ts`
- [ ] T051 [US3] Coordinate arrival-record cleanup before attendance loss, Meeting end, and live-meetup removal finalization in `functions/src/live_meetup/privacy_transition_coordinator.ts`
- [ ] T052 [US3] Add a location-free arrival target and unavailable-state rendering in `lib/features/notifications/data/repositories/notification_repository_impl.dart`
- [ ] T053 [US3] Add arrival notification rendering and no-location UI regression tests in `test/features/notifications/presentation/widgets/arrival_notification_test.dart`

**Checkpoint**: First explicit arrivals independently notify only valid peers and disclose no location or status beyond the authorized arrival event.

---

## Phase 6: User Story 4 - Review and Control Notifications (Priority: P2)

**Goal**: Provide the cross-platform notification center, unread badge, safe navigation, read state, preferences, and device-alert guidance.

**Independent Test**: Generate mixed categories, page through more than 100 items, read/open on another supported session, change preferences, and verify unavailable/Windows/denied-permission outcomes remain non-sensitive.

- [ ] T054 [P] [US4] Add notification-center Cubit state transitions, paging, read/open races, and cleared-auth-state tests in `test/features/notifications/presentation/cubit/notification_center_cubit_test.dart`
- [ ] T055 [P] [US4] Add preferences Cubit and permission-guidance tests in `test/features/notifications/presentation/cubit/notification_preferences_cubit_test.dart`
- [ ] T056 [P] [US4] Add unread-badge, center pagination, unavailable-state, and accessibility widget tests in `test/features/notifications/presentation/widgets/notification_center_test.dart`
- [ ] T057 [US4] Implement watched newest-first pages, unread summary, read/open command submission, and lifecycle-safe state clearing in `lib/features/notifications/presentation/cubit/notification_center/notification_center_cubit.dart`
- [ ] T058 [US4] Implement optional-alert preference editing and explicit permission-request guidance in `lib/features/notifications/presentation/cubit/notification_preferences/notification_preferences_cubit.dart`
- [ ] T059 [US4] Implement the accessible unread badge and notification-center entry point in `lib/features/notifications/presentation/widgets/notification_unread_badge.dart` and `lib/features/home/presentation/widgets/home_mobile_layout.dart`
- [ ] T060 [US4] Implement loading, empty, error, stable paging, read/unread, and non-sensitive unavailable center states in `lib/features/notifications/presentation/screens/notification_center_screen.dart`
- [ ] T061 [US4] Implement the three mutable preferences, required-category explanation, and unsupported/denied guidance in `lib/features/notifications/presentation/screens/notification_preferences_screen.dart`
- [ ] T062 [US4] Add `/notifications` and preferences routes plus semantic destination handoff in `lib/core/routes/app_router.dart`
- [ ] T063 [US4] Initialize device registration only after authentication; handle foreground/opened alerts through repository reauthorization; unregister on sign-out in `lib/main.dart`
- [ ] T064 [US4] Add router, DI, authentication bootstrap, multi-session read state, and Windows fallback integration tests in `test/core/routes/app_router_test.dart`, `test/core/di/injection_container_test.dart`, and `test/features/notifications/notification_integration_test.dart`

**Checkpoint**: Every supported platform has a private, accessible center and preferences; device alerts remain optional and never bypass reauthorization.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Complete source lifecycle coverage, performance/security verification, and release validation documentation.

- [ ] T065 [P] Coordinate notification cleanup before crew-membership removal or crew deletion finalization in `functions/src/live_meetup/privacy_transition_coordinator.ts` and `functions/src/notifications/transition_handler.ts`
- [ ] T066 [P] Coordinate notification cleanup before outing-participant removal finalization in `functions/src/live_meetup/privacy_transition_coordinator.ts` and `functions/src/notifications/transition_handler.ts`
- [ ] T067 [P] Coordinate notification cleanup before outing-deletion finalization in `functions/src/outings/outing_deletion.ts` and `functions/src/notifications/transition_handler.ts`
- [ ] T068 [P] Add 30-day boundary, cleanup-resume, unread-summary repair, 100-recipient/500-target scale, and 100-trial-per-category SC-001 center-availability timing tests in `functions/test/notifications/cleanup.test.ts` and `functions/test/notifications/performance_profile.test.ts`
- [ ] T069 [P] Add 100-trial-per-enabled-category SC-002 provider-handoff timing tests with generic-payload assertions in `functions/test/notifications/delivery.test.ts`
- [ ] T070 [P] Run and repair focused/full Flutter, Functions, and Firestore emulator validation documented in `specs/007-notifications/quickstart.md`
- [ ] T071 [P] Verify deployed index/TTL definitions and FCM platform configuration against `firebase.json`, `firestore.indexes.json`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, and `web/firebase-messaging-sw.js`
- [ ] T072 Document the user-approval gate and run Android, physical iOS, Web, Windows fallback, and timed SC-003/SC-008 usability smoke checks only after approval in `specs/007-notifications/quickstart.md`
- [ ] T073 [P] Add a final scope-review assertion that Phase 7 introduces none of the FR-023 prohibited capabilities in `specs/007-notifications/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 1) has no dependencies.
- Foundational (Phase 2) depends on setup and blocks all stories.
- US1 and US2 (both P1) can proceed in parallel after Phase 2, except shared edits to `event_handler.ts` and `notification_repository_impl.dart` must be coordinated.
- US3 and US4 depend on the foundational pipeline; US3 can run alongside US1/US2, while US4 can begin when the repository contract is stable.
- Polish follows the desired story set.

### User Story Dependencies

- **US1**: Foundation only; MVP candidate.
- **US2**: Foundation only; shares trusted event plumbing with US1.
- **US3**: Foundation plus Live Meetup transaction integration; independent of invitation and voting flows.
- **US4**: Foundation plus repository contract; renders all categories but can be developed with fixture records.

### Parallel Examples

**US1**: Run T032 and T033 in parallel, then coordinate T034-T036 and T037; T038 can proceed once the semantic target contract is fixed.

**US2**: Run T039 and T040 in parallel; T041/T042 can be developed independently from T043, then integrate eligibility and presentation work.

**US3**: Run T047 and T048 in parallel; T049 and T051 touch separate live-meetup files, then complete T050 and T052-T053.

**US4**: Run T054-T056 in parallel; T057-T058 and T059-T061 can proceed concurrently once entity interfaces are finalized.

## Implementation Strategy

### MVP First

1. Complete Phases 1 and 2.
2. Complete US1 (T032-T038).
3. Validate invitation creation, retry idempotency, source invalidation, Rules denial, unread state, and safe navigation.
4. Demonstrate the center with invitation records before expanding event categories.

### Incremental Delivery

1. Foundation -> trusted private notification pipeline.
2. US1 -> actionable invitations.
3. US2 -> reliable outing planning updates.
4. US3 -> privacy-safe arrival awareness.
5. US4 -> full center, preferences, and platform guidance.
6. Polish -> lifecycle, scale, and approved device validation.

## Format Validation

All 73 tasks use the required checkbox, sequential task ID, optional `[P]` marker, required user-story label in story phases, explicit action, and concrete file path format.
