# Data Model: Agreement System

This document defines Phase 4 entities, Firestore paths, validation, privacy, relationships, migration behavior, and state transitions.

## 1. Outing Participant (Extended)

- **Existing path**: `/outing_participants/{outingId}_{userId}`

New fields:

| Field | Type | Rules |
|---|---|---|
| `attendanceStatus` | String | Exactly one of `invited`, `accepted`, `declined` |
| `respondedAt` | Timestamp (nullable) | Null while invited; required when accepted or declined |

Existing creator participants start as `accepted`; all other newly added participants start as `invited`. Only the participant may change their own attendance response, and only before the outing enters `meeting`. A declined participant remains in the roster.

### Migration

- Legacy records with `isCreatorParticipant == true` are read and backfilled as `accepted`.
- Other legacy records are read and backfilled as `invited`.
- `respondedAt` is null for migrated invited records. Creator backfills use the migration time because the original response timestamp does not exist.
- After backfill verification, Security Rules require both Phase 4 fields on all new and updated participant records.

## 2. Outing (Extended)

- **Existing path**: `/outings/{outingId}`

New fields:

| Field | Type | Rules |
|---|---|---|
| `agreementRoundSequence` | Integer | Non-negative, increases by exactly one when a round opens |
| `activeAgreementRoundId` | String (nullable) | Required in `planning`; references the one open round |
| `confirmedAgreementRoundId` | String (nullable) | References the latest confirmed round |

The Functions command processor owns these fields and the `draft -> planning`, `planning -> confirmed`, and `confirmed -> planning` agreement transitions. Client lifecycle writes cannot modify them.

The outing's scheduled time and location are directly editable only while Draft. Once Planning opens, they remain the current baseline until a successful confirmation transaction replaces both with selected proposals. Confirmed or later schedule/location changes require reopening rather than a direct detail edit.

## 3. Agreement Round

- **Path**: `/agreement_rounds/{outingId}_{sequence}`

| Field | Type | Description |
|---|---|---|
| `outingId` | String | Owning outing |
| `crewId` | String | Denormalized owning crew |
| `sequence` | Integer | One-based round number, unique per outing |
| `status` | String | `open`, `confirmed`, `cancelled`, or `superseded` |
| `openedByUserId` | String | Authorized organizer who opened/reopened it |
| `openedAt` | Timestamp | Server opening time |
| `reopenReason` | String (nullable) | Required for rounds created from Confirmed |
| `seedTimeProposalId` | String | Proposal derived from the outing's current time |
| `seedLocationProposalId` | String | Proposal derived from the outing's current location |
| `confirmedByUserId` | String (nullable) | Organizer who confirmed |
| `confirmedAt` | Timestamp (nullable) | Server confirmation time |
| `selectedTimeProposalId` | String (nullable) | Winning time choice |
| `selectedLocationProposalId` | String (nullable) | Winning location choice |
| `eligibleVoterCount` | Integer (nullable) | Snapshot published only when closed |
| `timeVoteCount` | Integer (nullable) | Eligible time votes at confirmation |
| `locationVoteCount` | Integer (nullable) | Eligible location votes at confirmation |
| `supersededByRoundId` | String (nullable) | New round that replaced a prior confirmation |
| `closedAt` | Timestamp (nullable) | Confirmation, cancellation, or supersession time |

Open rounds contain no aggregate counts, leaders, or tie fields. Only one open round may exist per outing, referenced by the outing pointer.

## 4. Agreement Proposal

- **Path**: `/agreement_proposals/{proposalId}`

| Field | Type | Description |
|---|---|---|
| `roundId` | String | Owning round |
| `outingId` | String | Owning outing |
| `crewId` | String | Owning crew |
| `category` | String | `time` or `location` |
| `authorUserId` | String | Accepted participant who proposed it |
| `timeValue` | Timestamp (nullable) | Required only for time proposals |
| `locationText` | String (nullable) | Trimmed display value, required only for location proposals |
| `normalizedKey` | String | Server-derived duplicate identity within category and round |
| `createdAt` | Timestamp | Server creation time |
| `isSeed` | Boolean | Whether copied from current outing details |

Proposal documents are function-created, immutable, and non-deletable. Equivalent active proposals reuse the existing proposal. A time proposal whose value is no longer in the future is ineligible at read/confirmation time but remains historical. Each round supports at most 50 proposals per category.

## 5. Agreement Vote

- **Path**: `/agreement_votes/{roundId}_{category}_{userId}`

