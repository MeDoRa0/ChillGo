# Tasks: Phase 1 — Authentication & Profiles

**Input**: Design documents from [specs/001-auth-profiles/](../../specs/001-auth-profiles/)

**Prerequisites**: [plan.md](../../specs/001-auth-profiles/plan.md), [spec.md](../../specs/001-auth-profiles/spec.md), [research.md](../../specs/001-auth-profiles/research.md), [data-model.md](../../specs/001-auth-profiles/data-model.md)

**Tests**: Included. As mandated by the ChillGo Constitution, repository implementations and Cubits/Blocs require automated unit and bloc tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Configure Firestore Security Rules file in [firestore.rules](../../firestore.rules) and Firebase Storage rules in [storage.rules](../../storage.rules)
- [x] T002 [P] Set up Firebase CLI and Firestore emulator testing scripts in [package.json](../../package.json)
- [x] T003 [P] Ensure authentication/profile dependency packages are added to [pubspec.yaml](../../pubspec.yaml)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Define abstract repositories AuthRepository and ProfileRepository in [lib/features/authentication/domain/repositories/auth_repository.dart](../../lib/features/authentication/domain/repositories/auth_repository.dart) and [lib/features/profile/domain/repositories/profile_repository.dart](../../lib/features/profile/domain/repositories/profile_repository.dart)
- [x] T005 [P] Create UserProfile entity model in [lib/features/authentication/domain/entities/user_profile.dart](../../lib/features/authentication/domain/entities/user_profile.dart)
- [x] T006 [P] Setup dependency injection configuration for auth and profile repositories in [lib/core/di/injection.dart](../../lib/core/di/injection.dart)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Federated Sign-In & Account Registration (Priority: P1) 🎯 MVP

**Goal**: Users can authenticate via Google/Apple and be routed correctly based on whether they have a profile.

**Independent Test**: Verify that tapping Google or Apple Sign-In correctly authenticates a mock user in the emulator and routes them to onboarding (new user) or dashboard (returning user).

### Tests for User Story 1
- [x] T007 [US1] Create unit tests for AuthRepositoryImpl in [test/features/authentication/data/repositories/auth_repository_impl_test.dart](../../test/features/authentication/data/repositories/auth_repository_impl_test.dart)
- [x] T008 [P] [US1] Create AuthBloc tests in [test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart](../../test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart)

### Implementation for User Story 1
- [x] T009 [US1] Implement FirebaseAuthDatasource client calls in [lib/features/authentication/data/datasources/firebase_auth_datasource.dart](../../lib/features/authentication/data/datasources/firebase_auth_datasource.dart)
- [x] T010 [US1] Implement AuthRepositoryImpl in [lib/features/authentication/data/repositories/auth_repository_impl.dart](../../lib/features/authentication/data/repositories/auth_repository_impl.dart)
- [x] T011 [P] [US1] Create AuthBloc state management in [lib/features/authentication/presentation/blocs/auth/auth_bloc.dart](../../lib/features/authentication/presentation/blocs/auth/auth_bloc.dart)
- [x] T012 [US1] Implement UI/UX for LoginScreen supporting Google and Apple sign-in options in [lib/features/authentication/presentation/screens/login_screen.dart](../../lib/features/authentication/presentation/screens/login_screen.dart)
- [x] T013 [US1] Update App Router to redirect unauthenticated users to /login in [lib/core/routes/app_router.dart](../../lib/core/routes/app_router.dart)

**Checkpoint**: User Story 1 is functional. Users can authenticate and are routed appropriately.

---

## Phase 4: User Story 2 - Profile Onboarding (Username & Display Name Creation) (Priority: P1)

**Goal**: Collect a unique username and display name for new users using a Firestore transaction.

**Independent Test**: Registering a profile with a unique username completes onboarding; duplicate usernames must fail.

### Tests for User Story 2
- [x] T014 [US2] Create unit tests for ProfileRepositoryImpl in [test/features/profile/data/repositories/profile_repository_impl_test.dart](../../test/features/profile/data/repositories/profile_repository_impl_test.dart)
- [x] T015 [P] [US2] Implement OnboardingCubit tests in [test/features/profile/presentation/blocs/onboarding/onboarding_cubit_test.dart](../../test/features/profile/presentation/blocs/onboarding/onboarding_cubit_test.dart)

