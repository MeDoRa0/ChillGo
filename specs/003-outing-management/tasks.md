# Tasks: Outing Management

**Input**: Design documents from `specs/003-outing-management/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/)

**Tests**: Required by ChillGo Constitution Principle IV. Write tests before implementation for each story where practical.

**Organization**: Tasks are grouped by user story so a lower-cost LLM can implement one independently testable slice at a time. A story checkpoint is not complete until its required P1/widget/rules tests are implemented, checked off, and passing.

## LLM Handoff Guardrails

- Stay inside Phase 3 only: no voting, accepting/declining outing invitations, chat, live location, maps, selected places, coordinates, or push notifications.
- Follow existing Crew feature patterns in `lib/features/crews/` and `test/features/crews/`.
- Keep production code under `lib/features/outings/` except routing, DI, Firestore rules, and Crew screen navigation entry points needed to expose outing flows.
- Use free-text `locationText` only.
- New outings start as `draft`.
- Creating an outing must also create the creator participant.
- Use top-level Firestore collections: `outings` and `outing_participants`.
- Use predictable participant document IDs: `${outingId}_${userId}`.
- All local documentation links must be repo-relative.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other [P] tasks in the same phase when files do not overlap
- **[Story]**: User story label from [spec.md](./spec.md)
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare directories, confirm patterns, and avoid path drift before implementation.

- [X] T001 Read `specs/003-outing-management/spec.md`, `specs/003-outing-management/plan.md`, `specs/003-outing-management/data-model.md`, and `specs/003-outing-management/contracts/outing_repository.md` before editing any code.
- [X] T002 Verify or create outing feature subdirectories in `lib/features/outings/data/datasources/`, `lib/features/outings/data/models/`, `lib/features/outings/data/repositories/`, `lib/features/outings/domain/entities/`, `lib/features/outings/domain/repositories/`, `lib/features/outings/domain/services/`, `lib/features/outings/presentation/cubit/`, and `lib/features/outings/presentation/screens/`.
- [X] T003 Verify or create outing test subdirectories in `test/features/outings/data/datasources/`, `test/features/outings/data/repositories/`, `test/features/outings/domain/`, `test/features/outings/presentation/cubit/`, and `test/features/outings/presentation/screens/`.
- [X] T004 [P] Review Crew entity/model patterns in `lib/features/crews/domain/entities/crew.dart` before implementing outing entities in `lib/features/outings/domain/entities/`.
- [X] T005 [P] Review Crew repository/datasource patterns in `lib/features/crews/data/datasources/firestore_crews_datasource.dart` and `lib/features/crews/data/repositories/crew_repository_impl.dart`.
- [X] T006 [P] Review Cubit state patterns in `lib/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart` and mirror Equatable state style for outings.
- [X] T007 [P] Review existing Firestore rules helper style in `firestore.rules` before adding outing helpers.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared domain, model, rule, and DI foundation that every user story depends on.

**CRITICAL**: No user story implementation should begin until this phase is complete.

### Tests for Foundation

- [X] T008 [P] Add status parsing and transition tests in `test/features/outings/domain/outing_lifecycle_policy_test.dart`.
- [X] T009 [P] Add Outing entity parsing/copy tests in `test/features/outings/domain/outing_entity_test.dart`.
- [X] T010 [P] Add OutingParticipant entity parsing/copy tests in `test/features/outings/domain/outing_participant_entity_test.dart`.
- [X] T011 [P] Add OutingModel serialization tests in `test/features/outings/data/models/outing_model_test.dart`.
- [X] T012 [P] Add OutingParticipantModel serialization tests in `test/features/outings/data/models/outing_participant_model_test.dart`.

### Implementation for Foundation

- [X] T013 [P] Implement `OutingStatus` enum with stable Firestore values and parser in `lib/features/outings/domain/entities/outing_status.dart`.
- [X] T014 [P] Implement `Outing` entity with immutable fields, `fromMap`, and `copyWith` in `lib/features/outings/domain/entities/outing.dart`.
- [X] T015 [P] Implement `OutingParticipant` entity with immutable fields, `fromMap`, and `copyWith` in `lib/features/outings/domain/entities/outing_participant.dart`.
- [X] T016 Implement `OutingLifecyclePolicy` valid transition checks in `lib/features/outings/domain/services/outing_lifecycle_policy.dart`.
- [X] T017 [P] Implement `OutingModel` Firestore DTO mapping in `lib/features/outings/data/models/outing_model.dart`.
- [X] T018 [P] Implement `OutingParticipantModel` Firestore DTO mapping in `lib/features/outings/data/models/outing_participant_model.dart`.
- [X] T019 Define `OutingRepository` interface matching `contracts/outing_repository.md` in `lib/features/outings/domain/repositories/outing_repository.dart`.
- [X] T020 Create `FirestoreOutingsDatasource` constructor and collection references for `outings`, `outing_participants`, `crew_memberships`, `crews`, and `users` in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T021 Create `OutingRepositoryImpl` shell with `currentUid` guard and injected datasource in `lib/features/outings/data/repositories/outing_repository_impl.dart`.
- [X] T022 Register `FirestoreOutingsDatasource` and `OutingRepository` in `lib/core/di/injection_container.dart`.
- [X] T023 Add shared outing helper functions for valid strings, timestamps, membership, crew ownership, outing manager, outing payload shape, participant payload shape, and transition validation in `firestore.rules`.

**Checkpoint**: Domain entities, DTOs, lifecycle policy, repository interface, datasource shell, DI shell, and Firestore helper skeleton compile.

---

## Phase 3: User Story 1 - Create an Outing Inside a Crew (Priority: P1) MVP

**Goal**: A current crew member can create an outing with title, future date/time, free-text location, optional description, initial `draft` status, and automatic creator participant.

**Independent Test**: Sign in as a crew member, create an outing, and verify it appears under that crew with the creator as the first participant.

### Tests for User Story 1

- [ ] T024 [P] [US1] Add datasource test for atomic outing plus creator participant creation in `test/features/outings/data/datasources/firestore_outings_datasource_test.dart`.
- [X] T025 [P] [US1] Add repository validation tests for title, future schedule, free-text location, and missing current UID in `test/features/outings/data/repositories/outing_repository_impl_test.dart`.
- [X] T026 [P] [US1] Add form Cubit create success/error tests in `test/features/outings/presentation/cubit/outing_form_cubit_test.dart`.
- [ ] T027 [P] [US1] Add widget test for required create form fields and validation messages in `test/features/outings/presentation/screens/outing_form_screen_test.dart`.
- [ ] T028 [P] [US1] Add Firestore emulator tests for outing creation, non-member creation rejection, initial `draft` status, and missing creator participant rejection in `firestore_tests/rules.test.js`.

### Implementation for User Story 1

- [X] T029 [US1] Implement `createOuting` batch write in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T030 [US1] Implement profile payload loading for creator participant cache fields in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T031 [US1] Implement create validation and `createOuting` delegation in `lib/features/outings/data/repositories/outing_repository_impl.dart`.
- [X] T032 [US1] Implement `OutingFormCubit` create states and create action in `lib/features/outings/presentation/cubit/outing_form/outing_form_cubit.dart`.
- [X] T033 [US1] Implement `OutingFormScreen` create mode with title, description, future date/time, and free-text location fields in `lib/features/outings/presentation/screens/outing_form_screen.dart`.
- [X] T034 [US1] Add create outing navigation entry from crew details or crew outing area in `lib/features/crews/presentation/screens/crew_details_screen.dart`.
- [X] T035 [US1] Add outing create route using `crewId` path or query parameter in `lib/core/routes/app_router.dart`.
- [X] T036 [US1] Update Firestore create rules for `/outings/{outingId}` and `/outing_participants/{outingId}_{userId}` in `firestore.rules`.
- [ ] T037 [US1] Run `flutter test test/features/outings/data/repositories/outing_repository_impl_test.dart test/features/outings/presentation/cubit/outing_form_cubit_test.dart test/features/outings/presentation/screens/outing_form_screen_test.dart` from project root `.` and fix failures in touched files.

**Checkpoint**: User Story 1 is the MVP only after the atomic creator-participant creation tests, form validation tests, Firestore access-control tests, and story-specific emulator tests are implemented and passing.

---

## Phase 4: User Story 2 - View Outing Details and Crew Outings (Priority: P2)

**Goal**: Crew members can view outings for a crew and open outing details with core information, participant roster, lifecycle status, and cancellation/history state.

**Independent Test**: Create multiple outings in one crew, open the crew outings list, and open each outing detail as a member while non-members cannot view private data.

### Tests for User Story 2

- [ ] T038 [P] [US2] Add datasource stream tests for crew outings ordering and malformed record tolerance in `test/features/outings/data/datasources/firestore_outings_datasource_test.dart`.
- [ ] T039 [US2] Add datasource stream tests for outing detail plus participant roster loading in `test/features/outings/data/datasources/firestore_outings_datasource_test.dart`.
- [ ] T040 [P] [US2] Add repository stream delegation tests in `test/features/outings/data/repositories/outing_repository_impl_test.dart`.
- [X] T041 [P] [US2] Add `OutingsListCubit` load success/error tests in `test/features/outings/presentation/cubit/outings_list_cubit_test.dart`.
- [X] T042 [P] [US2] Add `OutingDetailCubit` load success/error tests in `test/features/outings/presentation/cubit/outing_detail_cubit_test.dart`.
- [ ] T043 [P] [US2] Add outing list and empty-state widget tests in `test/features/outings/presentation/screens/outings_list_screen_test.dart`.
- [ ] T044 [P] [US2] Add outing details widget tests for core fields, status, roster, and cancellation reason rendering in `test/features/outings/presentation/screens/outing_details_screen_test.dart`.
- [ ] T045 [P] [US2] Add Firestore emulator tests for member read access and non-member read rejection in `firestore_tests/rules.test.js`.

### Implementation for User Story 2

- [X] T046 [US2] Implement `streamCrewOutings` and active/history ordering in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T047 [US2] Implement `streamOuting`, `streamParticipants`, and combined detail loading support in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T048 [US2] Implement repository read methods in `lib/features/outings/data/repositories/outing_repository_impl.dart`.
- [X] T049 [US2] Implement `OutingsListCubit` states and stream subscription lifecycle in `lib/features/outings/presentation/cubit/outings_list/outings_list_cubit.dart`.
- [X] T050 [US2] Implement `OutingDetailCubit` states and stream subscription lifecycle in `lib/features/outings/presentation/cubit/outing_detail/outing_detail_cubit.dart`.
- [X] T051 [US2] Implement `OutingsListScreen` with loading, empty, error, active, and history sections in `lib/features/outings/presentation/screens/outings_list_screen.dart`.
- [X] T052 [US2] Implement `OutingDetailsScreen` core detail and roster UI in `lib/features/outings/presentation/screens/outing_details_screen.dart`.
- [X] T053 [US2] Add outing list and outing detail routes in `lib/core/routes/app_router.dart`.
- [X] T054 [US2] Link crew details to the outing list screen in `lib/features/crews/presentation/screens/crew_details_screen.dart`.
- [X] T055 [US2] Update Firestore read rules for `/outings/{outingId}` and `/outing_participants/{outingId}_{userId}` in `firestore.rules`.
- [ ] T056 [US2] Run `flutter test test/features/outings/presentation/cubit/outings_list_cubit_test.dart test/features/outings/presentation/cubit/outing_detail_cubit_test.dart test/features/outings/presentation/screens/outings_list_screen_test.dart test/features/outings/presentation/screens/outing_details_screen_test.dart` from project root `.` and fix failures in touched files.

**Checkpoint**: User Story 2 works independently after creating or seeding outings.

---

## Phase 5: User Story 3 - Edit or Cancel an Outing (Priority: P3)

**Goal**: The outing creator or crew owner can edit active outing planning details or cancel an outing with a visible reason; edits are blocked after cancellation, completion, or archive.

**Independent Test**: Create an outing, edit every editable field, cancel it with a reason, verify the reason is visible, and verify further planning edits are blocked.

### Tests for User Story 3

- [ ] T057 [P] [US3] Add datasource tests for updating active outing details and rejecting terminal-status edits in `test/features/outings/data/datasources/firestore_outings_datasource_test.dart`.
- [ ] T058 [US3] Add datasource tests for cancelling with reason and preserving outing history in `test/features/outings/data/datasources/firestore_outings_datasource_test.dart`.
- [X] T059 [P] [US3] Add repository validation tests for edit fields and cancellation reason in `test/features/outings/data/repositories/outing_repository_impl_test.dart`.
- [X] T060 [P] [US3] Add form Cubit edit/cancel tests in `test/features/outings/presentation/cubit/outing_form_cubit_test.dart`.
- [ ] T061 [P] [US3] Add screen tests for edit mode, cancel dialog, and blocked edit message in `test/features/outings/presentation/screens/outing_form_screen_test.dart`.
- [ ] T062 [P] [US3] Add Firestore emulator tests for manager edit/cancel, non-manager rejection, missing cancellation reason, and terminal edit rejection in `firestore_tests/rules.test.js`.

### Implementation for User Story 3

- [X] T063 [US3] Implement `updateOutingDetails` in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T064 [US3] Implement `cancelOuting` with `cancelledReason` and `cancelledAt` in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T065 [US3] Implement repository edit validation and cancellation validation in `lib/features/outings/data/repositories/outing_repository_impl.dart`.
- [X] T066 [US3] Extend `OutingFormCubit` for edit and cancel flows in `lib/features/outings/presentation/cubit/outing_form/outing_form_cubit.dart`.
- [ ] T067 [US3] Extend `OutingFormScreen` for edit mode, disabled terminal-state fields, and cancel dialog in `lib/features/outings/presentation/screens/outing_form_screen.dart`.
- [X] T068 [US3] Add edit and cancel actions to `OutingDetailsScreen` for creator/owner-visible controls in `lib/features/outings/presentation/screens/outing_details_screen.dart`.
- [X] T069 [US3] Add or update edit outing route in `lib/core/routes/app_router.dart`.
- [X] T070 [US3] Update Firestore update rules for outing detail edits, cancellation, terminal states, and no direct delete in `firestore.rules`.
- [ ] T071 [US3] Run `flutter test test/features/outings/data/repositories/outing_repository_impl_test.dart test/features/outings/presentation/cubit/outing_form_cubit_test.dart test/features/outings/presentation/screens/outing_form_screen_test.dart test/features/outings/presentation/screens/outing_details_screen_test.dart` from project root `.` and fix failures in touched files.

**Checkpoint**: User Story 3 works without requiring participant-management or lifecycle-management UI from User Story 4.

---

## Phase 6: User Story 4 - Manage Participants and Lifecycle (Priority: P4)

**Goal**: The outing creator or crew owner can add/remove current crew members as participants and manually move outings through valid lifecycle transitions.

**Independent Test**: Add and remove crew members from an outing, attempt duplicates and non-crew members, change statuses through valid transitions, and confirm invalid transitions are blocked.

### Tests for User Story 4

- [ ] T072 [P] [US4] Add datasource tests for adding/removing participants and duplicate prevention in `test/features/outings/data/datasources/firestore_outings_datasource_test.dart`.
- [ ] T073 [US4] Add datasource tests for participant profile cache fields and non-crew-member rejection in `test/features/outings/data/datasources/firestore_outings_datasource_test.dart`.
- [X] T074 [P] [US4] Add repository tests for participant add/remove and lifecycle transition delegation in `test/features/outings/data/repositories/outing_repository_impl_test.dart`.
- [X] T075 [P] [US4] Add lifecycle policy tests for every allowed and rejected transition in `test/features/outings/domain/outing_lifecycle_policy_test.dart`.
- [X] T076 [P] [US4] Add detail Cubit tests for add participant, remove participant, and change status flows in `test/features/outings/presentation/cubit/outing_detail_cubit_test.dart`.
- [ ] T077 [P] [US4] Add detail screen tests for participant controls, duplicate error, and status controls in `test/features/outings/presentation/screens/outing_details_screen_test.dart`.
- [ ] T078 [P] [US4] Add Firestore emulator tests for participant create/delete, non-member target rejection, invalid lifecycle transitions, and terminal participant delete rejection in `firestore_tests/rules.test.js`.

### Implementation for User Story 4

- [X] T079 [US4] Implement `addParticipant` and `removeParticipant` in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T080 [US4] Implement `changeLifecycleStatus` in `lib/features/outings/data/datasources/firestore_outings_datasource.dart`.
- [X] T081 [US4] Implement repository participant and lifecycle methods with `OutingLifecyclePolicy` checks in `lib/features/outings/data/repositories/outing_repository_impl.dart`.
- [X] T082 [US4] Extend `OutingDetailCubit` with participant add/remove and lifecycle change commands in `lib/features/outings/presentation/cubit/outing_detail/outing_detail_cubit.dart`.
- [X] T083 [US4] Add participant management UI to `OutingDetailsScreen` using current crew member choices from `CrewRepository.streamMembers` in `lib/features/outings/presentation/screens/outing_details_screen.dart`.
- [X] T084 [US4] Add lifecycle status controls to `OutingDetailsScreen` using allowed next statuses from `OutingLifecyclePolicy` in `lib/features/outings/presentation/screens/outing_details_screen.dart`.
- [X] T085 [US4] Update Firestore participant and lifecycle rules in `firestore.rules`.
- [ ] T086 [US4] Run `flutter test test/features/outings/domain/outing_lifecycle_policy_test.dart test/features/outings/presentation/cubit/outing_detail_cubit_test.dart test/features/outings/presentation/screens/outing_details_screen_test.dart` from project root `.` and fix failures in touched files.

**Checkpoint**: All Phase 3 user stories are independently functional.

---

## Phase 7: Firestore Rules Validation

**Purpose**: Validate security across all Phase 3 stories with emulator tests.

- [ ] T087 Add final outing rule fixtures and helper builders for users, crews, memberships, outings, and participants in `firestore_tests/rules.test.js`.
- [ ] T088 Run `cd firestore_tests && npm test` using `firestore_tests/package.json` after T087 and story-specific rules tests are implemented, then fix failures in `firestore.rules` or `firestore_tests/rules.test.js`.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, integration quality, and final validation.

- [ ] T089 [P] Add missing user-facing error string normalization for outing errors in `lib/features/outings/data/repositories/outing_repository_impl.dart`.
- [ ] T090 [P] Add accessibility labels and responsive layout checks for outing screens in `lib/features/outings/presentation/screens/outings_list_screen.dart`, `lib/features/outings/presentation/screens/outing_details_screen.dart`, and `lib/features/outings/presentation/screens/outing_form_screen.dart`.
- [ ] T091 [P] Add route-level not-found/access-denied handling for missing outing or missing crew membership in `lib/core/routes/app_router.dart`.
- [X] T092 Add all outing feature registrations to `lib/core/di/injection_container.dart`, including `OutingsListCubit`, `OutingDetailCubit`, and `OutingFormCubit` factories.
- [X] T093 Run `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe analyze` from project root `.` and fix analyzer issues in touched files.
- [X] T094 Run `C:\src\flutter\bin\flutter.bat test --no-pub test/features/outings/` from project root `.` and fix outing feature test failures.
- [X] T095 Run `C:\src\flutter\bin\flutter.bat test --no-pub` from project root `.` and fix regression failures in touched files.
- [ ] T096 Verify quickstart scenarios from `specs/003-outing-management/quickstart.md` and record any manual E2E gaps in `specs/003-outing-management/quickstart.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup and blocks all user stories.
- **US1 Create Outing (Phase 3)**: Depends on Foundation and is the MVP.
- **US2 View Outings (Phase 4)**: Depends on Foundation; most useful after US1 exists.
- **US3 Edit/Cancel (Phase 5)**: Depends on US1 for created outings and US2 for visible detail confirmation.
- **US4 Participants/Lifecycle (Phase 6)**: Depends on US1 and US2; can be implemented before US3 if needed, but final validation should cover both.
- **Rules Validation (Phase 7)**: Depends on all story-specific rule tasks.
- **Polish (Phase 8)**: Depends on desired story phases.

