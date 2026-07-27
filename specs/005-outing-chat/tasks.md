# Tasks: Outing Chat

**Input**: Design documents from `specs/005-outing-chat/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Automated tests are required by the project constitution for domain logic, repositories, Cubits, widgets, Cloud Functions, integration flows, and Firestore Security Rules. Test tasks appear before their corresponding implementation tasks.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated as an independently useful increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it changes different files and does not depend on an incomplete task
- **[Story]**: Maps a task to a user story from [spec.md](./spec.md)
- Every task names the exact file or files it changes

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared Firebase configuration and focused test harnesses without introducing new Flutter dependencies.

- [X] T001 Create the `firestore.indexes.json` configuration scaffold and reference it from `firebase.json`, deferring story-specific history indexes to T053 and cleanup/TTL policies to T076
- [X] T002 [P] Add focused `test:chat` and `test:chat:integration` scripts while preserving existing scripts in `functions/package.json`
- [X] T003 [P] Create reusable Auth/Firestore/Functions emulator fixtures for chat tests in `functions/test/chat/chat_test_utils.ts`
- [X] T004 [P] Create shared fake repository, clock, message, command, and outing builders in `test/features/chat/chat_test_helpers.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish provider-neutral chat types, contracts, validation policies, serialization, and trusted time before any user story implementation.

**CRITICAL**: No user story work begins until this phase is complete.

### Foundational Tests

- [X] T005 [P] Add entity equality, stable cursor ordering, page-bound, send-attempt, summary, and failure tests in `test/features/chat/domain/chat_entities_test.dart`
- [X] T006 [P] Add writable lifecycle, membership, participation, attendance-independence, and revocation policy tests in `test/features/chat/domain/chat_access_policy_test.dart`
- [X] T007 [P] Add exact 24-hour cutoff, wrong-device-clock, next-expiry scheduling, server-time probe offset, offline establishment failure, refresh, and probe cleanup tests in `test/features/chat/domain/chat_expiry_policy_test.dart` and `test/features/chat/data/services/firestore_chat_clock_test.dart`
- [X] T008 [P] Add Unicode-whitespace trimming, 1-2,000 scalar-value limits, timestamps, snapshots, and terminal payload mapping tests in `test/features/chat/data/models/chat_models_test.dart`
- [X] T009 Prove the expiry-constrained `get`/`list` Rules strategy against `request.time`, trusted-clock drift, long-lived listeners, and boundary expiration in `firestore_tests/rules.test.js`; revise `specs/005-outing-chat/plan.md` before repository work if direct list queries cannot satisfy the approved access model

### Foundational Implementation

- [X] T010 [P] Implement immutable message and ordering values in `lib/features/chat/domain/entities/chat_message.dart` and `lib/features/chat/domain/entities/chat_message_cursor.dart`
- [X] T011 [P] Implement bounded history page values in `lib/features/chat/domain/entities/chat_page.dart`
- [X] T012 [P] Implement command status, stable client identity, local attempt state, and safe failure values in `lib/features/chat/domain/entities/chat_command.dart`
- [X] T013 [P] Implement private cursor and outing summary values in `lib/features/chat/domain/entities/chat_read_state.dart`
- [X] T014 Define the provider-neutral history, send, command, read-state, and summary interface in `lib/features/chat/domain/repositories/chat_repository.dart`
- [X] T015 [P] Implement lifecycle and eligibility decisions in `lib/features/chat/domain/services/chat_access_policy.dart`
- [X] T016 [P] Define the trusted clock abstraction in `lib/features/chat/domain/services/chat_clock.dart`
- [X] T017 Implement exact availability filtering and next-expiry scheduling against `ChatClock` in `lib/features/chat/domain/services/chat_expiry_policy.dart`
- [X] T018 [P] Implement command serialization, terminal result mapping, and safe error-code mapping in `lib/features/chat/data/models/chat_command_model.dart`
- [X] T019 [P] Implement immutable message serialization and author snapshot mapping in `lib/features/chat/data/models/chat_message_model.dart`
- [X] T020 [P] Implement private monotonic cursor serialization in `lib/features/chat/data/models/chat_read_state_model.dart`
- [X] T021 Implement the owner-private online server-time probe, monotonic round-trip offset, refresh, and best-effort probe removal in `lib/features/chat/data/services/firestore_chat_clock.dart`

