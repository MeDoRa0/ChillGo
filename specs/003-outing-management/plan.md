# Implementation Plan: Outing Management

**Branch**: `codex/003-outing-management` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from [spec.md](./spec.md)

## Summary

This feature implements Phase 3: Outing Management. Crew members can create outings inside crews, view crew outings and outing details, and the outing creator or crew owner can edit details, cancel outings, manage participants, and manually advance the outing lifecycle. The implementation will use the existing Flutter feature-first architecture and Cloud Firestore, with top-level `outings` and `outing_participants` collections, predictable participant IDs, and security rules that reuse crew membership checks.

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter SDK

**Primary Dependencies**: `cloud_firestore: ^6.6.0`, `firebase_auth: ^6.5.4`, `flutter_bloc: ^8.1.3`, `go_router: ^14.0.1`, `get_it: ^7.6.0`, `equatable: ^2.0.6`

**Storage**: Cloud Firestore

**Testing**: `flutter_test`, `bloc_test: ^9.1.5`, `mocktail: ^1.0.4`, Firestore Emulator rules tests

**Target Platform**: Multi-platform (Android, iOS, Web, Windows)

**Project Type**: mobile-app / multi-platform app

**Performance Goals**: Outing list/detail updates appear in real time; local validated actions complete in under 1 second; network-backed actions settle in under 3 seconds under normal connectivity.

**Constraints**: Preserve crew-first access, use repository interfaces for Firestore access, keep Phase 3 location free-text only, exclude voting/chat/live meetup/notifications, and use O(1)-friendly security checks through predictable participant IDs.

**Scale/Scope**: Up to 100 crew members per crew, up to 100 active or historical outings per crew in MVP validation, and one participant record per outing-member pair.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First and Clean Architecture)**: PASS. New outing production files stay under `lib/features/outings` and split into `domain`, `data`, and `presentation`; required cross-feature wiring is limited to shared infrastructure and entry points in `firestore.rules`, `lib/core/di/injection_container.dart`, `lib/core/routes/app_router.dart`, and `lib/features/crews/presentation/screens/crew_details_screen.dart`.
- **Principle II (Crew-First Interaction Model)**: PASS. Outings exist only inside crews; direct friendships, social feeds, and non-crew access are excluded.
- **Principle III (Decoupled Provider Interfaces)**: PASS. Presentation Cubits will depend on an `OutingRepository` interface; Firestore-specific behavior stays in data sources/repositories.
- **Principle IV (Mandatory Automated Testing)**: PASS. Domain validation, repository behavior, Cubits, widgets/screens, and Firestore rules will be covered by automated tests.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. Phase 3 does not create chat, live location, or presence data. Completed and archived outings are retained as persistent history.

## Project Structure

### Documentation (this feature)

```text
specs/003-outing-management/
|-- plan.md              # This file
|-- research.md          # Phase 0 output
|-- data-model.md        # Phase 1 output
|-- quickstart.md        # Phase 1 output
|-- contracts/           # Phase 1 output
`-- tasks.md             # Phase 2 output, created by /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/outings/
|-- data/
|   |-- datasources/
|   |   `-- firestore_outings_datasource.dart
|   |-- models/
|   |   |-- outing_model.dart
|   |   `-- outing_participant_model.dart
|   `-- repositories/
|       `-- outing_repository_impl.dart
|-- domain/
|   |-- entities/
|   |   |-- outing.dart
|   |   |-- outing_participant.dart
|   |   `-- outing_status.dart
|   |-- repositories/
|   |   `-- outing_repository.dart
|   `-- services/
|       `-- outing_lifecycle_policy.dart
`-- presentation/
    |-- cubit/
    |   |-- outing_detail/
    |   |   `-- outing_detail_cubit.dart
    |   |-- outings_list/
    |   |   `-- outings_list_cubit.dart
    |   `-- outing_form/
    |       `-- outing_form_cubit.dart
    `-- screens/
        |-- outing_details_screen.dart
        |-- outing_form_screen.dart
        `-- outings_list_screen.dart

test/features/outings/
|-- data/
|   |-- datasources/        # planned datasource coverage
|   `-- repositories/
|       `-- outing_repository_impl_test.dart
|-- domain/
|   |-- outing_entity_test.dart
|   |-- outing_lifecycle_policy_test.dart
|   `-- outing_participant_entity_test.dart
|-- outing_repository_fake.dart
`-- presentation/
    |-- cubit/
    |   |-- outing_detail_cubit_test.dart
    |   |-- outing_form_cubit_test.dart
    |   `-- outings_list_cubit_test.dart
    `-- screens/            # planned widget coverage

test/features/authentication/presentation/blocs/auth/auth_bloc_test.dart
test/features/crews/presentation/screens/crew_details_screen_test.dart

firestore.rules
firestore_tests/rules.test.js
```

**Structure Decision**: Single Flutter project using the existing feature-first folder `lib/features/outings/`. Firestore security rule updates remain in the root `firestore.rules`, with emulator validation in `firestore_tests/rules.test.js`.

## Complexity Tracking

*No violations identified. Fully compliant with Constitution.*

## Phase 0: Research

Research output is captured in [research.md](./research.md). All planning decisions are resolved; no `NEEDS CLARIFICATION` items remain.

## Phase 1: Design & Contracts

Design outputs:

- [data-model.md](./data-model.md)
- [contracts/outing_repository.md](./contracts/outing_repository.md)
- [contracts/firestore_rules.md](./contracts/firestore_rules.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Principle I (Feature-First and Clean Architecture)**: PASS. The data model and contracts map to `lib/features/outings` with domain interfaces separated from Firestore implementation.
- **Principle II (Crew-First Interaction Model)**: PASS. Outing access and participant eligibility are entirely derived from crew membership.
- **Principle III (Decoupled Provider Interfaces)**: PASS. The repository contract isolates Firestore and keeps UI state management provider-agnostic.
- **Principle IV (Mandatory Automated Testing)**: PASS. Quickstart and contracts require repository, Cubit/widget, and Firestore Emulator security-rule validation.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. No temporary chat, live location, or presence data is introduced in Phase 3.
