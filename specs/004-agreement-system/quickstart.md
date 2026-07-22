# Quickstart & Validation Guide: Agreement System

This guide validates Phase 4 design outcomes. It references [data-model.md](./data-model.md) and the contracts under [contracts/](./contracts/).

## Prerequisites

1. Phase 2 Crew Management and Phase 3 Outing Management are implemented.
2. Flutter and project dependencies are installed.
3. Firebase CLI and Node.js 22 are available.
4. Functions dependencies are installed after the implementation creates `functions/package.json`.

## Automated Validation

### Flutter Agreement Tests

```bash
flutter test test/features/voting/ test/features/outings/domain/outing_participant_entity_test.dart test/features/outings/domain/outing_lifecycle_policy_test.dart
```

**Expected**: Attendance, eligibility, sealed visibility, repository mapping, Cubit, and screen tests pass.

### Functions Tests

```bash
npm --prefix functions test
```

**Expected**: Command schemas, idempotent claims, proposal deduplication, eligibility filtering, sealed preview, tie validation, confirmation, cancellation, and reopening tests pass.

### Firestore Security Rules Tests

```bash
npm --prefix firestore_tests test
```

**Expected**: The access matrix in [contracts/firestore_rules.md](./contracts/firestore_rules.md) passes, including owner-only vote reads and denied vote listing.

### All Flutter Tests

```bash
flutter test
```

**Expected**: Existing authentication, profile, crew, and outing behavior remains green with the new agreement feature.

### Analyze

```bash
dart analyze
```

**Expected**: No analyzer errors or warnings in production or test Dart code.

## Integrated Emulator Validation

Configure `firebase.json` to include the Functions emulator, then run the automated integration harness through:

```bash
firebase emulators:exec --only auth,firestore,functions "npm --prefix functions run test:integration"
```

**Expected**: Firestore command creation triggers the Functions processor, terminal command state is observable, duplicate delivery is harmless, and all resulting documents remain consistent.

## Manual Validation Scenarios

Manual end-to-end validation requires user confirmation before execution because it involves interactive application flows.

### Setup

- Crew `Weekend Hikers`
- Alice: crew owner and outing participant
- Bob: outing creator, automatically Accepted
- Carol: invited outing participant
- An outing in Draft with a future time and free-text location

### Scenario A: Attendance

1. Carol accepts, changes to Declined, then changes back to Accepted before Meeting.
2. Verify the roster remains stable and summary counts change once per response.
3. Enter Meeting and verify further response changes are blocked.

### Scenario B: Proposals and Sealed Voting

1. Open planning as Bob.
2. Verify direct edits to the outing time and location are now blocked.
3. Bob and Carol submit time and location proposals, including equivalent duplicates.
4. Cast and change both votes.
5. Verify each participant sees only their own selections; no totals, leaders, ties, or other selections appear.
6. Verify submitted proposals cannot be edited or withdrawn.

### Scenario C: Confirmation and Tie Resolution

1. Create tied votes in one category and a unique leader in the other.
2. Begin confirmation as Bob or Alice.
3. Verify only tied proposal choices are revealed, without counts or voter identities.
4. Select a tied leader and confirm.
5. Verify the outing becomes Confirmed, final time/location update, aggregate results appear, and ballots remain private.

### Scenario D: Concurrency and Eligibility

1. Change a vote while the organizer attempts confirmation.
2. Remove or decline a participant before confirmation.
3. Verify confirmation either retries against current state or returns `confirmation_state_changed`; ineligible votes do not count and no partial result exists.

### Scenario E: Reopen Agreement

1. Reopen a Confirmed outing with a reason.
2. Verify the prior round becomes immutable history.
3. Verify a new Planning round is seeded with current details and has zero votes.
4. Verify reopening is blocked in Meeting or later states.

### Scenario F: Cross-Platform Command Path

1. Execute attendance, proposal, vote, and confirmation flows on Android, iOS, Web, and Windows builds.
2. Verify all clients use Firestore commands and observe the same pending/success/failure semantics.

### Scenario G: Creator Removal at Any Time

1. As Bob, remove creator-owned outings representing Draft, Planning, Confirmed, Meeting, Completed, Archived, and Cancelled states.
2. For outings with agreement activity, verify participant records, rounds, proposals, votes, results, and pending work are no longer accessible after removal.
3. Verify Alice cannot permanently remove Bob's outing even though Alice owns the crew.
4. Repeat a removal request and overlap removal with another pending agreement action; verify removal remains successful and no outing data is recreated.

