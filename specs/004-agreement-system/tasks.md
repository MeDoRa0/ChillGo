# Tasks: Agreement System

**Input**: Design documents from `specs/004-agreement-system/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Automated tests are included because the feature specification, contracts, and project constitution require coverage for domain logic, repositories, Cubits, widgets, Cloud Functions, migrations, and Firestore Security Rules.

**Organization**: Tasks are grouped by user story so each increment can be implemented and validated independently.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the Flutter feature boundary, Functions project, and emulator configuration used by all stories.

- [X] T001 Create the voting feature layer directories and barrel-free file structure described in the plan under `lib/features/voting/`
- [X] T002 Initialize the Node.js 22 TypeScript Functions package with Firebase Functions v2, Firebase Admin, Mocha, and firebase-functions-test in `functions/package.json`
- [X] T003 [P] Configure strict TypeScript compilation and test source inclusion in `functions/tsconfig.json`
- [X] T004 [P] Register Firestore and Functions source/emulator configuration in `firebase.json`
- [X] T005 [P] Add Functions emulator and agreement test commands to `functions/package.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Define shared agreement types, persistence mappings, command processing, privacy rules, and dependency wiring that every user story needs.

**Critical**: No user story work begins until this phase is complete.

- [X] T006 [P] Define time/location agreement categories and serialization values in `lib/features/voting/domain/entities/agreement_category.dart`
- [X] T007 [P] Define agreement round states and immutable round entity fields in `lib/features/voting/domain/entities/agreement_round.dart`
- [X] T008 [P] Define immutable proposal entity fields and deterministic time eligibility/expiry behavior in `lib/features/voting/domain/entities/agreement_proposal.dart`
- [X] T009 [P] Define private vote identity and selection fields in `lib/features/voting/domain/entities/agreement_vote.dart`
- [X] T010 [P] Define closed aggregate result fields in `lib/features/voting/domain/entities/agreement_result.dart`
- [X] T011 [P] Define command types, statuses, sanitized results, and stable failures in `lib/features/voting/domain/entities/agreement_command.dart`
- [X] T012 Define provider-neutral agreement reads, attendance, voting, and command methods in `lib/features/voting/domain/repositories/agreement_repository.dart`
- [X] T013 [P] Implement Firestore serialization for rounds in `lib/features/voting/data/models/agreement_round_model.dart`
- [X] T014 [P] Implement Firestore serialization for immutable proposals in `lib/features/voting/data/models/agreement_proposal_model.dart`
- [X] T015 [P] Implement Firestore serialization for private votes in `lib/features/voting/data/models/agreement_vote_model.dart`
- [X] T016 [P] Implement Firestore serialization for aggregate results in `lib/features/voting/data/models/agreement_result_model.dart`
- [X] T017 [P] Implement Firestore serialization for command requests and sanitized terminal states in `lib/features/voting/data/models/agreement_command_model.dart`
- [X] T018 Implement agreement snapshot queries, owner-only vote reads, predictable vote writes, and immutable command creation in `lib/features/voting/data/datasources/firestore_agreement_datasource.dart`
- [X] T019 Implement repository stream composition, local validation, command dispatch, and stable failure mapping in `lib/features/voting/data/repositories/agreement_repository_impl.dart`
- [X] T020 [P] Define strict command request schemas, payload allowlists, and stable error codes in `functions/src/agreement/command_schema.ts`
- [X] T021 [P] Implement eligibility resolution and sealed tally primitives that exclude ineligible voters and expired proposals in `functions/src/agreement/agreement_tally.ts`
- [X] T022 Implement transactional idempotent command claiming, deterministic effects, and terminal status updates in `functions/src/agreement/agreement_transactions.ts`
- [X] T023 Implement Firestore v2 command dispatch with safe error sanitization in `functions/src/agreement/command_handler.ts`
- [X] T024 Export the agreement command trigger from `functions/src/index.ts`
- [X] T025 Add shared crew, participant, round, proposal, vote, result, and command rule helpers and collection match blocks in `firestore.rules`
- [X] T026 Register AgreementRepository, its datasource, and agreement Cubits in `lib/core/di/injection_container.dart`

**Checkpoint**: Shared agreement storage, trusted command processing, privacy boundaries, and dependency injection are ready.

---

