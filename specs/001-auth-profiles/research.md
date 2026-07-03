# Research Notes: Phase 1 - Authentication & Profiles

This document summarizes the technical decisions, rationale, and alternatives evaluated for the ChillGo authentication and profile system.

## Decisions

### 1. Authentication Integration Strategy
- **Decision**: Use official FlutterFire plugins `firebase_auth`, `google_sign_in`, and `sign_in_with_apple`. All Firebase interactions are abstracted behind the `AuthRepository` interface in the domain layer.
- **Rationale**: Keeps client code secure, official plugins have solid multi-platform support, and Apple/Google sign-in SDKs are directly supported by FlutterFire.
- **Alternatives Considered**: Hand-rolling custom OAuth2 redirects (rejected as insecure, complex, and prone to breaking changes on the OAuth provider side).

### 2. Session Persistence
- **Decision**: Rely on Firebase Auth's native token and session persistence.
- **Rationale**: Firebase Auth maintains user credentials in local keychain/keystore on mobile, IndexedDB on Web, and local persistence on desktop, and handles token refresh under the hood.
- **Alternatives Considered**: Storing session tokens manually via `flutter_secure_storage` (rejected as redundant logic that duplicates Firebase Auth functionality).

### 3. Username Uniqueness Strategy
- **Decision**: Implement a double-write index approach in Cloud Firestore:
  1. Main profile stored in collection `users` keyed by Firebase UID (`users/{uid}`).
  2. Username reservation document stored in collection `usernames` keyed by lowercase username (`usernames/{username_lowercase}`).
  3. During onboarding, a Firestore transaction verifies if `usernames/{username_lowercase}` exists. If it does not, it writes the reservation document containing `uid` and creates the `users/{uid}` profile.
- **Rationale**: Provides atomic, race-condition-free uniqueness checking natively within Firestore without needing Cloud Functions.
- **Alternatives Considered**: Cloud Functions validation (rejected for MVP due to higher latency and execution cost, though it remains viable if security requirements tighten).

### 4. Custom Profile Avatar Upload and Optimization
- **Decision**: Accept JPEG, PNG, and WebP source images up to 5 MB before compression. Compress images client-side using `image_picker` sizing options and the `image` library to target uploads under 500 KB, then upload to Firebase Storage under `avatars/{uid}` with the correct image MIME type.
- **Rationale**: The 5 MB pre-compression limit matches the product requirement while still keeping stored avatars small for bandwidth, Firebase Storage cost, and profile loading latency.
- **Alternatives Considered**: Uploading raw files (rejected as mobile photos can be 5-10 MB, which would degrade performance and rapidly deplete free storage tiers); accepting every `image/*` MIME type (rejected because the spec only allows JPEG, PNG, and WebP).

### 5. Authenticated Profile Lookup
- **Decision**: Expose lookup by normalized username to authenticated users, returning only username, display name, and avatar URL for invitation flows.
- **Rationale**: This supports Crew invitation by username while preserving the constitution's restriction that ChillGo does not expose social graph or feed-style profile data.
- **Alternatives Considered**: Restricting lookups to existing crew members (rejected because invitations require finding users before membership exists); exposing email or provider metadata (rejected because it is unnecessary for invites and exceeds the public profile data allowed by the spec).