### User Story Dependencies

- **US1 (P1)**: No story dependency after Foundation; recommended MVP.
- **US2 (P2)**: Can be built after Foundation using seeded data, but pairs naturally with US1.
- **US3 (P3)**: Requires outing creation and detail visibility to validate end-to-end.
- **US4 (P4)**: Requires outing detail visibility and lifecycle policy foundation.

### Within Each User Story

- Tests before implementation.
- Domain/policy before repository behavior.
- Datasource before repository implementation.
- Repository before Cubits.
- Cubits before screens.
- Firestore rule updates before emulator validation.

## Parallel Opportunities

- Setup review tasks T004-T007 can run in parallel.
- Foundation tests T008-T012 can run in parallel.
- Foundation entity/model implementations T013-T015 and T017-T018 can run in parallel after their tests exist.
- Story test tasks marked [P] can run in parallel because they target different files or isolated test groups.
- US1 and US2 can be developed in parallel after Foundation if US2 uses seeded outing data in tests.
- US3 and US4 can be developed in parallel after US1/US2 if they coordinate changes to `OutingDetailsScreen`.

## Parallel Example: User Story 1

```text
Task: T024 datasource create test in test/features/outings/data/datasources/firestore_outings_datasource_test.dart
Task: T025 repository validation test in test/features/outings/data/repositories/outing_repository_impl_test.dart
Task: T026 form Cubit create test in test/features/outings/presentation/cubit/outing_form_cubit_test.dart
Task: T027 form screen widget test in test/features/outings/presentation/screens/outing_form_screen_test.dart
Task: T028 Firestore create rules test in firestore_tests/rules.test.js
```

