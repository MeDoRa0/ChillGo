# Contract: Notification Processing

## Source-to-record contract

1. A source action succeeds first.
2. A trusted transaction writes its immutable `notification_event`, or a narrow source trigger creates the equivalent deterministic event for legacy direct writes.
3. The event worker claims `(sourceEventId, recipientUserId)` work idempotently.
4. It re-reads the source and recipient authorization, calculates category eligibility, and creates one deterministic notification while updating the unread summary in one transaction.
5. A delivery worker revalidates source, preference, expiry, and device registration before submitting a generic provider message.

No source failure, rejected action, local draft, duplicate event delivery, or delivery retry may create another center record.

## Source semantics

| Category | Authoritative condition | Exclusions |
|---|---|---|
| Crew invitation | New pending invitation addressed to a registered user | revoked, consumed, or duplicate invitation |
| Outing invitation | New non-creator invited participant who remains a crew member | creator record, missing membership, non-Invited record |
| Voting update | New eligible proposal in Planning | actor, vote changes, totals, ballots, ineligible proposal |
| Agreement confirmed/reopened | Successful trusted agreement command | failed/retried command and private ballot data |
| Outing change | One successful edit with title/description/schedule/location delta | lifecycle-only/no-op update; one item per recipient per edit |
| Attendee arrival | First explicit Arrived transition while Meeting | Getting Ready, On My Way, repeated Arrived, location/map changes |

## Notification command contract

```text
pending -> processing -> succeeded
                      `-> failed
```

`mark_read` and `open` require an available recipient-owned record. They atomically set `readAt` only once and decrement the summary only if it was unread. `register_device` requires a supported platform, random installation ID, bounded token/payload shape, and current authenticated user; it upserts one registration. `unregister_device` removes only the requester’s known installation. Every terminal command scrubs payload and returns a stable non-sensitive result.

## Delivery contract

- Recheck recipient/source eligibility and the optional-category preference immediately before delivery.
- Send to every fresh, permission-granted registration for the recipient, in batches of no more than 500 targets.
- Payload contains generic title/body and only `notificationId`, `category`, and schema version. It must contain no outing/crew/member/location/vote details or device token.
- Provider failures may be retried and may deliver duplicates. Invalid/unregistered target responses delete that registration. Neither source actors nor other users can inspect delivery/open outcomes.
- Foreground receipt may show an accessible in-app banner; a tap or cold-start payload loads the opaque record and re-authorizes before navigation.

## Cleanup and race contract

- `expiresAt` is exactly creation +30 days. Clients and Rules treat the boundary as unavailable; a minutely worker deletes bounded batches; TTL is only recovery.
- Access-ending operations first set a notification cleanup-pending denial state, delete records/work while conditionally updating summaries, verify emptiness, then finalize source deletion/change.
- Duplicate source events, work claims, cleanup, invalidation, or provider callbacks are no-ops after their deterministic target is terminal.
- Read/open racing with expiry or invalidation ends with either a single successful read before the boundary or an unavailable outcome; unread counts never go below zero.

## Stable failure categories

| Backend condition | User-facing category |
|---|---|
| No authenticated user | Sign-in required |
| Missing/revoked source or access | Notification unavailable |
| Expired record | Notification expired |
| Unsupported/denied/offline device alerts | Device alerts unavailable |
| Retryable trusted processing failure | Notification service unavailable |
