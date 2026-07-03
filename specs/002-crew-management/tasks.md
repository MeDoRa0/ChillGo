# Tasks: Phase 2 — Crew Management

**Input**: Design documents from [specs/002-crew-management/](../../specs/002-crew-management/)

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [quickstart.md](./quickstart.md)

**Tests**: Included. As mandated by the ChillGo Constitution, repository implementations and Cubits/Blocs require automated unit and bloc tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create folder structure for crew feature under [lib/features/crews/](../../lib/features/crews/)
- [ ] T002 Update router to register `/crews`, `/crews/:crewId` and `/invitations` in [lib/core/routes/app_router.dart](../../lib/core/routes/app_router.dart)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Define Crew domain entity in [lib/features/crews/domain/entities/crew.dart](../../lib/features/crews/domain/entities/crew.dart)
- [ ] T004 Define CrewMembership domain entity in [lib/features/crews/domain/entities/crew_membership.dart](../../lib/features/crews/domain/entities/crew_membership.dart)
- [ ] T005 Define CrewInvitation domain entity in [lib/features/crews/domain/entities/crew_invitation.dart](../../lib/features/crews/domain/entities/crew_invitation.dart)
- [ ] T006 Define abstract CrewRepository interface in [lib/features/crews/domain/repositories/crew_repository.dart](../../lib/features/crews/domain/repositories/crew_repository.dart)
- [ ] T007 [P] Update Firestore security rules for crews, memberships, and invitations collections in [firestore.rules](../../firestore.rules)
- [ ] T008 [P] Implement Firestore Security Rules tests for crews, memberships, and invitations collections in [firestore_tests/rules.test.js](../../firestore_tests/rules.test.js)
- [ ] T009 Implement FirestoreCrewsDatasource for Firestore CRUD operations in [lib/features/crews/data/datasources/firestore_crews_datasource.dart](../../lib/features/crews/data/datasources/firestore_crews_datasource.dart)
- [ ] T010 Implement CrewRepositoryImpl in [lib/features/crews/data/repositories/crew_repository_impl.dart](../../lib/features/crews/data/repositories/crew_repository_impl.dart)
- [ ] T011 Register CrewRepository and FirestoreCrewsDatasource with GetIt container in [lib/core/di/injection_container.dart](../../lib/core/di/injection_container.dart)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Creating a Crew and Listing Members (Priority: P1) 🎯 MVP

**Goal**: Authenticated users can create a Crew, view details (name and member list), and list themselves as the Owner.

**Independent Test**: A user can create a crew by inputting a name, and immediately see the crew listed in their Crews list with themselves as the owner and only member.

### Tests for User Story 1
- [ ] T012 [P] [US1] Create unit tests for repository crew creation and member listing in [test/features/crews/data/repositories/crew_repository_impl_test.dart](../../test/features/crews/data/repositories/crew_repository_impl_test.dart)
- [ ] T013 [P] [US1] Create bloc tests for CrewsListCubit in [test/features/crews/presentation/blocs/crews_list_cubit_test.dart](../../test/features/crews/presentation/blocs/crews_list_cubit_test.dart)
- [ ] T014 [P] [US1] Create bloc tests for CrewDetailCubit in [test/features/crews/presentation/blocs/crew_detail_cubit_test.dart](../../test/features/crews/presentation/blocs/crew_detail_cubit_test.dart)

### Implementation for User Story 1
- [ ] T015 [US1] Implement CrewsListCubit state management in [lib/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart](../../lib/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart)
- [ ] T016 [US1] Implement CrewDetailCubit state management in [lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart](../../lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart)
- [ ] T017 [US1] Build CrewsListScreen UI displaying crews and create crew button in [lib/features/crews/presentation/screens/crews_list_screen.dart](../../lib/features/crews/presentation/screens/crews_list_screen.dart)
- [ ] T018 [US1] Build CrewDetailsScreen UI showing details and members in [lib/features/crews/presentation/screens/crew_details_screen.dart](../../lib/features/crews/presentation/screens/crew_details_screen.dart)
- [ ] T019 [US1] Build CrewMemberListItem widget in [lib/features/crews/presentation/widgets/crew_member_list_item.dart](../../lib/features/crews/presentation/widgets/crew_member_list_item.dart)
- [ ] T020 [US1] Integrate "My Crews" button on home screen to navigate to `/crews` in [lib/features/home/presentation/widgets/home_mobile_layout.dart](../../lib/features/home/presentation/widgets/home_mobile_layout.dart)

