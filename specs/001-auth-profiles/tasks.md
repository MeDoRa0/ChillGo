# Tasks: Phase 1 - Authentication & Profiles

**Input**: Design documents from [specs/001-auth-profiles/](../../specs/001-auth-profiles/)

**Prerequisites**: [plan.md](../../specs/001-auth-profiles/plan.md), [spec.md](../../specs/001-auth-profiles/spec.md), [research.md](../../specs/001-auth-profiles/research.md), [data-model.md](../../specs/001-auth-profiles/data-model.md), [contracts/](../../specs/001-auth-profiles/contracts/)

**Tests**: Required. The ChillGo Constitution mandates automated tests for repository implementations, Cubits/Blocs, domain behavior, and Firestore/Storage rules.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified independently. If a listed file already exists, update it in place to satisfy the described behavior instead of creating a duplicate.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on another incomplete task.
- **[Story]**: Applies only to user-story tasks, for example `[US1]`.
- Every task includes exact repo-relative file paths.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm Firebase, package, emulator, and platform setup before feature work.

- [ ] T001 Verify authentication/profile dependencies are present in [pubspec.yaml](../../pubspec.yaml): `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`, `sign_in_with_apple`, `flutter_bloc`, `bloc_test`, `mocktail`, `image_picker`, and `image`.
- [ ] T002 [P] Configure Firebase project files and emulator flag handling in [lib/main.dart](../../lib/main.dart), [lib/firebase_options.dart](../../lib/firebase_options.dart), and [firebase.json](../../firebase.json).
- [ ] T003 [P] Configure Firestore rules entry in [firebase.json](../../firebase.json) to use [firestore.rules](../../firestore.rules).
- [ ] T004 [P] Configure Storage rules entry in [firebase.json](../../firebase.json) to use [storage.rules](../../storage.rules).
- [ ] T005 [P] Configure Firestore emulator rules test command in [firestore_tests/package.json](../../firestore_tests/package.json).
- [ ] T006 [P] Add image picker platform permissions for Android in [android/app/src/main/AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml).
- [ ] T007 [P] Add image picker platform permissions for iOS in [ios/Runner/Info.plist](../../ios/Runner/Info.plist).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared domain contracts, entities, exceptions, dependency injection, and route shells required by all stories.

**CRITICAL**: No user story implementation should begin until this phase is complete.

- [ ] T008 Define `AuthStatus`, `UserCredentials`, and `AuthRepository` exactly matching [specs/001-auth-profiles/contracts/auth_repository.dart](../../specs/001-auth-profiles/contracts/auth_repository.dart) in [lib/features/authentication/domain/repositories/auth_repository.dart](../../lib/features/authentication/domain/repositories/auth_repository.dart).
- [ ] T009 Define `UserProfile`, `PublicUserProfile`, and `ProfileRepository` exactly matching [specs/001-auth-profiles/contracts/profile_repository.dart](../../specs/001-auth-profiles/contracts/profile_repository.dart) in [lib/features/profile/domain/repositories/profile_repository.dart](../../lib/features/profile/domain/repositories/profile_repository.dart).
- [ ] T010 [P] Create or update the shared `UserProfile` domain entity with immutable fields `id`, `username`, `displayName`, `avatarUrl`, and `createdAt` in [lib/features/authentication/domain/entities/user_profile.dart](../../lib/features/authentication/domain/entities/user_profile.dart).
- [ ] T011 [P] Add feature-specific exception or failure mappings for auth cancellation, network failure, duplicate username, invalid username, invalid avatar, and unauthorized access in [lib/core/error/exceptions.dart](../../lib/core/error/exceptions.dart) and [lib/core/error/failures.dart](../../lib/core/error/failures.dart).
- [ ] T012 Register Firebase data sources, repositories, AuthBloc, OnboardingCubit, and ProfileCubit in [lib/core/di/injection.dart](../../lib/core/di/injection.dart) and [lib/core/di/injection_container.dart](../../lib/core/di/injection_container.dart).
- [ ] T013 Define route names and guarded redirects for `/login`, `/onboarding`, `/home`, and `/profile` in [lib/core/routes/app_router.dart](../../lib/core/routes/app_router.dart).
- [ ] T014 [P] Add Firestore rules for `/users/{uid}` and `/usernames/{username}` according to [specs/001-auth-profiles/data-model.md](../../specs/001-auth-profiles/data-model.md) in [firestore.rules](../../firestore.rules).
- [ ] T015 [P] Add Storage rules for `/avatars/{uid}` allowing authenticated owner writes for compressed JPEG, PNG, or WebP files under 500 KB in [storage.rules](../../storage.rules).

