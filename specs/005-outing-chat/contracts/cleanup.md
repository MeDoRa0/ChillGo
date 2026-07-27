# Contract: Outing Chat Cleanup

This contract defines automatic 24-hour cleanup and integration with permanent outing removal.

## Exact Availability Boundary

Every accepted message receives trusted timestamps:

```text
acceptedAt = backend acceptance time
expiresAt = acceptedAt + 24 hours
```

At `expiresAt`:

- domain/presentation filtering removes the message immediately;
- history and unread queries exclude it;
- direct message gets are denied by Security Rules;
- it cannot become visible again from cache, retry, pagination, or read state.

This boundary satisfies product unavailability independently of physical cleanup timing.

## Scheduled Hard Deletion

`chatCleanupScheduled` runs every minute through the v2 scheduler API. It uses trusted server time and bounded indexed queries to delete:

- `chat_messages` where `expiresAt <= now`;
- terminal `chat_commands` where `deleteAt <= now`, plus abandoned pending commands where `createdAt <= now - 24 hours`;
- `chat_read_states` where `cursorExpiresAt <= now`;
- `chat_rate_limits` where `purgeAfter <= now`.
- `chat_time_probes` where `requestedAt <= now - 10 minutes`.

Each collection is processed in batches below Firestore's write limit, repeats while a bounded invocation budget remains, and is safe to rerun. Failures are logged with collection, batch size, cutoff, and sanitized error code but never message text.

## TTL Backstop

Firestore TTL field policies mirror persistent collection cleanup fields where a dedicated expiry field exists. TTL is a retry/backstop only because Firebase does not guarantee immediate deletion at the expiry timestamp. Scheduled cleanup remains the prompt hard-deletion mechanism and covers abandoned commands/probes that have only a trusted creation timestamp.

TTL/index configuration is deployed from `firestore.indexes.json`; `firebase.json` references the index file. Emulator tests validate cleanup services directly, while a deployed-project smoke check verifies TTL/index configuration.

## Command Content Scrubbing

Terminal command processing deletes the message payload immediately. Scheduled/TTL deletion then removes the remaining command metadata by `deleteAt`. A failed or abandoned pending command cannot retain text beyond 24 hours.

## Permanent Outing Removal

Extend `OutingDeletionService` as follows:

1. Mark the outing `deletionPending` transactionally.
2. Chat command handlers re-read and reject this state before message creation.
3. Terminate/scrub pending and processing `chat_commands` for the outing.
4. Delete `chat_messages`, `chat_read_states`, and `chat_rate_limits` by indexed `outingId` queries.
5. Delete the outing through the existing flow.
6. Repeat the owned-record sweep to catch work that raced with the first pass.

Creator-requested removal and the existing client-signaled scheduled outing expiry both use this service. Repeated and overlapping deletion requests are successful no-ops after data is absent.

## Required Validation

- A message is present immediately before expiry and absent from product reads/state at the boundary.
- The scheduled cleanup service permanently deletes every expired record class and leaves future records intact.
- Duplicate cleanup execution is harmless.
- Terminal success/failure command documents contain no text payload.
- Removing an outing deletes or makes inaccessible all chat-owned data in every outing lifecycle status.
- A send racing with removal cannot create or recreate a message after `deletionPending` or outing absence.
- Cleanup logs and errors never include message text.
