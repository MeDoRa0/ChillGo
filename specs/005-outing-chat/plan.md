# Implementation Plan: Outing Chat

**Branch**: `codex/005-outing-chat` | **Date**: 2026-07-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from [spec.md](./spec.md)

## Summary

Phase 5 adds a dedicated, participant-only text chat to every outing, with realtime newest-message updates, cursor-based older history, private per-user read progress and unread counts, online-only manual-retry sending, a trusted rolling 30-message-per-minute limit, exact 24-hour supported-client unavailability, and automatic permanent cleanup. Flutter code will live in a new `lib/features/chat/` clean-architecture feature. Clients read authorized message snapshots directly but create send attempts through online-only Firestore transactions in `chat_commands`; Node.js 22/TypeScript Functions revalidate access, enforce rate limits, assign authoritative timestamps, and create immutable messages idempotently. An exact `expiresAt` boundary removes messages from product visibility, a one-minute scheduled cleanup performs prompt permanent deletion, and Firestore TTL is configured only as a backstop. The existing outing-deletion service will cascade through all chat-owned data and prevent in-flight sends from recreating a removed outing.

## Technical Context

**Language/Version**: Dart 3.12.2 with Flutter SDK; TypeScript 5.8.3 on Node.js 22 for Cloud Functions

**Primary Dependencies**: Existing `cloud_firestore: ^6.6.0`, `firebase_auth: ^6.5.4`, `firebase_core: ^4.11.0`, `flutter_bloc: ^9.1.1`, `go_router: ^17.3.0`, `get_it: ^9.2.1`, and `equatable: ^2.0.6`; Functions-side `firebase-functions: ^6.4.0` v2 APIs and `firebase-admin: ^13.4.0`. No Flutter `cloud_functions` or connectivity dependency is added; an online-only Firestore transaction provides the cross-platform send boundary and fails instead of queueing while offline.

**Storage**: Existing top-level `outings`, `outing_participants`, `crew_memberships`, and `users`; new top-level `chat_messages`, `chat_read_states`, `chat_commands`, trusted-only `chat_rate_limits`, and short-lived owner-private `chat_time_probes`. New composite indexes and TTL field policies are declared in `firestore.indexes.json` and wired through `firebase.json`.

**Testing**: `flutter_test`, `bloc_test: ^10.0.0`, `mocktail: ^1.0.4`; Firestore Emulator rules tests; TypeScript/Mocha Functions tests; integrated Auth, Firestore, and Functions emulator tests. Firestore production-index and TTL behavior require a deployment smoke check because the emulator does not enforce all production index/TTL behavior.

**Target Platform**: Android, iOS, Web, and Windows from one Flutter codebase; Firebase Functions backend. Windows remains subject to FlutterFire's upstream beta/support limitations and uses the same Firestore command/snapshot path as every other target.

**Project Type**: Multi-platform Flutter application plus serverless backend functions

**Performance Goals**: Under the SC-002 network profile, at least 95% of accepted sends reach the sender and another open participant view within 3 seconds across 100 trials. At up to 100 participants and 5,000 unexpired messages, at least 95% of history opens show the newest page within 3 seconds. Newest history is bounded to 50 live documents; older pages are fetched on demand.

**Constraints**: Current outing participation and current crew membership are both required; attendance response does not affect access. Sending is limited to Draft, Planning, Confirmed, and Meeting. Messages are immutable plain text of 1-2,000 Unicode scalar values after Unicode-whitespace trimming. Offline send attempts are never queued and require manual retry. Each participant may create at most 30 accepted messages per outing in a rolling minute. Read state is private and no cross-user receipts are exposed. Messages become unavailable in supported clients exactly at `expiresAt = acceptedAt + 24 hours`, using a server-synchronized clock rather than device wall time; the first successful scheduled cleanup after expiry permanently deletes records, while TTL is a non-exact retry backstop. Command handlers and cleanup are idempotent. Rich media, editing, manual deletion, reactions, replies, typing/presence, live meetup, maps, and notifications are excluded.

