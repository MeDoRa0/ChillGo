# Research: Architecture & Multi-Platform Setup

This document consolidates research and design decisions for establishing the foundational architecture and multi-platform configuration of ChillGo.

## 1. State Management

- **Decision**: `flutter_bloc` and `bloc_test` (for testing).
- **Rationale**: 
  - Directly mandated by the **ChillGo Constitution (Principle I & IV)**.
  - Enforces a clear separation between presentation and business logic.
  - Highly predictable, making it easy to test and trace state changes.
- **Alternatives considered**: 
  - `provider`: Rejected as it is less structured than BLoC/Cubit for larger applications.
  - `riverpod`: Rejected because BLoC is already ratified in the project constitution.

## 2. Routing Engine

- **Decision**: `go_router` (latest compatible version).
- **Rationale**: 
  - Declarative routing matching modern Flutter paradigms.
  - Excellent support for deep-linking (needed for crew invites/outings) and nested navigation (ShellRoute/StatefulShellRoute) for tabbed navigation.
  - Developed and maintained by the Flutter team.
- **Alternatives considered**: 
  - `auto_route`: Rejected due to code generation overhead (`build_runner`).
  - `Navigator 2.0 (manual)`: Rejected because of high complexity and boilerplate code.

## 3. Dependency Injection (DI)

- **Decision**: `get_it` (service locator).
- **Rationale**: 
  - Extremely lightweight and fast (O(1) lookup).
  - Simple setup to manage singletons and factory instances for repository interfaces.
  - Helps conform to **Principle III (Decoupled Provider Interfaces)** by resolving abstract interfaces to their concrete implementations.
- **Alternatives considered**: 
  - `injectable`: Rejected as it requires code generation, which slows down the build loop.
  - Manual Constructor Injection: Rejected because it becomes unwieldy to pass dependencies through deep widget trees.

## 4. Firebase SDK Additions

- **Decision**: Add `firebase_messaging`, `firebase_crashlytics`, and `firebase_analytics`.
- **Rationale**:
  - Mandated by **FR-005** (initialize FCM, Analytics, and Crashlytics) and **SC-002** (100% uncaught runtime exceptions logged to Crashlytics).
- **Alternatives considered**: None, as Firebase is the mandated backend infrastructure.

## 5. Responsive Layout Architecture

- **Decision**: Custom `ResponsiveLayout` widget using `LayoutBuilder` and defined breakpoints (Mobile < 600dp, Tablet >= 600dp and < 1024dp, Desktop >= 1024dp).
- **Rationale**:
  - Flutter's native `LayoutBuilder` and `MediaQuery` are highly performant and flexible.
  - Avoids bloating the project with external layout dependencies.
  - Enforces adaptive design where widgets adjust their layouts specifically per screen size, rather than scaling pixels.
- **Alternatives considered**: 
  - `responsive_framework`: Rejected because auto-scaling can make UI layouts look blurry/stretched on larger screens, whereas we want native adaptive layouts.

## 6. Environment Configurations

- **Decision**:
  - **Flutter version**: Stable 3.44.2 (Framework), Dart SDK 3.12.2.
  - **Firestore Emulator**: Setup Firestore local emulator for security rules validation before deployment.