### Implementation for User Story 2
- [x] T016 [US2] Implement FirestoreProfileDatasource in [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart)
- [x] T017 [US2] Implement ProfileRepositoryImpl in [lib/features/profile/data/repositories/profile_repository_impl.dart](../../lib/features/profile/data/repositories/profile_repository_impl.dart)
- [x] T018 [P] [US2] Implement OnboardingCubit state management in [lib/features/profile/presentation/blocs/onboarding/onboarding_cubit.dart](../../lib/features/profile/presentation/blocs/onboarding/onboarding_cubit.dart)
- [x] T019 [US2] Create UI for OnboardingScreen with username validation in [lib/features/profile/presentation/screens/onboarding_screen.dart](../../lib/features/profile/presentation/screens/onboarding_screen.dart)

**Checkpoint**: User Story 2 is functional. Users can create profiles and duplicate usernames are blocked.

---

## Phase 5: User Story 4 - Session Persistence & Sign Out (Priority: P1)

**Goal**: Keep user logged in across restarts and allow them to sign out to return to login.

**Independent Test**: Restarting the app skips login; signing out returns to the login screen.

### Implementation for User Story 4
- [x] T020 [US4] Configure Firebase Auth state listener for auto-login in [lib/features/authentication/presentation/blocs/auth/auth_bloc.dart](../../lib/features/authentication/presentation/blocs/auth/auth_bloc.dart)
- [x] T021 [US4] Add Sign Out button in UI and trigger signOut call via AuthRepository in [lib/features/profile/presentation/screens/profile_screen.dart](../../lib/features/profile/presentation/screens/profile_screen.dart)

**Checkpoint**: User Story 4 is functional. Persistence and sign out behave as expected.

---

## Phase 6: User Story 3 - Profile Management & Avatar Upload (Priority: P2)

**Goal**: View profile details, edit display name, and upload a compressed avatar image to Firebase Storage.

**Independent Test**: Changing the display name or selecting an image updates the profile details and reflects the new image immediately.

### Tests for User Story 3
- [x] T022 [P] [US3] Create profile edit Cubit tests in [test/features/profile/presentation/blocs/profile/profile_cubit_test.dart](../../test/features/profile/presentation/blocs/profile/profile_cubit_test.dart)

### Implementation for User Story 3
- [x] T023 [US3] Implement image picking and compression helper in [lib/features/profile/presentation/utils/image_helper.dart](../../lib/features/profile/presentation/utils/image_helper.dart)
- [x] T023a [US3] Configure camera and gallery usage permissions in platform config files [ios/Runner/Info.plist](../../ios/Runner/Info.plist) and [android/app/src/main/AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml)
- [x] T024 [US3] Implement avatar upload method in FirestoreProfileDatasource and ProfileRepositoryImpl in [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart)
- [x] T025 [US3] Create profile edit Cubit in [lib/features/profile/presentation/blocs/profile/profile_cubit.dart](../../lib/features/profile/presentation/blocs/profile/profile_cubit.dart)
- [x] T026 [US3] Create UI for ProfileScreen showing username and avatar in [lib/features/profile/presentation/screens/profile_screen.dart](../../lib/features/profile/presentation/screens/profile_screen.dart)

**Checkpoint**: User Story 3 is functional. Users can manage their profiles and upload custom avatars.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T027 [P] Set up and run security rules tests for Cloud Firestore and Firebase Storage in [firestore_tests/rules.test.js](../../firestore_tests/rules.test.js) against the local emulator suite
- [x] T029 [P] Update implementation walkthrough file [specs/001-auth-profiles/walkthrough.md](../../specs/001-auth-profiles/walkthrough.md)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel or sequentially in priority order
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch tests in parallel
Task: "Create unit tests for AuthRepositoryImpl in test/features/authentication/data/repositories/auth_repository_impl_test.dart"
Task: "Create AuthBloc tests in test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2, and 4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (Federated Login)
4. Complete Phase 4: User Story 2 (Profile Onboarding)
5. Complete Phase 5: User Story 4 (Session Persistence)
6. **STOP and VALIDATE**: Verify end-to-end login, onboarding, persistence, and uniqueness check.
7. Complete Phase 6: User Story 3 (Avatar upload & management).
8. Complete Phase 7: Polish.
