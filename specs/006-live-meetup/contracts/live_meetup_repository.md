# Contract: Live Meetup Repository

`LiveMeetupRepository` is the provider-neutral boundary consumed by Phase 6 Cubits.

## Read Operations

### `watchMeetup(outingId)`

Returns a stream of `LiveMeetupSnapshot`.

- Emits only while the acting user is eligible and the outing is Meeting.
- Joins the authoritative outing, Accepted participant roster, current statuses, fresh locations, and optional meetup point.
- Returns at most one status/location per attendee.
- Uses `TrustedClock` to remove a location exactly at `expiresAt`, including while no Firestore snapshot changes.
- Clears cached protected data and emits an access failure within one second after an observed lifecycle/attendance/participation/membership loss or any permission denial.
- Never emits raw Firestore, map-provider, or device-location types.

### `watchMeetupPointPreparation(outingId)`

- Available only to an outing creator who remains a current crew member or the current crew owner while Confirmed or Meeting, regardless of that organizer's attendance response.
- Returns free-text location plus the optional exact point.
- Never reads attendee status, sharing, or location collections in Confirmed.

## Command Operations

Every operation creates a new high-entropy command ID in an online Firestore transaction. No method automatically retries.

### `setStatus(outingId, value)`

- Accepts exactly the three domain status values.
- Completes only after the command is terminal.
- A superseded command returns a non-error result indicating it did not replace newer state.

### `startSharing(outingId, localSession, transferExisting)`

- `localSession` is generated in memory before submission.
- If another active session exists and `transferExisting == false`, returns `transferRequired`.
- On success, the repository retains the local secret only in the process-scoped sharing coordinator.
- No persistent preference or database cache stores the secret.

### `publishLocation(outingId, localSession, sample)`

- Enforces the 15-second cadence and 30-second monotonic sample-age ceiling locally before submission.
- Completes only after trusted validation.
- `sessionTransferred`, `sessionStopped`, or `accessDenied` immediately clears local sharing capability and cancels the device stream.
- Failures are not automatically retried.

### `stopSharing(outingId, localSession)`

- Uses the matching process secret.
- Success means the trusted transaction marked the control inactive and deleted the current point.
- Repeating stop after the same session is already inactive is an idempotent success.
- A stop from a transferred old session cannot stop the replacement session.

### `setMeetupPoint(outingId, point, confirmedLocationText)`

- Requires creator/crew-owner preparation access.
- The confirmation text must equal the current finalized outing location.
- Completes only after trusted state replaces the previous point.

## Local Sharing Coordinator

The coordinator:

- owns one active local session at a time per outing;
- creates a random process/session ID and secret with a cryptographically secure generator;
- never persists those values;
- owns `AppLifecycleListener`;
- starts the position stream only while `resumed`;
- cancels it on `inactive`, `hidden`, `paused`, or `detached`;
- may resume in the same process when the local session remains valid;
- clears the session on accepted stop/transfer-away/access loss/process detach;
- never starts on app launch from backend share metadata.

## Failure Contract

Stable failures:

- `unauthenticated`
- `permissionDenied`
- `notFound`
- `wrongOutingState`
- `attendanceRequired`
- `outingDeleting`
- `invalidStatus`
- `invalidLocation`
- `staleLocation`
- `locationPermissionDenied`
- `locationPermissionDeniedForever`
- `locationServiceDisabled`
- `locationUnavailable`
- `transferRequired`
- `sessionTransferred`
- `sessionStopped`
- `mapServiceUnavailable`
- `offline`
- `serviceUnavailable`

Failures contain safe acting-user guidance and never reveal whether another participant is sharing, their coordinates, or another device's identity.

## `LiveMeetupTransitionService`

This provider-neutral service is injected into existing Outing, Agreement, and Crew repositories for operations that can end live-meetup eligibility:

- `endOuting(outingId, targetTerminalStatus)`
- `declineAttendance(outingId)`
- `removeParticipant(outingId, targetUserId)`
- `removeMembership(crewId, targetUserId)`
- `deleteCrew(crewId)`

Each method creates one requester-private online transition command and completes only when trusted processing reports a terminal result. `declineAttendance` is required when the acting participant changes from Accepted to Declined; both existing attendance-response repository entry points use it for that eligibility-revoking case. The backend transport remains `change_attendance` with `targetAttendanceStatus == declined`. Success means access was denied, all affected status/share/location records were verified absent, and the requested authoritative transition was finalized. Offline attempts fail without queued mutation. A timeout or recoverable service error does not claim that the underlying transition completed; cleanup-pending state remains inaccessible and trusted repair may resume it.
