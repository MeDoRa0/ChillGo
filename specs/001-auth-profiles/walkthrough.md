# Implementation Walkthrough: Phase 1 - Authentication & Profiles

## Scope

Phase 1 implements federated sign-in, profile onboarding, session persistence, sign out, profile editing, and avatar uploads using Firebase Auth, Cloud Firestore, Firebase Storage, and feature-first Flutter layers.

## Implemented User Stories

- US1: Google and Apple sign-in are routed through `AuthRepository` and `AuthBloc`; unauthenticated users are redirected to `/login`.
- US2: Onboarding creates immutable usernames and display names through `ProfileRepository` using Firestore-backed profile storage.
- US4: Firebase Auth status drives route refreshes, and Profile includes sign out through `AuthBloc`.
- US3: Profile management now displays username, display name, and avatar; display names can be edited, and avatars can be selected from camera or gallery, compressed client-side, uploaded to Storage, and saved on the user profile.

## Validation Coverage

- Repository tests cover profile repository delegation.
- Bloc/Cubit tests cover profile loading, display-name updates, invalid display-name handling, and avatar updates.
- Firebase rules tests cover Firestore profile ownership, username registry immutability, and Storage avatar read/write constraints.

## Manual Verification Notes

Use `specs/001-auth-profiles/quickstart.md` for emulator startup and end-to-end validation. The key manual checks are:

- New users reach onboarding after provider sign-in.
- Duplicate usernames are rejected.
- Returning users bypass login after restart.
- Profile screen updates display name immediately after save.
- Avatar selection uploads to `avatars/{uid}` and refreshes the profile image.
- Sign out returns the user to `/login`.