**Checkpoint**: User Story 1 is functional. Users can create crews and view member lists.

---

## Phase 4: User Story 2 - Inviting Members by Username (Priority: P1)

**Goal**: Allow a Crew Owner to invite other users to their Crew by entering their unique username.

**Independent Test**: A Crew Owner can enter a username, the system verifies the user exists and creates a pending invitation.

### Tests for User Story 2
- [ ] T021 [P] [US2] Add unit tests for username lookup and invitation sending in [test/features/crews/data/repositories/crew_repository_impl_test.dart](../../test/features/crews/data/repositories/crew_repository_impl_test.dart)
- [ ] T022 [P] [US2] Update bloc tests for CrewDetailCubit to cover invitation sending and validation in [test/features/crews/presentation/blocs/crew_detail_cubit_test.dart](../../test/features/crews/presentation/blocs/crew_detail_cubit_test.dart)

### Implementation for User Story 2
- [ ] T023 [US2] Implement username verification and invitation write in [lib/features/crews/data/repositories/crew_repository_impl.dart](../../lib/features/crews/data/repositories/crew_repository_impl.dart)
- [ ] T024 [US2] Update CrewDetailCubit to handle invitation requests in [lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart](../../lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart)
- [ ] T025 [US2] Build InviteMemberDialog widget in [lib/features/crews/presentation/widgets/invite_member_dialog.dart](../../lib/features/crews/presentation/widgets/invite_member_dialog.dart)
- [ ] T026 [US2] Update CrewDetailsScreen UI to display a list of pending invitations (owner only) and hook up the dialog in [lib/features/crews/presentation/screens/crew_details_screen.dart](../../lib/features/crews/presentation/screens/crew_details_screen.dart)

**Checkpoint**: User Story 2 is functional. Owners can send invitations by username and view them as pending.

---

## Phase 5: User Story 3 - Managing Invitations (Accepting/Rejecting) (Priority: P2)

**Goal**: Allow invited users to see their pending invitations and accept or reject them.

**Independent Test**: An invited user sees the invitation, accepts it, and becomes a crew member, or rejects it and the invitation disappears.

### Tests for User Story 3
- [ ] T027 [P] [US3] Create unit tests for accepting and rejecting invitations in [test/features/crews/data/repositories/crew_repository_impl_test.dart](../../test/features/crews/data/repositories/crew_repository_impl_test.dart)
- [ ] T028 [P] [US3] Create bloc tests for InvitationsCubit in [test/features/crews/presentation/blocs/invitations_cubit_test.dart](../../test/features/crews/presentation/blocs/invitations_cubit_test.dart)

### Implementation for User Story 3
- [ ] T029 [US3] Implement acceptInvitation and rejectInvitation methods in [lib/features/crews/data/repositories/crew_repository_impl.dart](../../lib/features/crews/data/repositories/crew_repository_impl.dart)
- [ ] T030 [US3] Implement InvitationsCubit state management in [lib/features/crews/presentation/blocs/invitations/invitations_cubit.dart](../../lib/features/crews/presentation/blocs/invitations/invitations_cubit.dart)
- [ ] T031 [US3] Build InvitationsScreen UI listing received invitations with action buttons in [lib/features/crews/presentation/screens/invitations_screen.dart](../../lib/features/crews/presentation/screens/invitations_screen.dart)
- [ ] T032 [US3] Integrate navigation to invitations screen on home dashboard or home app bar in [lib/features/home/presentation/widgets/home_mobile_layout.dart](../../lib/features/home/presentation/widgets/home_mobile_layout.dart)

**Checkpoint**: User Story 3 is functional. Users can accept/reject invitations.

---

## Phase 6: User Story 4 - Editing and Deleting Crews (Priority: P2)

**Goal**: Allow Crew Owners to edit the crew's name or delete the crew entirely.

**Independent Test**: The owner can change the crew name or delete it, removing it from all members' lists.

