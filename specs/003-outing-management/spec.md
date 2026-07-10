# Feature Specification: Outing Management

**Feature Branch**: `codex/003-outing-management`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "read main_plan.md and create a specification for Phase 3 - Outing Management only"

## Clarifications

### Session 2026-07-10

- Q: Should the outing creator be automatically added as a participant? -> A: The outing creator is automatically added as the first participant.
- Q: What form should outing location take in Phase 3? -> A: Location is free-text only, such as "City Center Cafe".
- Q: How should lifecycle statuses be controlled in Phase 3? -> A: Organizer/crew owner can manually move outings through all lifecycle statuses in Phase 3.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create an Outing Inside a Crew (Priority: P1)

A crew member creates a new outing for an existing crew by entering the core outing details so the crew has one shared place to organize the event.

**Why this priority**: Outing creation is the foundation of Phase 3. Without it, crews cannot organize outings and later phases for agreement, chat, live meetup, and notifications have no outing record to build on.

**Independent Test**: Can be fully tested by signing in as a member of a crew, creating an outing with required details, and verifying that the outing appears in that crew's outing list and detail view.

**Acceptance Scenarios**:

1. **Given** a signed-in user belongs to a crew, **When** the user creates an outing with a title, date, time, and free-text location, **Then** the outing is saved under that crew, visible to crew members, and the creator appears as the first participant.
2. **Given** a signed-in user does not belong to a crew, **When** the user attempts to create an outing for that crew, **Then** the outing is not created and the user is told they do not have access.
3. **Given** a crew member starts creating an outing, **When** required details are missing or invalid, **Then** the outing is not created and the user can correct the missing information.

---

### User Story 2 - View Outing Details and Crew Outings (Priority: P2)

Crew members view all outings for a crew and open an outing to see its title, description, scheduled date and time, location, participants, status, and cancellation reason when applicable.

**Why this priority**: A created outing only solves the coordination problem if members can reliably find it and understand its current state.

**Independent Test**: Can be fully tested by creating multiple outings in one crew, opening the crew outing list, and verifying each outing can be opened with complete detail information.

**Acceptance Scenarios**:

1. **Given** a crew has upcoming and past outings, **When** a crew member opens the crew outings area, **Then** the member can see outings grouped or ordered so upcoming active outings are easy to find.
2. **Given** a crew member opens an outing, **When** the detail view loads, **Then** the member sees the outing's core details, participant roster, and current lifecycle status.
3. **Given** a user is not a member of the crew, **When** the user attempts to view an outing from that crew, **Then** outing details are not shown.

---

### User Story 3 - Edit or Cancel an Outing (Priority: P3)

An outing organizer or crew owner updates outing details when plans change, or cancels the outing with a reason so crew members have a clear source of truth.

**Why this priority**: Outings often change before they happen. Controlled edits and cancellation prevent stale plans from spreading across the crew.

**Independent Test**: Can be fully tested by creating an outing, editing each editable field, cancelling the outing, and verifying the detail view reflects the final state.

**Acceptance Scenarios**:

1. **Given** an active outing exists, **When** the outing organizer updates the title, description, date, time, or location, **Then** crew members see the updated outing details.
2. **Given** an active outing exists, **When** the outing organizer cancels it and provides a reason, **Then** the outing is marked cancelled and the cancellation reason is visible to crew members.
3. **Given** an outing is cancelled, completed, or archived, **When** a user attempts to edit planning details, **Then** the system prevents the change and explains that the outing is no longer editable.

---

### User Story 4 - Manage Participants and Lifecycle (Priority: P4)

An outing organizer manages which crew members are included in the outing and moves the outing through its lifecycle as it progresses from draft planning to historical record.

**Why this priority**: Participant and status management make outings structured enough for later agreement, chat, live meetup, and notification phases while remaining valuable on their own.

**Independent Test**: Can be fully tested by adding and removing crew members from an outing, changing lifecycle statuses in valid order, and confirming the roster, current status, and allowed transition sequence stay consistent.

**Acceptance Scenarios**:

1. **Given** an outing exists for a crew, **When** the organizer adds participants, **Then** only current members of that crew can be added.
2. **Given** an outing has participants, **When** the organizer removes a participant before the outing is completed, **Then** the participant no longer appears in the outing roster.
3. **Given** an outing is in a lifecycle status, **When** the outing creator or crew owner advances, completes, or archives it using an allowed transition, **Then** the outing status changes and crew members see the updated status.

### Edge Cases

