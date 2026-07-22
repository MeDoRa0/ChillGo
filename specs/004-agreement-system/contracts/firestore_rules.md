# Contract: Firestore Security Rules for Agreement System

These rules complement trusted Functions validation. Admin SDK writes bypass Security Rules, so every command handler must repeat authorization and invariant checks.

## Shared Helpers

Rules add predictable paths and checks for outing participants, agreement rounds, proposals, votes, and commands. Common checks verify:

- authenticated current crew membership;
- outing-to-crew and round-to-outing consistency;
- current participant record at `${outingId}_${request.auth.uid}`;
- Accepted attendance status;
- outing Planning state and matching active round;
- exact document shapes and immutable identity fields.

## `outing_participants`

- Crew members retain existing roster read access.
- New non-creator participants must start `invited` with null `respondedAt`.
- Creator participant must start `accepted` with a timestamp.
- A participant may update only their own `attendanceStatus` and `respondedAt`, preserving every other field, before Meeting.
- `attendanceStatus` must be `accepted` or `declined` for a response and `respondedAt` must be a current request timestamp.
- Profile synchronization remains permitted through the existing allowlisted profile fields.

## `agreement_rounds`

- Current crew members may read round documents.
- All client create, update, and delete operations are denied.
- Open documents must never contain aggregate counts or final selections; Functions are responsible for trusted writes.

## `agreement_proposals`

- Current crew members may read proposals belonging to their outing.
- All client create, update, and delete operations are denied; proposals are command-created and immutable.

## `agreement_votes`

- `get` is allowed only when `resource.data.userId == request.auth.uid`.
- `list` is denied, preventing clients from reconstructing totals or identities.
- Create/update/delete is allowed only to the signed-in voter while they are an Accepted participant, a current crew member, the outing is Planning, and the referenced round is active/open.
- Document ID must equal `${roundId}_${category}_${request.auth.uid}`.
- Proposal must exist and match the same round, outing, crew, and category.
- Updates may change only `proposalId` and `updatedAt`; identity and `createdAt` are immutable.
- A time vote targeting a proposal already in the past is rejected.

## `agreement_results`

- Current crew members may read results only when the owning round is not open.
- All client writes and deletes are denied.

## `agreement_commands`

- A current crew member may create a command only when `requestedByUserId == request.auth.uid`, status is `pending`, timestamps and keys match the exact request schema, and the referenced outing belongs to the claimed crew.
- A `delete_outing` command may be created only by the outing creator; crew ownership alone does not grant permanent-removal permission.
- An `expire_outing` command with an empty payload may be created by any current crew member; Functions enforce the 12-hour threshold against the authoritative outing document.
- Type-specific payload keys are allowlisted; results, errors, processing fields, and hidden tally data cannot be supplied at creation.
- Only the requester may get/list their command documents.
- All client updates and deletes are denied.
- Command creation rules provide a first authorization layer; Functions revalidate roles and state transactionally.

## `outings`

- Add agreement pointer fields to the valid shape.
- Client detail edits cannot change agreement fields.
- Client lifecycle edits cannot perform `draft -> planning`, `planning -> confirmed`, or `confirmed -> planning`; these are trusted command effects.
- Client edits may change scheduled time and location only while the outing is Draft. From Planning onward, those fields are agreement-controlled; title and description retain their existing active-outing edit policy.
- Direct client deletion is denied. Permanent removal is performed by trusted `delete_outing` or `expire_outing` handling after creator or expiry authorization.

## Required Emulator Tests

- Only a participant can change their attendance response; changes stop at Meeting.
- Non-participants and former crew members cannot respond, propose, vote, read results, or create useful commands.
- Vote gets are owner-only and vote list queries fail for participants, organizers, and owners.
- Vote IDs enforce one vote per category; valid selection changes and withdrawals work only during an open round.
- Proposal and result client writes always fail.
- Open-round documents expose no aggregate fields.
- Command documents are requester-readable, create-only, exact-shape, and payload-allowlisted.
- Direct agreement-controlled outing transitions and pointer edits fail.
- Direct schedule/location edits fail in Planning, Confirmed, Meeting, and historical states.
- Closed results are readable to current crew members without revealing individual votes.
- Batched removal/membership changes cannot be abused to retain agreement access.
- Crew owners and participants cannot permanently remove an outing they did not create; creator-authored `delete_outing` commands are accepted in every lifecycle status.
