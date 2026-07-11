# Quickstart & Validation Guide: Outing Management

This guide outlines runnable validation scenarios for Phase 3: Outing Management.

## Prerequisites

1. Phase 1 Authentication & Profiles is available.
2. Phase 2 Crew Management is available.
3. Firebase Emulator Suite is installed.
4. From the project root, start the local emulator suite when running manual validation:

```bash
firebase emulators:start --only auth,firestore,storage
```

## Automated Test Executions

### Run Outings Feature Tests

```bash
flutter test test/features/outings/
```

**Expected Outcome**: Domain policy, repository, Cubit, widget, and screen tests for outings pass.

### Run All Flutter Tests

```bash
flutter test
```

**Expected Outcome**: Existing authentication, profile, crew, and outing tests pass together.

### Run Firestore Security Rules Tests

```bash
cd firestore_tests
npm test
```

**Expected Outcome**: Firestore rules enforce the contract in [contracts/firestore_rules.md](./contracts/firestore_rules.md).

## Manual Validation Scenarios

Manual end-to-end validation requires user confirmation before execution because it involves interactive app flows.

### Setup

1. Create or use a crew named `Weekend Hikers`.
2. Ensure the crew has at least two members:
   - Alice: crew owner
   - Bob: crew member

### Scenario A: Create Outing

1. Sign in as Bob.
2. Open `Weekend Hikers`.
3. Create an outing:
   - Title: `Friday Cafe`
   - Date/time: a future date and time
   - Location: `City Center Cafe`
   - Description: optional
4. Verify the outing appears in the crew outings list.
5. Open the outing details.

**Expected Outcome**:

- The outing is visible to crew members.
- Bob appears as the first participant.
- Location is displayed as free text.
- Status starts as `draft`.

### Scenario B: Edit and Participant Management

1. Sign in as Bob, the outing creator.
2. Edit the outing title, date/time, description, and free-text location.
3. Add Alice as a participant.
4. Try adding Alice again.

**Expected Outcome**:

- Updated details appear in the outing detail view.
- Alice appears once in the roster.
- Duplicate participant attempts show a clear error or no-op result.

### Scenario C: Crew Owner Management

1. Sign in as Alice, the crew owner.
2. Open Bob's outing.
3. Add or remove a participant.
4. Change lifecycle status using an allowed transition.

**Expected Outcome**:

- Crew owner can manage the outing.
- Invalid lifecycle transitions are blocked.
- Crew members see the updated status.

### Scenario D: Access Control

1. Sign in as a user who is not a member of `Weekend Hikers`.
2. Attempt to open the outing directly or through any available deep link/navigation path.

**Expected Outcome**:

- Private outing details are not shown.
- The user receives a clear access-denied message or is redirected away from the outing.

### Scenario E: Cancellation and History

1. Sign in as the outing creator or crew owner.
2. Cancel an active outing with reason `Bad weather`.
3. Reopen the crew outings list and outing details.
4. Attempt to edit planning details.

**Expected Outcome**:

- The outing remains visible as history.
- Cancellation reason is displayed.
- Planning edits are blocked after cancellation.
