# Feature Specification: Phase 3 - Outing Management

**Feature Branch**: `003-outing-management`

**Created**: 2026-07-04

**Status**: Draft

**Input**: User description: "read main_plan.md and create a specification for Phase 3 - Outing Management only"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create an Outing Inside a Crew (Priority: P1)

As a crew member, I want to create an outing for one of my crews so that the group has a single structured place for the outing title, description, date, time, location, participants, and status.

**Why this priority**: Creating an outing is the core Phase 3 outcome. Without it, crews cannot organize outings at all.

**Independent Test**: A crew member can open a crew, enter the required outing details, save the outing, and see it listed under that crew without using voting, chat, or notifications.

**Acceptance Scenarios**:

1. **Given** an authenticated user who is a member of a crew, **When** they create an outing with a title, date, time, location, and at least one participant, **Then** the outing is saved under that crew and visible in the crew outings list.
2. **Given** a crew member is creating an outing, **When** they omit a required field, **Then** the system prevents saving and clearly identifies the missing field.
3. **Given** a user who is not a member of a crew, **When** they attempt to create an outing for that crew, **Then** the system denies the action.

---

### User Story 2 - View Outing Details and Participants (Priority: P1)

As a crew member, I want to open an outing details screen so that I can understand what is planned, who is included, and what the current outing status is.

**Why this priority**: Outing details create the shared source of truth that replaces scattered chat messages.

**Independent Test**: A crew member can select an outing from the crew outings list and review its title, description, scheduled date/time, location, participants, creator, and lifecycle status.

**Acceptance Scenarios**:

1. **Given** a crew has at least one outing, **When** a crew member opens the outing, **Then** the details screen shows the saved outing information and participant list.
2. **Given** an outing has no optional description, **When** a crew member opens the outing, **Then** the details screen still renders the required outing information without empty placeholder clutter.
3. **Given** a user is no longer a member of the crew, **When** they try to open one of that crew's outings, **Then** the system prevents access.

---

### User Story 3 - Edit an Existing Outing (Priority: P2)

As an outing creator or authorized crew manager, I want to update outing details before the outing is finalized so that the plan can stay accurate when circumstances change.

**Why this priority**: Plans change often, and editing prevents crews from creating duplicate outings for corrections.

**Independent Test**: An authorized user can change editable outing fields, save the update, and every crew member who can view the outing sees the latest version.

**Acceptance Scenarios**:

1. **Given** an outing is still editable, **When** an authorized user changes the title, description, date, time, location, or participant list, **Then** the updated details replace the previous details.
2. **Given** an unauthorized crew member views an outing, **When** they attempt to edit it, **Then** edit controls are unavailable or the action is rejected.
3. **Given** an outing is cancelled, completed, or archived, **When** an authorized user attempts to edit planning details, **Then** the system blocks the edit and explains that the outing is no longer editable.

---

### User Story 4 - Manage Outing Participants (Priority: P2)

As an outing creator or authorized crew manager, I want to choose which crew members are included in an outing so that only relevant members are associated with that plan.

**Why this priority**: Outings belong to crews, but not every crew member necessarily participates in every outing.

**Independent Test**: An authorized user can add and remove participants from the crew member list, and the outing details reflect the final participant set.

**Acceptance Scenarios**:

1. **Given** a crew has multiple members, **When** an authorized user adds members to an outing, **Then** those members appear in the outing participant list.
2. **Given** a participant has not yet reached a final attendance decision, **When** an authorized user removes them from the outing, **Then** they no longer appear in the participant list.
3. **Given** a user is not a member of the crew, **When** an authorized user searches for participants, **Then** that user is not available to add to the outing.

---

### User Story 5 - Cancel and Track Outing Lifecycle (Priority: P3)

As an outing creator or authorized crew manager, I want to cancel an outing or move it through appropriate lifecycle states so that the crew understands whether the outing is still being planned, active, finished, or retained for history.

**Why this priority**: Lifecycle management keeps the outing list understandable, but the MVP still delivers value with creation, details, and editing.

**Independent Test**: An authorized user can cancel an outing and can view lifecycle status changes in the outing list and details screen.

**Acceptance Scenarios**:

1. **Given** an outing is in Draft or Planning status, **When** an authorized user cancels it with a reason, **Then** the outing status becomes Cancelled and the reason is visible on the outing details screen.
2. **Given** an outing reaches an end state, **When** it is viewed later, **Then** it remains available as historical crew context unless deleted according to a later retention policy.
3. **Given** an outing status changes, **When** crew members view the outing list, **Then** the latest lifecycle status is visible without opening the detail screen.

### Edge Cases

