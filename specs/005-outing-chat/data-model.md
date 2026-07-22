# Data Model: Outing Chat

This document defines Phase 5 entities, Firestore paths, validation, ownership, ordering, privacy, expiry, and lifecycle behavior.

## 1. Outing Chat Channel (Logical)

An outing has exactly one logical chat identified by its existing `outingId`; no channel document is required.

Chat access requires all of the following at read/write time:

1. The user is authenticated.
2. `/outings/{outingId}` exists and is not `deletionPending`.
3. `/crew_memberships/{crewId}_{userId}` exists for the outing's authoritative crew.
4. `/outing_participants/{outingId}_{userId}` exists.

Attendance status does not affect chat access. Draft, Planning, Confirmed, and Meeting are writable; Completed, Archived, and Cancelled are read-only until messages expire or the outing is removed.

## 2. Chat Message

- **Path**: `/chat_messages/{outingId}_{clientMessageId}`

| Field | Type | Rules |
|---|---|---|
| `outingId` | String | Existing outing; immutable |
| `crewId` | String | Must equal the outing's authoritative crew; immutable |
| `clientMessageId` | String | High-entropy ID generated once for the composed submission; immutable |
| `authorUserId` | String | Trusted command actor; immutable |
| `authorUsername` | String | Accepted-time display snapshot from the user/participant profile; immutable |
| `authorDisplayName` | String | Accepted-time display snapshot; immutable |
| `authorAvatarUrl` | String (nullable) | Accepted-time display snapshot; immutable |
| `text` | String | Unicode-whitespace-trimmed text, 1-2,000 Unicode scalar values; immutable |
| `acceptedAt` | Timestamp | Trusted server acceptance time; immutable |
| `expiresAt` | Timestamp | Exactly `acceptedAt + 24 hours`; immutable and TTL-enabled |

All client writes are denied. Trusted processing creates the document once. Ordering is ascending `(acceptedAt, documentId)` in domain/UI state; newest queries use both fields descending and reverse the page for display.

The author display snapshot preserves attribution while the message remains available even if the author is later removed from the outing or crew. It contains only profile fields allowed by the constitution.

## 3. Chat Command Attempt

- **Path**: `/chat_commands/{commandId}`

Client-created pending shape:

| Field | Type | Rules |
|---|---|---|
| `type` | String | Exactly `send_message` |
| `outingId` | String | Target outing |
| `crewId` | String | Claimed crew, verified against outing |
| `requestedByUserId` | String | Must equal authenticated user |
| `clientMessageId` | String | Stable across manual retry attempts for the same composition |
| `payload` | Map | Exactly `{text}` with trimmed length 1-2,000 |
| `status` | String | Exactly `pending` at creation |
| `createdAt` | Timestamp | Request/server timestamp |

Trusted terminal fields:

| Field | Type | Description |
|---|---|---|
| `status` | String | `processing`, `succeeded`, or `failed` |
| `processingEventId` | String (nullable) | Trigger delivery currently owning processing |
| `processedAt` | Timestamp (nullable) | Trusted completion time |
| `result` | Map (nullable) | On success: message ID, accepted time, expiry time |
| `errorCode` | String (nullable) | Stable safe failure code |
| `errorMessage` | String (nullable) | Non-sensitive display message |
| `retryAt` | Timestamp (nullable) | Present for `rate_limited` |
| `deleteAt` | Timestamp (nullable) | Trusted terminal cleanup time, no later than 24 hours after `createdAt`; TTL-enabled |

Trusted processing removes `payload` and adds `deleteAt` on every terminal outcome so command history cannot duplicate message text. Clients may create and read their own commands but may not update or delete them. Scheduled cleanup removes abandoned pending commands by `createdAt` even if trusted processing never added `deleteAt`.

`commandId` identifies one network/processing attempt; `clientMessageId` identifies the intended message across attempts.

## 4. Chat Rate Limit

- **Path**: `/chat_rate_limits/{outingId}_{userId}`

| Field | Type | Rules |
|---|---|---|
| `outingId` | String | Rate bucket outing |
| `crewId` | String | Authoritative owning crew |
| `userId` | String | Rate-limited participant |
| `acceptedAt` | List<Timestamp> | Ascending timestamps strictly inside the rolling 60-second window; maximum 30 |
| `updatedAt` | Timestamp | Latest accepted-message transaction time |
| `purgeAfter` | Timestamp | Oldest time when the bucket is guaranteed empty; cleanup/TTL field |

All client reads and writes are denied. The message-acceptance transaction prunes old entries, evaluates the count, and appends the new timestamp atomically. An idempotent retry that finds an existing matching message does not consume a new slot.

## 5. Chat Read State

- **Path**: `/chat_read_states/{outingId}_{userId}`

| Field | Type | Rules |
|---|---|---|
| `outingId` | String | Owning outing; immutable |
| `crewId` | String | Owning crew; immutable |
| `userId` | String | State owner and authenticated writer; immutable |
| `readThroughAcceptedAt` | Timestamp | Primary ordering value of newest viewed message |
| `readThroughMessageId` | String | Secondary ordering value for equal timestamps |
| `cursorExpiresAt` | Timestamp | Expiry of the cursor's source message; scheduled/TTL cleanup field |
| `updatedAt` | Timestamp | Server update time |