### Tests for User Story 4
- [ ] T033 [P] [US4] Add unit tests for editing name and deleting crew in [test/features/crews/data/repositories/crew_repository_impl_test.dart](../../test/features/crews/data/repositories/crew_repository_impl_test.dart)
- [ ] T034 [P] [US4] Update bloc tests for CrewDetailCubit to cover editing name and deletion in [test/features/crews/presentation/blocs/crew_detail_cubit_test.dart](../../test/features/crews/presentation/blocs/crew_detail_cubit_test.dart)

### Implementation for User Story 4
- [ ] T035 [US4] Implement updateCrewName and deleteCrew methods in [lib/features/crews/data/repositories/crew_repository_impl.dart](../../lib/features/crews/data/repositories/crew_repository_impl.dart)
- [ ] T036 [US4] Update CrewDetailCubit to handle edit name and delete actions in [lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart](../../lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart)
- [ ] T037 [US4] Update CrewDetailsScreen UI to add Edit and Delete actions in [lib/features/crews/presentation/screens/crew_details_screen.dart](../../lib/features/crews/presentation/screens/crew_details_screen.dart)

**Checkpoint**: User Story 4 is functional. Owners can manage crew name editing and deletion.

---

## Phase 7: User Story 5 - Member Management (Leaving and Removing Members) (Priority: P3)

**Goal**: Allow Crew Members to leave a Crew and Crew Owners to remove members.

**Independent Test**: A member can leave the crew, and the owner can remove any non-owner member.

### Tests for User Story 5
- [ ] T038 [P] [US5] Add unit tests for removing members and leaving a crew in [test/features/crews/data/repositories/crew_repository_impl_test.dart](../../test/features/crews/data/repositories/crew_repository_impl_test.dart)
- [ ] T039 [P] [US5] Update bloc tests for CrewDetailCubit to cover leave and remove actions in [test/features/crews/presentation/blocs/crew_detail_cubit_test.dart](../../test/features/crews/presentation/blocs/crew_detail_cubit_test.dart)

### Implementation for User Story 5
- [ ] T040 [US5] Implement removeMember and leaveCrew methods in [lib/features/crews/data/repositories/crew_repository_impl.dart](../../lib/features/crews/data/repositories/crew_repository_impl.dart)
- [ ] T041 [US5] Update CrewDetailCubit to handle leave and remove member requests in [lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart](../../lib/features/crews/presentation/blocs/crew_detail/crew_detail_cubit.dart)
- [ ] T042 [US5] Update CrewDetailsScreen UI to add leave and remove buttons in [lib/features/crews/presentation/screens/crew_details_screen.dart](../../lib/features/crews/presentation/screens/crew_details_screen.dart)

**Checkpoint**: User Story 5 is functional. Members can leave, and owners can remove members.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T043 [P] Set up and run security rules tests in [firestore_tests/rules.test.js](../../firestore_tests/rules.test.js) against local emulator
- [ ] T044 Run all automated unit and bloc tests under [test/features/crews/](../../test/features/crews/)
- [ ] T045 Perform manual end-to-end verification of all scenarios in [quickstart.md](./quickstart.md) and verify responsive design
- [X] T046 [P] Update walkthrough documentation artifact `walkthrough.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel or sequentially in priority order
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Serves as the basis for sending invitations
- **User Story 3 (P2)**: Requires invitations from US2 to be generated - Bob needs to receive an invitation to accept it
- **User Story 4 (P2)**: Can start after Foundational (Phase 2)
- **User Story 5 (P3)**: Requires existing crew members (either via US1 or US3) to perform leave/remove actions

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch unit and bloc tests for User Story 1:
Task: "Create unit tests for repository crew creation and member listing in test/features/crews/data/repositories/crew_repository_impl_test.dart"
Task: "Create bloc tests for CrewsListCubit in test/features/crews/presentation/blocs/crews_list_cubit_test.dart"
Task: "Create bloc tests for CrewDetailCubit in test/features/crews/presentation/blocs/crew_detail_cubit_test.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Crews List & Details)
4. Complete Phase 4: User Story 2 (Inviting members)
5. **STOP and VALIDATE**: Verify that crews can be created and invitations sent to valid users.
6. Complete Phase 5: User Story 3 (Accepting/Rejecting invitations)
7. Complete Phase 6: User Story 4 (Edit/Delete)
8. Complete Phase 7: User Story 5 (Member Management)
9. Complete Phase 8: Polish.

## Phase 9: Convergence

- [X] T047 Add or update the Crew Management walkthrough documentation artifact per T046 (missing)