**Checkpoint**: Foundation is ready. User stories can now be implemented in priority order or in parallel by separate agents.

---

## Phase 3: User Story 1 - Federated Sign-In & Account Registration (Priority: P1) MVP

**Goal**: A new or returning user signs in with Google, or Apple where supported, and is routed to onboarding or home based on profile existence.

**Independent Test**: A mock unauthenticated user can sign in, cancellation stays on login with a friendly message, new authenticated users reach onboarding, and returning users reach home.

### Tests for User Story 1

- [ ] T016 [P] [US1] Write FirebaseAuthDatasource tests for Google success, Apple success, provider cancellation, and provider failure in [test/features/authentication/data/datasources/firebase_auth_datasource_test.dart](../../test/features/authentication/data/datasources/firebase_auth_datasource_test.dart).
- [ ] T017 [P] [US1] Write AuthRepositoryImpl tests for auth status mapping `unknown`, `unauthenticated`, `authenticatedNoProfile`, and `authenticatedWithProfile` in [test/features/authentication/data/repositories/auth_repository_impl_test.dart](../../test/features/authentication/data/repositories/auth_repository_impl_test.dart).
- [ ] T018 [P] [US1] Write AuthBloc tests for app start, Google sign-in, Apple sign-in, cancellation error, and authenticated routing states in [test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart](../../test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart).
- [ ] T019 [P] [US1] Write LoginScreen widget tests for Google button, conditional Apple button, loading state, and cancellation message in [test/features/authentication/presentation/screens/login_screen_test.dart](../../test/features/authentication/presentation/screens/login_screen_test.dart).
- [ ] T020 [P] [US1] Write router redirect tests for unauthenticated, authenticated-no-profile, and authenticated-with-profile states in [test/core/routes/app_router_test.dart](../../test/core/routes/app_router_test.dart).

### Implementation for User Story 1

- [ ] T021 [US1] Implement Google sign-in and Apple sign-in provider calls with cancellation handling in [lib/features/authentication/data/datasources/firebase_auth_datasource.dart](../../lib/features/authentication/data/datasources/firebase_auth_datasource.dart).
- [ ] T022 [US1] Implement AuthRepositoryImpl so `status` combines Firebase auth state with profile existence from ProfileRepository in [lib/features/authentication/data/repositories/auth_repository_impl.dart](../../lib/features/authentication/data/repositories/auth_repository_impl.dart).
- [ ] T023 [US1] Implement AuthEvent classes for app start, Google sign-in request, Apple sign-in request, and auth sign-out request in [lib/features/authentication/presentation/blocs/auth/auth_event.dart](../../lib/features/authentication/presentation/blocs/auth/auth_event.dart).
- [ ] T024 [US1] Implement AuthState classes for initial, loading, unauthenticated, authenticatedNoProfile, authenticatedWithProfile, and failure states in [lib/features/authentication/presentation/blocs/auth/auth_state.dart](../../lib/features/authentication/presentation/blocs/auth/auth_state.dart).
- [ ] T025 [US1] Implement AuthBloc event handlers and repository subscription cleanup in [lib/features/authentication/presentation/blocs/auth/auth_bloc.dart](../../lib/features/authentication/presentation/blocs/auth/auth_bloc.dart).
- [ ] T026 [US1] Implement LoginScreen with Google sign-in, supported Apple sign-in, loading state, and friendly errors in [lib/features/authentication/presentation/screens/login_screen.dart](../../lib/features/authentication/presentation/screens/login_screen.dart).
- [ ] T027 [US1] Wire AuthBloc-driven routing so authenticated users without profiles go to `/onboarding` and users with profiles go to `/home` in [lib/core/routes/app_router.dart](../../lib/core/routes/app_router.dart).

**Checkpoint**: User Story 1 is functional and independently testable.

---

## Phase 4: User Story 2 - Profile Onboarding (Username & Display Name Creation) (Priority: P1)