**Checkpoint**: Domain and data contracts are stable, tested, provider-neutral, and ready for story work.

---

## Phase 3: User Story 1 — Exchange Outing Messages (Priority: P1) MVP

**Goal**: Let eligible participants exchange valid plain-text messages in one stable realtime conversation, with online-only explicit retry, idempotency, lifecycle enforcement, and a rolling per-participant rate limit.

**Independent Test**: Add two current crew members as participants in one writable outing, exchange messages, and establish that both see the same ordered conversation while invalid text, offline sends, excess sends, and users outside the outing fail safely without duplicates or metadata exposure.

### Tests for User Story 1

- [X] T022 [P] [US1] Add Rules emulator cases for message reads, exact command creates, attendance independence, requester-only command reads, invalid shapes, client message writes, and inaccessible rate buckets in `firestore_tests/rules.test.js`
- [X] T023 [P] [US1] Add command parsing and Unicode scalar-value validation tests in `functions/test/chat/command_schema.test.ts`
- [X] T024 [P] [US1] Add acceptance transaction tests for eligibility, lifecycle, author snapshots, deterministic identity, lost acknowledgements, rolling-window concurrency, retry times, and payload scrubbing in `functions/test/chat/chat_transactions.test.ts`
- [X] T025 [P] [US1] Add duplicate trigger, claim ownership, terminal no-op, and safe error tests in `functions/test/chat/command_handler.test.ts`
- [X] T026 [P] [US1] Add repository tests for bounded latest snapshots, online-only transaction failure, command observation, explicit retry identity, failure mapping, and access-revocation clearing in `test/features/chat/data/repositories/chat_repository_impl_test.dart`
- [X] T027 [P] [US1] Add Cubit tests for initial loading, realtime merge, sending/sent/failed states, manual retry, rate-limit countdown, validation, and protected-state clearing in `test/features/chat/presentation/cubit/outing_chat_cubit_test.dart`
- [X] T028 [P] [US1] Add widget tests for composer validation, pending/failed retry affordances, identity-conflict explicit-resend guidance, author attribution, message ordering, blocked access, and writable status in `test/features/chat/presentation/screens/outing_chat_screen_test.dart`
- [X] T029 [P] [US1] Add route and outing-card chat-entry tests in `test/core/routes/app_router_test.dart` and `test/features/outings/presentation/widgets/interactive_outing_card_test.dart`

### Implementation for User Story 1

- [X] T030 [P] [US1] Add exact command schema parsing, Unicode trimming, scalar limits, stable error codes, and sanitized results in `functions/src/chat/command_schema.ts`
- [X] T031 [US1] Implement trusted command claiming, authorization rereads, deterministic message creation, author snapshots, rolling rate buckets, idempotent success, and terminal payload scrubbing in `functions/src/chat/chat_transactions.ts`
- [X] T032 [US1] Implement the v2 Firestore command trigger with duplicate-delivery convergence and sanitized logging in `functions/src/chat/command_handler.ts`
- [X] T033 [US1] Export the chat command trigger from `functions/src/index.ts`
- [X] T034 [US1] Add participant-only message/query rules, create-only command rules, requester-private command reads, denied rate-bucket access, and owner-private time-probe rules in `firestore.rules`
- [X] T035 [US1] Implement latest-50 message watching, online-only command transactions, command watching, and access-error mapping in `lib/features/chat/data/datasources/firestore_chat_datasource.dart`
- [X] T036 [US1] Implement latest-message mapping, expiry filtering, send validation, stable manual-retry identity, and command result mapping in `lib/features/chat/data/repositories/chat_repository_impl.dart`
- [X] T037 [US1] Implement realtime conversation and local send-attempt state management in `lib/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart`
- [X] T038 [P] [US1] Implement trimmed text entry, scalar counter, submit gating, sending state, and explicit retry UI in `lib/features/chat/presentation/widgets/chat_composer.dart`
- [X] T039 [P] [US1] Implement immutable text bubbles with allowed author snapshots, timestamps, and local outcome presentation in `lib/features/chat/presentation/widgets/chat_message_bubble.dart`
- [X] T040 [US1] Compose access, loading, empty, error, writable, and conversation states in `lib/features/chat/presentation/screens/outing_chat_screen.dart`
- [X] T041 [US1] Register lazy chat clock/datasource/repository services and factory Cubits in `lib/core/di/injection_container.dart`
- [X] T042 [US1] Add the `/outings/:outingId/chat` route and scoped Cubit construction in `lib/core/routes/app_router.dart`
- [X] T043 [US1] Add the eligible participant chat entry and writable/read-only affordance to `lib/features/outings/presentation/widgets/interactive_outing_card.dart`

