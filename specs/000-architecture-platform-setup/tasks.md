# Tasks: Architecture & Multi-Platform Setup

**Input**: Design documents from `/specs/000-architecture-platform-setup/`

**Prerequisites**: [plan.md](../../specs/000-architecture-platform-setup/plan.md), [spec.md](../../specs/000-architecture-platform-setup/spec.md), [research.md](../../specs/000-architecture-platform-setup/research.md), [data-model.md](../../specs/000-architecture-platform-setup/data-model.md), [repository_contracts.md](../../specs/000-architecture-platform-setup/contracts/repository_contracts.md)

**Tests**: This project requires automated testing per the ChillGo Constitution (Principle IV).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Paths assume single project structure: `lib/`, `test/` at repository root.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 [P] Add dependencies to `pubspec.yaml` (go_router, get_it, flutter_bloc, firebase_messaging, firebase_crashlytics, firebase_analytics, shared_preferences, and dev_dependencies: bloc_test, mocktail)
- [x] T002 Configure project linting options in `analysis_options.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core clean architecture infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Create directory structure under `lib/core/` (error, presentation, domain, data, routes, di) and a placeholder feature under `lib/features/home/`
- [x] T004 [P] Implement core failure classes in `lib/core/error/failures.dart`
- [x] T005 [P] Implement core exception classes in `lib/core/error/exceptions.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Multi-Platform Application Launch (Priority: P1) 🎯 MVP

**Goal**: Launch the ChillGo application on Android, iOS, Web, and Windows showing a responsive themed home interface.

**Independent Test**: Build and launch the application on Android emulator, iOS simulator, Chrome browser, and Windows desktop, resizing the viewport to verify responsive layouts.

### Implementation for User Story 1

- [x] T006 [P] [US1] Create the responsive layout wrapper in `lib/core/presentation/widgets/responsive_layout.dart`
- [x] T007 [P] [US1] Design the adaptive mobile layout for Home screen in `lib/features/home/presentation/widgets/home_mobile_layout.dart`
- [x] T008 [P] [US1] Design the adaptive tablet layout for Home screen in `lib/features/home/presentation/widgets/home_tablet_layout.dart`
- [x] T009 [P] [US1] Design the adaptive desktop layout for Home screen in `lib/features/home/presentation/widgets/home_desktop_layout.dart`
- [x] T010 [US1] Implement responsive Home screen in `lib/features/home/presentation/pages/home_screen.dart` utilizing the layouts and wrapper
- [x] T011 [US1] Update `lib/main.dart` to boot directly into `HomeScreen` as the primary screen

**Checkpoint**: At this point, the application boots and renders responsively on all target platforms.

---

## Phase 4: User Story 2 - Developer Architecture & Directory Structure (Priority: P1)

**Goal**: Establish clean routing, dependency injection, and module resolving to support future development.

**Independent Test**: Perform route transitions to `/details` and verify correct DI service registration resolving and route interception.

### Tests for User Story 2

- [x] T012 [P] [US2] Write unit tests for router mapping and path matches in `test/core/routes/app_router_test.dart`
- [x] T013 [P] [US2] Write unit tests for service locator registration and resolving in `test/core/di/injection_container_test.dart`

### Implementation for User Story 2

- [x] T014 [P] [US2] Setup declarative routes for home, details, and 404 page in `lib/core/routes/app_router.dart`
- [x] T015 [P] [US2] Implement fallback `NotFoundScreen` in `lib/core/presentation/pages/not_found_page.dart`
- [x] T016 [P] [US2] Create dummy `DetailsPage` in `lib/features/home/presentation/pages/details_page.dart`
- [x] T017 [US2] Setup `GetIt` container in `lib/core/di/injection_container.dart` to initialize and register mock repositories for config and diagnostics
- [x] T018 [US2] Update `lib/main.dart` to initialize the injection container and use the router configuration

**Checkpoint**: At this point, routing transitions and dependency locator works successfully.

---

## Phase 5: User Story 3 - Backend Integration & Diagnostics (Priority: P1)

**Goal**: Initialize Firebase SDK services, Firestore repository mapping, local log capture, and Firebase Crashlytics error trapping.

**Independent Test**: Write data DTO to Firestore emulator and verify serialization. Cause a simulated crash in the app to confirm local capture and remote logging.

