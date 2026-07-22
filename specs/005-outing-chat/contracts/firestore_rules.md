# Contract: Firestore Security Rules for Outing Chat

Security Rules are the client-access boundary. Trusted Admin SDK Functions bypass Rules and must repeat every authorization and invariant check.

## Shared Eligibility Helpers

Rules add predictable-path helpers that require:

- authentication;
- existing `/outings/{outingId}` with matching crew and no deletion-pending state;
- existing `/crew_memberships/{crewId}_{request.auth.uid}`;
- existing `/outing_participants/{outingId}_{request.auth.uid}`.

Attendance response is intentionally not checked. Query shapes are outing-scoped and bounded; rules are not filters, so supported clients must query only authorized outing records and apply the trusted expiry cutoff defined by the repository contract.

## `chat_messages`

- `get` requires current chat eligibility and `expiresAt > request.time`.
- `list` and aggregation queries require current chat eligibility, the owning outing, declared accepted-time/document-ID ordering, and bounded query shapes. Ordinary history pages use a limit no greater than 50; bounded unread count aggregations may cover no more than the feature maximum of 5,000 available messages.
- Because Rules evaluate a query's potential result set, list authorization does not claim to compare each candidate document with a moving `request.time` boundary. Supported clients must use the server-synchronized cutoff and exact domain expiry policy, while scheduled cleanup permanently removes expired records.
- The `get`/`list` split, trusted-clock drift, long-lived listener behavior, and expiry boundary must pass the blocking emulator proof before direct client history implementation proceeds. Failure of that proof requires a trusted provider-neutral read boundary and a plan revision.
- All client create, update, and delete operations are denied.
- Author display fields are immutable trusted snapshots and remain within the constitution's allowed profile shape.

## `chat_commands`

- Create requires an authenticated current participant and crew member, an outing in Draft/Planning/Confirmed/Meeting, and `deletionPending != true`.
- `requestedByUserId` equals `request.auth.uid`; claimed `crewId` matches the authoritative outing.
- Type is exactly `send_message`; top-level and payload keys/types are allowlisted.
- Text must be a nonempty string inside a conservative Rules size ceiling. Trusted processing remains authoritative for Unicode-whitespace trimming and the exact 1-2,000 Unicode scalar-value limit.
- Status is exactly `pending` and `createdAt` is constrained to request time. Trusted processing adds the terminal deletion timestamp; abandoned pending commands are removed by scheduled age-based cleanup.
- Only the requester may get/list their commands.
- All client updates and deletes are denied; terminal fields and payload scrubbing are trusted writes.

## `chat_read_states`

- Document ID is exactly `${outingId}_${request.auth.uid}`.
- Only the state owner may get/list/create/update the document, while continuing to satisfy chat eligibility.
- Identity fields are immutable; the read cursor may only move forward in `(acceptedAt, messageId)` order.
- The cursor values must match a currently readable message in the same outing and crew at write time.
- `updatedAt` is constrained to request time.
- Client delete is denied; scheduled/trusted cleanup removes expired cursors and outing deletion removes all states.
- No participant, organizer, or crew owner may read another participant's state.

## `chat_rate_limits`

- All client reads, creates, updates, and deletes are denied.
- Only trusted processing may create/prune buckets.

## `chat_time_probes`

- Create requires exact keys, `userId == request.auth.uid`, deterministic owner-prefixed document ID, and `requestedAt == request.time`.
- Only the owner may get or delete the probe.
- List and update are denied.
- Probes contain no chat content and are cleaned immediately by the client or after 10 minutes by trusted cleanup.

## Existing Collections

- `outings` continues to deny direct client deletion and protects `deletionPending` from ordinary edits.
- `outing_participants` and `crew_memberships` remain the authoritative predictable-path eligibility sources.
- Existing agreement privacy and command rules remain unchanged.

## Required Emulator Tests

- Current participants in the owning crew can read unexpired messages; attendance status does not alter access.
- Non-participants, former participants, other crews, and unauthenticated users cannot get/list messages or infer protected metadata.
- Message client writes always fail.
- Completed, Archived, and Cancelled outings reject command creation but still allow eligible reads of unexpired history.
- Draft, Planning, Confirmed, and Meeting allow exact-shape pending command creation.
- Offline behavior is tested in repository/transaction tests; ordinary direct command writes with invalid shape/status fail.
- Command update/delete fails, and only requester reads succeed.
- Read-state owner create/advance succeeds; backward, cross-user, invalid-message, and identity-changing writes fail.
- Rate-limit documents are inaccessible to all clients.
- Expired direct gets and eligible list queries fail/omit content as designed.
- Bounded query requirements reject unscoped or over-limit message queries.
- Time probes are owner-private, exact-shape, non-listable, and cannot be forged with another timestamp.
- Batched outing/participant/membership changes cannot preserve chat access.
- `deletionPending` prevents new commands and direct outing deletion remains denied.
