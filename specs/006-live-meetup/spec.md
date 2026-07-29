# Feature Specification: Live Meetup

**Feature Branch**: `codex/006-live-meetup`

**Created**: 2026-07-27

**Status**: Draft

**Input**: User description: "Read `main_plan.md` and create a specification for Phase 6 — Live Meetup."

**Refinement Input**: "Refine Live Meetup to resolve the cleanup-timing, expiry-anchor, and stale-location ambiguities identified by the latest analysis."

## Clarifications

### Session 2026-07-27

- Q: How should location sharing behave when the participant backgrounds or closes ChillGo? → A: Continue while ChillGo is foregrounded on any screen; pause when backgrounded or closed, and let the last point expire within two minutes.
- Q: How should sharing behave when the same participant uses ChillGo on multiple devices? → A: Only one device may share at a time; starting on another device explicitly transfers sharing and stops the previous device.
- Q: When should foreground location updates resume after ChillGo was backgrounded or closed? → A: Resume automatically after temporary backgrounding; require an explicit restart after ChillGo is closed and reopened.
- Q: Which moment starts a live location's two-minute lifetime? → A: The authoritative acceptance time assigned when the online location-update attempt is accepted for processing; later processing, storage, or display MUST NOT extend the lifetime.
- Q: Which location samples are usable? → A: Only samples submitted within 30 seconds of acquisition, with finite latitude from -90 through 90, finite longitude from -180 through 180, and finite accuracy from 0 through 5,000 meters.
- Q: When must temporary live data be deleted after eligibility or the outing lifecycle ends? → A: Deletion is part of the authoritative transition itself; the transition MUST NOT be acknowledged as complete while the affected live status, sharing state, or location remains.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Share Arrival Status (Priority: P1)

An accepted outing participant shares whether they are Getting Ready, On My Way, or Arrived so the attending group can understand everyone's progress without asking for repeated updates.

**Why this priority**: Arrival status provides the core coordination value of Phase 6 even when a participant does not want to share a precise location.

**Independent Test**: Can be fully tested by moving a confirmed outing into Meeting, having accepted participants update their statuses, and verifying that every eligible participant sees one current, correctly attributed status per attendee while ineligible users cannot view or change it.

**Acceptance Scenarios**:

1. **Given** an accepted participant is a current member of the outing's crew and the outing is in Meeting, **When** the participant selects Getting Ready, On My Way, or Arrived, **Then** that selection becomes the participant's one current live status and is visible to other eligible participants with its update time.
2. **Given** a participant already has a live status, **When** the participant selects another valid status, **Then** the new status replaces the previous status without creating a public status history.
3. **Given** two or more attendees update their statuses close together, **When** the meetup view refreshes, **Then** every eligible participant sees the latest accepted status for each attendee.
4. **Given** an outing is not in Meeting, or a user is Invited, Declined, removed from the outing, or no longer a crew member, **When** that user attempts to set a live status, **Then** the update is rejected without changing the attendee summary.
5. **Given** a status update cannot be accepted because the participant is offline or the service is unreachable, **When** the participant submits it, **Then** the participant sees that the update failed and the system does not later apply it automatically without another explicit action.

---

### User Story 2 - Share Live Location Voluntarily (Priority: P2)

An eligible participant explicitly starts sharing their current location with the attending group and can stop at any time, making it easier to coordinate travel while preserving control over precise location data.

**Why this priority**: Live location answers the most time-sensitive meetup question—where attendees currently are—while requiring clear, revocable consent.

**Independent Test**: Can be fully tested by granting and denying location permission, starting and stopping sharing, interrupting updates, and verifying that only fresh locations from consenting eligible participants appear and that no location history is available.

**Acceptance Scenarios**:

1. **Given** an eligible participant has not enabled sharing for the outing, **When** the participant opens Live Meetup, **Then** precise location sharing remains off and no location is disclosed until the participant explicitly starts it.
2. **Given** an eligible participant explicitly starts sharing and location access is available, **When** a fresh location is accepted, **Then** other eligible participants can see that participant's latest location, identity, current live status, and freshness time on the shared map, and its two-minute lifetime begins at the authoritative acceptance time assigned to that online submission.
3. **Given** an eligible participant is sharing, **When** the participant stops sharing, **Then** their location is removed from every supported meetup view promptly and later device movement is not shared.
4. **Given** a participant denies or revokes device location access, **When** they attempt to start or continue sharing, **Then** no new location is disclosed, the participant sees clear corrective guidance, and status sharing remains available.
5. **Given** a sharing device stops providing updates because of lost connectivity, lost permission, application interruption, or device shutdown, **When** its last accepted location reaches the freshness limit, **Then** that location disappears from the active shared map automatically.
6. **Given** a user is not eligible for the live meetup, **When** that user attempts to read or submit a live location, **Then** access is denied without revealing whether another participant is sharing.
7. **Given** a participant is actively sharing, **When** they navigate to another ChillGo screen while the application remains foregrounded, **Then** sharing may continue; when ChillGo is temporarily backgrounded, no new locations are submitted and sharing resumes automatically if the same application session returns to the foreground; when ChillGo is closed, the sharing session ends and reopening requires another explicit start-sharing action.
8. **Given** a participant is actively sharing from one device, **When** the participant explicitly starts sharing from another device, **Then** sharing transfers to the new device, the prior device can no longer submit accepted locations, and the participant still appears as one map sharer.
9. **Given** a device supplies a location sample, **When** more than 30 seconds elapsed before submission or its coordinates or accuracy fall outside the accepted bounds, **Then** the sample is rejected without replacing the participant's last accepted location or extending its expiry.

---

### User Story 3 - Coordinate on a Shared Meetup Map (Priority: P3)

Accepted participants use one shared map to identify the agreed meetup point and the fresh locations and arrival states of attendees who chose to share.

**Why this priority**: A shared visual view turns separate status and location updates into an actionable picture of who is still travelling and where the group is meeting.

**Independent Test**: Can be fully tested by setting a meetup point, displaying multiple active sharers, handling a missing meetup point, and verifying that map details remain understandable across supported screen sizes and input methods.

**Acceptance Scenarios**:

1. **Given** an outing has a confirmed free-text location, **When** the outing creator or crew owner selects an exact meetup point for that location, **Then** eligible participants see the point identified as the meetup destination on the shared map.
2. **Given** a meetup point and one or more fresh participant locations exist, **When** an eligible participant opens the shared map, **Then** the map distinguishes the destination from participant locations and identifies each sharer by display name, avatar when available, live status, and freshness time.
3. **Given** no exact meetup point has been selected, **When** an eligible participant opens Live Meetup, **Then** the confirmed free-text location remains visible, the missing map point is explained, and active participant locations can still be viewed.
4. **Given** a participant location becomes unavailable or expires while the map is open, **When** the view receives the change, **Then** the corresponding participant marker is removed without implying that the participant left the outing.
5. **Given** an outing participant sets Arrived, **When** others view the meetup summary or map, **Then** the participant is clearly identified as Arrived; proximity to the meetup point alone does not change status automatically.
6. **Given** the meetup view is used on Android or iOS, **When** participants use touch or assistive technology appropriate to the platform, **Then** status, sharing controls, participant identities, and map alternatives remain usable.

---

### User Story 4 - End Live Coordination Safely (Priority: P4)

Participants can rely on live meetup access ending and precise temporary data being removed when the outing or their eligibility ends.

**Why this priority**: Location and presence are unusually sensitive. A strict end boundary is necessary for participant trust and the project's temporary-data lifecycle rules.

**Independent Test**: Can be fully tested by completing, cancelling, archiving, or permanently removing an outing and by removing a participant or crew membership while Live Meetup is open, then verifying immediate access loss and permanent cleanup.

**Acceptance Scenarios**:

1. **Given** an outing in Meeting has live statuses, active sharing states, or locations, **When** it moves to Completed, Cancelled, or Archived, **Then** the Live Meetup becomes unavailable immediately, no further updates are accepted, and the transition is not acknowledged as complete until all outing-owned live statuses, sharing states, and locations are permanently deleted.
2. **Given** a participant is removed from the outing, declines before Meeting, leaves the crew, or is removed from the crew, **When** eligibility changes, **Then** that participant immediately loses live meetup access, and the eligibility transition is not acknowledged as complete until their live status, sharing state, and location are permanently deleted.
3. **Given** a participant is viewing Live Meetup when access is lost, **When** the application observes the loss or receives an access denial, **Then** protected status and location data are cleared from the participant's view before any later live meetup state is shown.
4. **Given** the outing creator permanently removes the outing or scheduled outing cleanup removes it, **When** live meetup work is in progress, **Then** all live meetup data is inaccessible and no delayed action can recreate it.
5. **Given** live meetup cleanup is retried or overlaps another cleanup request, **When** processing completes, **Then** no live status or location is restored and users do not receive a failure merely because the data was already absent.

### Edge Cases

- A participant opens Live Meetup just as the outing moves from Confirmed to Meeting; controls become available only after Meeting is authoritative.
- A participant sets a status from two supported devices close together; one latest accepted status is shown consistently and no public history is created.
- A participant transfers sharing to a second device while the first device has an update in flight; the transfer takes precedence, the delayed update from the first device is rejected, and only the second device can provide later accepted points.
- A participant temporarily backgrounds ChillGo while sharing; no background updates are submitted, the last point expires after two minutes if the interruption continues, and sharing resumes automatically only if the same application session returns to the foreground.
- A participant closes ChillGo while sharing; the sharing session ends, the last point expires within two minutes, and reopening ChillGo does not restart location updates without a new explicit start-sharing action.
- Location permission is approximate, unavailable, or temporarily interrupted; the participant is told the accuracy or availability limitation and no false precision is implied.
- A device reports a sample more than 30 seconds after acquisition, a non-finite or out-of-range coordinate, a negative or non-finite accuracy, or accuracy above 5,000 meters; the sample is rejected without replacing the last accepted point or extending its expiry.
- A participant stops sharing while an update is in flight; stopping takes precedence and the delayed update cannot make the participant visible again without fresh explicit consent.
- A location expires while another participant has the map open; the marker is removed at the freshness boundary without requiring a manual refresh.
- The organizer changes the exact meetup point while participants are travelling; eligible participants see the new point clearly, while automatic notifications remain outside Phase 6.
- Several participants occupy the same or nearby coordinates; the view keeps their identities and statuses discoverable without treating them as one attendee.
- No participant shares a location; the meetup summary and status features remain useful and the map can still show the exact meetup point when one exists.
- Device wall-clock time is incorrect; location sample age is measured as elapsed acquisition-to-submission time within the active application session, while freshness, ordering, expiry, and cleanup boundaries use authoritative acceptance and lifecycle times rather than the device wall clock.
- An outing is completed while location updates are in flight; the terminal outing state wins and no later update restores live data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide exactly one Live Meetup space for each outing, associated with that outing and its owning crew.
- **FR-002**: System MUST allow participant status, attendee-summary, and live-location access only while the outing is in Meeting and only to authenticated users who are current outing participants, current members of the outing's crew, and Accepted attendees. The organizer-only meetup-point preparation permitted by FR-018 MUST NOT expose participant live data before Meeting.
- **FR-003**: System MUST prevent users with Invited or Declined attendance, former participants, former crew members, and users from other outings or crews from viewing or changing live statuses, locations, or the attendee summary. The separate meetup-point preparation exception defined by FR-018 is governed by organizer authority rather than attendance, and MUST NOT grant access to participant live data.
- **FR-004**: System MUST support exactly three participant-controlled live statuses: Getting Ready, On My Way, and Arrived.
- **FR-005**: Each eligible participant MUST have at most one current live status per outing, and a successful update MUST replace the previous status without exposing a public status-change history.
- **FR-006**: System MUST allow an eligible participant to correct their current status by selecting any of the three valid statuses while the outing remains in Meeting.
- **FR-007**: Each visible live status MUST identify its participant and authoritative accepted update time.
- **FR-008**: Status and location updates MUST require an online acceptance outcome, MUST show success or failure to the acting participant, and MUST NOT be queued for automatic application after a failed or offline attempt.
- **FR-009**: Precise location sharing MUST be disabled by default for every participant and outing, and MUST begin only after the participant gives an explicit, outing-specific start action.
- **FR-010**: Before location sharing begins, the system MUST explain who can see the location, when it expires, and how the participant can stop sharing.
- **FR-011**: System MUST allow a sharing participant to stop at any time with one clear action, MUST make the participant's last location unavailable to all clients within 5 seconds of an accepted stop, and MUST prevent an in-flight location update from restarting sharing.
- **FR-012**: System MUST keep status sharing usable when a participant chooses not to share location or when device location access is unavailable.
- **FR-013**: System MUST retain and expose no more than the latest accepted live location for one participant in one outing; Phase 6 MUST NOT provide routes travelled, location history, or replay.
- **FR-014**: Each live location MUST identify its participant, outing, owning crew, geographic point, available accuracy information, and authoritative acceptance time. The authoritative acceptance time MUST be the system-assigned time at which the online location-update attempt is accepted for processing; later processing, storage, retry, or display time MUST NOT replace or advance it.
- **FR-015**: A participant's accepted live location MUST expire exactly 2 minutes after the authoritative acceptance time defined by FR-014 unless a fresher eligible update replaces it, and expired locations MUST NOT appear on the active map or remain retrievable through the product.
- **FR-016**: The meetup view MUST communicate each displayed location's freshness and accuracy without presenting an expired, invalid, or unavailable point as current.
- **FR-017**: System MUST allow no more than one active sharing device per participant and outing. Starting from another device MUST require an explicit transfer action, MUST revoke the prior device's ability to submit accepted locations before enabling the new device, and MUST preserve one logical participant identity and at most one visible location.
- **FR-018**: System MUST allow only an outing creator who remains a current member of the outing's crew or the current crew owner to read, set, or change the exact meetup point for preparation, regardless of that organizer's attendance response, and only for a Confirmed or Meeting outing with a finalized free-text location. During Meeting, other eligible attendees may read the point as part of Live Meetup but may not change it.
- **FR-019**: Setting or changing an exact meetup point MUST require an explicit confirmation that identifies the selected point and its relationship to the outing's free-text location.
- **FR-020**: The shared meetup map MUST distinguish the exact meetup point from participant locations and MUST provide each displayed participant's name, avatar when available, current live status when set, and location freshness.
- **FR-021**: When no exact meetup point exists, the system MUST keep the confirmed free-text location visible, explain that no map point is set, and allow otherwise eligible participant location sharing to continue.
- **FR-022**: The Live Meetup summary MUST show every eligible attendee grouped or labeled by current status, including an explicit Not Updated state for attendees who have not shared a live status.
- **FR-023**: System MUST NOT infer or change Getting Ready, On My Way, or Arrived based on distance, motion, location permission, or map position; only the participant's explicit status action may change it.
- **FR-024**: When a participant loses outing participation, Accepted attendance, or crew membership, the system MUST immediately deny new live meetup reads and writes and make that participant's live status, sharing state, and location unavailable. The authoritative eligibility transition MUST permanently delete those records before the transition is acknowledged as complete.
- **FR-025**: After a supported client observes eligibility loss or an access denial, it MUST clear already displayed protected live status and location data within one second and before accepting any later live meetup state.
- **FR-026**: When an outing leaves Meeting for Completed, Cancelled, or Archived, the system MUST immediately make all live statuses, sharing states, and locations unavailable and reject later updates. Permanent deletion of all outing-owned live status, sharing-state, and location records MUST be part of the authoritative lifecycle transition, and the transition MUST NOT be acknowledged as complete while any such record remains.
- **FR-027**: Permanent outing removal and scheduled outing cleanup MUST remove or render inaccessible the exact meetup point and every outing-owned live meetup record, and delayed or in-flight actions MUST NOT recreate the outing or its live data.
- **FR-028**: Live meetup cleanup and stop-sharing operations MUST be safe to repeat and overlap without restoring data or producing a user-visible failure solely because target data is already absent.
- **FR-029**: System MUST present non-sensitive, actionable explanations for missing sign-in, missing eligibility, wrong outing status, location permission denial, stale or invalid location, connection failure, and unavailable live meetup service without revealing protected data.
- **FR-030**: System MUST support status updates, sharing controls, attendee summaries, Google Maps interaction, and a non-map textual alternative consistently on Android and iOS.
- **FR-031**: The non-map alternative MUST expose the meetup location label, whether an exact point is available, each attendee's status, which attendees are actively sharing, and the freshness of shared locations without requiring visual map interpretation.
- **FR-032**: Phase 6 MUST NOT add automatic arrival detection, geofences, turn-by-turn navigation, route sharing, location history, background surveillance after sharing ends, attendee messaging, typing or presence indicators beyond the three live statuses, arrival notifications, general push notifications, or notification preferences.
- **FR-033**: While a participant's explicit share remains active, the system MAY submit fresh locations from any ChillGo screen only while the application is foregrounded. It MUST stop submitting locations while ChillGo is backgrounded, MUST allow the last accepted point to expire under FR-015, and MAY resume automatically only when the same application session returns to the foreground. Closing ChillGo MUST end that sharing session, and a later application session MUST require another explicit start-sharing action before submitting any location.
- **FR-034**: A location sample MUST be rejected unless no more than 30 seconds elapsed between acquisition and online submission, latitude is finite and from -90 through 90 degrees, longitude is finite and from -180 through 180 degrees, and reported accuracy is finite and from 0 through 5,000 meters. Rejecting a sample MUST NOT replace the last accepted location or extend its expiry, and device wall-clock time MUST NOT determine sample age or freshness.