### Tests for User Story 3

- [x] T019 [P] [US3] Write unit tests for AppConfiguration model serialization in `test/core/data/models/app_configuration_model_test.dart`
- [x] T020 [P] [US3] Write unit tests for DiagnosticsLog model serialization in `test/core/data/models/diagnostics_log_model_test.dart`
- [x] T021 [US3] Write unit tests for `ConfigRepositoryImpl` using mock Firestore and shared preferences clients in `test/core/data/repositories/config_repository_impl_test.dart`
- [x] T022 [US3] Write unit tests for `DiagnosticsRepositoryImpl` using mock Crashlytics and Analytics clients in `test/core/data/repositories/diagnostics_repository_impl_test.dart`
- [x] T022b [US3] Write unit tests for `GlobalErrorHandler` verifying exception catching and Crashlytics/Analytics integration in `test/core/error/global_error_handler_test.dart`

### Implementation for User Story 3

- [x] T023 [P] [US3] Create `AppConfiguration` domain entity in `lib/core/domain/entities/app_configuration.dart`
- [x] T024 [P] [US3] Create `DiagnosticsLog` domain entity in `lib/core/domain/entities/diagnostics_log.dart`
- [x] T025 [P] [US3] Define abstract `ConfigRepository` in `lib/core/domain/repositories/config_repository.dart`
- [x] T026 [P] [US3] Define abstract `DiagnosticsRepository` in `lib/core/domain/repositories/diagnostics_repository.dart`
- [x] T027 [P] [US3] Create `AppConfigurationModel` DTO in `lib/core/data/models/app_configuration_model.dart`
- [x] T028 [P] [US3] Create `DiagnosticsLogModel` DTO in `lib/core/data/models/diagnostics_log_model.dart`
- [x] T029 [US3] Implement `ConfigRepositoryImpl` in `lib/core/data/repositories/config_repository_impl.dart`
- [x] T030 [US3] Implement `DiagnosticsRepositoryImpl` in `lib/core/data/repositories/diagnostics_repository_impl.dart`
- [x] T030b [US3] Update service locator registration in `lib/core/di/injection_container.dart` to inject concrete `ConfigRepositoryImpl` and `DiagnosticsRepositoryImpl`
- [x] T031 [US3] Implement `GlobalErrorHandler` in `lib/core/error/global_error_handler.dart` to intercept Flutter and Platform exceptions
- [x] T032 [US3] Update `lib/main.dart` to initialize Firebase and setup global error boundary
- [x] T032b [US3] Configure Local Firebase Emulator (Firestore) in `firebase.json`
- [x] T032c [US3] Set up a Node.js test environment under `firestore_tests/` and write automated security rules tests validating read/write constraints defined in `firestore.rules`
- [x] T032d [US3] Run local Firestore emulator and verify that Firestore security rules tests pass successfully
- [x] T033 [US3] Add a debug crash button to `lib/features/home/presentation/pages/home_screen.dart` that triggers a simulated error to verify logging

**Checkpoint**: At this point, Firebase integration, offline logging, and crash-reporting architectures are active and verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, lint enforcement, and final validation

- [x] T034 Run full validation commands and checklist in `specs/000-architecture-platform-setup/quickstart.md`
- [x] T035 [P] Resolve any code style warnings reported by `flutter analyze`
- [x] T036 Update documentation and record walkthrough in `specs/000-architecture-platform-setup/walkthrough.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories.
- **User Stories (Phase 3+)**: All depend on Foundational phase completion.
  - User Story 1 (P1): MVP priority.
  - User Story 2 (P2): Depends on User Story 1 pages structure.
  - User Story 3 (P3): Integrates Firebase setup to boot processes.
- **Polish (Final Phase)**: Depends on all user stories being complete.

### Parallel Opportunities

- Add dependencies and configure linting (Phase 1) can run in parallel.
- Creating data model files and abstract repositories (Phase 5) can run in parallel.
- All models unit tests can run in parallel.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Verify responsive layout compiles and boots on all target devices.

### Incremental Delivery

1. Setup + Foundation -> Code framework ready
2. Add US1 -> Verify UI rendering -> MVP Demo
3. Add US2 -> Verify clean routing & navigation -> Developer Demo
4. Add US3 -> Integrate Firebase service hooks -> Operational Demo