## Phase 3: User Story 1 - Respond to an Outing (Priority: P1) MVP

**Goal**: Invited participants can accept or decline before Meeting, change their response, remain in the roster, and see accurate attendance summaries.

**Independent Test**: Add a current crew member as an invited outing participant, change that member between Accepted and Declined, and verify one participant record and the Invited/Accepted/Declined counts update; reject a non-participant and post-Meeting response.

### Tests for User Story 1

- [X] T027 [P] [US1] Add entity tests for defaults, valid response changes, creator acceptance, and legacy field fallback in `test/features/outings/domain/outing_participant_entity_test.dart`
- [X] T028 [P] [US1] Add model and migration mapping tests for attendanceStatus/respondedAt in `test/features/outings/data/models/outing_participant_model_test.dart`
- [X] T029 [P] [US1] Add repository tests for response writes, stable failures, and one-record semantics in `test/features/outings/data/repositories/outing_repository_impl_test.dart`
- [X] T030 [P] [US1] Add lifecycle tests that permit responses before Meeting and reject them from Meeting onward in `test/features/outings/domain/outing_lifecycle_policy_test.dart`
- [X] T031 [P] [US1] Add rules emulator cases for participant-only responses, membership loss, field allowlists, and Meeting cutoff in `firestore_tests/rules.test.js`
- [X] T032 [P] [US1] Add widget coverage for separate attendance counts and response controls in `test/features/voting/presentation/screens/agreement_screen_test.dart`

### Implementation for User Story 1