**Scale/Scope**: Up to 100 outing participants, 5,000 concurrently unexpired messages per outing, live newest page of 50 messages, older pages of 50, one read-state record per participant per outing, at most 30 timestamps per participant/outing rate bucket, one transient time probe per active chat session, and multiple concurrent outing chats across crews

### Expiry Query Security Boundary

Firestore list queries are authorized against their potential result set. A client-generated trusted-clock cutoff cannot be assumed to equal Security Rules `request.time` while a query or listener is evaluated.

Direct message `get` operations MUST deny an expired document against `request.time`. List and aggregation Rules MUST enforce authentication, current crew membership, current outing participation, outing ownership, query bounds, and ordering, but MUST NOT claim to enforce a moving per-document expiry boundary through `request.time`. Supported clients MUST query from a server-synchronized cutoff and apply `ChatExpiryPolicy` at the exact local product boundary; scheduled cleanup closes the temporary raw-record window by permanently deleting expired records.

A blocking Firestore Emulator proof MUST establish the chosen `get`/`list` split, query constraints, clock drift behavior, long-lived listener behavior, and boundary expiration before repository implementation. If the proof shows that direct list queries cannot satisfy the approved retention and access model, direct client reads MUST be replaced by a trusted provider-neutral read boundary and this plan MUST be revised before implementation continues. Client-side filtering by itself is not treated as an authorization boundary for participant, crew, outing, or read-state privacy.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First and Clean Architecture)**: PASS. Chat production code is isolated under `lib/features/chat/{domain,data,presentation}`; only shared DI, routing, outing entry UI, Firebase configuration, rules, indexes, and trusted backend cleanup are changed outside the feature.
- **Principle II (Crew-First Interaction Model)**: PASS. Every chat read, send, and read-state change requires both current outing participation and current membership in the outing's crew. No direct messaging, friendship, or social feed is introduced.
- **Principle III (Decoupled Provider Interfaces)**: PASS. Presentation depends on `ChatRepository`; Firestore queries, commands, aggregation reads, and Functions processing remain behind data/backend boundaries.
- **Principle IV (Mandatory Automated Testing)**: PASS. Message/access/expiry policies, models, repository behavior, Cubits, widgets, Functions transactions/cleanup, and Firestore Security Rules all receive automated coverage.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. Every accepted message receives a trusted 24-hour expiration. Product visibility ends at the boundary, scheduled cleanup hard-deletes expired data, and Firestore TTL provides a retry backstop.
- **Architecture & Platform Constraints**: PASS. Security Rules protect every client-accessible collection; sensitive rate limiting and message acceptance execute in trusted Functions; the Firestore-only client path remains shared by Android, iOS, Web, and Windows.

## Project Structure

### Documentation (this feature)

```text
specs/005-outing-chat/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- chat_commands.md
|   |-- chat_repository.md
|   |-- cleanup.md
|   `-- firestore_rules.md
`-- tasks.md                 # Created later by /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/chat/
|-- data/
|   |-- datasources/
|   |   `-- firestore_chat_datasource.dart
|   |-- models/
|   |   |-- chat_command_model.dart
|   |   |-- chat_message_model.dart
|   |   `-- chat_read_state_model.dart
|   |-- services/
|   |   `-- firestore_chat_clock.dart
|   `-- repositories/
|       `-- chat_repository_impl.dart
|-- domain/
|   |-- entities/
|   |   |-- chat_command.dart
|   |   |-- chat_message.dart
|   |   |-- chat_message_cursor.dart
|   |   |-- chat_page.dart
|   |   `-- chat_read_state.dart
|   |-- repositories/
|   |   `-- chat_repository.dart
|   `-- services/
|       |-- chat_access_policy.dart
|       |-- chat_clock.dart
|       `-- chat_expiry_policy.dart
`-- presentation/
    |-- cubit/
    |   |-- outing_chat/
    |   |   `-- outing_chat_cubit.dart
    |   `-- chat_summary/
    |       `-- chat_summary_cubit.dart
    |-- screens/
    |   `-- outing_chat_screen.dart
    `-- widgets/
        |-- chat_composer.dart
        |-- chat_history_list.dart
        |-- chat_message_bubble.dart
        `-- chat_unread_badge.dart

functions/
|-- src/
|   |-- index.ts
|   |-- chat/
|   |   |-- command_handler.ts
|   |   |-- command_schema.ts
|   |   |-- chat_transactions.ts
|   |   `-- cleanup.ts
|   `-- outings/
|       `-- outing_deletion.ts          # Extend cascade for chat-owned data
|-- test/chat/
|   |-- chat_test_utils.ts
|   |-- command_schema.test.ts
|   |-- command_handler.test.ts
|   |-- chat_transactions.test.ts
|   |-- cleanup.test.ts
|   |-- outing_deletion.test.ts
|   `-- chat_integration.test.ts
`-- package.json

