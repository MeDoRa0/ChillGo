# Contract: Firestore Rules

This contract defines the security behavior that Phase 3 Firestore rules and emulator tests must enforce.

## Collections

- `/outings/{outingId}`
- `/outing_participants/{outingId}_{userId}`

## Membership Helpers

Rules MUST reuse the existing crew membership model:

- A signed-in user is a crew member when `/crew_memberships/{crewId}_{uid}` exists.
- A signed-in user is a crew owner when the crew owner record and owner membership agree.
- An outing manager is the outing creator or the owning crew's owner.

## Outing Access

| Operation | Allowed When | Must Reject |
|-----------|--------------|-------------|
| Read outing | Caller is a current member of the outing's crew | Non-members and signed-out users |
| Create outing | Caller is a current crew member, initial status is `draft`, and creator participant exists in the same logical write | Non-members, invalid payloads, missing creator participant |
| Update outing details | Caller is outing creator or crew owner, outing is editable, and only planning fields plus the system-maintained `updatedAt` value change | Non-managers, invalid lifecycle/status changes, edits after cancellation/completion/archive, changes to `crewId`, `createdByUserId`, `createdAt`, `cancelledReason`, `cancelledAt`, `archivedAt`, or lifecycle status |
| Cancel outing | Caller is outing creator or crew owner, reason is valid, status can be cancelled | Missing reason, non-manager caller, terminal status |
| Archive outing | Caller is outing creator or crew owner and status is `completed` | Non-manager caller, invalid source status |
| Delete outing | No direct client delete in Phase 3 | All direct delete attempts |

## Participant Access

| Operation | Allowed When | Must Reject |
|-----------|--------------|-------------|
| Read participant | Caller is a current member of the participant's crew | Non-members and signed-out users |
| Create participant | Caller is outing creator or crew owner, target user is current crew member, and ID equals `outingId_userId` | Non-manager caller, non-member target user, duplicate IDs, mismatched crew IDs |
| Delete participant | Caller is outing creator or crew owner and outing is not completed or archived | Non-manager caller, terminal outing status |
| Update participant | No client updates in Phase 3 | All update attempts |

## Required Emulator Test Cases

- Non-members cannot read outing documents or participant documents.
- Current crew members can read outing documents and participant roster documents.
- Any current crew member can create an outing for that crew.
- Outing creation fails without the creator participant record.
- Outing creator and crew owner can edit active outing details.
- Non-manager crew members cannot edit, cancel, change lifecycle status, or manage participants.
- Duplicate participant creation is rejected by predictable ID.
- Adding a non-crew member as participant is rejected.
- Invalid lifecycle transitions are rejected.
- Cancelled, completed, and archived outing planning edits are rejected.
- Direct client deletion of outing documents is rejected.
