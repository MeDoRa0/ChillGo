# Research Notes: Phase 1 — Authentication & Profiles

This document summarizes the technical decisions, rationale, and alternatives evaluated for the ChillGo authentication and profile system.

## Decisions

### 1. Authentication Integration Strategy
- **Decision**: Use official FlutterFire plugins `firebase_auth`, `google_sign_in`, and `sign_in_with_apple`. All Firebase interactions are abstracted behind the `AuthRepository` interface in the domain layer.
- **Rationale**: Keeps client code secure, official plugins have solid multi-platform support, and apple/google sign-in SDKs are directly supported by FlutterFire.
- **Alternatives Considered**: Hand-rolling custom OAuth2 redirects (rejected as it is insecure, complex, and prone to breaking changes on OAuth provider side).

### 2. Session Persistence
- **Decision**: Rely entirely on Firebase Auth's native token and session persistence.
- **Rationale**: Firebase Auth maintains user credentials in local keychain/keystore on mobile, indexedDB on Web, and secure files on Windows, and handles token refresh under the hood seamlessly.
- **Alternatives Considered**: Storing session tokens manually via `flutter_secure_storage` (rejected as it adds redundant logic, increases maintenance, and duplicates Firebase Auth functionality).

### 3. Username Uniqueness Strategy
- **Decision**: Implement a double-write index approach in Cloud Firestore:
  1. Main profile stored in collection `users` keyed by User UID (`users/{uid}`).
  2. Username reservation document stored in a unique collection `usernames` keyed by lowercase username (`usernames/{username_lowercase}`).
  3. During onboarding, a Firestore Transaction verifies if `usernames/{username_lowercase}` exists. If it does not, it writes the document in `usernames` (containing `uid`) and creates the `users/{uid}` profile.
- **Rationale**: Provides atomic, race-condition-free uniqueness checking natively within Firestore without needing Cloud Functions.
- **Alternatives Considered**: Cloud Functions validation (rejected for MVP due to higher latency and execution cost, though it remains a viable backup if security requirements tighten).

### 4. Custom Profile Avatar Upload and Optimization
- **Decision**: Compress images client-side using `image_picker` (setting `maxWidth` and `maxHeight` properties) and `image` library to compress size to under 500 KB, then upload to Firebase Storage under `avatars/{uid}`.
- **Rationale**: Saves user bandwidth, minimizes Firebase Storage costs, and reduces loading latency when retrieving profile pictures.
- **Alternatives Considered**: Uploading raw files (rejected as mobile photos can be 5–10MB, which would degrade performance and rapidly deplete free storage tiers).
