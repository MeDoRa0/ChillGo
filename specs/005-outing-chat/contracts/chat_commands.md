# Contract: Outing Chat Commands

This contract defines the Firestore boundary between Flutter clients and trusted Functions for accepting text messages.

## Create Attempt

The repository generates:

- one stable `clientMessageId` for the intended message, reused on manual retry;
- one new `commandId` for each send attempt.

It then runs an online Firestore transaction that reads the outing and creates `/chat_commands/{commandId}`. If the transaction cannot reach Firestore, it fails and creates no queued command.

```text
type: send_message
outingId: non-empty outing ID
crewId: crew read from the outing transaction
requestedByUserId: authenticated UID
clientMessageId: stable high-entropy message identity
payload:
  text: Unicode-whitespace-trimmed string of 1-2,000 Unicode scalar values
status: pending
createdAt: request/server timestamp
```

Security Rules require exact top-level/payload keys, actor identity, active outing status, current crew membership, current outing participation, and create-only access. Trusted processing treats every claimed value as untrusted and resolves authoritative records again.

## Processing Contract

The v2 Firestore creation trigger:

1. Claims a pending command by trigger event ID.
2. Revalidates outing, membership, participant, status, content, and deletion state.
3. Resolves `/chat_messages/{outingId}_{clientMessageId}`.
4. Returns an already-existing matching message as idempotent success.
5. Otherwise enforces the rolling rate bucket and creates the message transactionally.
6. Removes `payload` on every terminal result.

Admin SDK processing bypasses Security Rules, so every rule-level authorization and shape check is repeated in trusted code.

## Status Contract

```text
pending -> processing -> succeeded
                      `-> failed
```

Terminal success result:

```text
messageId: deterministic final message ID
acceptedAt: trusted Timestamp
expiresAt: acceptedAt + 24 hours
alreadyAccepted: Boolean
```

Terminal rate-limit failure additionally exposes `retryAt`. No result exposes another user's read state or protected chat metadata.

Trusted processing also adds `deleteAt`, no later than 24 hours after `createdAt`, to every terminal command.

## Retry and Idempotency

- Offline transaction failure: no command exists; local state becomes failed.
- Explicit retry: create a new command ID with the same `clientMessageId` and unchanged text.
- Lost acknowledgement after acceptance: the next attempt finds the existing matching message and succeeds without creating a duplicate or consuming another rate slot.
- Reusing a `clientMessageId` with different outing, author, or text: fail `message_identity_conflict`.
- Duplicate trigger delivery: terminal commands and existing deterministic messages make processing a no-op.
- Rate-limited attempt: terminal failure; retry is allowed only by an explicit later attempt.

## Stable Error Codes

- `unauthenticated`
- `permission_denied`
- `not_found`
- `invalid_command`
- `invalid_message`
- `invalid_outing_state`
- `outing_deleting`
- `rate_limited`
- `message_identity_conflict`
- `already_processed`
- `internal_error`

Errors contain safe user-facing text. `rate_limited` includes only the acting participant's `retryAt`.

## Data Minimization

- Pending commands contain text only until trusted processing reaches a terminal result.
- Success and failure both remove `payload` and retain only sanitized metadata.
- Every terminal command has trusted `deleteAt` no later than 24 hours after creation and is covered by scheduled cleanup plus TTL backstop. Scheduled cleanup also deletes abandoned pending commands once `createdAt` reaches 24 hours.
- Outing deletion terminates or removes all related command attempts and prevents them from recreating messages.