**Checkpoint**: User Story 1 is a usable MVP with secure realtime messaging, manual retry, and trusted acceptance.

---

## Phase 4: User Story 2 — Review Recent Conversation History (Priority: P2)

**Goal**: Let participants reopen chats and progressively review all still-available history in stable order without gaps, duplicates, scroll jumps, or expired content.

**Independent Test**: Seed more than 100 unexpired messages including tied acceptance times, reopen on another session, load older pages, receive a new message while reading older content, and establish stable one-time ordering while expired content remains unavailable even with an incorrect device clock.

### Tests for User Story 2

- [X] T044 [P] [US2] Add repository tests for two-field cursors, 50-item page caps, tied timestamps, deduplication, concurrent realtime/page merges, new-participant history, trusted cutoffs, and unavailable offline clock establishment in `test/features/chat/data/repositories/chat_repository_impl_test.dart`
- [X] T045 [P] [US2] Add Cubit tests for progressive older loading, exhaustion, stable viewport intent, new-message affordance, reconnect refresh, and exact expiry removal in `test/features/chat/presentation/cubit/outing_chat_cubit_test.dart`
- [X] T046 [P] [US2] Add screen tests for newest-first opening, older-history controls, first-load/next-page failures, empty history, new-message affordance, and preserved reading position in `test/features/chat/presentation/screens/outing_chat_screen_test.dart`
- [X] T047 [P] [US2] Add Rules emulator cases for the proven outing-scoped list strategy, accepted-time/document-ID ordering, direct expired gets, 50-item history limits, aggregation bounds, and forbidden unscoped queries in `firestore_tests/rules.test.js`

### Implementation for User Story 2

- [X] T048 [US2] Implement two-field newest and older queries with 50-item caps and trusted expiry cutoffs in `lib/features/chat/data/datasources/firestore_chat_datasource.dart`
- [X] T049 [US2] Implement chronological page reversal, cross-boundary ID deduplication, stable merging, cursor exhaustion, and expiry timers in `lib/features/chat/data/repositories/chat_repository_impl.dart`
- [X] T050 [US2] Extend conversation state with older-page loading, viewport preservation intent, reconnect behavior, and next-expiry removal in `lib/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart`
- [X] T051 [US2] Implement stable chronological slivers, older loading states, and new-message affordances in `lib/features/chat/presentation/widgets/chat_history_list.dart`
- [X] T052 [US2] Integrate paginated history, expiry transitions, and viewport behavior in `lib/features/chat/presentation/screens/outing_chat_screen.dart`
- [X] T053 [US2] Add the history and unread aggregation query indexes in `firestore.indexes.json`

**Checkpoint**: User Stories 1 and 2 work independently; history remains bounded, stable, and retention-safe.

---

## Phase 5: User Story 3 — Keep Track of Unread Messages (Priority: P3)

**Goal**: Provide private, cross-session read progress, accurate unread counts that exclude own/expired messages, an outing-card badge, and first-unread positioning without exposing read receipts.

**Independent Test**: Send messages while one participant is outside chat, establish the badge count excludes their own messages, open at the first unread item, read through newest, and establish zero unread state on another session while no other user—including organizers—can read the private cursor.

### Tests for User Story 3

