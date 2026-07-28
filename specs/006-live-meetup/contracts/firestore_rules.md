# Contract: Firestore Security Rules for Live Meetup

Security Rules are the client-access boundary. Trusted Admin SDK Functions bypass Rules and repeat every check.

## Eligibility Helpers

Rules use predictable document paths to require:

- authenticated user;
- existing owning crew with `deletionPending != true`;
- existing outing with matching crew, `deletionPending != true`, and `liveMeetupCleanupPending != true`;
- current `/crew_memberships/{crewId}_{uid}` with `liveMeetupCleanupPending != true`;
- current `/outing_participants/{outingId}_{uid}` with `liveMeetupCleanupPending != true`;
- `attendanceStatus == accepted`;
- `outing.status == meeting`.

Meetup-point preparation uses a separate helper requiring Confirmed or Meeting, a current crew membership, and either `outing.createdByUserId == uid` or the current crew membership role is owner. It does not require Accepted attendance and does not grant participant-data access.

## `live_meetup_statuses`

- Eligible Meeting attendees may get/list statuses for their outing.
- List requires exact `outingId` scope and a limit no greater than 100.
- All client writes are denied.
- Confirmed-only meetup-point preparation does not grant status access.

## `live_locations`

- Eligible Meeting attendees may list an exact outing scope with limit no greater than 100.
- Direct get additionally requires `expiresAt > request.time`.
- List authorization does not claim to enforce a moving per-document expiry boundary; supported clients must use the trusted-clock cutoff and exact domain filter.
- All client writes are denied.
- The direct-get/list split, long-lived listener behavior, device clock drift, and expiry timer must pass a blocking Emulator proof before repository implementation.

## `live_meetup_shares`

- All client reads and writes are denied.
- Session hashes and control watermarks are trusted-only.

## `meetup_points`

- During Meeting, eligible attendees may get the deterministic outing point.
- During Confirmed or Meeting, an outing creator who remains a current crew member or the current crew owner may get it for preparation regardless of attendance.
- List is denied; the document ID is known from the outing.
- All client writes are denied.
- No point access grants status/location/summary access.

## `live_meetup_commands`

- Create requires exact top-level keys and `requestedByUserId == request.auth.uid`.
- `createdAt == request.time`.
- `crewId` matches the authoritative outing.
- Exact type-specific payload keys/types and conservative bounds are enforced.
- `set_status`, start, publish, and stop require Meeting eligibility.
- `set_meetup_point` requires Confirmed/Meeting organizer authority.
- `publish_location` accepts numeric latitude/longitude/accuracy/sample-age bounds but trusted processing remains authoritative.
- Only the requester may get a command by known document ID.
- List, update, and delete are denied.
- `purgeAt` must equal the type-specific bounded deadline from `request.time`.

## `live_meetup_time_probes`

- Create requires exact owner-prefixed document ID, exact keys, `userId == uid`, and `requestedAt == request.time`.
- Owner may get/delete the known probe.
- List and update are denied.

## `live_meetup_transitions`

- Create requires exact top-level keys, `requestedByUserId == request.auth.uid`, `createdAt == request.time`, `status == pending`, and an exact type-specific target shape.
- `end_outing`, participant removal, membership removal, and crew deletion require their existing authoritative organizer/owner permissions.
- `change_attendance` requires the requester to target their own current Accepted participant record and requires `targetAttendanceStatus == declined`.
- Only the requester may get a transition by its known document ID.
- List, update, and delete are denied.
- Only trusted processing may set cleanup-pending flags, progress fields, terminal results, or finalize the underlying lifecycle/eligibility mutation.

## Existing Collections

- `outings` continues to protect `deletionPending`.
- `outing_participants`, `crew_memberships`, and crew-owner role remain authoritative.
- Existing Chat and Agreement privacy rules remain unchanged except where terminal outing commands and Accepted-to-Declined attendance responses delegate to the privacy-transition coordinator.
- Direct client writes that complete a Meeting outing, change Accepted attendance to Declined, remove a current participant, remove a crew membership, or delete a crew are denied; existing repositories route those operations through `live_meetup_transitions`.
- Cleanup-pending outing, participant, membership, or crew records deny Phase 6 access before the coordinator starts physical deletion.

## Required Emulator Tests

- Accepted current participants in the owning crew can read bounded Meeting status/location queries.
- Invited, Declined, removed participants, former crew members, other crews, unauthenticated users, and non-Meeting states cannot read protected data.
- A Confirmed current organizer may get/set via command the meetup point regardless of attendance but cannot read participant live data before Meeting.
- An Invited or Declined current organizer retains only the separate point-preparation access; a former-crew creator has neither preparation nor participant-data access.
- Non-organizers cannot prepare/read a Confirmed point.
- Expired direct location gets fail; supported bounded list plus repository expiry proof never yields expired domain state.
- Unscoped, cross-outing, over-limit, and command list queries fail.
- All status/location/share/point client writes fail.
- Exact-shape valid command creation succeeds; forged actor/crew/time/status/payload/bounds fail.
- Command get is requester-only; list/update/delete fail.
- Time probes are exact-owner, non-listable, and non-forgeable.
- Valid transition creation, including self-targeted Accepted-to-Declined attendance change, is requester-private; forged actor/target/type/time and transition listing fail.
- Direct destructive client mutations that can end eligibility fail.
- Cleanup-pending flags prevent reads, commands, and recreation before deletion/finalization completes.
- `deletionPending` prevents new commands.
