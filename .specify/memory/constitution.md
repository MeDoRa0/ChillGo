<!--
Sync Impact Report:
- Version change: 1.2.0 → 1.3.0
- List of modified principles: None
- Added sections:
  - Repo-Relative Links (under Development Workflow & Quality Gates)
- Removed sections: None
- Templates requiring updates: None
- Follow-up TODOs: None
-->

# ChillGo Constitution

## Core Principles

### I. Feature-First and Clean Architecture
The codebase MUST be organized by feature folders (e.g., authentication, profile, crews, outings, voting, chat, live_meetup, notifications) rather than by technical layers at the root. Within each feature, code MUST be structured into three distinct layers: `domain` (containing platform-agnostic business logic, entity models, and repository interfaces), `data` (containing specific API/database implementations, DTO models, and data sources), and `presentation` (containing UI components, widgets, and state management via Cubits/Blocs).
**Rationale**: This separation enforces decoupling, making the business logic easy to test and adapt, while enabling multiple developers to work on separate features in parallel without file conflicts.

### II. Crew-First Interaction Model
Relationships and interactions between users MUST only occur within the context of a `Crew`. Direct friendships, friend lists, followers, and social feeds are strictly prohibited. To invite members to a Crew, users MUST invite them by username. User profile data is restricted to Firebase UID, unique username, display name, avatar, and created date.
**Rationale**: ChillGo is a structured coordination tool, not a social network. Restricting interactions to Crews simplifies user management, improves privacy, and aligns with the core philosophy.

### III. Decoupled Provider Interfaces (Interface-First)
Infrastructure services—specifically maps, authentication providers, and database clients—MUST be accessed via abstract repository or service interfaces defined in the domain layer. For example, map providers (Google Maps initially) MUST be wrapped under a generic map service interface.
**Rationale**: This decoupling enables simple unit testing with mock services and facilitates transitioning to other providers or supporting different platforms (Android, iOS, Web, Windows) without modifying core business logic.

### IV. Mandatory Automated Testing
All core business logic (domain models, use cases), state management logic (Cubits/Blocs), and database constraints (Firestore Security Rules) MUST have automated test suites. Specifically:
- Domain layer functions and repository implementations MUST be verified with unit tests.
- Blocs and Cubits MUST be verified with bloc-test.
- Firestore Security Rules MUST be validated using the Firestore local emulator before deployment.
**Rationale**: Rigorous testing prevents regressions across multiple platforms (mobile, desktop, and web) and ensures secure database access control.

### V. Temporary Data Lifecycle Rules
Database records for ephemeral data MUST be cleaned up automatically.
- Chat messages MUST be automatically deleted or archived after 24 hours.
- Live location data and active presence data MUST be deleted immediately upon outing completion.
**Rationale**: Auto-cleanup minimizes Firestore storage costs, reduces database read load during active coordination, and preserves user location privacy after outings.

## Architecture & Platform Constraints

- **Technology Stack**: The project is built using Flutter for the frontend, flutter_bloc/Cubit for state management, and Firebase services (Auth, Firestore, Cloud Functions, FCM, Storage, Analytics, Crashlytics) for the backend.
- **Multi-Platform Support**: Codebase must maintain single-source compatibility for Android, iOS, Web, and Windows. No platform-specific UI hacks unless abstracted behind a platform-agnostic interface.
- **Firestore Schema & Security**: All access to Firestore must be protected by security rules validated via Firestore Emulator. Direct client write operations must be minimized, utilizing Cloud Functions for sensitive operations or permission validation where appropriate.

## Development Workflow & Quality Gates

- **Phase-Based Execution**: Development must follow the Spec-Kit Phase sequence (Phase 0 to Phase 8).
- **Branch Strategy**: A dedicated Git branch MUST be created for each feature specification at the time the specification is created. Development work for a given phase must only be performed on its corresponding branch.
- **Dependency Order**: Implement model/data DTOs and repository contracts before Bloc/Cubit presenters, and presenters before UI views.
- **Code Quality**: Adhere to strict linting rules and verify all tests pass on all target platforms (web, mobile, desktop) before code is merged.
- **End-to-End (E-2-E) Testing**: Any task that requires an E-2-E test MUST first prompt the user for permission or confirmation to perform the task or not, as the AI agent cannot perform manual E-2-E tests.
- **Repo-Relative Links**: All links to local files in specifications, plans, checklists, and documentation files MUST use repo-relative paths (e.g., `[spec.md](./spec.md)`) instead of absolute local file URIs (e.g., `file:///c:/...`). Absolute local URIs leak personal machine structure and fail to resolve for other contributors or in CI.

## Governance

- **Supremacy**: This constitution is the single source of truth. All feature specifications (`spec.md`), plans (`plan.md`), and checklists (`checklist.md`) must conform to these principles.
- **Amendments**: Amendments require a version bump following semantic versioning (MAJOR for breaking changes/removals, MINOR for additions, PATCH for clarifications) and a migration plan for existing code.
- **Compliance Check**: Before any implementation phase starts, a "Constitution Check" must be run and documented in `plan.md`.

**Version**: 1.3.0 | **Ratified**: 2026-06-28 | **Last Amended**: 2026-06-30