- [X] T054 [P] [US3] Add Rules emulator cases for owner-only read-state get/list/create/advance, immutable identity, monotonic cursors, readable-message validation, expired cursors, and cross-user denial in `firestore_tests/rules.test.js`
- [X] T055 [P] [US3] Add repository tests for monotonic mark-through, effective expired cursor fallback, bounded all-author/own-author count subtraction, reconnect refresh, and private failure mapping in `test/features/chat/data/repositories/chat_repository_impl_test.dart`
- [X] T056 [P] [US3] Add summary Cubit tests for access, newest-message, cursor, and reconnect refresh signals plus read-only status in `test/features/chat/presentation/cubit/chat_summary_cubit_test.dart`
- [X] T057 [P] [US3] Add chat-screen tests for first-unread positioning and mark-through-newest behavior in `test/features/chat/presentation/screens/outing_chat_screen_test.dart`
- [X] T058 [P] [US3] Add outing-card tests for zero/nonzero unread badges, lifecycle labels, inaccessible chats, and no cross-user receipt UI in `test/features/outings/presentation/widgets/interactive_outing_card_test.dart`

### Implementation for User Story 3

- [X] T059 [US3] Add owner-private monotonic read-state and bounded unread aggregation query rules in `firestore.rules`
- [X] T060 [US3] Implement personal cursor watching/writing and bounded all-author/own-author aggregation reads in `lib/features/chat/data/datasources/firestore_chat_datasource.dart`
- [X] T061 [US3] Implement effective-cursor fallback, monotonic read advancement, unread subtraction, and summary refresh triggers in `lib/features/chat/data/repositories/chat_repository_impl.dart`
- [X] T062 [US3] Implement private unread and writable-summary state management in `lib/features/chat/presentation/cubit/chat_summary/chat_summary_cubit.dart`
- [X] T063 [P] [US3] Implement the accessible zero/nonzero unread indicator in `lib/features/chat/presentation/widgets/chat_unread_badge.dart`
- [X] T064 [US3] Advance read state only after viewing through the newest available message and open at the first available unread message in `lib/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart` and `lib/features/chat/presentation/screens/outing_chat_screen.dart`
- [X] T065 [US3] Integrate scoped summary state, unread badge, and read-only label without receipts in `lib/features/outings/presentation/widgets/interactive_outing_card.dart`

**Checkpoint**: User Stories 1–3 work independently with private, accurate, retention-aware unread state.

---

## Phase 6: User Story 4 — End Chat Access Safely (Priority: P4)

**Goal**: Revoke access immediately, keep terminal outings read-only, enforce exact 24-hour unavailability, permanently delete ephemeral records, and prevent outing-removal races from recreating chat data.

**Independent Test**: Exercise participant/crew removal, terminal outing statuses, exact expiry boundaries, repeated scheduled cleanup, abandoned commands/probes, and creator/expiry outing deletion racing a send; establish immediate denial, safe read-only behavior, hard deletion, idempotency, and no recreation.

### Tests for User Story 4

- [X] T066 [P] [US4] Add cleanup tests for message, terminal/abandoned command, cursor, rate-bucket, and stale-probe batches, retry safety, invocation bounds, and text-free logs in `functions/test/chat/cleanup.test.ts`
- [X] T067 [P] [US4] Add outing-deletion tests for deletion marking, command termination/scrubbing, every lifecycle status, second sweeps, repeated deletion, and concurrent send rejection in `functions/test/chat/outing_deletion.test.ts`
- [X] T068 [P] [US4] Add integrated emulator tests for eligibility revocation, terminal read-only state, exact visibility boundary, command processing, scheduled cleanup services, and outing-removal races in `functions/test/chat/chat_integration.test.ts`
- [X] T069 [P] [US4] Add Rules emulator cases for participant/membership removal, terminal-status reads versus sends, deletion-pending denial, expired reads, and direct outing deletion protection in `firestore_tests/rules.test.js`
- [X] T070 [P] [US4] Add Cubit and screen tests proving protected content clears within one second after an observed revocation signal, later stale chat state is rejected, and read-only, expiry, safe-reason, and permanent-removal transitions remain correct in `test/features/chat/presentation/cubit/outing_chat_cubit_test.dart` and `test/features/chat/presentation/screens/outing_chat_screen_test.dart`

### Implementation for User Story 4

