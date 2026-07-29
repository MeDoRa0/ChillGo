# Contract: Live Meetup Cleanup and Privacy Transitions

Privacy transitions make temporary status, sharing, and location data inaccessible at cleanup start and physically absent before an eligibility or terminal outing change is acknowledged. Asynchronous cleanup remains recovery-only.

## Immediate Authorization Boundary

At the first Rules evaluation after any of these changes, protected reads/writes fail:

- outing leaves Meeting;
- outing has `liveMeetupCleanupPending == true`;
- outing becomes `deletionPending` or absent;
- owning crew becomes `deletionPending` or absent;
- participant has `liveMeetupCleanupPending == true`;
- participant attendance is no longer Accepted;
- participant record is removed;
- crew membership has `liveMeetupCleanupPending == true`;
- crew membership is removed.

Supported clients watch the required access records and clear protected in-memory state within one second after observing loss or any permission denial.

## Authoritative Privacy Transition

Requester-private `live_meetup_transitions` cover:

- `end_outing`: move a Meeting outing to an allowed terminal status;
- `change_attendance`: change the requesting participant from Accepted to Declined only after deleting that participant's protected presence;
- `remove_participant`: remove one outing participant;
- `remove_membership`: remove one crew membership and its outing participation;
- `delete_crew`: remove a crew and all owned outings through their existing deletion cascades.

Trusted processing is resumable and follows this order:

1. Revalidate requester authority and target state.
2. Set `liveMeetupCleanupPending == true` on authoritative outing, participant, or membership targets. Crew deletion sets the crew's existing `deletionPending` boundary and marks its outings cleanup-pending. Rules immediately deny affected Live Meetup access and commands.
3. Persist transition phase/cursor progress.
4. Delete affected `live_meetup_statuses`, `live_meetup_shares`, and `live_locations` in bounded batches.
5. Re-query every affected protected collection and require an empty result.
6. Apply the requested terminal status or Declined attendance response, or delete the participant/membership/crew-owned records.
7. Mark the transition command successful only after step 6 commits.

If processing fails after step 2, the pending flag remains, access stays denied, and the transition is not reported successful. Duplicate trigger delivery, explicit retry, or scheduled repair resumes the recorded phase/cursor. Trusted live-meetup command processing rejects all operations whose authoritative records are cleanup-pending, so concurrent or delayed commands cannot recreate data.

The existing Outing, Agreement, and Crew repositories MUST use this service instead of direct client mutation whenever an operation can end Meeting access or participant/crew eligibility. Both existing attendance-response entry points MUST route an Accepted-to-Declined response through `change_attendance`; a response that does not revoke existing eligibility may use its existing path.

## Event-Driven Recovery Cleanup

Idempotent v2 triggers handle:

- unexpected outing status/deletion-pending changes: delete all outing status/share/location documents when Meeting ends;
- unexpected participant delete or attendance change away from Accepted: delete that participant's status/share/location;
- unexpected crew-membership delete: query current outings for that crew as needed and delete the user's Phase 6 temporary records;
- agreement/location-finalization change: delete a meetup point whose `locationTextSnapshot` no longer matches.

These triggers cover administrative or legacy bypasses but do not make such bypasses compliant with delete-before-acknowledgment. Event ordering is untrusted. Each cleanup re-reads authoritative records or safely deletes by deterministic path/query and never recreates state.

## Scheduled Repair Cleanup

A one-minute scheduled Function deletes in bounded batches:

- `live_locations` with `expiresAt <= now`;
- `live_meetup_commands` with `purgeAt <= now`;
- nonterminal `live_meetup_transitions` whose processing lease expired;
- time probes older than ten minutes;
- status/share/location records for terminal/non-Meeting outings found by bounded repair scans;
- records and transitions identified by retry markers from failed cleanup.

Each target logs collection, count, latency, and safe error code only.

## TTL Backstop

TTL field policies:

- `live_locations.expiresAt`
- `live_meetup_commands.purgeAt`
- `live_meetup_transitions.purgeAt` for terminal transition records only

TTL is not a visibility or transition-completion mechanism because deletion is delayed and unordered. It only removes expired locations or terminal command records missed by normal cleanup.

## Outing Deletion Cascade

Extend `OutingDeletionService` to:

1. Mark the outing `deletionPending`.
2. Terminate/scrub pending Live Meetup commands and incompatible privacy transitions.
3. Delete `live_meetup_statuses`, `live_meetup_shares`, `live_locations`, and `meetup_points` by `outingId`.
4. Delete the outing.
5. Repeat command termination and owned-record sweep.

The existing delete-outing command is not marked successful until the cascade finishes. The owned-collection list remains explicit and covered by tests.

## Completion/Overlap Semantics

- Missing documents are success.
- Duplicate scheduler/event invocations are success.
- Duplicate privacy-transition delivery resumes or returns the prior terminal result.
- Stop concurrent with cleanup is success.
- A delayed publish command after cleanup fails lifecycle/eligibility revalidation.
- A delayed meetup-point command after outing deletion cannot recreate the outing or point.
- Cleanup failures remain pending/inaccessible and are retried without falsely acknowledging the underlying transition.

## Physical Deletion Targets

- Expired locations: first successful minutely invocation after expiry.
- Eligibility/Meeting loss, including Accepted-attendance loss: all affected status/share/location records are verified absent before the authoritative transition is finalized or acknowledged.
- Failed in-progress privacy transition: inaccessible immediately; resumable repair continues until deletion verification and finalization succeed.
- Terminal commands: within ten minutes.
- Terminal transition records: within ten minutes after their result is observed or their bounded purge deadline.
- Abandoned location commands: within two minutes.
- Abandoned probes: within ten minutes.
- Meetup point: persists with outing unless invalidated by location change; deleted with permanent outing removal.
