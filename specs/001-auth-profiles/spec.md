# Feature Specification: Phase 1 — Authentication & Profiles

**Feature Branch**: `001-auth-profiles`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Phase 1 — Authentication & Profiles only from main_plan.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Federated Sign-In & Account Registration (Priority: P1)

As a new or returning user, I want to sign in securely using my Google or Apple account so that I don't have to manage another password.

**Why this priority**: It is the entrance to the application. Without authentication, users cannot access any features.

**Independent Test**: A user can launch the app, choose to authenticate with Google or Apple, complete the authentication, and either proceed to the profile creation screen (if new) or the dashboard (if returning).

**Acceptance Scenarios**:

1. **Given** a new user who is not logged in, **When** they tap "Sign in with Google" or "Sign in with Apple" and complete the provider authentication, **Then** they are redirected to the Username & Display Name creation screen.
2. **Given** an existing user who is not logged in, **When** they tap "Sign in with Google" or "Sign in with Apple" and complete the provider authentication, **Then** they are redirected directly to the home dashboard.
3. **Given** a user who initiates sign-in, **When** they cancel the provider sign-in flow, **Then** they remain on the landing screen with an appropriate message.

---

### User Story 2 - Profile Onboarding (Username & Display Name Creation) (Priority: P1)

As a newly authenticated user, I want to choose a unique username and display name so that my friends can invite me to crews and know who I am.

**Why this priority**: Crucial for user identification and core Crew-First interaction.

**Independent Test**: A user can input a username and display name, validate that the username is unique and conforms to formatting rules, and successfully complete onboarding to enter the app.

**Acceptance Scenarios**:

1. **Given** a new user on the onboarding screen, **When** they enter a valid, unique username and a display name and confirm, **Then** their profile is created and they enter the app dashboard.
2. **Given** a new user on the onboarding screen, **When** they enter a username that is already taken by another user (case-insensitive), **Then** they see a clear error indicating the username is unavailable and cannot proceed.
3. **Given** a new user on the onboarding screen, **When** they enter a username containing spaces or invalid characters, **Then** they see a validation error and cannot proceed.

---

### User Story 3 - Profile Management & Avatar Upload (Priority: P2)

As an onboarded user, I want to view my profile details, edit my display name, and upload a custom avatar image so that I can personalize my appearance within the application.

**Why this priority**: Allows personalization, but is secondary to authentication and profile onboarding.

**Independent Test**: A user can navigate to the profile screen, edit their display name, upload an avatar, and see the updated information reflected immediately.

**Acceptance Scenarios**:

1. **Given** an onboarded user on the profile screen, **When** they update their display name and save, **Then** the display name is updated and visible.
2. **Given** an onboarded user on the profile screen, **When** they select and upload a valid image file as an avatar, **Then** the avatar is uploaded, saved, and displayed on their profile.
3. **Given** an onboarded user on the profile screen, **When** they attempt to change their username, **Then** they find that the username field is read-only and cannot be changed.

---

### User Story 4 - Session Persistence & Sign Out (Priority: P1)

As a user, I want my login session to persist when I close the application, and I want a clear option to sign out when I want to secure my account.

**Why this priority**: Fundamental usability and security.

**Independent Test**: A user closes and reopens the app to verify they remain logged in, and can tap sign out to return to the landing screen.

**Acceptance Scenarios**:

1. **Given** a logged-in user, **When** they close and reopen the application, **Then** they bypass the login screen and land directly on the home dashboard.
2. **Given** a logged-in user on the profile or settings screen, **When** they tap the "Sign Out" button, **Then** their session is terminated, and they are redirected back to the login landing screen.

### Edge Cases

- **Network Interruption**: If the internet connection is lost during authentication or profile creation, the system shows a friendly network error message and allows the user to retry once the connection is restored.
- **Interrupted Onboarding**: If the app is closed or crashes after third-party authentication but before username and display name creation, the system detects this incomplete state on the next launch and redirects the user back to the onboarding screen.
- **Concurrent Username Selection**: If two users attempt to claim the exact same username at the same time, the system enforces a strict uniqueness constraint at the data layer, allowing only one to succeed and prompting the other to choose a different username.
- **Large/Invalid Avatar File**: If a user uploads an extremely large image or unsupported file format as an avatar, the system validates the file, rejects it with a user-friendly error message, or compresses it client-side before saving.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support federated authentication via third-party identity providers (Google and Apple).
- **FR-002**: System MUST persist the user's authentication session across application restarts.
- **FR-003**: System MUST require new users to create a unique username and a display name before accessing any other features.
- **FR-004**: System MUST enforce that usernames are unique (case-insensitive), do not contain spaces, and only contain alphanumeric characters or underscores.
- **FR-005**: System MUST allow users to view their profile details (username, display name, avatar, account creation date).
- **FR-006**: System MUST allow users to edit their display name.
- **FR-007**: System MUST NOT allow users to change their username once it has been created (usernames are immutable).
- **FR-008**: System MUST support uploading a custom profile picture/avatar.
- **FR-009**: System MUST allow users to sign out, clearing the local authentication session.

### Key Entities *(include if feature involves data)*

- **User Profile**: Represents the user's application identity. Key attributes:
  - `ID`: Unique identifier generated by the authentication provider.
  - `Username`: Unique, alphanumeric (plus underscores), case-insensitive, immutable, no spaces.
  - `Display Name`: User-friendly display name, mutable.
  - `Avatar URL`: Reference to the user's profile image.
  - `Created Date`: Timestamp of when the user account was first created.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: New users can complete the sign-in and profile onboarding flow (from landing page to dashboard) in under 90 seconds.
- **SC-002**: Returning authenticated users bypass the login screen and load the dashboard in under 1.5 seconds under normal network conditions.
- **SC-003**: Duplicate username registrations are prevented in 100% of cases.
- **SC-004**: 99.9% of authentication attempts complete successfully or fail with a clear, user-friendly error message.

## Assumptions

- Users have access to a Google or Apple account to sign in.
- The target platforms have a local secure storage mechanism to store session tokens.
- Avatar image files will be stored in a cloud storage service and referenced via URLs.
- The design system will define consistent buttons and inputs for login and profile onboarding.