- [X] T071 [US4] Implement bounded minutely cleanup for expired messages, terminal/abandoned commands, read cursors, rate buckets, and stale time probes with sanitized observability in `functions/src/chat/cleanup.ts`
- [X] T072 [US4] Export the scheduled chat cleanup function from `functions/src/index.ts`
- [X] T073 [US4] Extend outing deletion to mark `deletionPending`, terminate commands, sweep every chat-owned collection, delete the outing, and repeat the sweep idempotently in `functions/src/outings/outing_deletion.ts`
- [X] T074 [US4] Harden command acceptance against deletion-pending/absent outings and overlapping deletion after claim in `functions/src/chat/chat_transactions.ts`
- [X] T075 [US4] Complete expiry, lifecycle, deletion-pending, and immediate eligibility-revocation protections in `firestore.rules`
- [X] T076 [US4] Add cleanup and outing-ownership indexes plus all persistent TTL backstops in `firestore.indexes.json`
- [X] T077 [US4] Map terminal outing states, removed access, trusted-clock loss, expiry, and outing absence to protected read-only/inaccessible presentation state in `lib/features/chat/data/repositories/chat_repository_impl.dart` and `lib/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart`
- [X] T078 [US4] Present non-sensitive lifecycle, membership, connectivity, expiry, and removal explanations while clearing cached protected content in `lib/features/chat/presentation/screens/outing_chat_screen.dart`

**Checkpoint**: All four stories satisfy authorization, lifecycle, privacy, retention, and deletion-race requirements.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Complete regression, performance, platform, deployment, documentation, and release-quality gates that span multiple stories.

- [X] T079 [P] Add DI registration and disposal regression coverage for chat services and Cubits in `test/core/di/injection_container_test.dart`
- [X] T080 [P] Add accessibility, text direction, line break, emoji, link text, and large-history widget coverage in `test/features/chat/presentation/screens/outing_chat_screen_test.dart`
- [X] T081 [P] Add regressions proving agreement, outing, membership, and participant rules remain unchanged outside chat in `firestore_tests/rules.test.js`
- [X] T082 Add sanitized structured metrics for command terminal latency, rate-limit rejection, cleanup failure, and permission denial without message content in `functions/src/chat/command_handler.ts` and `functions/src/chat/cleanup.ts`
- [X] T083 Run focused and full Flutter tests plus static analysis from `specs/005-outing-chat/quickstart.md`, fixing regressions in the exact source/test paths identified by the failing output
- [X] T084 Run focused/full Functions, Firestore Rules, and integrated emulator suites from `specs/005-outing-chat/quickstart.md`, fixing regressions in the exact source/test paths identified by the failing output
- [X] T085 Validate newest-page and accepted-send performance against SC-002 and SC-007 with up to 100 participants and 5,000 unexpired messages, recording automated evidence in `specs/005-outing-chat/quickstart.md`
- [ ] T086 Obtain explicit user authorization before usability studies or manual Android, iOS, Web, and Windows E2E execution, recording the authorization in `specs/005-outing-chat/quickstart.md`
- [ ] T087 Run the authorized SC-001 and SC-008 usability protocol, calculate success against the required percentage of the total sample and minimum-success floor, and record participant counts, platform distribution, timings, success rates, and observations in `specs/005-outing-chat/quickstart.md`
- [ ] T088 Run authorized Android, iOS, Web, and Windows smoke tests and record results and Windows support observations in `specs/005-outing-chat/quickstart.md`
- [ ] T089 Coordinate deployed Security Rules, Functions scheduler, indexes, and TTL smoke validation without enabling chat beforehand, recording project-plan and production evidence in `specs/005-outing-chat/quickstart.md`
- [X] T090 Reconcile implemented behavior and commands with `specs/005-outing-chat/spec.md`, `specs/005-outing-chat/plan.md`, `specs/005-outing-chat/contracts/`, and `specs/005-outing-chat/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 — Setup**: Starts immediately.
- **Phase 2 — Foundational**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 — User Story 1**: Depends on Phase 2 and provides the MVP message exchange.
- **Phase 4 — User Story 2**: Depends on the shared repository and conversation state introduced by User Story 1; its pagination and history behavior remains independently testable.
- **Phase 5 — User Story 3**: Depends on the shared repository and newest-message signal from User Story 1; it does not require older-history loading from User Story 2.
- **Phase 6 — User Story 4**: Depends on the command, repository, and lifecycle paths established by User Story 1; its cleanup and removal paths can be developed alongside User Stories 2 and 3 after that point.
- **Phase 7 — Polish**: Depends on every story selected for release. Manual E2E and deployed-project checks remain gated by user authorization and deployment authority.

### User Story Dependency Graph

```text
Setup -> Foundational -> US1 (MVP)
                         |---> US2
                         |---> US3
                         `---> US4
US2 + US3 + US4 -> Polish and release gates
```