- [X] T033 [P] [US1] Define invited, accepted, and declined attendance values in `lib/features/outings/domain/entities/attendance_status.dart`
- [X] T034 [US1] Extend the participant entity with attendanceStatus/respondedAt and legacy defaults in `lib/features/outings/domain/entities/outing_participant.dart`
- [X] T035 [US1] Extend participant Firestore mapping and creator/invite defaults in `lib/features/outings/data/models/outing_participant_model.dart`
- [X] T036 [US1] Add participant response semantics and remove acceptance-as-participant-creation from `lib/features/outings/domain/repositories/outing_repository.dart`
- [X] T037 [US1] Implement response updates and participant creation defaults in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`
- [X] T038 [US1] Map attendance response validation and failures in `lib/features/outings/data/repositories/outing_repository_impl.dart`
- [X] T039 [US1] Enforce the pre-Meeting attendance transition policy in `lib/features/outings/domain/services/outing_lifecycle_policy.dart`
- [X] T040 [US1] Enforce participant-only attendance field updates and creator/invite defaults in `firestore.rules`
- [X] T041 [P] [US1] Implement Invited/Accepted/Declined counts and current-user response controls in `lib/features/voting/presentation/widgets/attendance_summary.dart`
- [X] T042 [US1] Add attendance state loading and response actions to `lib/features/voting/presentation/cubit/agreement_detail/agreement_detail_cubit.dart`
- [X] T043 [US1] Render attendance state, controls, and blocked-action messages in `lib/features/voting/presentation/screens/agreement_screen.dart`
- [X] T044 [US1] Backfill legacy participant attendance fields with creator acceptance and invited defaults in `firestore_tests/migrate_schema.js`

**Checkpoint**: User Story 1 is independently functional and is the suggested MVP.

---

## Phase 4: User Story 2 - Suggest Times and Locations (Priority: P2)

**Goal**: Accepted participants can submit immutable, deduplicated future-time and normalized-location proposals during Planning.

**Independent Test**: Open a Planning round for an accepted participant, submit one future time and one location, retry equivalent values, and verify two reusable choices with visible authors; reject invalid state, input, expiry, and mutation attempts.

### Tests for User Story 2

- [X] T045 [P] [US2] Add repository tests for proposal command creation, validation, reuse results, and failure mapping in `test/features/voting/data/repositories/agreement_repository_impl_test.dart`
- [X] T046 [P] [US2] Add Functions tests for open-round seeding, normalization, deduplication, immutability, limits, and invalid states in `functions/test/agreement/command_handler.test.ts`
- [X] T047 [P] [US2] Add rules tests denying proposal writes and unauthorized proposal/round reads in `firestore_tests/rules.test.js`
- [X] T048 [P] [US2] Add ballot widget tests for proposal visibility, author display, validation, and immutable choices in `test/features/voting/presentation/screens/agreement_screen_test.dart`

### Implementation for User Story 2

- [X] T049 [US2] Implement transactional open_round and create_proposal operations with seeded choices, normalization, deduplication, expiry checks, and category caps in `functions/src/agreement/agreement_transactions.ts`
- [X] T050 [US2] Enforce organizer/accepted-participant roles and Planning/open-round preconditions for proposal commands in `functions/src/agreement/command_handler.ts`
- [X] T051 [US2] Deny client proposal mutations and restrict proposal/round reads to current crew members in `firestore.rules`
- [X] T052 [US2] Add open-round and time/location proposal command methods to `lib/features/voting/data/repositories/agreement_repository_impl.dart`
- [X] T053 [P] [US2] Implement time and location proposal forms, immutable choices, author labels, and expired-time states in `lib/features/voting/presentation/widgets/proposal_ballot.dart`
- [X] T054 [US2] Add proposal/open-round pending, success, reused, validation, and terminal failure flows in `lib/features/voting/presentation/cubit/agreement_command/agreement_command_cubit.dart`
- [X] T055 [US2] Integrate open-round and proposal interactions into `lib/features/voting/presentation/screens/agreement_screen.dart`

**Checkpoint**: User Stories 1 and 2 work independently; Planning produces valid ballot choices.

---

## Phase 5: User Story 3 - Vote on Proposed Details (Priority: P3)

**Goal**: Accepted participants can cast, move, and withdraw one private vote per category while all interim aggregate information stays sealed.

**Independent Test**: Cast and change time/location votes using two accepted users, verify predictable one-vote-per-category documents and each user's own selections, and prove totals, ties, participation, and other ballots cannot be read while open.

### Tests for User Story 3

- [X] T056 [P] [US3] Add direct unit tests for proposal time eligibility/expiry behavior and agreement eligibility policy decisions covering attendance, crew membership, outing state, proposal category, and expiry in `test/features/voting/domain/agreement_eligibility_policy_test.dart`
- [X] T057 [P] [US3] Add sealed visibility tests for open rounds, own selections, closed aggregates, and private ballots in `test/features/voting/domain/agreement_visibility_policy_test.dart`
- [X] T058 [P] [US3] Add repository tests for predictable vote IDs, selection changes, withdrawal, and private streams in `test/features/voting/data/repositories/agreement_repository_impl_test.dart`
- [X] T059 [P] [US3] Add Cubit tests for own-vote updates and hidden aggregate state in `test/features/voting/presentation/cubit/agreement_detail_cubit_test.dart`
- [X] T060 [P] [US3] Add rules tests for owner-only vote get, denied list, one vote per category, valid changes/withdrawals, and eligibility loss in `firestore_tests/rules.test.js`

### Implementation for User Story 3

- [X] T061 [P] [US3] Implement proposal and voter eligibility decisions in `lib/features/voting/domain/services/agreement_eligibility_policy.dart`
- [X] T062 [P] [US3] Implement open/closed round field visibility decisions in `lib/features/voting/domain/services/agreement_visibility_policy.dart`
- [X] T063 [US3] Enforce predictable vote identity, owner-only reads, denied lists, active proposal validation, and open-round writes in `firestore.rules`
- [X] T064 [US3] Implement cast, change, withdraw, and own-vote stream operations in `lib/features/voting/data/datasources/firestore_agreement_datasource.dart`
- [X] T065 [US3] Map vote operations and sealed agreement detail composition in `lib/features/voting/data/repositories/agreement_repository_impl.dart`
- [X] T066 [US3] Add cast/change/withdraw selection behavior without aggregate disclosure in `lib/features/voting/presentation/widgets/proposal_ballot.dart`
- [X] T067 [US3] Stream the active round, proposals, own votes, and eligibility state in `lib/features/voting/presentation/cubit/agreement_detail/agreement_detail_cubit.dart`

**Checkpoint**: User Stories 1-3 provide sealed, independently testable collaborative voting.

---

## Phase 6: User Story 4 - Confirm the Group Agreement (Priority: P4)

**Goal**: An outing creator or crew owner previews sealed ties and atomically confirms eligible leading choices, publishing aggregates only after closure.

**Independent Test**: Prepare unique and tied leaders with at least one eligible vote per category, preview as an organizer, select only tied leaders, confirm, and verify atomic outing/round/results updates; reject unauthorized, stale, empty, and concurrent confirmation attempts without leaking interim data.

### Tests for User Story 4

- [X] T068 [P] [US4] Add tally tests for eligibility filtering, expired times, unique leaders, ties, participation snapshots, and zero-vote rejection in `functions/test/agreement/agreement_tally.test.ts`
- [X] T069 [P] [US4] Add command tests for sealed preview, organizer authorization, tie validation, stale preview conflicts, idempotency, and atomic confirmation in `functions/test/agreement/command_handler.test.ts`
- [X] T070 [P] [US4] Add command Cubit tests for pending, tie-choice, confirmation-changed retry, success, and terminal failures in `test/features/voting/presentation/cubit/agreement_command_cubit_test.dart`
- [X] T071 [P] [US4] Add rules tests for requester-only commands, exact payloads, denied client result writes, closed result reads, and protected outing transitions in `firestore_tests/rules.test.js`
- [X] T072 [P] [US4] Add widget tests for organizer confirmation, tied-choice disclosure, hidden counts, and post-confirmation summaries in `test/features/voting/presentation/screens/agreement_screen_test.dart`

### Implementation for User Story 4

- [X] T073 [US4] Complete eligible tallying and leader derivation without pre-confirmation disclosure in `functions/src/agreement/agreement_tally.ts`
- [X] T074 [US4] Implement sealed preview and atomic confirm transactions with tie validation, aggregate results, lifecycle changes, and deterministic idempotency in `functions/src/agreement/agreement_transactions.ts`
- [X] T075 [US4] Dispatch preview_confirmation and confirm_round with organizer authorization and safe conflict errors in `functions/src/agreement/command_handler.ts`
- [X] T076 [US4] Enforce requester-private exact-shape commands, closed-only aggregate reads, and trusted agreement lifecycle/detail fields in `firestore.rules`
- [X] T077 [US4] Add preview and confirmation command/result mapping in `lib/features/voting/data/repositories/agreement_repository_impl.dart`
- [X] T078 [US4] Implement preview, tied-choice selection, pending completion, retry, and confirmation state in `lib/features/voting/presentation/cubit/agreement_command/agreement_command_cubit.dart`
- [X] T079 [P] [US4] Render selected choices, aggregate results, and participation totals without individual ballots in `lib/features/voting/presentation/widgets/confirmed_result_summary.dart`
- [X] T080 [US4] Integrate organizer confirmation controls and confirmed summaries into `lib/features/voting/presentation/screens/agreement_screen.dart`
- [X] T081 [US4] Prevent direct Draft-to-Planning and Planning-to-Confirmed transitions and non-Draft time/location edits in `lib/features/outings/domain/services/outing_lifecycle_policy.dart`

**Checkpoint**: User Stories 1-4 complete the core agreement lifecycle and preserve sealed-ballot privacy.

---

## Phase 7: User Story 5 - Reopen an Agreement When Plans Change (Priority: P5)

**Goal**: Authorized organizers can reopen Confirmed outings before Meeting with a reason, preserving history and starting a fresh seeded round with zero votes.

**Independent Test**: Confirm a round, reopen it with a valid reason, and verify the old round/results remain immutable, the new Planning round is seeded from current details with no votes, and later-state or unauthorized reopen attempts fail.

### Tests for User Story 5

- [X] T082 [P] [US5] Add Functions tests for reason validation, supersession, repeated rounds, seeded proposals, zero carried votes, authorization, and state rejection in `functions/test/agreement/command_handler.test.ts`
- [X] T083 [P] [US5] Add Cubit tests for reopen pending/success/failure and refreshed round history in `test/features/voting/presentation/cubit/agreement_command_cubit_test.dart`
- [X] T084 [P] [US5] Add widget tests for reopen reason input, historical rounds, and Meeting-or-later blocking in `test/features/voting/presentation/screens/agreement_screen_test.dart`
- [X] T085 [P] [US5] Add rules tests proving prior rounds/results are immutable and direct Confirmed-to-Planning writes fail in `firestore_tests/rules.test.js`

### Implementation for User Story 5

- [X] T086 [US5] Implement reopen_round to supersede the prior result, seed a new sequence, preserve history, and return the outing to Planning atomically in `functions/src/agreement/agreement_transactions.ts`
- [X] T087 [US5] Validate organizer role, Confirmed state, pre-Meeting timing, and 3-200 character reason in `functions/src/agreement/command_handler.ts`
- [X] T088 [US5] Map reopen commands and historical agreement streams in `lib/features/voting/data/repositories/agreement_repository_impl.dart`
- [X] T089 [US5] Add reopen reason, pending state, and round refresh behavior in `lib/features/voting/presentation/cubit/agreement_command/agreement_command_cubit.dart`
- [X] T090 [US5] Render reopen controls and immutable prior-round history in `lib/features/voting/presentation/screens/agreement_screen.dart`
- [X] T091 [US5] Route agreement-controlled cancellation through cancel_outing and atomically close any open round in `functions/src/agreement/agreement_transactions.ts`

**Checkpoint**: The first five user stories are functional and each confirmed round remains auditable without exposing private ballots.

---

## Phase 8: User Story 6 - Remove an Outing at Any Time (Priority: P6)

**Goal**: The outing creator can permanently remove an outing in any lifecycle status, with complete cleanup of outing-owned participant and agreement data.

**Independent Test**: Remove creator-owned outings in each supported status, verify non-creators are rejected, verify all correlated data is inaccessible afterward, and verify repeated or overlapping requests are safe.

### Tests for User Story 6

- [X] T102 [P] [US6] Add Functions tests for creator-only authorization, every lifecycle status, full correlated-data cleanup, pending-command races, and idempotent repeated deletion in `functions/test/agreement/command_handler.test.ts`
- [X] T103 [P] [US6] Add repository and widget tests proving the removal control is creator-only, available in every outing status, confirms permanent deletion, and reports pending/success/failure safely in `test/features/outings/`
- [X] T104 [P] [US6] Add Firestore Rules tests rejecting direct deletion by crew owners and participants and requiring creator-authored delete commands in `firestore_tests/rules.test.js`

### Implementation for User Story 6

- [X] T105 [US6] Add the idempotent `delete_outing` command and trusted cascading cleanup for the outing, participants, rounds, proposals, votes, results, and pending command work in `functions/src/agreement/`
- [X] T106 [US6] Route `OutingRepository.deleteOuting` and the creator-only removal UI through the command path without lifecycle-status restrictions in `lib/features/outings/`

**Checkpoint**: Creator-only permanent removal works in every status and leaves no accessible outing-owned data.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Complete routing, migration verification, integration coverage, performance validation, and repository-wide quality gates.

- [X] T092 [P] Register the outing agreement route and authorization redirects in `lib/core/routes/app_router.dart`
- [X] T093 Integrate agreement actions, attendance controls, lifecycle-controlled editing, and creator removal into `lib/features/outings/presentation/widgets/interactive_outing_card.dart` and its crew/list screen entry points
- [X] T094 [P] Add integrated Auth/Firestore/Functions emulator coverage for command triggering, duplicate delivery, concurrency, membership changes, terminal-state observation, and end-to-end timing from command creation through the resulting Firestore snapshot in `functions/test/agreement/agreement_integration.test.ts`
- [X] T095 Add the integrated Auth/Firestore/Functions emulator test script in `functions/package.json`
- [X] T096 Verify migration idempotency and post-migration attendance invariants in `firestore_tests/migrate_schema.test.js`
- [X] T097 Validate that the Cubit exposes pending state immediately, remains responsive during delayed command completion, and presents snapshot/result completion without imposing unit-test timing assertions for backend performance in `test/features/voting/presentation/cubit/agreement_command_cubit_test.dart`
- [X] T098 Run the Flutter feature tests from `specs/004-agreement-system/quickstart.md`
- [X] T099 Run the Functions, Firestore Rules, and integrated emulator suites from `specs/004-agreement-system/quickstart.md`
- [X] T100 Run the full Flutter test suite and Dart analyzer from `specs/004-agreement-system/quickstart.md`
- [X] T101 With user permission and an Android-emulator-only scope (Web and Windows explicitly excluded), execute scenarios A-G, run the instrumented SC-004 trials under the documented network profile, and record platform, sample size, warm/cold classification, and outcomes in `specs/004-agreement-system/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup and blocks every user story.
- **US1 (Phase 3)**: Starts after Foundational and is the MVP.
- **US2 (Phase 4)**: Starts after Foundational; relies on attendance eligibility from US1 for full integration.
- **US3 (Phase 5)**: Depends on US2 choices and US1 attendance eligibility.
- **US4 (Phase 6)**: Depends on US3 ballots and US2 proposals.
- **US5 (Phase 7)**: Depends on US4 confirmation history.
- **US6 (Phase 8)**: Depends on the command foundation and outing-owned agreement collections from US2-US5.
- **Polish (Phase 9)**: Depends on all stories selected for delivery; manual T101 additionally requires explicit user permission.