**Goal**: A newly authenticated user creates an immutable unique username and a mutable display name before entering the app.

**Independent Test**: A new user can submit a valid unique username and display name, duplicate usernames fail case-insensitively, invalid usernames fail locally, and success routes to home.

### Tests for User Story 2

- [ ] T028 [P] [US2] Write username validation tests for 3-20 chars, lowercase normalization, alphanumeric/underscore only, no spaces, and display name 1-50 chars in [test/features/profile/domain/profile_validation_test.dart](../../test/features/profile/domain/profile_validation_test.dart).
- [ ] T029 [P] [US2] Write FirestoreProfileDatasource tests for transaction profile creation, duplicate username collision, profile fetch, and username availability in [test/features/profile/data/datasources/firestore_profile_datasource_test.dart](../../test/features/profile/data/datasources/firestore_profile_datasource_test.dart).
- [ ] T030 [P] [US2] Write ProfileRepositoryImpl tests for validation, normalized username writes, duplicate username mapping, and profile retrieval in [test/features/profile/data/repositories/profile_repository_impl_test.dart](../../test/features/profile/data/repositories/profile_repository_impl_test.dart).
- [ ] T031 [P] [US2] Write OnboardingCubit tests for initial state, validation failure, duplicate username failure, network failure, and successful profile creation in [test/features/profile/presentation/blocs/onboarding/onboarding_cubit_test.dart](../../test/features/profile/presentation/blocs/onboarding/onboarding_cubit_test.dart).
- [ ] T032 [P] [US2] Write OnboardingScreen widget tests for form validation, disabled submit while invalid, loading state, duplicate username error, and success callback in [test/features/profile/presentation/screens/onboarding_screen_test.dart](../../test/features/profile/presentation/screens/onboarding_screen_test.dart).
- [ ] T033 [P] [US2] Write Firestore rules tests preventing username overwrite and enforcing owner-only profile create/update in [firestore_tests/rules.test.js](../../firestore_tests/rules.test.js).

### Implementation for User Story 2

- [ ] T034 [US2] Implement username and display name validation helpers in [lib/features/profile/domain/repositories/profile_repository.dart](../../lib/features/profile/domain/repositories/profile_repository.dart) or a dedicated [lib/features/profile/domain/profile_validation.dart](../../lib/features/profile/domain/profile_validation.dart).
- [ ] T035 [US2] Implement Firestore transaction creating `/usernames/{username_lowercase}` and `/users/{uid}` atomically in [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart).
- [ ] T036 [US2] Implement profile fetch and username availability reads in [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart).
- [ ] T037 [US2] Implement ProfileRepositoryImpl validation and data source delegation for create profile, get profile, and username availability in [lib/features/profile/data/repositories/profile_repository_impl.dart](../../lib/features/profile/data/repositories/profile_repository_impl.dart).
- [ ] T038 [US2] Implement OnboardingCubit states and submission flow in [lib/features/profile/presentation/blocs/onboarding/onboarding_cubit.dart](../../lib/features/profile/presentation/blocs/onboarding/onboarding_cubit.dart).
- [ ] T039 [US2] Implement OnboardingScreen form with username, display name, inline validation, loading state, duplicate error, and submit action in [lib/features/profile/presentation/screens/onboarding_screen.dart](../../lib/features/profile/presentation/screens/onboarding_screen.dart).
- [ ] T040 [US2] Update router refresh logic so successful onboarding moves from `/onboarding` to `/home` in [lib/core/routes/app_router.dart](../../lib/core/routes/app_router.dart).

**Checkpoint**: User Story 2 is functional and independently testable.

---

## Phase 5: User Story 4 - Session Persistence & Sign Out (Priority: P1)

**Goal**: Firebase Auth session persistence keeps users logged in across restarts, and sign out returns users to login.

**Independent Test**: Relaunching after login bypasses login, interrupted onboarding returns to onboarding, and tapping sign out clears the session and returns to login.

### Tests for User Story 4

- [ ] T041 [P] [US4] Extend AuthRepositoryImpl tests for persisted current user, missing profile after restart, and sign-out status transition in [test/features/authentication/data/repositories/auth_repository_impl_test.dart](../../test/features/authentication/data/repositories/auth_repository_impl_test.dart).
- [ ] T042 [P] [US4] Extend AuthBloc tests for startup session restore, incomplete onboarding restore, and sign-out event in [test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart](../../test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart).
- [ ] T043 [P] [US4] Write ProfileScreen sign-out widget test in [test/features/profile/presentation/screens/profile_screen_test.dart](../../test/features/profile/presentation/screens/profile_screen_test.dart).

