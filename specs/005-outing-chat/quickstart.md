# Quickstart & Validation Guide: Outing Chat

This guide validates Phase 5 design outcomes. It references [data-model.md](./data-model.md) and the contracts under [contracts/](./contracts/). It does not authorize production deployment or manual device E2E execution.

## Prerequisites

1. Phase 2 Crew Management, Phase 3 Outing Management, and Phase 4 Agreement System are implemented.
2. Flutter/Dart dependencies are installed.
3. Node.js 22, Functions dependencies, and Firebase CLI are available.
4. Auth, Firestore, and Functions emulators use the existing project configuration.
5. Implementation adds `firestore.indexes.json`, references it from `firebase.json`, and configures the cleanup schedule/TTL fields described in [contracts/cleanup.md](./contracts/cleanup.md).

## Automated Validation

### Focused Flutter Tests

```bash
flutter test test/features/chat/ test/features/outings/presentation/widgets/interactive_outing_card_test.dart test/core/routes/app_router_test.dart test/core/di/injection_container_test.dart
```

**Expected**: Entities/models, trusted-clock/expiry/access policy, repository mapping/pagination, online-only send failure, explicit retry, command observation, read state, unread summary, Cubits, chat screen, route, DI, and outing entry/badge tests pass.

### Full Flutter Suite and Analyzer

```bash
flutter test
dart analyze
```

**Expected**: All existing features remain green and static analysis reports no issues.

### Functions Unit Tests

```bash
npm --prefix functions run test:chat
```

**Expected**: Command parsing, actor/state validation, stable message identity, lost-acknowledgement retry, trigger idempotency, rolling-window concurrency, retry time, payload scrubbing, expiry cleanup, and outing-deletion races pass.

The implementation adds `test:chat` to `functions/package.json`; the full Functions suite remains:

```bash
npm --prefix functions test
```

### Firestore Security Rules

```bash
npm --prefix firestore_tests test
```

**Expected**: Message, command, read-state, rate-bucket, expiry, participant/membership, lifecycle, query-bound, and deletion-pending access cases pass without regressing agreement/outings rules.

### Integrated Emulator Flow

```bash
npm --prefix functions run test:chat:integration
```

**Expected**: Authenticated clients create online-only commands, Functions create messages and terminal results, listeners observe stable history, rate-limit and idempotency behavior hold under concurrency, scheduled cleanup services delete expired records, and outing removal cascades through chat data.

The implementation adds the focused script while preserving the existing full integration command.

### Recorded Automated Evidence — 2026-07-22

All commands below were run from the repository described by this guide:

- Full Flutter suite: **210 tests passed**.
- Focused chat/repository/Cubit regressions: **14 tests passed** after the final access-revocation hardening.
- Dart analyzer: **exit 0** with seven pre-existing informational style notices outside the chat feature and no chat findings.
- Focused Functions suite: **17 tests passed**.
- Full Functions suite: **24 tests passed** and **9 emulator-only tests were skipped** when no emulators were configured.
- Firestore Security Rules suite: **passed**, including chat expiry/query proof and non-chat regression cases.
- Auth/Firestore/Functions integrated emulator suite: **6 tests passed** in 22 seconds, covering command acceptance and idempotency, immutable author snapshots, rolling rate limiting, lifecycle and eligibility revalidation, cleanup, outing deletion races, and the performance profile.

The emulator performance profile used 100 eligible participants and 5,000 unexpired messages. Across 100 accepted-send trials, both terminal sender state and a second conversation observer saw every message in under three seconds: **532 ms maximum** and **518 ms p95**. The ordered newest-50 query completed in **71 ms**. This is repeatable local emulator evidence for SC-002 and SC-007; deployed index enforcement and real network/device smoke validation remain part of the deployment and manual gates below.

## Validation Scenarios

### Scenario A: Participant-Only Access and Lifecycle

1. Create one outing with Invited, Accepted, and Declined current participants plus one non-participant crew member.
2. Verify all three participants can read/send in Draft, Planning, Confirmed, and Meeting.
3. Verify the non-participant and a removed member cannot query content or read-state metadata.
4. Move the outing to Completed, Archived, or Cancelled and verify history remains readable while sends become read-only failures.

### Scenario B: Online-Only Send and Idempotent Retry

