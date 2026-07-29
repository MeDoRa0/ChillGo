# Data Model: Live Meetup

This document defines Phase 6 entities, Firestore paths, privacy, ordering, expiry, and lifecycle behavior.

## 1. Live Meetup Space (Logical)

Each outing has one logical Live Meetup identified by its existing `outingId`; no channel document is required.

Protected attendee summary, status, sharing, and location access requires:

1. Authenticated user.
2. Existing owning crew with `deletionPending != true`.
3. Existing outing with `deletionPending != true`, `liveMeetupCleanupPending != true`, and `status == meeting`.
4. Existing `/crew_memberships/{crewId}_{userId}` for the outing's crew with `liveMeetupCleanupPending != true`.
5. Existing `/outing_participants/{outingId}_{userId}` with `attendanceStatus == accepted` and `liveMeetupCleanupPending != true`.

Meetup-point preparation is separate: in Confirmed or Meeting, only an outing creator who remains a current crew member or the current crew owner may read/set it, regardless of that organizer's attendance response. During Meeting, other eligible attendees may read it.

## 2. Live Meetup Status

- **Path**: `/live_meetup_statuses/{outingId}_{userId}`

| Field | Type | Rules |
|---|---|---|
| `outingId` | String | Existing authoritative outing; immutable |
| `crewId` | String | Must equal outing crew; immutable |
| `userId` | String | Eligible participant; immutable |
| `value` | String | `getting_ready`, `on_my_way`, or `arrived` |
| `acceptedAt` | Timestamp | Rules-validated command creation time |
| `acceptedCommandId` | String | Tie-breaker/idempotency identity |

Trusted processing creates or replaces the deterministic document only when `(acceptedAt, acceptedCommandId)` is newer than the stored tuple. There is no status-history collection. All client writes are denied.

## 3. Live Location Share Control

- **Path**: `/live_meetup_shares/{outingId}_{userId}`
- **Client access**: denied for all reads and writes

| Field | Type | Rules |
|---|---|---|
| `outingId` | String | Owning outing |
| `crewId` | String | Owning crew |
| `userId` | String | Sharing participant |
| `active` | Boolean | Whether a session credential may publish |
| `sessionId` | String (nullable) | High-entropy process session ID |
| `sessionTokenHash` | String (nullable) | SHA-256 of process-memory secret |
| `deviceSessionHash` | String (nullable) | Non-public diagnostic equality value; never a stable hardware ID |
| `startedAt` | Timestamp (nullable) | Latest accepted start/transfer |
| `stoppedAt` | Timestamp (nullable) | Latest accepted stop |
| `lastControlAt` | Timestamp | Latest start/transfer/stop ordering timestamp |
| `lastControlCommandId` | String | Ordering tie-breaker |

Start creates an active state if none is active. If another session is active, `transferExisting == true` is required. Transfer atomically changes the session/token hashes and deletes the current location. Stop succeeds only for the matching active session, marks the control inactive, removes token/session fields, and deletes the location. Older control commands become `superseded`.

The raw token is never stored after terminal command scrubbing and is never persisted by Flutter. Closing the application loses it; reopening requires an explicit new start/transfer.

## 4. Live Location

- **Path**: `/live_locations/{outingId}_{userId}`

| Field | Type | Rules |
|---|---|---|
| `outingId` | String | Owning outing; immutable |
| `crewId` | String | Owning crew; immutable |
| `userId` | String | Eligible sharing participant; immutable |
| `point` | GeoPoint | Finite latitude/longitude inside valid ranges |
| `accuracyMeters` | Number | Finite, `0..5000` |
| `acceptedAt` | Timestamp | Trusted command `createdAt` |
| `acceptedCommandId` | String | Ordering tie-breaker |
| `expiresAt` | Timestamp | Exactly `acceptedAt + 2 minutes`; TTL-enabled |

One trusted transaction validates eligibility and the active session hash, rejects stale samples, compares the ordering tuple, and creates/replaces this document. The transaction never writes a route or previous point.

Supported clients query by `outingId`, use the trusted clock, and exclude a point when `trustedNow >= expiresAt`. Domain timers remove it at the exact boundary while a listener is open. Direct gets are denied after `request.time`; minutely cleanup and TTL remove the physical record.

## 5. Meetup Point

- **Path**: `/meetup_points/{outingId}`

| Field | Type | Rules |
|---|---|---|
| `outingId` | String | Matches document ID |
| `crewId` | String | Authoritative outing crew |
| `point` | GeoPoint | Valid selected coordinate |
| `locationTextSnapshot` | String | Exact finalized outing location text confirmed by setter |
| `setByUserId` | String | Outing creator who remains a current crew member, or current crew owner |
| `acceptedAt` | Timestamp | Trusted command creation time |
| `acceptedCommandId` | String | Ordering tie-breaker |

Trusted processing accepts changes only while the outing is Confirmed or Meeting, the location text is nonempty/finalized, and the actor is either the outing creator with a current crew membership or the current crew owner. Attendance does not affect this preparation authority. The command must repeat `locationTextSnapshot`; a mismatch fails rather than silently relating the point to changed text.