### Implementation for User Story 4

- [ ] T044 [US4] Ensure AuthRepositoryImpl relies on Firebase Auth native persistence and does not store tokens manually in [lib/features/authentication/data/repositories/auth_repository_impl.dart](../../lib/features/authentication/data/repositories/auth_repository_impl.dart).
- [ ] T045 [US4] Implement sign-out event dispatch and state transition in [lib/features/authentication/presentation/blocs/auth/auth_bloc.dart](../../lib/features/authentication/presentation/blocs/auth/auth_bloc.dart).
- [ ] T046 [US4] Add a clear sign-out action in the profile UI that calls AuthBloc/AuthRepository in [lib/features/profile/presentation/screens/profile_screen.dart](../../lib/features/profile/presentation/screens/profile_screen.dart).
- [ ] T047 [US4] Ensure router redirects signed-out users to `/login` and authenticated users without profiles to `/onboarding` after app restart in [lib/core/routes/app_router.dart](../../lib/core/routes/app_router.dart).

**Checkpoint**: User Story 4 is functional and independently testable.

---

## Phase 6: User Story 3 - Profile Management & Avatar Upload (Priority: P2)

**Goal**: An onboarded user views profile details, edits display name, uploads a custom avatar, and exposes only public lookup fields to authenticated users.

**Independent Test**: A user can edit display name, upload a valid avatar, reject invalid/large avatar files, keep username read-only, and another authenticated user can look up only username/display name/avatar.

### Tests for User Story 3

- [ ] T048 [P] [US3] Write image helper tests for JPEG, PNG, WebP acceptance, unsupported type rejection, 5 MB source limit, and compressed target under 500 KB in [test/features/profile/presentation/utils/image_helper_test.dart](../../test/features/profile/presentation/utils/image_helper_test.dart).
- [ ] T049 [P] [US3] Extend FirestoreProfileDatasource tests for display name update, public lookup by username, avatar upload URL write, and content type validation in [test/features/profile/data/datasources/firestore_profile_datasource_test.dart](../../test/features/profile/data/datasources/firestore_profile_datasource_test.dart).
- [ ] T050 [P] [US3] Extend ProfileRepositoryImpl tests for display name update, avatar upload, and public lookup field filtering in [test/features/profile/data/repositories/profile_repository_impl_test.dart](../../test/features/profile/data/repositories/profile_repository_impl_test.dart).
- [ ] T051 [P] [US3] Write ProfileCubit tests for load profile, edit display name, avatar validation failure, avatar upload success, and lookup success/failure in [test/features/profile/presentation/blocs/profile/profile_cubit_test.dart](../../test/features/profile/presentation/blocs/profile/profile_cubit_test.dart).
- [ ] T052 [P] [US3] Write ProfileScreen widget tests for read-only username, editable display name, avatar picker action, loading state, and error messages in [test/features/profile/presentation/screens/profile_screen_test.dart](../../test/features/profile/presentation/screens/profile_screen_test.dart).
- [ ] T053 [P] [US3] Extend Firestore and Storage rules tests for authenticated public profile reads, owner-only updates, immutable username registry, and avatar owner-only writes in [firestore_tests/rules.test.js](../../firestore_tests/rules.test.js).

### Implementation for User Story 3

- [ ] T054 [US3] Implement image picking and compression helper for JPEG, PNG, and WebP source files up to 5 MB in [lib/features/profile/presentation/utils/image_helper.dart](../../lib/features/profile/presentation/utils/image_helper.dart).
- [ ] T055 [US3] Implement display name update in [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart).
- [ ] T056 [US3] Implement avatar upload to `/avatars/{uid}` with MIME metadata and download URL retrieval in [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart).
- [ ] T057 [US3] Implement public lookup by normalized username returning only `username`, `displayName`, and `avatarUrl` in [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart).
- [ ] T058 [US3] Implement ProfileRepositoryImpl methods for update profile, upload avatar, and lookup by username in [lib/features/profile/data/repositories/profile_repository_impl.dart](../../lib/features/profile/data/repositories/profile_repository_impl.dart).
- [ ] T059 [US3] Implement ProfileCubit states and methods for loading profile, saving display name, uploading avatar, and looking up public profiles in [lib/features/profile/presentation/blocs/profile/profile_cubit.dart](../../lib/features/profile/presentation/blocs/profile/profile_cubit.dart).
- [ ] T060 [US3] Implement ProfileScreen with read-only username, editable display name, avatar preview/upload, created date display, sign-out affordance, and friendly errors in [lib/features/profile/presentation/screens/profile_screen.dart](../../lib/features/profile/presentation/screens/profile_screen.dart).

