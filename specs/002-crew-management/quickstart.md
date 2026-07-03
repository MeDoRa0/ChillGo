# Quickstart & Validation Guide: Crew Management

This guide outlines runnable scenarios to validate Phase 2: Crew Management end-to-end, utilizing the local Firestore Emulator and automated unit/integration tests.

## Prerequisites

Before starting, ensure the Firebase Emulator Suite is installed and configured:
1. Java Development Kit (JDK) installed (required by Firebase Emulator).
2. Start the local Firebase emulator suite from the project root:
   ```bash
   firebase emulators:start --only firestore
   ```

---

## 1. Automated Test Executions

### Running Domain & Presentation Tests
To verify the business logic, Cubits/Blocs, and mock repository implementations:
```bash
flutter test test/features/crews/
```
*Expected Outcome*: All unit and bloc tests pass.

### Running Firestore Security Rules Tests
To verify that database read/write access constraints are correctly enforced by security rules:
```bash
npm run test:firestore
# OR, if running custom mocha/jest test script in firestore_tests directory:
cd firestore_tests && npm test
```
*Expected Outcome*: All test cases verify that:
- Non-members cannot read crews.
- Non-owners cannot update or delete crews.
- Non-owners cannot invite or remove members.
- Members can leave, but owners cannot leave.
- Duplicate memberships/invitations are rejected.

---

## 2. Manual E-2-E Verification Scenario

Below is the step-by-step walkthrough to manually verify the feature in a local debug build:

### Setup Profiles
1. Launch the app in two separate emulator instances (or one mobile emulator and one desktop/web window).
2. Create Account 1:
   - Username: `alice_cool`
   - Display Name: `Alice`
3. Create Account 2:
   - Username: `bob_chill`
   - Display Name: `Bob`

### Scenario A: Crew Creation & Membership List
1. **On Alice's app**:
   - Go to the **Crews** screen.
   - Tap **Create Crew**.
   - Input `"Weekend Hikers"` and submit.
2. **Verification**:
   - Alice is redirected to the Crew Details screen.
   - The Crew Name is displayed as `"Weekend Hikers"`.
   - The Member List displays exactly 1 member: `Alice (Owner)`.

### Scenario B: Inviting a User
1. **On Alice's app**:
   - In Crew Details, find the "Invite Member" section.
   - Enter Bob's username: `bob_chill`.
   - Tap **Invite**.
2. **Verification**:
   - Bob's name appears immediately under the "Pending Invitations" section in Alice's UI.
   - Enter a non-existent username (e.g., `nobody_here`) -> verify UI displays "Username not found".
   - Enter `bob_chill` again -> verify UI displays "User already has a pending invitation".

### Scenario C: Accepting/Rejecting Invitation
1. **On Bob's app**:
   - Navigate to the **Invitations** dashboard.
   - Verify there is a pending invitation to join `"Weekend Hikers"` from `Alice`.
2. **Accept Flow**:
   - Tap **Accept**.
   - Bob is added to `"Weekend Hikers"` and redirected to the Crew list showing it.
   - Navigate to Crew Details -> verify Member List now shows:
     - `Alice (Owner)`
     - `Bob (Member)`
   - On Alice's app, Bob moves from "Pending Invitations" to "Members" list in real-time.
3. **Leave Flow**:
   - Bob taps **Leave Crew**.
   - Bob is redirected to dashboard, and `"Weekend Hikers"` is removed from Bob's crews.
   - On Alice's app, Bob is removed from the member list.