### Key Entities *(include if feature involves data)*

- **Live Meetup Space**: The temporary coordination area owned by one outing and crew. Its availability is governed by the outing's Meeting status and each user's current participation, crew membership, and Accepted attendance.
- **Live Meetup Status**: One participant's latest explicit Getting Ready, On My Way, or Arrived selection for an outing, including participant association and authoritative accepted update time. It has no user-visible history and is temporary.
- **Live Location Share**: A participant's explicit per-outing consent state indicating whether fresh location updates may be accepted. It includes the participant and outing association, active or stopped state, authoritative start or stop time, and the single device currently authorized to provide updates when active.
- **Live Location**: The latest accepted geographic point for one participant in one outing, including available accuracy, the authoritative acceptance time assigned when its online submission was accepted for processing, and an expiration time exactly two minutes later. It replaces prior points and never forms a route history.
- **Meetup Point**: The exact map point selected by the outing creator or crew owner to represent the finalized free-text location. It is distinct from temporary participant locations.
- **Eligible Attendee**: An authenticated current outing participant who remains a current crew member, has Accepted attendance, and is accessing an outing in Meeting.
- **Outing**: The crew event whose lifecycle status, finalized free-text location, participant roster, attendance responses, ownership, and permanent removal govern Live Meetup.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 95% of eligible participants can open Live Meetup and publish a valid arrival status in under 20 seconds without assistance.
- **SC-002**: Under a network profile with round-trip latency no greater than 100 milliseconds and packet loss below 1%, at least 95% of accepted status changes and fresh location updates become visible to another eligible participant with Live Meetup open within 5 seconds, measured across at least 100 updates of each type.
- **SC-003**: In 100% of authorization tests, Invited or Declined attendees, non-participants, former participants, former crew members, and users from other crews cannot read or change protected live status, location, sharing consent, or attendee-summary data. Exact-map-point access MUST follow the separate FR-018 boundary: an authorized current organizer may prepare it in Confirmed or Meeting regardless of attendance, eligible attendees may read it during Meeting, and no such access exposes participant live data.
- **SC-004**: In 100% of consent tests, no precise participant location is disclosed before an explicit start-sharing action, and an accepted stop makes the location unavailable across supported clients within 5 seconds.
- **SC-005**: In 100% of freshness-boundary tests, no participant location is shown or retrievable as active at or after exactly 2 minutes from its authoritative acceptance time, regardless of later processing, retry, storage, or display delays.
- **SC-006**: In 100% of data-lifecycle tests, participant status, sharing state, and location are unavailable at the first authorization evaluation after participant eligibility ends or the outing leaves Meeting, and the authoritative transition is not reported as complete until all affected temporary records are permanently deleted without user action or later data recreation.
- **SC-007**: At least 90% of representative test participants can identify the meetup point, determine who is Getting Ready, On My Way, Arrived, or Not Updated, and stop their own location sharing without assistance.
- **SC-008**: For an outing with 100 eligible attendees and 100 simultaneous fresh location shares, at least 95% of meetup-opening trials show the attendee summary, meetup point state, and current sharer state within 3 seconds under the network conditions defined in SC-002.
- **SC-009**: In 100% of multi-device and concurrent-update tests, each attendee has no more than one visible current status and one visible current location, with no duplicate attendee identities on the shared map.
- **SC-010**: In 100% of accessibility checks, all status and location-sharing actions and all information needed to understand meetup progress are available without relying solely on map color, marker position, touch gestures, or visual interpretation.
- **SC-011**: In 100% of location-boundary tests, samples submitted more than 30 seconds after acquisition, samples with non-finite or out-of-range coordinates, and samples with accuracy outside 0 through 5,000 meters are rejected without replacing the last accepted point or extending its expiry.