**Checkpoint**: User Story 3 is functional and independently testable.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verify quality, performance, documentation, and quickstart scenarios across all stories.

- [ ] T061 [P] Run and fix Flutter analyzer issues for auth/profile changes using `flutter analyze` and update affected files under [lib/](../../lib/) and [test/](../../test/).
- [ ] T062 [P] Run and fix all Flutter tests using `flutter test` with focus on [test/features/authentication/](../../test/features/authentication/) and [test/features/profile/](../../test/features/profile/).
- [ ] T063 [P] Run and fix Firebase emulator rules tests using [firestore_tests/package.json](../../firestore_tests/package.json) and [firestore_tests/rules.test.js](../../firestore_tests/rules.test.js).
- [ ] T064 Verify Quickstart Scenario A for new user onboarding from [specs/001-auth-profiles/quickstart.md](../../specs/001-auth-profiles/quickstart.md) and record notes in [specs/001-auth-profiles/walkthrough.md](../../specs/001-auth-profiles/walkthrough.md).
- [ ] T065 Verify Quickstart Scenario B for duplicate username protection from [specs/001-auth-profiles/quickstart.md](../../specs/001-auth-profiles/quickstart.md) and record notes in [specs/001-auth-profiles/walkthrough.md](../../specs/001-auth-profiles/walkthrough.md).
- [ ] T066 Verify Quickstart Scenario C for session persistence and sign out from [specs/001-auth-profiles/quickstart.md](../../specs/001-auth-profiles/quickstart.md) and record notes in [specs/001-auth-profiles/walkthrough.md](../../specs/001-auth-profiles/walkthrough.md).
- [ ] T067 Verify Quickstart Scenario D for avatar upload and public lookup from [specs/001-auth-profiles/quickstart.md](../../specs/001-auth-profiles/quickstart.md) and record notes in [specs/001-auth-profiles/walkthrough.md](../../specs/001-auth-profiles/walkthrough.md).
- [ ] T068 [P] Update feature documentation with final commands, emulator caveats, and any skipped manual verification in [specs/001-auth-profiles/walkthrough.md](../../specs/001-auth-profiles/walkthrough.md).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundational**: Depends on Phase 1. Blocks all user stories.
- **Phase 3 US1**: Depends on Phase 2.
- **Phase 4 US2**: Depends on Phase 2, and should be integrated after US1 for the normal new-user flow.
- **Phase 5 US4**: Depends on Phase 2, and should be integrated after US1 and US2 for complete routing behavior.
- **Phase 6 US3**: Depends on Phase 2 and benefits from US2 profile creation.
- **Phase 7 Polish**: Depends on whichever user stories are implemented.

### User Story Dependencies

- **US1 Federated Sign-In**: Can start after Phase 2. MVP entry point.
- **US2 Profile Onboarding**: Can start after Phase 2, but full user flow depends on US1.
- **US4 Session Persistence & Sign Out**: Can start after Phase 2, but complete acceptance depends on US1 and US2 route states.
- **US3 Profile Management & Avatar Upload**: Can start after Phase 2, but requires an onboarded profile from US2 for end-to-end testing.

### Within Each User Story

- Write tests first and confirm they fail for missing behavior.
- Implement data source/repository behavior before Cubit/Bloc behavior.
- Implement Cubit/Bloc behavior before UI screens.
- Complete routing integration last for stories that change navigation.

---

## Parallel Opportunities

- Setup tasks T002-T007 can run in parallel after T001.
- Foundational tasks T010, T011, T014, and T015 can run in parallel after T008 and T009 are clear.
- Test tasks within each story are parallelizable where marked `[P]`.
- US1, US2, US4, and US3 can be assigned to separate agents after Phase 2, but route and profile-flow integration should be reconciled sequentially in priority order: US1 -> US2 -> US4 -> US3.

