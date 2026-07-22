# Implementation Plan: Agreement System

**Branch**: `codex/004-agreement-system` | **Date**: 2026-07-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from [spec.md](./spec.md)

## Summary

Phase 4 adds attendance responses, immutable time and location proposals, sealed one-choice ballots, organizer confirmation, agreement reopening, creator-requested permanent outing removal at any lifecycle status, and client-signaled cleanup after a 12-hour post-outing grace period. Flutter code will live primarily in a new `lib/features/voting/` clean-architecture feature, with the attendance state added to the existing outing participant model. Cloud Firestore stores rounds, proposals, private per-user votes, aggregate results, and cross-platform command documents. Node.js 22/TypeScript second-generation Cloud Functions process sensitive commands and coordinated deletion so ballot totals remain hidden, outing-owned data is cleaned up, and Windows follows the same Flutter data path as Android, iOS, and Web.

## Technical Context

**Language/Version**: Dart 3.12.2 with Flutter SDK; TypeScript on Node.js 22 for Cloud Functions

**Primary Dependencies**: Existing `cloud_firestore: ^6.6.0`, `firebase_auth: ^6.5.4`, `firebase_core: ^4.11.0`, `flutter_bloc: ^8.1.3`, `go_router: ^14.0.1`, `get_it: ^7.6.0`, and `equatable: ^2.0.6`; Functions-side `firebase-functions` v2 API and `firebase-admin`. No Flutter `cloud_functions` dependency is introduced because its current platform list omits Windows.

**Storage**: Cloud Firestore top-level collections: existing `outings` and `outing_participants`; new `agreement_rounds`, `agreement_proposals`, `agreement_votes`, `agreement_results`, and `agreement_commands`

**Testing**: `flutter_test`, `bloc_test: ^9.1.5`, `mocktail: ^1.0.4`, Firestore Emulator rules tests, and Node function tests with `firebase-functions-test` plus Mocha; integrated command processing through the Auth, Firestore, and Functions emulators

**Target Platform**: Android, iOS, Web, and Windows from one Flutter codebase; Firebase Functions backend

**Project Type**: Multi-platform Flutter application plus serverless backend functions

**Performance Goals**: Apply the measurement conditions defined by SC-004. Measure attendance and vote latency from user submission through the acting participant's reflected Firestore snapshot. Measure warm agreement-command latency from command document creation through terminal command status and the resulting snapshot. Cold invocations must expose pending state within 500 milliseconds and are reported separately from the warm-command target.

**Constraints**: Crew-first authorization; sealed ballots hide totals, leaders, ties, participation counts, and other users' selections while open; individual votes remain private after confirmation; proposals and completed rounds are immutable until their outing is permanently removed by its creator or app-observed expiry cleanup; cleanup signals begin only after a 12-hour grace period and are independently revalidated by trusted code; schedule and location are directly editable only in Draft and become agreement-controlled once Planning opens; sensitive aggregation, lifecycle changes, and cascading outing removal run in trusted functions; command handlers and expiry cleanup are idempotent; only the outing creator may request early permanent removal, in any lifecycle status; no chat, live meetup, maps, or notifications; repository interfaces isolate Firebase; documentation uses repo-relative links

**Scale/Scope**: Up to 100 crew members and outing participants, one attendance response per participant, one vote per participant per category per round, up to 50 proposals per category per round, and multiple preserved agreement rounds per outing

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First and Clean Architecture)**: PASS. Agreement production code is isolated under `lib/features/voting/{domain,data,presentation}`. Necessary outing participant and lifecycle changes stay in the owning `outings` feature, while shared wiring is limited to DI, routing, Firebase configuration, rules, and the Functions backend.
- **Principle II (Crew-First Interaction Model)**: PASS. Every agreement record carries an outing and crew association, and all reads or actions require current membership in the outing's crew. No direct friendship or social feature is introduced.
- **Principle III (Decoupled Provider Interfaces)**: PASS. Presentation code depends on `AgreementRepository`; Firestore command transport, snapshots, and Functions processing remain behind data-layer or backend boundaries.
- **Principle IV (Mandatory Automated Testing)**: PASS. Domain policies, repositories, Cubits, widgets, command handlers, transactional tallying, and Firestore Security Rules all receive automated coverage.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. Agreement history is persistent decision data, not ephemeral chat, location, or presence data. Phase 4 creates none of the temporary data governed by this principle.
- **Architecture & Platform Constraints**: PASS. The Firestore command pattern avoids a Flutter plugin without Windows support and maintains one cross-platform client path. Sensitive tallying is server controlled.

