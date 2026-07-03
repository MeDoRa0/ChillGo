# Feature Specification: Crew Management

**Feature Branch**: `phase-2-crew-management`

**Created**: 2026-07-01

**Status**: Draft

**Input**: User description: "Phase 2 — Crew Management"

## Clarifications

### Session 2026-07-01

- Q: How should the Crew Invitation document's lifecycle be managed in Firestore once a user accepts or rejects it? → A: Delete the invitation document immediately upon both acceptance and rejection.
- Q: Can a Crew Owner revoke (cancel) a pending invitation after sending it, and do invitations have an expiration period? → A: Owners can revoke pending invitations at any time; invitations do not expire automatically.
- Q: How should cascading outing deletion be handled when a Crew is deleted? → A: Defer implementation to the Outing Management phase (Phase 3+), keeping the requirement documented in the spec.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Creating a Crew and Listing Members (Priority: P1)

As a user, I want to create a Crew (with a name) so that I can have a persistent group for organizing outings. I also want to view the details of my crew (the crew name and member list) and be marked as the Owner.

**Why this priority**: This is the core MVP block. Without creating a Crew, no outings or group coordination can occur.

**Independent Test**: A user can create a crew by inputting a name, and immediately see the crew listed in their Crews list with themselves as the owner and only member.

**Acceptance Scenarios**:

1. **Given** the user is on the Crews list screen, **When** they tap "Create Crew", enter a valid crew name (e.g., "School Friends"), and tap "Submit", **Then** the Crew is created and they are redirected to the Crew Details screen showing "School Friends" with them listed as the owner.
2. **Given** a user has created a crew, **When** they view the Crew Details, **Then** they see the name of the Crew and a member list containing only their profile.

---

### User Story 2 - Inviting Members by Username (Priority: P1)

As a Crew Owner, I want to invite other users to my Crew by entering their unique username so that we can organize outings together.

**Why this priority**: A crew needs members to be useful. Inviting by username is the core mechanic defined by the Crew-First Interaction Model.

**Independent Test**: A Crew Owner can enter a username, the system verifies the user exists and creates a pending invitation.

**Acceptance Scenarios**:

1. **Given** the Crew Owner is on the Crew Details screen, **When** they type an existing user's username (e.g., "john_doe") and tap "Invite", **Then** a pending invitation is sent and the UI displays "john_doe" under a "Pending Invitations" list.
2. **Given** the Crew Owner is on the Crew Details screen, **When** they type a non-existent username and tap "Invite", **Then** the system displays a validation error "Username not found" and no invitation is sent.

---

### User Story 3 - Managing Invitations (Accepting/Rejecting) (Priority: P2)

As an invited user, I want to see my pending invitations and accept or reject them so that I can join crews I want to be part of or decline the ones I don't.

**Why this priority**: Enables the invited users to actually join the Crew, completing the group loop.

**Independent Test**: An invited user sees the invitation, accepts it, and becomes a crew member, or rejects it and the invitation disappears.

**Acceptance Scenarios**:

1. **Given** a user is on their Dashboard/Invitations screen, **When** they tap "Accept" on an invitation to "Football Friends", **Then** they are added as a member of "Football Friends" and can see it under their Crew list.
2. **Given** a user is on their Dashboard/Invitations screen, **When** they tap "Reject" on an invitation, **Then** the invitation is deleted, they are not added to the Crew, and it no longer appears in their list.

---

### User Story 4 - Editing and Deleting Crews (Priority: P2)

As a Crew Owner, I want to edit the crew's name or delete the crew entirely if it's no longer needed.

**Why this priority**: Essential crew lifecycle management.

**Independent Test**: The owner can change the crew name or delete it, removing it from all members' lists.

**Acceptance Scenarios**:

1. **Given** a Crew Owner is on the Crew Settings screen, **When** they modify the crew name and tap save, **Then** the new name is updated instantly for all members.
2. **Given** a Crew Owner is on the Crew Settings screen, **When** they tap "Delete Crew" and confirm, **Then** the Crew is deleted and all members no longer see it in their lists.

---

### User Story 5 - Member Management (Leaving and Removing Members) (Priority: P3)

As a Crew Member, I want to leave a Crew when I no longer wish to participate. As a Crew Owner, I want to remove members from the Crew if necessary.

**Why this priority**: Allows group clean-up and maintenance.

**Independent Test**: A member can leave the crew, and the owner can remove any non-owner member.

**Acceptance Scenarios**:

1. **Given** a Crew Member is on the Crew Details screen, **When** they tap "Leave Crew" and confirm, **Then** they are removed from the crew and redirected back to the dashboard.
2. **Given** the Crew Owner is on the Crew Details/Member List screen, **When** they tap "Remove" next to a member's name and confirm, **Then** that member is immediately removed from the Crew.

### Edge Cases

- **Duplicate Invitations**: What happens when a user attempts to invite a username that is already in the Crew or has a pending invitation? The system must show a validation error (e.g., "User is already a member" or "User already has a pending invitation").
- **Owner Leaving**: What happens if the Crew Owner leaves the Crew? The Crew Owner cannot leave the Crew directly. They must delete the Crew to dissolve it (or transfer ownership, which is out of scope for MVP).
- **Crew Deletion Cleanup**: What happens when a Crew is deleted? Deleting the Crew must automatically remove all related `crew_memberships` records, automatically delete all pending invitations for that Crew, and cancel/delete all associated outings. (Note: The implementation of cascading outing cleanup is deferred to Phase 3+ when Outings are introduced).
- **Invitation Privileges**: Can standard members invite other members? No, only the Crew Owner has privileges to invite or remove members.
- **Invitation Revocation**: Can the Crew Owner revoke a pending invitation? Yes, the Crew Owner can revoke/cancel a pending invitation at any time. Standard members cannot revoke invitations.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated users to create a Crew by providing a Crew name (between 3 and 50 characters).
- **FR-002**: The creator of a Crew MUST be automatically assigned the role of Owner (`owner`).
- **FR-003**: System MUST support roles within a Crew: Owner (`owner`) and Member (`member`).
- **FR-004**: System MUST allow the Crew Owner to invite other users to the Crew by entering their exact, unique username.
- **FR-005**: System MUST validate that the invited username exists in the system.
- **FR-006**: System MUST prevent duplicate invitations (cannot invite an existing member or someone with an active pending invitation).
- **FR-007**: System MUST allow invited users to view their pending Crew invitations.
- **FR-008**: System MUST allow invited users to accept an invitation (which adds them as a Member and deletes the invitation document) or reject/decline the invitation (which simply deletes the invitation document).
- **FR-009**: System MUST allow the Crew Owner to edit the Crew name.
- **FR-010**: System MUST allow the Crew Owner to delete the Crew.
- **FR-011**: System MUST allow Crew Members to leave the Crew.
- **FR-012**: System MUST prevent the Crew Owner from leaving the Crew directly (they must delete it to dissolve it).
- **FR-013**: System MUST allow the Crew Owner to remove any member from the Crew.
- **FR-014**: System MUST list all members of a Crew including their Display Name, Username, Avatar, and Role (Owner vs. Member) to any active member of the Crew.
- **FR-015**: System MUST enforce that only Crew Members or the Crew Owner can view the Crew details or member list.
- **FR-016**: System MUST allow the Crew Owner to revoke/cancel a pending invitation, which immediately deletes the invitation document.

### Key Entities *(include if feature involves data)*

- **Crew**:
  - Represents a persistent group of users.
  - Key attributes: `id` (unique identifier), `name` (string), `ownerId` (UID of the owner), `createdAt` (timestamp).
- **Crew Membership**:
  - Represents a user's participation in a crew.
  - Key attributes: `id` (unique identifier), `crewId` (identifier of the Crew), `userId` (UID of the User), `role` (enum: owner, member), `joinedAt` (timestamp).
- **Crew Invitation**:
  - Represents an invitation sent by an owner to a user.
  - Key attributes: `id` (unique identifier), `crewId` (identifier of the Crew), `invitedUserId` (UID of the invited user), `invitedByUserId` (UID of the owner who sent it), `createdAt` (timestamp). (Note: No status enum is required as presence of the document represents a pending invitation).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a Crew and have it fully operational in under 15 seconds.
- **SC-002**: An owner can invite a user and that user receives the invitation list update in under 3 seconds.
- **SC-003**: 100% of invalid username invitations are rejected at submission with a clear error message.
- **SC-004**: System supports up to 100 members per Crew while maintaining a stable 60 FPS scroll rate on reference devices.

## Assumptions

- **Internet Connectivity**: Users have active internet connectivity to perform real-time interactions (invitations, accepts, etc.).
- **User Database**: A global registry of users exists (implemented in Phase 1) with unique usernames to allow lookups.
- **No Ownership Transfer**: Transferring Crew ownership to another member is out of scope for the MVP.
- **Single Owner**: A Crew has exactly one owner at any time.
- **Platform Parity**: The Crew management interface will look and behave consistently across Android, iOS, Web, and Windows.