---

## Parallel Example: User Story 1

```text
Task: "T016 [P] [US1] Write FirebaseAuthDatasource tests in test/features/authentication/data/datasources/firebase_auth_datasource_test.dart"
Task: "T017 [P] [US1] Write AuthRepositoryImpl tests in test/features/authentication/data/repositories/auth_repository_impl_test.dart"
Task: "T018 [P] [US1] Write AuthBloc tests in test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart"
Task: "T019 [P] [US1] Write LoginScreen widget tests in test/features/authentication/presentation/screens/login_screen_test.dart"
Task: "T020 [P] [US1] Write router redirect tests in test/core/routes/app_router_test.dart"
```

## Parallel Example: User Story 2

```text
Task: "T028 [P] [US2] Write username validation tests in test/features/profile/domain/profile_validation_test.dart"
Task: "T029 [P] [US2] Write FirestoreProfileDatasource tests in test/features/profile/data/datasources/firestore_profile_datasource_test.dart"
Task: "T030 [P] [US2] Write ProfileRepositoryImpl tests in test/features/profile/data/repositories/profile_repository_impl_test.dart"
Task: "T031 [P] [US2] Write OnboardingCubit tests in test/features/profile/presentation/blocs/onboarding/onboarding_cubit_test.dart"
Task: "T032 [P] [US2] Write OnboardingScreen widget tests in test/features/profile/presentation/screens/onboarding_screen_test.dart"
```

## Parallel Example: User Story 3