1. Disconnect Firestore and submit a valid message.
2. Verify no command/message is queued and local state becomes failed.
3. Reconnect and explicitly retry with the same `clientMessageId`; verify one message is accepted.
4. Simulate a lost terminal acknowledgement and retry through a new command; verify the existing message is returned without duplication or another rate slot.

### Scenario C: History Ordering and Pagination

1. Seed more than 100 unexpired messages, including equal accepted timestamps.
2. Verify the newest 50 appear in stable chronological display order.
3. Load older pages and verify there are no gaps or duplicates.
4. Add a new message while reviewing older history and verify the reading position remains stable.
5. Add a new outing participant and verify currently unexpired history becomes available.
6. Set the device wall clock incorrectly and verify ordering/expiry still use the server-synchronized clock.
7. Prove in the Rules emulator that direct expired gets are denied, authorized list/aggregation queries remain valid across clock drift and long-lived listeners, and unscoped or over-limit queries remain denied.

### Scenario D: Private Read State and Unread Count

1. Have another participant send three messages while the acting participant is outside chat.
2. Verify unread count is three and own messages are excluded.
3. Open at the first unread message, view through newest, and verify the count becomes zero across a second session.
4. Verify no user, creator, or crew owner can read another participant's cursor.
5. Expire the cursor/message and verify neither contributes to unread state.

### Scenario E: Rolling Rate Limit

1. Accept 30 messages for one participant/outing inside a rolling minute.
2. Verify the next attempt fails with `rate_limited` and an exact safe retry time.
3. Verify other participants and other outings remain unaffected.
4. Advance beyond the oldest timestamp and verify one new message is accepted.
5. Race concurrent 30th/31st attempts and verify no over-acceptance.

### Scenario F: 24-Hour Unavailability and Hard Cleanup

1. Create messages immediately before and after the expiry boundary.
2. Verify the first remains available just before `expiresAt` and is removed from UI/domain/query results at the boundary.
3. Run the first successful scheduled cleanup invocation after expiry and verify expired messages, command metadata, cursor states, and rate buckets are permanently deleted while future records remain.
4. Repeat cleanup and verify idempotency.
5. Verify terminal command documents contain no message text.
6. Verify abandoned time probes older than 10 minutes are removed without exposing cross-user data.

### Scenario G: Outing Removal Race

1. Populate chat data for outings in every lifecycle status.
2. Remove each outing through the existing creator or expiry command path.
3. Verify messages, read states, commands, and rate buckets become inaccessible/absent.
4. Overlap removal with a send and verify `deletionPending`/absence prevents message recreation.

## Cross-Platform and Manual E2E Gate

The same repository/Firestore path must be validated on Android, iOS, Web, and Windows. FlutterFire currently gives Windows different upstream support guarantees, so a Windows smoke test is mandatory before release.

Manual device E2E requires explicit user permission under the project constitution. Do not mark cross-platform interaction or performance scenarios complete without that authorization and recorded evidence.

**Authorization status (2026-07-22): pending user approval.** No usability participants, physical-device tests, or manual platform E2E runs have been started.

### Usability Measurement Protocol

Usability execution also requires explicit user permission. Recruit at least 20 representative participants who have not previously completed the measured workflow, with at least five trials on each of Android, iOS, Web, and Windows.

- **SC-001**: Start timing when an eligible outing entry is visible and stop when the first valid message reaches sent state. At least 95% of the total sample, and no fewer than 19 participants, must finish within 30 seconds without assistance.
- **SC-008**: At least 90% of the total sample, and no fewer than 18 participants, must identify unread state, open at the unread boundary, and identify writable versus read-only status without assistance.
- Record authorization, participant count, platform distribution, timings, success rates, failures, and observations in this guide before marking either criterion complete.

## Deployment Gate

- Deploy and verify composite indexes before enabling production chat queries.
- Deploy Security Rules, Functions triggers/scheduler, and TTL field policies as a coordinated release.
- Confirm the Firebase project plan supports scheduled Cloud Functions/Cloud Scheduler.
- Run a deployed-project smoke test for production index enforcement and TTL policy presence; the emulator is insufficient for those two checks.
- Run focused/full Flutter, Functions, Rules, and integrated emulator suites before deployment.
- Monitor cleanup failures, command terminal latency, rate-limit rejection rate, and permission denials without logging message text.

**Deployment status (2026-07-22): not started.** Emulator validation is complete, but no production project, Rules, Functions, scheduler, index, or TTL state was changed by this implementation run.