### Within Each User Story

- Write the story's automated tests first and establish that they fail for the missing behavior.
- Implement domain/data contracts before Cubits, and Cubits before widgets/screens.
- Implement Rules and trusted Function authorization before treating client access as complete.
- Complete the independent test at the phase checkpoint before starting the next sequential story.

### Parallel Opportunities

- In Setup, T002–T004 can run in parallel after T001's configuration shape is known.
- In Foundational, T005–T008 can run in parallel; T009 is the blocking Rules/query proof; T010–T013, T015–T016, and T018–T020 touch independent files after that proof passes.
- In US1, T022–T029 can be authored in parallel; T030, T034, T038, and T039 touch separate layers.
- In US2, T044–T047 can run in parallel, followed by independent UI work in T051 while repository queries are completed.
- In US3, T054–T058 can run in parallel, and T059, T062, and T063 touch independent layers.
- In US4, T066–T070 can run in parallel; T071 and T073 are separate trusted services.
- After US1, US2, US3, and US4 can be assigned concurrently, subject to coordination around shared repository, Rules, Cubit, and index files.

---

## Parallel Execution Examples

### User Story 1

```text
Task T023: functions/test/chat/command_schema.test.ts
Task T026: test/features/chat/data/repositories/chat_repository_impl_test.dart
Task T027: test/features/chat/presentation/cubit/outing_chat_cubit_test.dart
Task T029: test/core/routes/app_router_test.dart and interactive_outing_card_test.dart
```

### User Story 2

```text
Task T044: repository pagination and merge tests
Task T045: Cubit paging and expiry tests
Task T046: history screen behavior tests
Task T047: bounded history Rules tests
```

### User Story 3

```text
Task T054: private read-state Rules tests
Task T056: summary Cubit tests
Task T057: first-unread screen tests
Task T058: outing-card badge tests
```

### User Story 4

```text
Task T066: scheduled cleanup tests
Task T067: outing-deletion tests
Task T069: lifecycle and revocation Rules tests
Task T070: lifecycle presentation tests
```

---

## Implementation Strategy

### MVP First — User Story 1

1. Complete Setup and Foundational phases.
2. Complete User Story 1 tests and implementation.
3. Run the US1 independent test with two participants and one excluded user.
4. Stop and validate secure online-only exchange, retry, idempotency, ordering, and rate limiting before adding history/read-state features.

### Incremental Delivery

1. **Foundation**: Provider-neutral entities, policies, repository contract, serialization, and trusted clock.
2. **US1 MVP**: Secure realtime text exchange with manual retry and trusted rate limiting.
3. **US2**: Stable bounded history, pagination, and exact retention visibility.
4. **US3**: Private read progress, unread summary, first-unread positioning, and outing badge.
5. **US4**: Immediate revocation, terminal read-only state, hard cleanup, and race-safe outing deletion.
6. **Release**: Full regression, performance evidence, authorized cross-platform E2E, and coordinated deployed configuration smoke checks.

### Team Parallelization

After US1 stabilizes, separate owners can implement US2 history, US3 unread state, and US4 backend cleanup/removal. Shared edits to `firestore.rules`, `firestore.indexes.json`, `lib/features/chat/data/repositories/chat_repository_impl.dart`, and `lib/features/chat/presentation/cubit/outing_chat/outing_chat_cubit.dart` must be sequenced or integrated deliberately.

---

## Notes

- `[P]` marks tasks that can proceed without an incomplete task changing the same files.
- Story labels provide traceability to the four prioritized scenarios in [spec.md](./spec.md).
- No new Flutter connectivity or callable-Functions dependency is introduced.
- Test tasks precede implementation because automated coverage is constitutionally required.
- T086 must pause for explicit user permission before any usability study or manual E2E execution.
- T089 requires valid deployment authority and must not be inferred from task generation alone.
- Commit after each task or coherent task group, and stop at any checkpoint for independent validation.
