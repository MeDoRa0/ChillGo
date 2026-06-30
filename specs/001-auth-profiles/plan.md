# Implementation Plan: Phase 1 — Authentication & Profiles

**Branch**: `001-auth-profiles` | **Date**: 2026-06-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from [spec.md](./spec.md)

## Summary

Implement federated authentication (Google & Apple Sign-In) and profile management (username/display name onboarding, avatar upload, and session persistence) in a multi-platform Flutter client using Firebase Authentication, Cloud Firestore, and Firebase Storage. The implementation will follow Feature-First Clean Architecture and wrap Firebase services behind abstract repository interfaces in the domain layer for testability.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`, `sign_in_with_apple`, `flutter_bloc`, `image_picker`, `image`

**Storage**: Cloud Firestore (user profiles and username registry), Firebase Storage (profile avatars), local cache (Firebase native persistence)

**Testing**: `flutter_test` (unit and widget tests), `bloc_test` (Cubit/Bloc state tests), Firestore Local Emulator (security rules validation)

**Target Platform**: Android, iOS, Web, Windows

**Project Type**: Mobile, Desktop, and Web Client App

**Performance Goals**: Onboarding complete in <90 seconds; returning user dashboard loading in <1.5 seconds; fluid UI rendering at 60/120 fps

**Constraints**: Usernames must be case-insensitive unique, immutable, and contain no spaces. Authentication must be decoupled from Firebase SDK direct calls in UI components.

**Scale/Scope**: MVP client application with initial user registration and profile management.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Gate I: Feature-First & Clean Architecture**: **PASS**. All files will be placed under features `authentication` and `profile`, split into `domain`, `data`, and `presentation` layers.
- **Gate II: Crew-First Interaction Model**: **PASS**. Profile data model contains only `id`, `username`, `displayName`, `avatarUrl`, and `createdAt` as defined by the constitution.
- **Gate III: Decoupled Provider Interfaces**: **PASS**. Abstract repository contracts (`AuthRepository`, `ProfileRepository`) will be defined in the domain layers. UI and presenters will consume repositories via dependency injection.
- **Gate IV: Mandatory Automated Testing**: **PASS**. We will verify repositories with unit tests, Blocs/Cubits with `bloc_test`, and Firestore rules with the emulator.

## Project Structure

### Documentation (this feature)

```text
specs/001-auth-profiles/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── contracts/           # Phase 1 output
    ├── auth_repository.dart
    └── profile_repository.dart
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── routes/
│   │   └── app_router.dart
│   └── theme/
└── features/
    ├── authentication/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── firebase_auth_datasource.dart
    │   │   ├── models/
    │   │   │   └── user_profile_model.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user_profile.dart
    │   │   └── repositories/
    │   │       └── auth_repository.dart
    │   └── presentation/
    │       ├── blocs/
    │       │   └── auth/
    │       │       ├── auth_bloc.dart
    │       │       ├── auth_event.dart
    │       │       └── auth_state.dart
    │       └── screens/
    │           └── login_screen.dart
    └── profile/
        ├── data/
        │   ├── datasources/
        │   │   └── firestore_profile_datasource.dart
        │   └── repositories/
        │       └── profile_repository_impl.dart
        ├── domain/
        │   ├── repositories/
        │   │   └── profile_repository.dart
        │   └── usecases/
        │       ├── create_profile.dart
        │       ├── get_profile.dart
        │       ├── update_profile.dart
        │       └── upload_avatar.dart
        └── presentation/
            ├── blocs/
            │   └── profile/
            └── screens/
                ├── onboarding_screen.dart
                └── profile_screen.dart
```

**Structure Decision**: Real paths will align to `lib/features/authentication` and `lib/features/profile` as shown in the tree above.

## Complexity Tracking

*No constitution check violations were detected, so no complexity tracking is needed.*