## Deployment Gate

- Functions deployment requires a Firebase project plan that supports Cloud Functions.
- Run Flutter, Functions, Rules, and integrated emulator suites before deployment.
- Do not deploy Security Rules that require migrated attendance fields until the participant backfill has completed and been verified.

## Validation Record — 2026-07-12

Automated validation was executed on Windows in the local development environment:

- Flutter agreement tests: PASS (38 tests).
- Full Flutter suite: PASS (153 tests).
- Dart analyzer: PASS with no remaining issues.
- Functions unit suite: PASS (5 tests); 2 emulator-only cases are skipped by the unit command.
- Firestore and Storage Security Rules suite: PASS after running through `firebase emulators:exec`.
- Schema migration suite: PASS (2 tests), including idempotency.
- Auth, Firestore, and Functions integration command: PASS, including terminal command observation and duplicate-delivery behavior.

The current integration timing assertion verifies completion within 15 seconds. It does not collect the sample size, warm/cold split, or network profile required for an SC-004 performance claim. Physical Android, iOS, Web, and Windows interaction scenarios A–F remain a human device-validation gate; they were not marked passed by the automated local run.

## Validation Record — 2026-07-13

Automated validation after adding creator-only permanent outing removal:

- Full Flutter suite: PASS (157 tests).
- Dart analyzer: PASS with no issues.
- Functions unit suite: PASS (6 tests); 4 emulator-only cases are intentionally skipped by the unit command.
- Auth, Firestore, and Functions integration suite: PASS (4 tests), including every lifecycle status, correlated-data cleanup, and overlapping deletion requests.
- Firestore and Storage Security Rules suite: PASS (29 tests), including denied direct deletion and creator-only `delete_outing` authorization.
- Schema migration suite: PASS (2 tests).

### Android Emulator T101 Record

The user authorized T101 with an Android-emulator-only scope and explicitly excluded Web and Windows. iOS was not included in this run.

- Platform: Android emulator `emulator-5554`, Android 16, 1080 x 2424.
- Backend: local Firebase Auth, Firestore, Functions, and Storage emulators, reached from Android through `10.0.2.2`.
- Network profile: 20 ICMP samples, 0% packet loss, 1.886 ms average RTT, 5.933 ms maximum RTT. This satisfies SC-004's maximum 100 ms RTT and below-1% packet-loss conditions.
- Attendance: 100 instrumented snapshot-observed trials; p95 390 ms; PASS against the 3-second target.
- Vote change: 100 instrumented snapshot-observed warm trials; p95 219 ms; PASS against the 3-second target.
- Confirmation: 100 instrumented command-to-terminal/result trials. The first trial was classified cold at 316 ms; the remaining 99 were classified warm with p95 338 ms; PASS against the 3-second warm target.
- Scenario A: PASS. Attendance could be changed before Meeting, deterministic participant state was observed after each change, and Meeting changes were denied.
- Scenario B: PASS. Planning detail edits were denied, equivalent proposals were deduplicated, proposal mutation was denied, sealed-ballot listing was denied, and repeated vote changes were observed through the acting user's deterministic ballot.
- Scenario C: PASS. Tie preview exposed tied proposal IDs without counts, an organizer-selected tied leader confirmed successfully, and the outing/round transitioned to Confirmed.
- Scenario D: PASS. A participant declined before confirmation; confirmation used one eligible voter and one counted time ballot, excluding that participant's conflicting ballot. Command concurrency and retry behavior also remained covered by the passing integrated emulator suite recorded above.
- Scenario E: PASS. Reopening superseded the confirmed round and created a new open Planning round while preserving the prior round as immutable history; lifecycle denial remains covered by the rules and feature suites recorded above.
- Scenario F: PASS for the authorized Android scope. Attendance, proposals, votes, preview, confirmation, reopening, and deletion used the Firestore command/snapshot path on the emulator. Web and Windows were excluded by user instruction; iOS was outside this run's scope.
- Scenario G: PASS. The creator-only removal control deleted creator-owned outings in Draft, Planning, Confirmed, Meeting, Completed, Archived, and Cancelled states; correlated records became absent or inaccessible. A crew owner who was not the outing creator could neither see the removal control nor issue deletion. Duplicate and overlapping removal behavior remains covered by the passing integrated emulator suite recorded above.

Command: `flutter test --no-pub integration_test/agreement_android_t101_test.dart -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true` (PASS, 1 test). T101 is complete for the user-authorized Android-only scope.