The `(readThroughAcceptedAt, readThroughMessageId)` pair is an ordering cursor, not a hard document reference. It advances monotonically and never exposes content. Only the state owner may read or update it, and only while current participation and crew membership remain valid. Cross-user reads are denied.

When `cursorExpiresAt` passes, cleanup deletes the state. Any still-available messages after the old cursor remain unread, while earlier messages have also expired, so resetting to the current 24-hour lower bound preserves correct unread behavior without an orphaned pointer.

## 6. Chat Time Probe

- **Path**: `/chat_time_probes/{userId}_{probeId}`

| Field | Type | Rules |
|---|---|---|
| `userId` | String | Must equal authenticated creator |
| `requestedAt` | Timestamp | Server timestamp equal to request time |

The client creates the probe in an online transaction, waits for the committed server value, computes a session clock offset using monotonic round-trip timing, and deletes the probe. Only its owner may create/get/delete it; list and update are denied. Scheduled cleanup deletes probes older than 10 minutes if a client exits before deletion. No chat content, outing identity, or cross-user state is stored.

## 7. Local Send Attempt (Domain/Presentation Only)

This is not a Firestore document.

| Field | Type | Description |
|---|---|---|
| `clientMessageId` | String | Stable identity reused for manual retry |
| `text` | String | Local draft/retry content |
| `state` | Enum | `sending`, `sent`, or `failed` |
| `commandId` | String (nullable) | Current attempt being observed |
| `failure` | Domain failure (nullable) | Safe reason and optional retry time |

If the client transaction fails offline, no command document exists and the local attempt becomes `failed`. The UI never auto-retries; the participant explicitly retries with the same `clientMessageId`.

## Relationships

```text
Crew 1 --- * Outing 1 --- 1 LogicalChat
                  |             |--- * ChatMessage (24-hour immutable)
                  |             |--- * ChatReadState (one per participant)
                  |             |--- * ChatRateLimit (one per participant, trusted)
                  |             `--- * ChatCommandAttempt (requester-private)
                  `--- * OutingParticipant

User 1 --- * ChatMessage (author)
User 1 --- * ChatCommandAttempt (requester)
User 1 --- * ChatReadState (owner)
User 1 --- * ChatTimeProbe (short-lived owner-private clock sync)
```

## State Transitions

### Chat Writeability

```text
Draft | Planning | Confirmed | Meeting -> writable
Completed | Archived | Cancelled       -> read-only
Outing absent/deletionPending           -> inaccessible
```

### Send Attempt

```text
Local sending --offline/transaction failure--> Local failed
Local sending --command created--------------> Pending command
Pending -> Processing -> Succeeded -> Local sent
                      `-> Failed    -> Local failed
Local failed --explicit retry--> new command attempt with same clientMessageId
```

### Chat Message

```text
Absent --trusted acceptance--> Available immutable message
Available --expiresAt reached--> Product-inaccessible
Product-inaccessible --scheduled cleanup/TTL--> Permanently deleted
Any state --outing removal--> Permanently deleted/inaccessible
```

### Read State

```text
Absent --view through message--> Cursor
Cursor --view through newer message--> Advanced cursor
Cursor --cursor expiry/outing removal--> Deleted
```

## Message Acceptance Transaction

1. Claim the pending command idempotently for the trigger event.
2. Re-read the outing; require existence, matching crew, allowed status, and `deletionPending != true`.
3. Re-read the deterministic crew membership and outing participant records.
4. Validate actor identity, stable client message ID, and trimmed text.
5. Resolve the deterministic final message path.
6. If a matching message already exists, return its result without consuming another rate slot.
7. Read and prune the participant/outing rate bucket using trusted acceptance time.
8. If 30 timestamps remain, fail with `rate_limited` and the earliest valid retry time.
9. Otherwise append the acceptance time, create the immutable message and expiry, update the rate bucket, scrub the command payload, and mark the command succeeded atomically.

## Query and Index Shapes

- Newest/older history: `outingId == X`, `expiresAt > cutoff`, ordered by `acceptedAt desc`, document ID `desc`, limited to 50.
- Unread all-authors count: same outing/expiry constraints, starting after the private read cursor.
- Unread own-author count: same query plus `authorUserId == currentUserId`; subtract from all-authors count.
- Cleanup: `expiresAt <= now` for messages, terminal `deleteAt <= now` or abandoned `createdAt <= now - 24 hours` for commands, `cursorExpiresAt <= now` for read state, `purgeAfter <= now` for rate buckets, and `requestedAt <= now - 10 minutes` for time probes.
- Outing removal: indexed `outingId == X` ownership queries across all four chat collections.

Required composite indexes and TTL field overrides are declared in `firestore.indexes.json`. History pages use a limit of 50; unread aggregation queries use the same ownership/expiry constraints with a maximum count scope of 5,000. No Phase 5 data migration is required because all collections are new and lazily created.