- **Crew Deleted or Unavailable**: If the parent crew is deleted or unavailable while an outing is being created or edited, the system prevents saving the outing and explains that the crew no longer exists.
- **Participant Removed From Crew**: If a participant leaves or is removed from the crew, the outing must no longer treat them as an active participant for future management actions.
- **Date or Time in the Past**: If a user selects a past date/time during creation or editing, the system prevents saving unless the outing is being completed or archived as historical data.
- **Concurrent Edits**: If two authorized users edit the same outing at nearly the same time, the system preserves the latest valid update and clearly communicates when a user is looking at outdated details.
- **Cancellation After Status Change**: If an outing becomes completed or archived before cancellation is submitted, the system blocks cancellation and asks the user to refresh the outing state.
- **Empty Crew Member List**: If a crew has no eligible members besides the creator, the outing can still be created with the creator as the only participant.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated crew members to create outings within crews they belong to.
- **FR-002**: System MUST require each outing to have a title, scheduled date, scheduled time, location, creator, parent crew, participant list, and lifecycle status.
- **FR-003**: System MUST allow an optional outing description.
- **FR-004**: System MUST prevent users from creating, viewing, editing, cancelling, or managing participants for outings in crews they do not belong to.
- **FR-005**: System MUST show a crew outings list containing each outing's title, scheduled date/time, location summary, participant count, and lifecycle status.
- **FR-006**: System MUST show an outing details view containing the full outing details, creator, participant list, cancellation reason when applicable, and current lifecycle status.
- **FR-007**: System MUST allow the outing creator and authorized crew managers to edit planning details while the outing is in an editable lifecycle state.
- **FR-008**: System MUST prevent edits to planning details when an outing is cancelled, completed, or archived.
- **FR-009**: System MUST allow authorized users to add participants only from the parent crew's current member list.
- **FR-010**: System MUST allow authorized users to remove participants before those participants have a later-phase final attendance state.
- **FR-011**: System MUST ensure every outing always has at least one active participant.
- **FR-012**: System MUST assign each new outing an initial Draft status unless the creator explicitly publishes it to Planning during creation.
- **FR-013**: System MUST support Phase 3 user-driven lifecycle statuses of Draft, Planning, and Cancelled; Confirmed, Meeting, Completed, and Archived are reserved roadmap statuses that may be displayed if already present but cannot be reached through Phase 3 user actions.
- **FR-014**: System MUST restrict Phase 3 manual lifecycle transitions to the following authorized management actions: creation starts as Draft unless the creator publishes directly to Planning, authorized creators or crew managers may publish Draft outings to Planning when required details are complete, and authorized creators or crew managers may cancel Draft or Planning outings with a reason.
- **FR-015**: System MUST allow authorized users to cancel Draft or Planning outings and record a cancellation reason.
- **FR-016**: System MUST retain cancelled, completed, and archived outings as historical crew records unless a later retention policy removes them.
- **FR-017**: System MUST validate that scheduled outing date/time is not in the past during creation or planning edits.
- **FR-018**: System MUST provide clear, user-friendly feedback when an outing action fails because of missing fields, membership changes, stale data, or insufficient permissions.

### Key Entities *(include if feature involves data)*

- **Outing**: Represents an event organized inside one crew. Key attributes include title, optional description, scheduled date/time, location, creator, parent crew, participant list, lifecycle status, creation date, last updated date, and optional cancellation reason.
- **Outing Participant**: Represents a crew member included in an outing. Key attributes include user identity, display name snapshot, participant state for Phase 3 management, and date added.
- **Outing Lifecycle Status**: Represents the outing's current management state. Phase 3 user actions can reach Draft, Planning, or Cancelled only; Confirmed, Meeting, Completed, and Archived are reserved for later roadmap phases and are read-only if encountered.
- **Location Summary**: Represents the outing's selected place in a user-facing form, including a display name and enough saved location detail to identify the meetup place.
- **Crew Membership Reference**: Represents the relationship that proves a user belongs to the parent crew and can be considered for outing access or participation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Crew members can create a valid outing from a crew screen in under 90 seconds.
- **SC-002**: 95% of users can open an outing details view and identify the title, date/time, location, participants, and status within 10 seconds.
- **SC-003**: 100% of outing access attempts by non-crew members are rejected.
- **SC-004**: Authorized users can update editable outing details and see the updated details reflected in the outing list and details view within 3 seconds under normal network conditions.
- **SC-005**: 100% of created outings contain at least one active participant and a valid lifecycle status.
- **SC-006**: Cancelled outings clearly display their cancelled status and reason to eligible crew members in the outing details view.

## Assumptions

- Phase 1 authentication and profile management are already available.
- Phase 2 crew management is already available, including crew membership and authorized crew manager roles.
- Any current crew member may create an outing unless crew permissions later introduce stricter rules.
- The outing creator and crew owner are authorized managers for the outing by default.
- Phase 3 does not implement outing acceptance/decline, time/location suggestions, voting, chat, live location sharing, push notifications, or arrival statuses; those remain in later roadmap phases.
- Location selection is limited to saving and displaying a chosen location summary in Phase 3; advanced map interactions may be expanded in later planning.
