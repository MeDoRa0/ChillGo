# Research: Outing Chat

This document records Phase 0 decisions for implementing Phase 5 across Android, iOS, Web, and Windows while satisfying private participant access, online-only manual retry, rolling rate limiting, stable history, private read state, and 24-hour deletion.

## Decision 1: Use an Online-Only Firestore Command for Message Acceptance

**Decision**: Each send attempt creates an immutable `chat_commands` document inside a client Firestore transaction that reads the outing before writing. A second-generation Firestore-triggered Function revalidates the actor, outing, crew membership, participant record, lifecycle status, content, and deletion state before accepting the message.

**Rationale**: Ordinary Firestore writes may queue offline and synchronize later, contradicting the clarified manual-retry behavior. Firestore transactions fail offline and are never queued. The existing Phase 4 command pattern already provides one transport across all targets without adding Flutter `cloud_functions`, whose official Flutter platform matrix does not offer the same Windows path. Firestore triggers are at-least-once and unordered, so trusted processing must be idempotent. See [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions), [Firestore event delivery](https://firebase.google.com/docs/functions/firestore-events), and [Firebase Flutter platform support](https://firebase.google.com/docs/flutter/setup).

**Alternatives considered**:

- Direct client message writes: rejected because offline persistence can deliver a message later and rules cannot safely enforce the rolling limit under concurrency.
- Callable Functions from Flutter: rejected because it would not preserve the project's single Firestore-based path for Windows.
- Connectivity checks before a normal write: rejected because network reachability checks race with the actual write and cannot prevent Firestore queueing.

## Decision 2: Separate Stable Message Identity from Command Attempt Identity

**Decision**: Generate one high-entropy `clientMessageId` when the participant first submits a composed message and reuse it on manual retries. Generate a new `commandId` for each attempt. The final message ID is deterministic from the outing and `clientMessageId`. Trusted processing returns an existing matching message as success without consuming another rate-limit slot.

**Rationale**: Reusing one command document cannot support retry after a terminal rate-limit failure, while generating a new message identity after a lost acknowledgement can duplicate an already accepted message. Separate identities solve both cases. A successful message is immutable, and duplicate trigger or retry delivery converges on the same document.

**Alternatives considered**:

- Use the command ID as the message ID: rejected because a terminal failed command cannot be recreated for a later retry.
- Generate a new message ID for every retry: rejected because an accepted-but-unacknowledged first attempt could produce a duplicate.
- Allow clients to reset failed commands to pending: rejected because mutable commands complicate rules, trigger semantics, and auditability.

## Decision 3: Enforce the Rolling Limit with One Trusted Rate Bucket

**Decision**: Store up to 30 accepted timestamps in `chat_rate_limits/{outingId}_{userId}`. In the same backend transaction that creates a message, remove timestamps at or before `acceptedAt - 60 seconds`; reject with `rate_limited` and `retryAt` if 30 remain, otherwise append the trusted acceptance time.

**Rationale**: A single participant/outing document serializes competing sends and remains small. The specified ceiling is 0.5 accepted writes per second for one bucket, below a hot-document concern for this scope. Functions use processing/acceptance time because trigger delivery is unordered. Firestore transactions retry when a concurrently read document changes. See [Firestore transactions and contention](https://firebase.google.com/docs/firestore/manage-data/transactions).

**Alternatives considered**:

- Fixed calendar-minute buckets: rejected because a participant could send 60 messages across a minute boundary inside one rolling minute.
- Query recent messages without a shared rate document: rejected because concurrent transactions could both observe fewer than 30 before either creates a message.
- Client-only throttling: rejected because it is bypassable and inconsistent across devices.

## Decision 4: Use Top-Level Immutable Messages with Stable Cursor Pagination

**Decision**: Store immutable messages in top-level `chat_messages`, denormalizing `outingId` and `crewId` to match the existing repository schema. Query the newest 50 by `acceptedAt` and document ID descending; fetch older pages once with the same ordering and a two-field cursor. Merge and deduplicate by message ID, then present chronologically.

**Rationale**: Bounded listeners scale better than listening to all 5,000 available messages. The document-ID tie-breaker provides deterministic ordering when server timestamps match. Top-level ownership matches outings/agreement data and allows the existing outing deletion service to use indexed ownership sweeps. See [Firestore ordering and limits](https://firebase.google.com/docs/firestore/query-data/order-limit-data), [query cursors](https://firebase.google.com/docs/firestore/query-data/query-cursors), and [realtime query scaling](https://firebase.google.com/docs/firestore/enterprise/real-time-queries-at-scale).

**Alternatives considered**:

- Listen to all unexpired messages: rejected because it creates unbounded reads, state, and widget work.
- Store messages in an array on the outing: rejected because of document size, contention, and coarse updates.
- Nest messages in an outing subcollection: viable, but rejected to preserve the repository's top-level collection convention and reuse its indexed cascade-deletion pattern.

## Decision 5: Keep Read Progress Private and Compute Unread Counts on Demand

**Decision**: Store one owner-private `chat_read_states/{outingId}_{userId}` cursor containing the latest viewed `(acceptedAt, messageId)` ordering tuple plus its expiry. The tuple is a value cursor, not a dereference requirement. Advance it monotonically when the participant views through a newer message. Compute unread count as the count of available messages after the cursor minus the count of the participant's own messages after the same cursor, refreshing when latest-message or read-state signals change.

**Rationale**: Firestore cannot hide selected fields within a shared document, so private state belongs in separate owner-only records. Server count aggregations avoid loading thousands of messages merely to calculate a badge. They are not realtime or cached, so the application refreshes them on relevant snapshots, screen entry, and reconnect rather than promising Phase 7-style notification behavior. See [Security Rules field privacy](https://firebase.google.com/docs/firestore/security/rules-fields), [aggregation queries](https://firebase.google.com/docs/firestore/query-data/aggregation-queries), and [read-time aggregation limitations](https://firebase.google.com/docs/firestore/solutions/aggregation).

**Alternatives considered**:

- Per-message read-receipt arrays: rejected because read receipts are explicitly out of scope and arrays grow with participants.
- Fan out one unread counter update to every participant on each message: rejected because it can require 100 extra writes per message and creates contention/cost.
- Load every unexpired message to count locally: rejected because it conflicts with the 5,000-message scale target.

## Decision 6: Separate the Exact Access Boundary from Physical Deletion Timing

**Decision**: Trusted acceptance sets `expiresAt = acceptedAt + 24 hours`. Domain/UI expiry policy removes a message from visible state at that exact boundary, queries exclude expired records, and Security Rules deny direct reads after expiry. A v2 scheduled Function runs every minute and hard-deletes expired messages, expired or abandoned command attempts, expired read cursors, stale rate buckets, and abandoned time probes in bounded batches. Firestore TTL is enabled as a backstop rather than the user-visible expiry mechanism.

**Rationale**: Firestore TTL is not instantaneous; Firebase states that expired data is typically deleted within 24 hours after expiry, with unordered/nontransactional cleanup. It therefore cannot satisfy the exact product visibility boundary by itself. Minutely cleanup provides prompt permanent deletion, while the UI/rules boundary satisfies SC-006 even before the physical delete completes. See [Firestore TTL behavior](https://firebase.google.com/docs/firestore/ttl), [scheduled Functions](https://firebase.google.com/docs/functions/schedule-functions), and [rules are not filters](https://firebase.google.com/docs/firestore/security/rules-query).

**Alternatives considered**:

- Firestore TTL alone: rejected because its deletion delay is too broad for the specified boundary.
- One scheduled Cloud Task per message: rejected because it adds per-message infrastructure and still cannot promise exact distributed execution time.
- Archive expired messages: rejected by the clarification requiring permanent deletion.

## Decision 7: Minimize Text Retention in Command Records

**Decision**: A pending command temporarily contains the proposed text. On every terminal success or failure, trusted processing removes the text payload and stores only sanitized status, result/error metadata, and deletion time. Pending commands also carry a 24-hour deletion deadline and are included in scheduled/TTL cleanup.

**Rationale**: Leaving accepted or rejected text in command documents would bypass the 24-hour message policy even if `chat_messages` were deleted. Scrubbing terminal payloads reduces privacy exposure immediately and keeps retry text only in the acting client's local UI state.

**Alternatives considered**:

- Retain command payloads indefinitely for diagnostics: rejected because it duplicates private message content outside message retention.
- Let the client delete commands: rejected because clients must not mutate audit/processing state.
- Store only a content hash in the request: rejected because trusted processing still needs the original proposed text to create the message.

## Decision 8: Layer Rules with Trusted Revalidation and Extend Outing Deletion

**Decision**: Security Rules require authenticated current crew membership plus the deterministic current outing-participant record for message reads, command creation, and personal read-state access. Messages and rate buckets reject all client writes; commands are client-create-only and requester-readable; read states are owner-only. Functions repeat every check because Admin SDK writes bypass rules. The existing outing deletion service marks `deletionPending`, terminates chat commands, deletes all chat-owned records, deletes the outing, and performs a second ownership sweep.

**Rationale**: Rules are an initial boundary, not a substitute for trusted validation. Mark-first plus transactional outing rereads prevents a concurrent send from recreating data after removal. Deleting a parent document does not cascade to other collections or subcollections. See [Security Rules conditions and server clients](https://firebase.google.com/docs/firestore/security/rules-conditions), [rules query behavior](https://firebase.google.com/docs/firestore/security/rules-query), and [Firestore deletion behavior](https://firebase.google.com/docs/firestore/manage-data/delete-data).

**Alternatives considered**:

- Crew membership without outing participation: rejected because chat is outing-specific and the specification requires both.
- Attendance-status authorization: rejected because Invited, Accepted, and Declined participants all retain chat access.
- Client-side cascade deletion: rejected because it is interruptible, bypassable, and cannot coordinate in-flight Functions.

## Decision 9: Avoid New Client Dependencies and Require Layered Validation

**Decision**: Reuse current FlutterFire, Bloc, routing, DI, and Functions packages. Add `/outings/:outingId/chat`, integrate an unread badge/action into the shared interactive outing card, and test domain/data/presentation layers plus Functions, Rules, and emulator integration. Do not make App Check a correctness dependency because Windows lacks an equivalent supported Flutter path; Auth, Rules, and trusted validation remain mandatory.

**Rationale**: The feature needs no attachments, connectivity plugin, callable plugin, or notification transport. Existing dependencies already support snapshots, transactions, count queries, state management, and routing. App Check can be considered later as defense in depth on supported platforms. See [App Check overview](https://firebase.google.com/docs/app-check) and [Firebase Flutter platform support](https://firebase.google.com/docs/flutter/setup).

**Alternatives considered**:

- Add a connectivity plugin: rejected because network presence cannot prove Firestore reachability and transactions already provide the required failure behavior.
- Add write-time unread fan-out or push notifications: rejected because notifications belong to Phase 7.
- Make App Check mandatory with a Windows exemption: rejected because correctness must remain consistent across all four targets.

## Decision 10: Synchronize Expiry Against Trusted Server Time

**Decision**: On chat entry/reconnect and periodically while chat remains active, create an owner-private `chat_time_probes` document through an online transaction with `requestedAt` set by server timestamp. After the committed value returns, calculate a session clock offset using monotonic round-trip timing. All expiry cutoffs, queries, timers, and unread calculations use the resulting `ChatClock` abstraction. Delete the probe immediately; scheduled cleanup removes abandoned probes.

**Rationale**: The specification explicitly requires retention and ordering to remain correct when device time is wrong. `expiresAt` is authoritative, but comparing it to an untrusted device wall clock would still violate that edge case. A small Firestore probe reuses the existing cross-platform dependency, fails offline, contains no chat content, and keeps domain code testable with an injected clock.

**Alternatives considered**:

- Use `DateTime.now()` directly: rejected because device clock changes could reveal expired messages or hide valid ones early.
- Infer current time from the newest message: rejected because its acceptance time may be hours old.
- Add a separate time HTTP service: rejected because it creates another platform/auth/network path for a value Firestore can provide.

## Decision 11: Define the Text Limit as Unicode Scalar Values

**Decision**: Interpret the 1-2,000 character limit as Unicode scalar values after Unicode whitespace trimming. Dart validates with rune/code-point iteration and trusted TypeScript validates with code-point iteration. Security Rules provide a preliminary string/nonempty/size ceiling, while the trusted Function remains authoritative for exact Unicode normalization. Line breaks, emoji, links, and right-to-left text remain ordinary text.

**Rationale**: Native UTF-16 string lengths can count a supplementary emoji as two code units and produce different limits across clients and Functions. A code-point definition is testable across the authoritative layers without a new grapheme-segmentation dependency. The Rules language documents character sizing and trimming for its preliminary guard. See [Firebase Rules String reference](https://firebase.google.com/docs/reference/rules/rules.String).

**Alternatives considered**:

- UTF-16 code units: rejected because user-visible behavior differs for supplementary characters and is easy to implement inconsistently.
- UTF-8 bytes: rejected because non-ASCII messages would receive a much smaller effective limit.
- Grapheme clusters: user-friendly but rejected for Phase 5 because consistent cross-language segmentation would add dependency/version complexity beyond a plain-text MVP.