test/features/chat/
|-- chat_test_helpers.dart
|-- data/
|   |-- models/chat_models_test.dart
|   |-- services/firestore_chat_clock_test.dart
|   `-- repositories/chat_repository_impl_test.dart
|-- domain/
|   |-- chat_entities_test.dart
|   |-- chat_access_policy_test.dart
|   `-- chat_expiry_policy_test.dart
`-- presentation/
    |-- cubit/
    |   |-- outing_chat_cubit_test.dart
    |   `-- chat_summary_cubit_test.dart
    `-- screens/outing_chat_screen_test.dart

test/features/outings/presentation/widgets/interactive_outing_card_test.dart
test/core/routes/app_router_test.dart
test/core/di/injection_container_test.dart
firestore.rules
firestore.indexes.json
firestore_tests/rules.test.js
firebase.json
firebase.test.json
lib/core/di/injection_container.dart
lib/core/routes/app_router.dart
lib/features/outings/presentation/widgets/interactive_outing_card.dart
```

**Structure Decision**: Use the constitution's dedicated `chat` feature with domain entities/policies and a provider-neutral repository. Follow the repository's existing top-level Firestore schema and Phase 4 Firestore-command pattern rather than adding a second transport or nesting chat under outing documents. A trusted backend is necessary for rolling-window enforcement, authoritative acceptance time, idempotent creation, prompt cleanup, and coordinated outing deletion. The existing outing card is the shared entry surface for the chat route and unread badge.

## Complexity Tracking

No constitution violations require justification.

## Phase 0: Research

Research decisions and rejected alternatives are recorded in [research.md](./research.md). All product clarifications are resolved; T009 is an explicit implementation gate that must validate the selected Firestore expiry-query mechanics before repository work proceeds.

## Phase 1: Design & Contracts

Design outputs:

- [data-model.md](./data-model.md)
- [contracts/chat_commands.md](./contracts/chat_commands.md)
- [contracts/chat_repository.md](./contracts/chat_repository.md)
- [contracts/cleanup.md](./contracts/cleanup.md)
- [contracts/firestore_rules.md](./contracts/firestore_rules.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Principle I**: PASS. The data model and repository contract preserve the `chat` feature boundary; backend command and cleanup code remain under `functions/src/chat`, with only the existing outing-deletion service extended for cascading removal.
- **Principle II**: PASS. Contracts require current crew membership and deterministic outing participation for all chat access and revalidate both in trusted processing.
- **Principle III**: PASS. Presentation contracts contain domain messages, pages, cursors, commands, read state, and failures but no Firestore types.
- **Principle IV**: PASS. Quickstart and contracts require focused/full Flutter tests, Functions unit/integration tests, Security Rules emulator tests, and production index/TTL smoke validation.
- **Principle V**: PASS. Trusted `expiresAt`, exact domain/UI filtering, minutely scheduled hard deletion, TTL backstop, command-payload scrubbing, and outing cascade jointly prevent permanent chat retention.
- **Architecture & Platform Constraints**: PASS. Rules and trusted revalidation provide layered authorization; no unsupported callable dependency or platform-specific client path is introduced.