The point is persistent outing data, not participant presence. It is removed when the outing is permanently deleted. If agreement processing changes/reopens the finalized location, it deletes the stale point in the same trusted workflow or marks it unreadable until removed.

## 6. Live Meetup Command

- **Path**: `/live_meetup_commands/{commandId}`

Common client-created fields:

| Field | Type | Rules |
|---|---|---|
| `type` | String | Allowed command type |
| `outingId` | String | Target outing |
| `crewId` | String | Must match authoritative outing |
| `requestedByUserId` | String | Must equal authenticated UID |
| `payload` | Map | Exact allowlisted shape for type |
| `status` | String | Exactly `pending` |
| `createdAt` | Timestamp | Exactly `request.time`; operation ordering time |
| `purgeAt` | Timestamp | Exact bounded pending cleanup time for type; TTL-enabled |

Command payloads:

- `set_status`: `{value}`
- `start_sharing`: `{sessionId, sessionToken, deviceSessionId, transferExisting}`
- `publish_location`: `{sessionId, sessionToken, latitude, longitude, accuracyMeters, sampleAgeMillis}`
- `stop_sharing`: `{sessionId, sessionToken}`
- `set_meetup_point`: `{latitude, longitude, locationTextSnapshot}`

Trusted terminal fields:

| Field | Type | Description |
|---|---|---|
| `status` | String | `processing`, `succeeded`, `failed`, or `superseded` |
| `processingEventId` | String (nullable) | Trigger delivery claim |
| `processedAt` | Timestamp | Trusted completion time |
| `result` | Map (nullable) | Safe acting-user result without secrets/coordinates |
| `errorCode` | String (nullable) | Stable non-sensitive failure code |
| `errorMessage` | String (nullable) | Actionable user message |
| `purgeAt` | Timestamp | Shortened terminal cleanup deadline |

On every terminal outcome trusted processing deletes `payload` and any processing claim. Clients can `get` only their own exact known command. Listing, updating, and deleting commands are denied so another signed-in device cannot discover a newly transferred session token.

`publish_location` pending commands expire after two minutes. Other pending commands expire within one hour. Terminal commands expire within ten minutes.

## 7. Live Meetup Time Probe

- **Path**: `/live_meetup_time_probes/{userId}_{probeId}`

| Field | Type | Rules |
|---|---|---|
| `userId` | String | Authenticated owner |
| `requestedAt` | Timestamp | Exactly `request.time`; TTL/cleanup field |

The client creates the probe through an online transaction, reads the committed server timestamp, computes an offset using monotonic round-trip timing, and deletes it. Only exact owner get/create/delete is allowed; list/update are denied. Abandoned probes are removed after ten minutes.

## 8. Local Sharing Session (Process Memory Only)

| Field | Type | Description |
|---|---|---|
| `outingId` | String | Consented outing |
| `sessionId` | String | High-entropy ID |
| `sessionToken` | Secret string | Proves publication/stop capability |
| `deviceSessionId` | String | Random per application process; not hardware identity |
| `startedAt` | Trusted time | Accepted start/transfer |
| `lifecycleState` | Enum | Current Flutter lifecycle |
| `lastPublishMonotonic` | Duration | Cadence gate without wall clock |

This object is never serialized. Non-resumed lifecycle states cancel the location stream. A resumed state may restart only while this object remains present. Process restart removes it.

## 9. Domain Aggregate

`LiveMeetupSnapshot` contains:

- authoritative outing/eligibility state;
- confirmed free-text location;
- optional meetup point;
- all Accepted attendees;
- at most one current status per attendee;
- at most one fresh location per attendee;
- acting participant's local sharing state and command outcome.

The repository joins participant/status/location streams by `userId`, discards orphaned or mismatched records, sorts attendees deterministically by normalized display name then user ID, and emits no protected aggregate after access loss.

## 10. Live Meetup Privacy Transition

- **Path**: `/live_meetup_transitions/{transitionId}`
- **Purpose**: requester-private, resumable coordination for destructive lifecycle and eligibility changes that must delete protected presence before success

Client-created fields:

| Field | Type | Rules |
|---|---|---|
| `type` | String | `end_outing`, `change_attendance`, `remove_participant`, `remove_membership`, or `delete_crew` |
| `outingId` | String (nullable) | Required for outing/participant operations |
| `crewId` | String | Authoritative owning crew |
| `targetUserId` | String (nullable) | Required for participant/membership removal |
| `targetOutingStatus` | String (nullable) | Allowed terminal status for `end_outing` |
| `targetAttendanceStatus` | String (nullable) | Exactly `declined`; required for `change_attendance` |
| `requestedByUserId` | String | Authenticated requester |
| `status` | String | Exactly `pending` at creation |
| `createdAt` | Timestamp | Exactly `request.time` |
| `purgeAt` | Timestamp | Bounded pending retention; TTL-enabled after terminal processing |