```text
Task: "T048 [P] [US3] Write image helper tests in test/features/profile/presentation/utils/image_helper_test.dart"
Task: "T049 [P] [US3] Extend FirestoreProfileDatasource tests in test/features/profile/data/datasources/firestore_profile_datasource_test.dart"
Task: "T050 [P] [US3] Extend ProfileRepositoryImpl tests in test/features/profile/data/repositories/profile_repository_impl_test.dart"
Task: "T051 [P] [US3] Write ProfileCubit tests in test/features/profile/presentation/blocs/profile/profile_cubit_test.dart"
Task: "T052 [P] [US3] Write ProfileScreen widget tests in test/features/profile/presentation/screens/profile_screen_test.dart"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 Setup.
2. Complete Phase 2 Foundational.
3. Complete Phase 3 US1 Federated Sign-In.
4. Complete Phase 4 US2 Profile Onboarding.
5. Complete Phase 5 US4 Session Persistence & Sign Out.
6. Stop and validate login, onboarding, duplicate username handling, app restart, and sign out.

### Incremental Delivery

1. Deliver US1 so users can authenticate.
2. Deliver US2 so new users can create required profile identity.
3. Deliver US4 so returning users and sign-out behavior are correct.
4. Deliver US3 so onboarded users can manage profile details and avatar.
5. Finish Phase 7 quality gates and quickstart verification.

### Cheaper-Model Guidance

- Do not introduce direct Firebase SDK calls in UI files; route all Firebase access through repository interfaces.
- Do not create friendships, followers, feeds, or any direct social graph behavior.
- Do not allow username changes after profile creation.
- Normalize usernames to lowercase before checking availability, writing `/usernames/{username}`, or looking up profiles.
- Public lookup must expose only `username`, `displayName`, and `avatarUrl`.
- Prefer updating existing files listed in each task over creating parallel implementations.

---

## Phase 8: Convergence

**Purpose**: Close gaps found by `/speckit-converge` between the current codebase and the feature artifacts.

- [ ] T069 CRITICAL harden [firestore.rules](../../firestore.rules) so `/users/{uid}` updates cannot change immutable `username` or `createdAt`, and extend [firestore_tests/rules.test.js](../../firestore_tests/rules.test.js) to reject those writes per FR-007 and Constitution IV (contradicts).
- [ ] T070 CRITICAL add Firebase initialization/configuration support for Android, iOS, Web, and Windows in [lib/firebase_options.dart](../../lib/firebase_options.dart), [firebase.json](../../firebase.json), and platform Firebase config files including [android/app/google-services.json](../../android/app/google-services.json) so Google sign-in can run on every target platform per FR-001 (partial).
- [ ] T071 Implement authenticated public username lookup by adding `PublicUserProfile` and `lookupByUsername` to [lib/features/profile/domain/repositories/profile_repository.dart](../../lib/features/profile/domain/repositories/profile_repository.dart), [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart), [lib/features/profile/data/repositories/profile_repository_impl.dart](../../lib/features/profile/data/repositories/profile_repository_impl.dart), and related tests per FR-010 (missing).
- [ ] T072 Enforce avatar source validation and storage constraints for JPEG, PNG, and WebP only, 5 MB pre-compression limit, WebP MIME support, and strict `image/(jpeg|png|webp)` Storage rules in [lib/features/profile/presentation/utils/image_helper.dart](../../lib/features/profile/presentation/utils/image_helper.dart), [lib/features/profile/data/datasources/firestore_profile_datasource.dart](../../lib/features/profile/data/datasources/firestore_profile_datasource.dart), [storage.rules](../../storage.rules), and related tests per FR-008 (partial).
- [ ] T073 Route Google and Apple sign-in through AuthBloc by adding request/loading/failure events and states in [lib/features/authentication/presentation/blocs/auth/auth_event.dart](../../lib/features/authentication/presentation/blocs/auth/auth_event.dart), [lib/features/authentication/presentation/blocs/auth/auth_state.dart](../../lib/features/authentication/presentation/blocs/auth/auth_state.dart), [lib/features/authentication/presentation/blocs/auth/auth_bloc.dart](../../lib/features/authentication/presentation/blocs/auth/auth_bloc.dart), and [lib/features/authentication/presentation/screens/login_screen.dart](../../lib/features/authentication/presentation/screens/login_screen.dart) per US1/AC3 (partial).
- [ ] T074 Gate Apple sign-in UI and calls to supported Apple/Web platforms only in [lib/features/authentication/presentation/screens/login_screen.dart](../../lib/features/authentication/presentation/screens/login_screen.dart) and [lib/features/authentication/data/datasources/firebase_auth_datasource.dart](../../lib/features/authentication/data/datasources/firebase_auth_datasource.dart) per FR-001 (partial).
- [ ] T075 Display account creation date on [lib/features/profile/presentation/screens/profile_screen.dart](../../lib/features/profile/presentation/screens/profile_screen.dart) and cover it in [test/features/profile/presentation/screens/profile_screen_test.dart](../../test/features/profile/presentation/screens/profile_screen_test.dart) per FR-005 (partial).
- [ ] T076 Add planned profile domain usecases in [lib/features/profile/domain/usecases/create_profile.dart](../../lib/features/profile/domain/usecases/create_profile.dart), [lib/features/profile/domain/usecases/get_profile.dart](../../lib/features/profile/domain/usecases/get_profile.dart), [lib/features/profile/domain/usecases/update_profile.dart](../../lib/features/profile/domain/usecases/update_profile.dart), and [lib/features/profile/domain/usecases/upload_avatar.dart](../../lib/features/profile/domain/usecases/upload_avatar.dart), wire Cubits through them, and add usecase unit tests per plan: profile usecases (missing).
- [ ] T077 Add the planned user profile DTO/model mapping in [lib/features/authentication/data/models/user_profile_model.dart](../../lib/features/authentication/data/models/user_profile_model.dart) or move the model path to the profile feature consistently in a follow-up plan update per plan: authentication data model (missing).
- [ ] T078 Add missing task-required tests in [test/features/authentication/data/datasources/firebase_auth_datasource_test.dart](../../test/features/authentication/data/datasources/firebase_auth_datasource_test.dart), [test/features/authentication/presentation/screens/login_screen_test.dart](../../test/features/authentication/presentation/screens/login_screen_test.dart), [test/features/profile/domain/profile_validation_test.dart](../../test/features/profile/domain/profile_validation_test.dart), [test/features/profile/presentation/screens/onboarding_screen_test.dart](../../test/features/profile/presentation/screens/onboarding_screen_test.dart), [test/features/profile/presentation/screens/profile_screen_test.dart](../../test/features/profile/presentation/screens/profile_screen_test.dart), and [test/features/profile/presentation/utils/image_helper_test.dart](../../test/features/profile/presentation/utils/image_helper_test.dart) per T016, T019, T028, T032, T048, and T052 (partial).
