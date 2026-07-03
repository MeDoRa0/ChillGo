# Implementation Plan: Crew Management

**Branch**: `phase-2-crew-management` | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from [spec.md](./spec.md)

## Summary

This feature implements Crew Management (Phase 2), enabling users to create and manage Crews, send/revoke invitations by username, list members with their roles (owner vs. member), and accept or reject pending invitations. We utilize Cloud Firestore as the primary real-time database, structuring crews, memberships, and invitations in separate top-level collections with predictable document IDs to optimize security rules and prevent duplicate states.

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter SDK

**Primary Dependencies**: `cloud_firestore: ^5.0.0`, `firebase_auth: ^5.0.0`, `flutter_bloc: ^8.1.3`, `go_router: ^14.0.1`, `get_it: ^7.6.0`

**Storage**: Cloud Firestore

**Testing**: `flutter_test`, `bloc_test: ^9.1.5`, `mocktail: ^1.0.4`

**Target Platform**: Multi-platform (Android, iOS, Web, Windows)

**Project Type**: mobile-app / multi-platform app

**Performance Goals**: Real-time membership updates, instant response to actions (< 1s local, < 3s over network).

**Constraints**: Strict data lifecycle rules (deleting invitations upon accept/reject) and robust security rules (O(1) checks via predictable IDs).

**Scale/Scope**: Up to 100 members per crew.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First & Clean Architecture)**: PASS. All new files will reside under `lib/features/crews` structure, divided into `domain`, `data`, and `presentation`.
- **Principle II (Crew-First Interaction Model)**: PASS. All interactions are centered on crews. Inviting is done by username lookup via `usernames` collection. User profile attributes restricted to basic profile info.
- **Principle III (Decoupled Provider Interfaces)**: PASS. UI and Cubits interact with `CrewRepository` abstract class. Firestore implementation is kept separate under `data`.
- **Principle IV (Mandatory Automated Testing)**: PASS. Unit tests for `CrewRepositoryImpl` and bloc-tests for `CrewsListCubit`/`CrewDetailCubit`/`InvitationsCubit` will be created. Firestore rules will be tested locally.
- **Principle V (Temporary Data Lifecycle Rules)**: PASS. Invitation documents are deleted immediately upon acceptance or rejection.

## Project Structure

### Documentation (this feature)

```text
specs/002-crew-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── quickstart.md        # Phase 1 output
```

### Source Code (repository root)

```text
lib/features/crews/
├── data/
│   ├── datasources/
│   │   └── firestore_crews_datasource.dart
│   └── repositories/
│       └── crew_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── crew.dart
│   │   ├── crew_membership.dart
│   │   └── crew_invitation.dart
│   └── repositories/
│       └── crew_repository.dart
└── presentation/
    ├── blocs/
    │   ├── crew_detail/
    │   │   └── crew_detail_cubit.dart
    │   ├── crews_list/
    │   │   └── crews_list_cubit.dart
    │   └── invitations/
    │       └── invitations_cubit.dart
    ├── screens/
    │   ├── crews_list_screen.dart
    │   ├── crew_details_screen.dart
    │   └── invitations_screen.dart
    └── widgets/
        ├── crew_member_list_item.dart
        └── invite_member_dialog.dart
```

**Structure Decision**: Single project layout matching ChillGo's feature-first structure under `lib/features/crews/`.

## Complexity Tracking

*No violations identified. Fully compliant with Constitution.*