### User Story Dependency Graph

```text
Setup -> Foundation -> US1 (MVP)
                     -> US2 -> US3 -> US4 -> US5 -> US6
                         ^      ^
                         `-- US1 eligibility
```

US1 is independently deliverable. US2 can build proposal creation after Foundation, but its production acceptance checks consume US1 attendance. US3-US5 form the decision lifecycle in priority order. US6 depends on the established outing-owned data model so removal can clean it up completely.

### Within Each User Story

- Write the listed tests first and verify they fail for the intended behavior.
- Implement domain/entity and policy changes before repository/data behavior.
- Implement trusted backend and Security Rules constraints before exposing UI actions.
- Complete Cubit behavior before screen integration.
- Validate the independent test at each checkpoint before proceeding.

## Parallel Opportunities

- T003-T005 can run in parallel after T002 because they edit separate configuration files.
- T006-T011 and T013-T017 can be distributed by entity/model file; T012 then fixes the common repository contract.
- Flutter tests, Functions tests, and Rules tests marked `[P]` within each story can be authored concurrently.
- Domain policies, backend transaction primitives, Security Rules, and isolated widgets marked `[P]` can proceed concurrently when their contracts are fixed.
- T092 and T094 can proceed in parallel; T093 follows the completed agreement screen and routing contract.

## Parallel Examples

### User Story 1

```text
Task T027: Test participant entity attendance behavior.
Task T030: Test outing lifecycle response cutoff.
Task T031: Test Firestore attendance authorization.
Task T032: Test attendance summary widgets.
```

### User Story 2

```text
Task T045: Test repository proposal mapping.
Task T046: Test trusted proposal commands.
Task T047: Test proposal Security Rules.
Task T048: Test proposal ballot UI.
```

### User Story 3

```text
Task T056: Test eligibility policy.
Task T057: Test sealed visibility policy.
Task T058: Test private repository vote behavior.
Task T060: Test owner-only vote Security Rules.
```

### User Story 4

```text
Task T068: Test pure tally behavior.
Task T069: Test preview/confirmation transactions.
Task T070: Test command state management.
Task T071: Test command/result Security Rules.
Task T072: Test confirmation UI privacy.
```

### User Story 5

```text
Task T082: Test trusted reopening behavior.
Task T083: Test reopen Cubit states.
Task T084: Test reopen/history UI.
Task T085: Test historical immutability rules.
```

### User Story 6

```text
Task T102: Test trusted creator-only cascading removal.
Task T103: Test repository and removal UI behavior.
Task T104: Test direct-delete denial and command authorization rules.
```

## Implementation Strategy

### MVP First

1. Complete Setup and Foundational phases.
2. Complete User Story 1 through T044.
3. Run the US1 entity, model, repository, lifecycle, rules, and widget tests.
4. Demo attendance response and summary behavior as the independently valuable MVP.

### Incremental Delivery

1. Add US2 for immutable proposal collection.
2. Add US3 for sealed private voting.
3. Add US4 for trusted confirmation and published aggregates.
4. Add US5 for history-preserving plan changes.
5. Add US6 for creator-only permanent removal in every lifecycle status.
6. Finish routing, migration verification, emulator integration, performance assertions, and full quality gates.

## Notes

- `[P]` means the task edits a different file and does not depend on another incomplete task in the same phase.
- `[USn]` maps implementation and tests directly to the specification's user stories.
- Agreement proposal and round writes are server-controlled; votes and attendance are the only narrowly allowed direct client writes.
- Open rounds never expose totals, leaders, ties, participation counts, or other users' ballots.
- T101 must pause for explicit user permission because the constitution requires confirmation before manual end-to-end testing.
