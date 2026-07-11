# Contract: Outing Repository

This contract defines the domain-facing interface expected by Phase 3 presentation logic. Concrete persistence details belong in the data layer.

## Read Operations

### Watch Crew Outings

- **Input**: `crewId`
- **Allowed caller**: Current crew member
- **Output**: Ordered stream/list of outings for the crew
- **Rules**:
  - Active upcoming outings are returned before completed, cancelled, or archived outings.
  - Non-members receive an access failure without outing details.

### Watch Outing Detail

- **Input**: `outingId`
- **Allowed caller**: Current member of the outing's crew
- **Output**: Outing details and participant roster
- **Rules**:
  - Participant records are de-duplicated by `outingId_userId`.
  - Cancelled outings include cancellation reason.

## Write Operations

### Create Outing

- **Input**: `crewId`, `title`, optional `description`, `scheduledAt`, `locationText`
- **Allowed caller**: Current crew member
- **Output**: Created outing
- **Rules**:
  - Creates the outing record and creator participant in one Firestore batch or transaction through the repository create operation.
  - Either both records are committed or neither record is committed.
  - Sets the initial outing status to `draft`.
  - Automatically creates the creator participant record.
  - Rejects missing required fields, past schedule values, and non-member callers.

### Update Outing Details

- **Input**: `outingId`, editable planning fields
- **Allowed caller**: Outing creator or crew owner
- **Output**: Updated outing
- **Rules**:
  - Allowed only for active editable statuses.
  - Cannot edit planning details after cancellation, completion, or archive.
  - Location remains free-text only.

### Cancel Outing

- **Input**: `outingId`, `cancelledReason`
- **Allowed caller**: Outing creator or crew owner
- **Output**: Cancelled outing
- **Rules**:
  - Requires a non-empty cancellation reason.
  - Preserves the outing as crew history.
  - Blocks cancellation from non-cancellable statuses.

### Add Participant

- **Input**: `outingId`, `userId`
- **Allowed caller**: Outing creator or crew owner
- **Output**: Participant record
- **Rules**:
  - Target user must be a current member of the outing's crew.
  - Duplicate participants are rejected.

### Remove Participant

- **Input**: `outingId`, `userId`
- **Allowed caller**: Outing creator or crew owner
- **Output**: Success/failure
- **Rules**:
  - Allowed before completion or archive.
  - Does not remove crew membership.

### Change Lifecycle Status

- **Input**: `outingId`, next `status`
- **Allowed caller**: Outing creator or crew owner
- **Output**: Updated outing
- **Rules**:
  - Only allowed transitions from [data-model.md](../data-model.md) are accepted.
  - Cancellation is handled by `cancelOuting` because it requires `cancelledReason` and `cancelledAt`.
  - Archiving is valid only from `completed` and MUST set `archivedAt`.
  - Generic status changes MUST NOT create cancelled or archived records without their required metadata.
  - Agreement, chat, live meetup, and notifications are not required for Phase 3 transitions.

## Error Contract

Repository operations MUST expose user-actionable failures for:

- Missing or invalid required fields
- Permission denied
- Crew membership missing
- Duplicate participant
- Invalid lifecycle transition
- Attempted edit of cancelled, completed, or archived outing
- Network or persistence failure