## Parallel Example: User Story 2

```text
Task: T041 list Cubit tests in test/features/outings/presentation/cubit/outings_list_cubit_test.dart
Task: T042 detail Cubit tests in test/features/outings/presentation/cubit/outing_detail_cubit_test.dart
Task: T043 list screen tests in test/features/outings/presentation/screens/outings_list_screen_test.dart
Task: T044 details screen tests in test/features/outings/presentation/screens/outing_details_screen_test.dart
```

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 User Story 1.
3. Run US1 Flutter tests and Firestore create-rule tests.
4. Stop and validate that a crew member can create an outing and becomes the first participant.

### Incremental Delivery

1. Deliver US1 create outing MVP.
2. Add US2 viewing so outings are discoverable and inspectable.
3. Add US3 edit/cancel management.
4. Add US4 participant and lifecycle management.
5. Finish Firestore emulator validation and full test suite.

### Lower-Cost LLM Execution Advice

1. Implement tasks strictly in ID order unless the task is marked [P].
2. Do not invent extra fields beyond [data-model.md](./data-model.md).
3. Do not add Phase 4-7 behavior even if it seems useful.
4. When uncertain, copy the equivalent pattern from `lib/features/crews/` and adapt names to outings.
5. After each checkpoint, run only the tests listed in that checkpoint before continuing.
