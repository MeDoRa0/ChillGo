# Contract: Agreement Commands

This contract defines the cross-platform Firestore command boundary between Flutter clients and trusted Functions processing.

## Common Request Envelope

Clients create `/agreement_commands/{commandId}` with:

```text
type: command type
outingId: non-empty string
crewId: non-empty string
requestedByUserId: authenticated UID
payload: allowlisted command payload
status: pending
createdAt: request timestamp
```

Security Rules reject unknown top-level fields, mismatched UIDs, non-pending states, non-members, updates, and deletes. The function treats all IDs and payload values as untrusted and re-resolves authoritative documents.

## Command Types

### `open_round`

- **Actor**: outing creator or crew owner
- **Precondition**: outing is Draft and has no open round
- **Payload**: empty
- **Effect**: creates the next round and two seed proposals, increments the sequence, sets the active round, moves outing to Planning
- **Success result**: `roundId`

### `create_proposal`

- **Actor**: accepted participant and current crew member
- **Precondition**: outing is Planning and round is open
- **Payload**: `category` plus exactly one of `timeValue` or `locationText`
- **Effect**: creates an immutable proposal or reuses an equivalent proposal
- **Success result**: `proposalId`, `reused`

### `preview_confirmation`

- **Actor**: outing creator or crew owner
- **Precondition**: outing is Planning and each category has at least one eligible vote
- **Payload**: empty
- **Effect**: no agreement state mutation; command result exposes only whether each category is unique or tied and the proposal IDs of tied leaders
- **Success result**: `timeChoiceRequired`, `timeTiedProposalIds`, `locationChoiceRequired`, `locationTiedProposalIds`; no counts, voters, or unique leader ID

### `confirm_round`

- **Actor**: outing creator or crew owner
- **Precondition**: valid preview state still matches current tally
- **Payload**: optional `selectedTimeProposalId` and `selectedLocationProposalId`, required only for tied categories
- **Effect**: transactionally writes aggregate results, final selections, outing details, closed round, and Confirmed status
- **Success result**: `roundId`, selected proposal IDs, aggregate totals now safe to display
- **Conflict behavior**: if votes or eligibility changed so the supplied tie selection is no longer valid, fail with `confirmation_state_changed`; client requests a new preview

### `reopen_round`

- **Actor**: outing creator or crew owner
- **Precondition**: outing is Confirmed and has not entered Meeting
- **Payload**: `reason` trimmed to 3–200 characters
- **Effect**: supersedes the confirmed round, creates the next round with current outing details as seed proposals and zero votes, moves outing to Planning
- **Success result**: new `roundId`

### `cancel_outing`

- **Actor**: outing creator or crew owner
- **Precondition**: existing Phase 3 cancellation rules
- **Payload**: `reason` trimmed to 3–200 characters
- **Effect**: atomically cancels the outing and any open agreement round
- **Success result**: `outingId`

### `delete_outing`

- **Actor**: outing creator only
- **Precondition**: the outing exists; no lifecycle-status restriction applies
- **Payload**: empty
- **Effect**: permanently removes the outing and all outing-owned participant and agreement records; pending or concurrent commands must not recreate deleted data
- **Success result**: `outingId`, `alreadyAbsent`
- **Idempotency behavior**: an already-absent outing is treated as a successful no-op for a previously authorized deletion request

### `expire_outing`

- **Actor**: current crew member whose app observes the outing
- **Precondition**: the authoritative outing schedule is at least 12 hours in the past
- **Payload**: empty
- **Effect**: permanently removes the outing and the same outing-owned records as `delete_outing`
- **Success result**: `outingId`, `alreadyAbsent`
- **Validation behavior**: trusted processing revalidates current crew membership and `scheduledAt + 12 hours`; early signals fail with `invalid_outing_state`

## Command Status Contract

```text
pending -> processing -> succeeded
                      `-> failed
```

The processor may recover a stale `processing` command by transactionally claiming it with the trigger event ID and checking whether deterministic effects already exist. Terminal commands are immutable no-ops on duplicate delivery.

## Stable Error Codes

- `unauthenticated`
- `permission_denied`
- `not_found`
- `invalid_command`
- `invalid_outing_state`
- `not_accepted_participant`
- `proposal_limit_reached`
- `expired_time_proposal`
- `insufficient_votes`
- `tie_selection_required`
- `invalid_tie_selection`
- `confirmation_state_changed`
- `already_processed`
- `internal_error`

Error results contain safe messages and never reveal hidden totals, leaders, ties to non-organizers, or voter identities.
