# Contract: Live Meetup Command Processing

This contract defines the Firestore boundary between Flutter and trusted Functions.

## Creation Boundary

The repository:

1. Generates a high-entropy `commandId`.
2. Runs a Firestore transaction that reads the outing.
3. Creates one exact-shape pending command with `createdAt == request.time`.
4. Observes that known command document until terminal or timeout.

Offline transactions fail without creating queued work.

## Processing Contract

The v2 Firestore creation trigger:

1. Parses and validates the exact type-specific schema.
2. Claims the command by event ID.
3. Treats the Rules-bound `requestedByUserId` as the actor, then revalidates outing, crew, membership, participant, Accepted attendance, lifecycle, deletion state, and every cleanup-pending flag.
4. Uses `(createdAt, commandId)` as the authoritative operation tuple.
5. Applies one idempotent Firestore transaction.
6. Scrubs the payload on every terminal result.

Admin SDK code bypasses Rules, so every Rules check is repeated.

## Type Semantics

### `set_status`

- Requires Meeting eligibility.
- Replaces the deterministic status only when the operation tuple is newer.
- Older commands terminate as `superseded`.

### `start_sharing`

- Requires Meeting eligibility.
- Hashes the raw session secret with SHA-256.
- Starts when control is inactive.
- If active control belongs to another session, requires `transferExisting == true`.
- Transfer atomically replaces session hashes and deletes the current location.
- A start older than the latest control tuple is superseded.

### `publish_location`

- Requires Meeting eligibility and an active matching session/token hash.
- Validates coordinate/accuracy/sample-age bounds.
- Rejects if `createdAt + 2 minutes <= processingNow`.
- Replaces the deterministic location only for a newer operation tuple.
- Sets `acceptedAt = createdAt` and `expiresAt = createdAt + 2 minutes`.

### `stop_sharing`

- Requires the matching active session.
- Atomically marks control inactive, removes session/token fields, advances the control tuple, and deletes the current location.
- Repeated stop for the same already-stopped session is idempotent.
- A transferred/old session cannot stop the new session.

### `set_meetup_point`

- Requires Confirmed or Meeting plus outing-creator/current-crew-owner authority.
- Requires exact equality between payload `locationTextSnapshot` and current outing `locationText`.
- Replaces the point only for a newer operation tuple.

## Terminal Contract

```text
pending -> processing -> succeeded
                      |-> superseded
                      `-> failed
```

Safe success results contain only IDs, accepted timestamps, expiry timestamp where relevant, and idempotent/superseded flags. They never contain the raw session token or participant coordinates.

## Idempotency and Race Rules

- Duplicate trigger delivery: terminal command or matching applied command ID is a no-op.
- Old status/location event after a newer event: superseded.
- Old start after stop: superseded by control watermark.
- Old-device update after transfer: token hash mismatch.
- In-flight update concurrent with stop: transaction conflict/retry observes inactive control; stop's point deletion wins.
- In-flight update concurrent with an outing/eligibility privacy transition: cleanup-pending or authoritative lifecycle state rejects the update.
- Duplicate cleanup/stop: absence is success, never recreation.

## Stable Backend Error Codes

- `unauthenticated`
- `permission_denied`
- `not_found`
- `invalid_command`
- `invalid_status`
- `invalid_location`
- `stale_location`
- `invalid_outing_state`
- `attendance_required`
- `outing_deleting`
- `transfer_required`
- `session_transferred`
- `session_stopped`
- `already_processed`
- `internal_error`

## Data Minimization

- Coordinates and session secrets exist only in a requester-private pending command.
- Terminal processing deletes `payload`.
- Exact command gets are requester-only; list is denied.
- Pending location commands expire after two minutes; terminal commands after ten minutes.
- Logs exclude command payloads, coordinates, accuracy, search text, secrets, and participant profile data.