## Project Structure

### Documentation (this feature)

```text
specs/004-agreement-system/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- agreement_commands.md
|   |-- agreement_repository.md
|   `-- firestore_rules.md
`-- tasks.md                 # Created later by /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/voting/
|-- data/
|   |-- datasources/
|   |   `-- firestore_agreement_datasource.dart
|   |-- models/
|   |   |-- agreement_command_model.dart
|   |   |-- agreement_proposal_model.dart
|   |   |-- agreement_result_model.dart
|   |   |-- agreement_round_model.dart
|   |   `-- agreement_vote_model.dart
|   `-- repositories/
|       `-- agreement_repository_impl.dart
|-- domain/
|   |-- entities/
|   |   |-- agreement_category.dart
|   |   |-- agreement_command.dart
|   |   |-- agreement_proposal.dart
|   |   |-- agreement_result.dart
|   |   |-- agreement_round.dart
|   |   `-- agreement_vote.dart
|   |-- repositories/
|   |   `-- agreement_repository.dart
|   `-- services/
|       |-- agreement_eligibility_policy.dart
|       `-- agreement_visibility_policy.dart
`-- presentation/
    |-- cubit/
    |   |-- agreement_detail/
    |   |   `-- agreement_detail_cubit.dart
    |   `-- agreement_command/
    |       `-- agreement_command_cubit.dart
    |-- screens/
    |   `-- agreement_screen.dart
    `-- widgets/
        |-- attendance_summary.dart
        |-- proposal_ballot.dart
        `-- confirmed_result_summary.dart

lib/features/outings/domain/entities/
|-- attendance_status.dart
`-- outing_participant.dart              # Extended with attendance fields

functions/
|-- src/
|   |-- index.ts
|   `-- agreement/
|       |-- command_handler.ts
|       |-- command_schema.ts
|       |-- agreement_transactions.ts
|       `-- agreement_tally.ts
|-- test/agreement/
|   |-- command_handler.test.ts
|   `-- agreement_tally.test.ts
|-- package.json
`-- tsconfig.json

test/features/voting/
|-- data/repositories/agreement_repository_impl_test.dart
|-- domain/
|   |-- agreement_eligibility_policy_test.dart
|   `-- agreement_visibility_policy_test.dart
`-- presentation/
    |-- cubit/
    |   |-- agreement_command_cubit_test.dart
    |   `-- agreement_detail_cubit_test.dart
    `-- screens/agreement_screen_test.dart

test/features/outings/domain/outing_participant_entity_test.dart
test/features/outings/domain/outing_lifecycle_policy_test.dart
firestore.rules
firestore_tests/rules.test.js
firestore_tests/migrate_schema.js
firebase.json
lib/core/di/injection_container.dart
lib/core/routes/app_router.dart
```

**Structure Decision**: Use the constitution's existing `voting` feature boundary for agreement rounds, proposals, votes, command state, and UI. Attendance remains part of `OutingParticipant` because it is the participant's lifecycle state. A separate `functions/` TypeScript codebase is required for sealed aggregation and atomic lifecycle changes; the Flutter client communicates through Firestore command documents so all four supported platforms use identical code.

## Complexity Tracking

No constitution violations require justification.

## Phase 0: Research

Research decisions and rejected alternatives are recorded in [research.md](./research.md). All technical unknowns are resolved; no `NEEDS CLARIFICATION` markers remain.

## Phase 1: Design & Contracts

Design outputs:

- [data-model.md](./data-model.md)
- [contracts/agreement_commands.md](./contracts/agreement_commands.md)
- [contracts/agreement_repository.md](./contracts/agreement_repository.md)
- [contracts/firestore_rules.md](./contracts/firestore_rules.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Principle I**: PASS. The data model and repository contracts preserve feature-first ownership and clean layers; backend transaction code is isolated under `functions/src/agreement`.
- **Principle II**: PASS. Predictable crew membership and outing participant records are the authorization source for every agreement operation.
- **Principle III**: PASS. The `AgreementRepository` contract hides Firestore collections and asynchronous command processing from Cubits and screens.
- **Principle IV**: PASS. Contracts explicitly require Flutter unit/widget tests, function tests, integrated emulator tests, migration tests, and Security Rules tests.
- **Principle V**: PASS. Agreement rounds and aggregate results are retained as outing history; Phase 4 creates no temporary chat, live location, or presence records.
- **Architecture & Platform Constraints**: PASS. Firestore commands work through the already-supported Firestore plugin on Android, iOS, Web, and Windows, while server-side transactions protect ballot privacy and correctness.