| Field | Type | Description |
|---|---|---|
| `roundId` | String | Open round |
| `outingId` | String | Owning outing |
| `crewId` | String | Owning crew |
| `category` | String | `time` or `location` |
| `proposalId` | String | Current selected proposal in the same round/category |
| `userId` | String | Voter; must match authenticated user and document ID |
| `createdAt` | Timestamp | First vote time; immutable on changes |
| `updatedAt` | Timestamp | Latest selection time |

The voter may create, change, or delete only their own vote while the round and outing are in Planning and their participant status is Accepted. Only the voter may read the document. List queries are denied. At confirmation, the function excludes votes from participants who are no longer accepted/current members and excludes expired time proposals.

## 6. Agreement Result

- **Path**: `/agreement_results/{roundId}_{category}_{proposalId}`

| Field | Type | Description |
|---|---|---|
| `roundId` | String | Closed round |
| `outingId` | String | Owning outing |
| `crewId` | String | Owning crew |
| `category` | String | `time` or `location` |
| `proposalId` | String | Aggregated proposal |
| `voteCount` | Integer | Eligible aggregate count |
| `isLeader` | Boolean | Whether tied for the highest count |
| `isSelected` | Boolean | Whether chosen as the final result |
| `createdAt` | Timestamp | Confirmation time |

Only trusted functions create result documents. Current crew members may read them after the owning round is closed. No voter IDs are stored.

## 7. Agreement Command

- **Path**: `/agreement_commands/{commandId}`

| Field | Type | Description |
|---|---|---|
| `type` | String | `open_round`, `create_proposal`, `preview_confirmation`, `confirm_round`, `reopen_round`, `cancel_outing`, `delete_outing`, or `expire_outing` |
| `outingId` | String | Target outing |
| `crewId` | String | Claimed crew, verified by the function |
| `requestedByUserId` | String | Must equal authenticated creator |
| `payload` | Map | Type-specific, allowlisted input only |
| `status` | String | `pending`, `processing`, `succeeded`, or `failed` |
| `createdAt` | Timestamp | Client request time constrained to server time |
| `processedAt` | Timestamp (nullable) | Function completion time |
| `result` | Map (nullable) | Sanitized result; never includes totals before confirmation |
| `errorCode` | String (nullable) | Stable user-safe failure code |

Clients may create commands only for themselves with `pending` status and cannot update or delete them. Only the requester may read a command. Functions transition status transactionally and make duplicate trigger delivery a no-op after terminal status.

## Relationships

```text
Crew 1 --- * Outing 1 --- * AgreementRound
                   |             |--- * AgreementProposal
                   |             |--- * AgreementVote (private per voter)
                   |             `--- * AgreementResult (aggregate, closed only)
                   `--- * OutingParticipant (one attendance response each)

User 1 --- * AgreementCommand (requester-private)
```

## State Transitions

### Attendance

```text
Invited -> Accepted
Invited -> Declined
Accepted <-> Declined
```

Transitions stop when the outing enters Meeting.

### Agreement Round

```text
Open -> Confirmed
Open -> Cancelled
Confirmed -> Superseded (when a new round opens)
```

### Outing Agreement Lifecycle

```text
Draft --open_round--> Planning
Planning --confirm_round--> Confirmed
Confirmed --reopen_round--> Planning
```

Existing cancellation and later lifecycle transitions remain, but cancellation of an outing with an open round is processed atomically through the command processor.

Permanent outing removal is not a lifecycle transition. The outing creator may request it from any status. Once an app observes that `scheduledAt + 12 hours` has elapsed, a current crew member may send an `expire_outing` command; trusted processing rechecks both membership and the authoritative timestamp. Removal cascades to the outing participant roster and all agreement rounds, proposals, votes, aggregate results, and pending command work owned by the outing. The operation is idempotent, and other in-flight commands must not recreate data after the outing is absent.

## Confirmation Transaction

1. Verify command requester is the outing creator or current crew owner.
2. Verify outing is Planning and references the open round.
3. Re-read current crew memberships and participant attendance states.
4. Filter votes to accepted current participants and eligible proposals.
5. Require at least one eligible vote in each category.
6. Determine leaders without publishing interim counts.
7. If tied, validate the organizer selected only from the tied leaders returned by their preview command.
8. Write aggregate results, selected proposal IDs, participation snapshots, and close timestamps.
9. Update outing time, location, status, and agreement pointers in the same transaction.
10. Mark the command succeeded with only post-confirmation-safe result data.