- A crew has no outings yet; members see an empty state that makes creation possible for eligible users.
- A user is removed from a crew after creating or joining an outing; the user no longer has access to that crew's outing details.
- A participant is removed from the crew; the outing roster no longer treats that user as an active eligible participant.
- Two eligible users update the same outing close together; the final outing details remain consistent and do not produce duplicate participants or invalid statuses.
- An outing date or time is changed to the past; the system prevents active outing schedules that would be impossible to attend.
- A crew is deleted; its active outings are no longer available for member planning.
- An outing is cancelled; it remains visible as a historical record but cannot be edited as an active outing.
- An outing is archived; it is retained for history but separated from active planning views.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow eligible crew members to create outings within crews they currently belong to.
- **FR-002**: System MUST require each outing to have a title, scheduled date, scheduled time, free-text location, creator, crew association, lifecycle status, and creation date.
- **FR-003**: System MUST allow an outing to include an optional description.
- **FR-004**: System MUST prevent users from creating, viewing, editing, cancelling, or managing outings for crews they do not belong to.
- **FR-005**: Users MUST be able to view a list of outings for each crew they belong to.
- **FR-006**: System MUST make active upcoming outings easier to find than completed, cancelled, or archived outings.
- **FR-007**: Users MUST be able to open an outing details view showing core outing details, participant roster, lifecycle status, and relevant historical state such as cancellation or archive state.
- **FR-008**: System MUST allow the outing creator and crew owner to edit active outing details before completion or archive.
- **FR-009**: System MUST prevent edits to planning details after an outing is cancelled, completed, or archived.
- **FR-010**: System MUST allow the outing creator and crew owner to cancel an active outing.
- **FR-011**: System MUST require a cancellation reason when an outing is cancelled.
- **FR-012**: System MUST preserve cancelled outings as visible historical records for crew members.
- **FR-013**: System MUST allow the outing creator and crew owner to add current crew members as outing participants.
- **FR-014**: System MUST automatically add the outing creator as the first participant when an outing is created.
- **FR-015**: System MUST prevent adding non-crew members as outing participants.
- **FR-016**: System MUST allow the outing creator and crew owner to remove participants from an active outing before it is completed or archived.
- **FR-017**: System MUST prevent duplicate participant entries for the same outing.
- **FR-018**: System MUST track each participant's association with the outing separately from crew membership so outing rosters remain clear.
- **FR-019**: System MUST support the outing lifecycle statuses Draft, Planning, Confirmed, Meeting, Completed, Archived, and Cancelled.
- **FR-020**: System MUST allow the outing creator and crew owner to manually move outings through valid lifecycle transitions: Draft to Planning, Draft to Cancelled, Planning to Confirmed, Planning to Cancelled, Confirmed to Meeting, Confirmed to Cancelled, Meeting to Completed, Completed to Archived.
- **FR-021**: System MUST show a clear message when a requested outing action is blocked by permission, invalid data, invalid lifecycle status, or missing crew membership.
- **FR-022**: System MUST keep outing management separate from later agreement, chat, live meetup, and notification capabilities; Phase 3 MUST NOT require voting, accepting or declining invitations, chat messages, live location sharing, or push notifications.

### Key Entities *(include if feature involves data)*

- **Outing**: An event organized within a crew. Key attributes include title, optional description, scheduled date, scheduled time, free-text location, lifecycle status, creator, crew association, created date, updated date, cancellation reason when cancelled, and archived state when archived.
- **Outing Participant**: A crew member associated with a specific outing. Key attributes include outing association, user association, crew association, participant display information, participant creation date, and whether the participant was automatically added as the creator.
- **Crew**: The persistent group that owns outings. Outings can only exist within a crew, and only current crew members can access them.
- **Crew Member**: A user with current membership in the crew. Crew membership determines who can view outings and who can be added as a participant.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of eligible users can create a valid outing from an existing crew in under 2 minutes during usability testing.
- **SC-002**: 95% of crew members can find and open an active upcoming outing in under 30 seconds.
- **SC-003**: 100% of blocked access attempts by non-members fail without revealing private outing details.
- **SC-004**: 100% of cancelled outings display a cancellation reason and remain available as crew history.
- **SC-005**: 0 duplicate participant entries are created during repeated add participant attempts in validation testing.
- **SC-006**: 100% of lifecycle status changes follow the allowed transition order during acceptance testing.
- **SC-007**: At least 90% of test users report that the outing detail view clearly communicates what, when, where, who, and current status.

## Assumptions

- Phase 2 Crew Management exists: users can create crews, join crews, and have owner/member roles.
- Any current crew member may create an outing unless future business rules restrict this further.
- The outing creator and crew owner are the only users who can edit, cancel, manage participants, or move lifecycle status in Phase 3.
- Active outings are outings in Draft, Planning, Confirmed, or Meeting status. Completed, Archived, and Cancelled outings are historical or terminal for planning edits.
- Outings may be cancelled only from Draft, Planning, or Confirmed status in Phase 3.
- Manual lifecycle changes in Phase 3 are organizer controls and do not require voting, member acceptance, chat activity, live status, or notifications.
- Participant management in Phase 3 means selecting and maintaining the roster of crew members included in an outing; accepting, declining, voting, and final agreement belong to Phase 4.
- The outing creator is treated as participating by default unless removed later by an eligible manager before completion or archive.
- Chat belongs to Phase 5, live status and live location belong to Phase 6, and push notifications belong to Phase 7.
- Location in Phase 3 is free-text only; selected places, addresses, coordinates, and map-provider behavior are outside this specification.
- Historical cancelled, completed, and archived outings are retained for crew reference unless a later retention policy changes this.