### Usability Measurement Protocol

SC-001 and SC-007 MUST be evaluated with at least 20 representative participants who have not previously completed the measured workflow. Results MUST include at least five trials on each supported platform: Android and iOS.

For SC-001, timing begins when the eligible outing entry is visible and ends when the selected status is visibly accepted. At least 95% of the total sample, and no fewer than 19 participants, MUST finish within 20 seconds without assistance.

For SC-007, at least 90% of the total sample, and no fewer than 18 participants, MUST correctly identify the meetup point and attendee status summary and stop their own location sharing without assistance.

## Assumptions

- Phase 2 Crew Management, Phase 3 Outing Management, Phase 4 Agreement System, and Phase 5 Outing Chat are available, including authentication, crew membership, outing participant rosters, Accepted/Invited/Declined attendance, finalized free-text locations, lifecycle transitions, and permanent outing cleanup.
- Live Meetup is available only during Meeting. Confirmed outings allow authorized organizers to prepare an exact meetup point but do not expose participant live status or location until Meeting begins.
- Only Accepted participants use or view Live Meetup. Invited and Declined participants remain visible in the broader outing roster but cannot access precise live coordination data.
- Status updates are explicit and correctable rather than enforcing a one-way progression, because participants may select a status accidentally or need to reflect a real-world change.
- Location sharing is per participant and per outing, always starts off, and requires separate explicit consent for each outing. Prior consent is never carried into another outing.
- A participant may share from only one device at a time. Moving sharing to another device requires an explicit transfer that disables submissions from the prior device.
- A two-minute location freshness window begins at the authoritative acceptance time assigned when an online location-update attempt is accepted for processing. Later processing or display delay never extends that window. Active devices may refresh the latest point while sharing remains explicitly active.
- Location sharing may continue when a participant navigates among ChillGo screens while the application remains foregrounded. A temporary background interruption pauses updates and may resume automatically in the same application session. Closing ChillGo ends the sharing session; reopening requires a new explicit start. In every interruption, the last accepted point expires within two minutes if no fresh update replaces it.
- Phase 6 stores only the latest location needed for current coordination. Analytics, diagnostics, or audit records must not preserve precise participant coordinates or reconstruct routes.
- Location accuracy depends on the participant's device and permission choice. Samples remain usable only within the explicit FR-034 bounds; the product communicates accepted accuracy and never promises exact positioning.
- The exact meetup point supplements the finalized free-text location from Phase 4. It does not reopen voting or silently change the confirmed location label.
- Live statuses, active sharing states, and locations are temporary presence data. Their permanent deletion is part of the authoritative eligibility or terminal outing transition rather than delayed normal cleanup; recovery cleanup may remove anomalous leftovers but never extends access or defines the normal deletion boundary. The exact meetup point follows the outing's broader lifecycle and is removed when the outing itself is permanently removed.
- Arrival notifications and all other push notifications belong to Phase 7. Phase 6 may update an already open eligible view in real time but does not send notifications.
- All map capabilities remain provider-neutral. Turn-by-turn directions, automatic arrival, route history, and geofencing are outside this phase.