Trusted progress fields:

| Field | Type | Description |
|---|---|---|
| `status` | String | `pending`, `processing`, `succeeded`, or `failed` |
| `phase` | String | `authorize`, `deny_access`, `delete_presence`, `verify_empty`, or `finalize` |
| `cursor` | String (nullable) | Opaque bounded-batch resume cursor |
| `processingEventId` | String (nullable) | Trigger delivery claim |
| `processedAt` | Timestamp (nullable) | Trusted terminal time |
| `result` / `errorCode` | Map/String (nullable) | Requester-safe terminal outcome |
| `purgeAt` | Timestamp | Short bounded terminal retention; TTL-enabled |

The coordinator sets `liveMeetupCleanupPending == true` on affected outing, participant, or membership records; crew deletion uses the crew's existing `deletionPending` boundary and marks its outings pending before sweeping them. Rules deny live access whenever any applicable flag is true. The coordinator deletes status/share/location records in bounded batches, re-queries to prove the protected sets are empty, then applies the requested terminal outing status, Declined attendance response, or participant/membership/crew deletion. It marks the transition successful only after finalization. Failure leaves the pending flags and progress record in place so a retry or scheduled repair can resume without reopening access.

## Relationships

```text
Crew 1 --- * Outing 1 --- 1 LogicalLiveMeetup
                  |             |--- * LiveMeetupStatus (one per eligible attendee)
                  |             |--- * LiveMeetupShare (trusted control, one per attendee)
                  |             |--- * LiveLocation (latest only, max two minutes)
                  |             |--- 0..1 MeetupPoint
                  |             `--- * LiveMeetupCommand (short-lived)
                  `--- * OutingParticipant

User 1 --- * LiveMeetupStatus
User 1 --- * LiveMeetupShare
User 1 --- * LiveLocation
```

## State Transitions

### Feature Availability

```text
Confirmed + authorized current organizer -> meetup-point preparation only
Meeting + eligible Accepted    -> summary/status/location/map access
Any other state                -> unavailable
Outing/participant/membership cleanup pending -> unavailable
Outing absent/deletionPending                 -> unavailable
```

### Sharing Control

```text
Inactive --explicit start--------------------> Active(session A)
Active(A) --explicit transfer----------------> Active(session B), point deleted
Active(A) --matching explicit stop-----------> Inactive, point deleted
Active(A) --old/unmatched update or stop------> Rejected
Any state --cleanup-pending transition--------> Inaccessible
Inaccessible --presence deleted/finalized----> Eligibility/Meeting loss acknowledged
```

### Application Lifecycle

```text
Active + resumed -> position stream running
Active + non-resumed -> stream cancelled; last point ages normally
Same process resumes -> stream may restart with same secret
Process detached/closed -> secret lost; later process requires explicit start
```

### Live Location

```text
Absent --accepted matching-session update--> Fresh point
Fresh --newer accepted update-------------> Replaced point
Fresh --stop/transfer----------------------> Deleted
Fresh --expiresAt boundary-----------------> Product-inaccessible
Product-inaccessible --cleanup/TTL---------> Physically deleted
Any state --cleanup-pending transition-----> Inaccessible
Inaccessible --presence deletion verified--> Physically deleted, transition finalizable
```

## Command Transaction Rules

1. Claim command by trigger event ID; terminal duplicates are no-ops.
2. Re-read outing, crew membership, participant, attendance, `deletionPending`, and every `liveMeetupCleanupPending` flag.
3. Validate exact command schema and safe sample bounds.
4. Compare `(createdAt, commandId)` with the entity/control watermark.
5. For start/transfer/update/stop, hash and compare the process secret without logging it.
6. Apply all state changes and required point deletion atomically.
7. Scrub payload and write a terminal safe result in the same transaction when possible.
8. Treat a duplicate or older operation as idempotent/superseded, never as permission to recreate data.

## Query and Index Shapes

- Attendee roster: existing `outing_participants` query by `outingId`, bounded to 100.
- Status summary: `live_meetup_statuses where outingId == X`, bounded to 100.
- Fresh locations: `live_locations where outingId == X`, bounded to 100; repository applies exact trusted-time expiry.
- Meetup point: deterministic document get.
- Command observation: deterministic document get only; list denied.
- Expiry cleanup: `live_locations where expiresAt <= now`.
- Command cleanup: `live_meetup_commands where purgeAt <= now`.
- Probe cleanup: `live_meetup_time_probes where requestedAt <= now - 10 minutes`.
- Transition repair: `live_meetup_transitions` by nonterminal status/phase and bounded cursor.
- Outing cascade: `outingId == X` across every Phase 6 collection.

Composite indexes needed for bounded attendee/status/location query shapes, privacy-transition repair, and cleanup are declared in `firestore.indexes.json`. TTL field overrides apply to `live_locations.expiresAt`, `live_meetup_commands.purgeAt`, and `live_meetup_transitions.purgeAt`.
