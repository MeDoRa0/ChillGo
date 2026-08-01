# Quickstart: Validate Notifications

## Prerequisites

- Use branch `codex/007-notifications` with Firebase dependencies installed.
- Configure Auth, Firestore, Functions, and platform-specific Firebase Messaging prerequisites. Android needs notification permission/channel configuration. iOS needs Push Notifications, background remote-notification capability, and APNs credentials. Web and desktop delivery are outside the release scope and cannot register a notification target.
- Do not run manual device-push tests without user approval.

## Automated validation

1. Run focused Flutter notification tests, then the full Flutter suite:

   ```powershell
   flutter test test/features/notifications
   flutter test
   ```

2. Build and run focused Functions notification tests, including source mapping, idempotency, recipient rechecks, summary races, token cleanup, transition cleanup, and expiry:

   ```powershell
   Set-Location functions
   npm run test:notifications
   npm run test:notifications:integration
   ```

3. Run Firestore Rules emulator tests covering recipient-only reads, source revocation, direct-write denial, and command/preference shapes:

   ```powershell
   firebase emulators:exec --only auth,firestore,functions "npm run test:notifications:rules"
   ```

4. Verify the required index and TTL configuration through deployment review. TTL may be enabled successfully without satisfying punctual-expiry tests; scheduled cleanup and Rules remain required.

## Functional scenarios

| Scenario | Expected result |
|---|---|
| Create crew/outing invitation | One eligible recipient record, correct unread count, generic alert only when a supported device can receive it. |
| Create proposal, confirm/reopen agreement, or edit several outing fields | Correct recipients receive one category-safe record; ballots and counts stay private; multi-field edit is consolidated. |
| First explicit Arrived in Meeting | Other eligible Accepted attendees receive one record with no location; repeats and other statuses do not alert. |
| Toggle optional preferences | Later device alerts are suppressed only for that category; center records still exist; operational categories remain required. |
| Sign in on multiple devices and refresh a token | One center record, consistent read/unread state, alert attempt to every eligible target, no cross-account association after sign-out. |
| Revoke invitation/access, remove participation/membership, or end/remove outing | Rules deny immediately; cleanup removes related records and adjusts summaries before source finalization. |
| Reach 30-day boundary | Record disappears from client and unread count at the product boundary; scheduled cleanup deletes it; TTL later provides recovery only. |

## User-approved release smoke checks

After explicit approval, verify Android and physical iOS foreground/background/terminated open behavior, permission denial/settings recovery, APNs configuration, and invalid-token cleanup. Confirm all alert copy is generic and every tap reauthorizes before navigation. For SC-002, record physical-device receipt separately from the automated provider-handoff metric; device receipt is best-effort evidence, not an FCM guarantee.

With representative participants who explicitly consent, run timed usability checks for SC-003 and SC-008: ask participants to open a new invitation or identify a confirmed plan, then find alert preferences, disable one optional category, and explain the effect. Record completion time, success, and usability observations without collecting protected notification content.

Confirm the Phase 7 implementation introduces none of the excluded capabilities in FR-023, including notification replies, direct messages, social features, marketing notifications, background location tracking, live-location alert content, reactions, or notification-driven source changes.
