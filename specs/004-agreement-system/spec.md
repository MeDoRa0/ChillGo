# Feature Specification: Agreement System

**Feature Branch**: `codex/004-agreement-system`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Read main_plan.md and create a specification for Phase 4 — Agreement System only"

## Clarifications

### Session 2026-07-11

- Q: When should vote totals and individual selections be visible? → A: Votes and totals remain hidden until confirmation; afterward, aggregate results are visible while individual votes remain private.
- Q: How should a tie be resolved while voting results are sealed? → A: During confirmation, reveal only the tied leading choices to the authorized organizer, who selects one; keep counts and voter identities hidden until confirmation completes.
- Q: Can submitted proposals be edited or withdrawn? → A: No. Proposals are immutable after submission; participants submit a new proposal to correct one, and expired time proposals become ineligible automatically.
- Q: What minimum voting participation is required for confirmation? → A: At least one eligible vote is required in both the time and location categories; no percentage-based quorum applies.

### Session 2026-07-13

- Q: When may an outing be removed, and who may remove it? → A: The outing creator may permanently remove the outing at any time, regardless of lifecycle status.
- Q: What happens after an outing's scheduled time passes? → A: Once 12 hours have elapsed, an app client that observes the outing sends a cleanup command; trusted backend processing revalidates the authoritative schedule before permanent removal.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Respond to an Outing (Priority: P1)

An invited outing participant accepts or declines the outing so the crew can distinguish likely attendees from people who will not attend.

**Why this priority**: Attendance intent is the minimum agreement needed before collaborative planning is useful and directly addresses uncertainty about who is attending.

**Independent Test**: Can be fully tested by adding a crew member to an outing, having that member accept or decline, and verifying that the current response is visible to eligible crew members.

**Acceptance Scenarios**:

1. **Given** a current crew member is an invited participant in an outing that has not started, **When** the member accepts, **Then** the member's response becomes Accepted and is reflected in the attendance summary.
2. **Given** an invited participant does not plan to attend, **When** the participant declines, **Then** the response becomes Declined while the member remains visible in the outing roster.
3. **Given** an invited participant changes their mind before the outing enters Meeting, **When** the participant changes their response, **Then** the latest response replaces the previous response without creating a duplicate participant.
4. **Given** a crew member is not an outing participant, **When** that member attempts to accept or decline, **Then** the response is rejected and no attendance totals change.

---

### User Story 2 - Suggest Times and Locations (Priority: P2)

An accepted participant suggests a future date and time or a free-text location during planning so the crew can consider concrete alternatives in one shared place.

**Why this priority**: Structured proposals prevent possible times and places from being lost in conversation and create the choices needed for voting.

**Independent Test**: Can be fully tested by accepting an outing, submitting one time proposal and one location proposal, and verifying both appear as choices for that outing's active agreement round.

**Acceptance Scenarios**:

1. **Given** an accepted participant is viewing an outing in Planning, **When** the participant suggests a valid future date and time, **Then** the proposal is added to the active time choices with its author visible.
2. **Given** an accepted participant is viewing an outing in Planning, **When** the participant suggests a non-empty free-text location, **Then** the proposal is added to the active location choices with its author visible.
3. **Given** an equivalent active proposal already exists, **When** another participant submits the same time or normalized location, **Then** the existing choice is reused rather than displaying a duplicate choice.
4. **Given** an outing is Draft, Confirmed, Meeting, Completed, Archived, or Cancelled, **When** a participant attempts to add a proposal, **Then** the proposal is rejected with an explanation that proposals are only open during Planning.
5. **Given** a participant has submitted a proposal, **When** anyone attempts to edit or withdraw it, **Then** the proposal remains unchanged; a corrected choice must be submitted separately.

---

### User Story 3 - Vote on Proposed Details (Priority: P3)

An accepted participant casts one vote for a preferred time and one vote for a preferred location, and can change or withdraw either vote while planning remains open.

**Why this priority**: Voting turns suggestions into a transparent group preference and enables the organizer to confirm details based on the crew's input.

**Independent Test**: Can be fully tested by creating multiple choices in both categories; casting, changing, and withdrawing votes; and verifying that each participant retains at most one current vote per category, a withdrawn category returns to no current selection, and sealed aggregate information remains inaccessible while voting is open.

**Acceptance Scenarios**:

1. **Given** an accepted participant has not voted in a category, **When** the participant selects an active proposal, **Then** one vote is recorded for that participant in that category.
2. **Given** an accepted participant has already voted in a category, **When** the participant selects another active proposal in the same category, **Then** the vote moves to the new choice and the participant still has exactly one vote in that category.
3. **Given** an accepted participant has voted in a category, **When** the participant withdraws that vote while the agreement remains open, **Then** the participant has no current selection in that category and may cast another vote later.
4. **Given** voting remains open, **When** an eligible participant views the outing agreement, **Then** the participant can see their own selections but cannot see vote totals, leading choices, ties, or other participants' selections.
5. **Given** a participant has declined, left the crew, been removed from the outing, or the agreement is closed, **When** that user attempts to vote, **Then** the vote is rejected and totals remain unchanged.

---

### User Story 4 - Confirm the Group Agreement (Priority: P4)

The outing creator or crew owner closes voting and confirms the leading time and location so the outing has one authoritative schedule and meeting place.

**Why this priority**: Suggestions and voting only resolve coordination when an authorized person can turn the result into final outing details that everyone can trust.

**Independent Test**: Can be fully tested by completing both ballots, confirming their leading choices, and verifying that the outing details and lifecycle status reflect the final agreement and no further votes are accepted.

**Acceptance Scenarios**:

1. **Given** an outing is in Planning and both categories have at least one proposal, **When** the outing creator or crew owner confirms the agreement, **Then** a leading time and a leading location become the final outing details and the outing becomes Confirmed.
2. **Given** two or more choices are tied for the lead in a category, **When** the outing creator or crew owner begins confirmation, **Then** only the tied leading choices are revealed for selection, vote counts and voter identities remain hidden, and the selected tie resolution is preserved in the final agreement.
3. **Given** a non-authorized participant attempts final confirmation, **When** the action is submitted, **Then** the agreement remains open and no outing details change.
4. **Given** either category has no proposal, **When** an authorized organizer attempts final confirmation, **Then** confirmation is blocked and the missing decision is identified.
5. **Given** an agreement has been confirmed, **When** any participant attempts to add a proposal or cast or change a vote, **Then** the action is rejected and the confirmed result remains unchanged.
6. **Given** either category has received no eligible vote, **When** an authorized organizer attempts final confirmation, **Then** confirmation is blocked without revealing interim totals and the organizer is told that more participation is required.

---

### User Story 5 - Reopen an Agreement When Plans Change (Priority: P5)

Before the outing enters Meeting, the outing creator or crew owner reopens a confirmed agreement when the agreed time or location must change, giving accepted participants a new decision round without rewriting the historical result.

**Why this priority**: Real plans sometimes change after confirmation; a controlled reopening prevents silent edits from undermining trust in the agreement.

**Independent Test**: Can be fully tested by confirming an agreement, reopening it before Meeting, and verifying that a new Planning round accepts proposals and votes while the prior confirmed round remains visible as history.

**Acceptance Scenarios**:

1. **Given** an outing is Confirmed and has not entered Meeting, **When** the outing creator or crew owner provides a reason and reopens agreement, **Then** a new agreement round opens, the outing returns to Planning, and the prior round remains read-only.
2. **Given** a reopened agreement round begins, **When** participants view its choices, **Then** the currently confirmed time and location are available as initial choices without carrying forward prior votes.
3. **Given** an outing is in Meeting, Completed, Archived, or Cancelled, **When** an organizer attempts to reopen agreement, **Then** reopening is rejected and historical agreement data remains unchanged.

---

### User Story 6 - Remove an Outing (Priority: P6)

The outing creator permanently removes an outing when it should no longer exist, regardless of its current lifecycle status.

**Why this priority**: The creator remains accountable for the outing and needs a definitive cleanup action even after planning, confirmation, meeting, completion, cancellation, or archival.

**Independent Test**: Can be fully tested by creating outings in every supported lifecycle status, removing each as its creator, and verifying that the outing and all outing-owned participant and agreement data are no longer accessible while non-creators remain unable to remove it.

**Acceptance Scenarios**:

1. **Given** an outing exists in any supported lifecycle status, **When** its creator confirms permanent removal, **Then** the outing and all data owned exclusively by that outing are removed and it no longer appears to crew members.
2. **Given** an outing has an open or completed agreement round, **When** its creator removes the outing, **Then** its participant records, rounds, proposals, votes, aggregate results, and pending agreement work are also removed or terminated without leaving accessible orphaned data.
3. **Given** a crew owner or participant who did not create the outing attempts to remove it, **When** the request is submitted, **Then** removal is rejected and all outing data remains unchanged.
4. **Given** two removal requests overlap, **When** the first succeeds, **Then** later requests complete safely without restoring data or exposing an internal failure to the creator.

### Edge Cases

- The outing creator is automatically a participant and starts as Accepted, ensuring at least one eligible participant exists.
- An invited participant does not respond; the response remains Invited and is counted separately from Accepted and Declined.
- An accepted participant declines after voting; their votes stop contributing to active totals while their prior actions remain attributable in history.
- A participant is removed from the outing or crew while planning is open; they lose agreement access and their votes stop contributing to active totals.
- A proposed time passes before confirmation; it becomes ineligible for confirmation and must not be selected as the final time.
- A participant notices an error in a submitted proposal; the original remains unchanged and the participant may submit a corrected, non-equivalent proposal during Planning.
- Equivalent locations differ only by capitalization or surrounding whitespace; they are treated as one active choice.
- All votes are tied, or only one eligible participant votes; the result remains valid and transparently shows the level of participation.
- Two participants vote or change votes at nearly the same time; each participant still has at most one current vote per category and totals remain accurate.
- Confirmation and another vote occur nearly simultaneously; once confirmation succeeds, the final result is stable and later voting changes are rejected.
- The outing is cancelled while planning is open; proposals and votes become read-only history and cannot be confirmed.
- A confirmed outing is reopened more than once; each round remains distinct and prior results are not overwritten.
- The creator removes an outing while an agreement command is pending; the command cannot mutate or recreate the removed outing, and the removal completes safely.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow only current outing participants who are current members of the owning crew to respond to an outing invitation.
- **FR-002**: System MUST support exactly one current attendance response per outing participant: Invited, Accepted, or Declined.
- **FR-003**: System MUST allow an invited participant to accept or decline and allow a participant to change that response until the outing enters Meeting.
- **FR-004**: System MUST keep declined participants visible in the outing roster and show separate counts for Invited, Accepted, and Declined responses.
- **FR-005**: System MUST treat the outing creator as Accepted when the creator is automatically added as the first participant.
- **FR-006**: System MUST allow Accepted participants to create time and location proposals only while the outing is in Planning.
- **FR-007**: Each time proposal MUST identify a future date and time, its author, its agreement round, and its current eligibility for voting and confirmation.
- **FR-008**: Each location proposal MUST contain a non-empty free-text location, its author, its agreement round, and its current eligibility for voting and confirmation.
- **FR-009**: System MUST prevent equivalent active time or location proposals from appearing as duplicate voting choices within the same agreement round, and all submitted proposals MUST remain immutable and non-withdrawable.
- **FR-010**: System MUST treat the outing's current scheduled time and location as the initial proposals when an agreement round first opens.
- **FR-011**: System MUST allow each Accepted participant to hold at most one current vote in the time category and at most one current vote in the location category during an open agreement round.
- **FR-012**: System MUST allow an eligible voter to cast, change, or withdraw each vote while the agreement round remains open.
- **FR-013**: During an open agreement round, the system MUST show each eligible participant the active choices and their own current selections while hiding vote totals, leading choices, ties, participation counts, and other participants' selections.
- **FR-014**: System MUST exclude from active totals any vote belonging to a participant who declines, leaves the crew, or is removed from the outing before confirmation.
- **FR-015**: System MUST prevent users from proposing or voting unless they are Accepted participants and current members of the outing's crew.
- **FR-016**: System MUST allow only the outing creator or crew owner to confirm or reopen an agreement.
- **FR-017**: System MUST allow final confirmation only while the outing is in Planning, both time and location have at least one eligible proposal, and each category has received at least one eligible vote.
- **FR-018**: System MUST require the confirmed choice in each category to be a leading eligible proposal; when leading proposals are tied, the system MUST reveal only the tied leading choices to the confirming organizer, allow selection of any tied leader, and keep vote counts and voter identities hidden until confirmation completes.
- **FR-019**: Final confirmation MUST set the outing's scheduled time and free-text location to the selected choices, preserve who confirmed and when, close the active agreement round, and move the outing to Confirmed.
- **FR-020**: System MUST reject new proposals and vote changes after an agreement round is confirmed, cancelled, or superseded.
- **FR-021**: Until the outing creator removes the outing or app-observed cleanup runs at least 12 hours after its scheduled time, the system MUST preserve completed agreement rounds, their proposals, aggregate vote results, participation totals, selected choices, and confirmation outcome as read-only crew history; individual participants' ballot selections MUST remain private after confirmation.
- **FR-022**: System MUST allow an authorized organizer to reopen a Confirmed outing before Meeting only when a reason is provided.
- **FR-023**: Reopening MUST return the outing to Planning, create a new agreement round, seed it with the currently confirmed time and location, start with no votes, and preserve every prior round unchanged.
- **FR-024**: System MUST show a clear message when an agreement action is blocked because of permissions, attendance status, outing status, expired time, invalid input, or a closed agreement round.
- **FR-025**: System MUST prevent users who are not current members of the owning crew from viewing or changing attendance responses, proposals, votes, or agreement results.
- **FR-026**: Phase 4 MUST NOT add outing chat, read receipts, live meetup statuses, live location sharing, maps, automatic notifications, or push notifications.
- **FR-027**: System MUST allow only the outing creator to request permanent removal at any time, regardless of whether it is Draft, Planning, Confirmed, Meeting, Completed, Archived, or Cancelled.
- **FR-028**: Permanent outing removal MUST remove or render inaccessible every record owned exclusively by the outing, including participant records, agreement rounds, proposals, votes, aggregate results, and pending agreement work, without allowing an in-flight action to recreate outing data.
- **FR-029**: Permanent outing removal MUST be idempotent so repeated or overlapping removal requests do not restore data or produce a user-visible system failure after the outing is already absent.
- **FR-030**: When an authenticated crew member's app observes an outing at least 12 hours after `scheduledAt`, it MUST send an `expire_outing` command. Trusted processing MUST re-read the outing, reject early or non-member requests, and permanently remove eligible outings and all exclusively owned records.

### Key Entities *(include if feature involves data)*

- **Attendance Response**: The current invitation decision for one outing participant. It associates the participant and outing with exactly one state—Invited, Accepted, or Declined—and records when the current response was made.
- **Agreement Round**: One bounded decision cycle for an outing. It identifies its outing, sequence, open or closed state, opening context, eligible participation, final selections, confirming organizer and time, and reopening reason when derived from a prior confirmation.
- **Time Proposal**: A candidate future date and time within one agreement round, including its author, creation time, eligibility state, and relationship to any final selection.
- **Location Proposal**: A candidate free-text meeting location within one agreement round, including its author, normalized identity for duplicate detection, creation time, eligibility state, and relationship to any final selection.
- **Vote**: One participant's current selection in either the time or location category for one agreement round. A participant can have no more than one current vote per category.
- **Final Agreement**: The immutable outcome of a confirmed agreement round, including the selected time and location, participation totals, tie resolution where applicable, and who confirmed it and when.
- **Outing**: The crew event whose participant roster, schedule, location, and Planning or Confirmed lifecycle state govern the agreement process.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 95% of invited participants can accept or decline an outing in under 30 seconds during usability testing.
- **SC-002**: At least 90% of accepted participants can submit a valid proposal and cast both a time vote and a location vote without assistance on their first attempt.
- **SC-003**: 100% of validation scenarios maintain no more than one current attendance response per participant and one current vote per participant per category.
- **SC-004**: In at least 100 instrumented trials per operation under a network profile with round-trip latency no greater than 100 ms and packet loss below 1%, at least 95% of completed attendance and vote actions MUST appear in the acting participant's UI within 3 seconds measured from submission. For confirmation commands, a warm invocation—defined as an invocation occurring within 5 minutes of a successful agreement command—MUST publish the confirmed aggregate within 3 seconds in at least 95% of trials. Cold invocations are excluded from the three-second calculation but MUST expose a pending state within 500 milliseconds.
- **SC-005**: 100% of confirmed outings have at least one eligible vote in each category and use eligible leading choices for both time and location, including an explicitly selected tied leader when a tie exists.
- **SC-006**: 100% of unauthorized agreement actions are blocked without revealing private crew agreement data.
- **SC-007**: At least 90% of test users can identify whether agreement is open or confirmed in under 20 seconds and, after confirmation, identify the leading choices and participation level in the same time.
- **SC-008**: 100% of reopened agreements preserve the prior confirmed result and begin a distinct round with zero carried-over votes.
- **SC-009**: At least 90% of test users report that the final outing time and location and the basis for confirmation are clear.
- **SC-010**: In 100% of validation scenarios across all supported outing statuses, the creator can permanently remove the outing, non-creators cannot, and no outing-owned participant or agreement record remains accessible afterward.
- **SC-011**: In 100% of cleanup boundary tests, an app signal at or after `scheduledAt + 12 hours` removes the outing and its exclusively owned records, while an earlier signal is rejected and leaves the outing unchanged.

## Assumptions

- Phase 2 Crew Management and Phase 3 Outing Management are available, including crew membership, outing participant rosters, creator and crew-owner roles, editable free-text locations, and the outing lifecycle.
- An outing enters the agreement workflow when an authorized organizer moves it from Draft to Planning; proposal and voting actions are unavailable in Draft.
- Only Accepted outing participants propose and vote. Invited and Declined participants can view the agreement if they remain current crew members but do not affect voting eligibility.
- The initial Phase 3 scheduled time and location are treated as proposals rather than silently discarded when planning opens.
- A proposal author does not automatically cast a vote merely by creating a proposal; voting intent is recorded separately.
- Submitted proposals cannot be edited or withdrawn. Corrections are new proposals, and expired time proposals become ineligible without being deleted from the round history.
- Phase 4 uses one-choice voting independently for time and location. Ranking, multiple selections, anonymous ballots, weighted votes, vetoes, comments, and percentage-based quorum thresholds are outside this specification.
- Final confirmation is organizer-controlled but constrained to the crew's leading eligible choices. A simple plurality determines the lead; tied leaders require an explicit organizer choice.
- Vote totals, participation counts, leading choices, and ties remain hidden while voting is open to reduce social influence. The only pre-result exception is that an authorized organizer resolving a tie during confirmation sees the tied leading choices without counts or voter identities. After confirmation, crew members can see aggregate results but not how any individual participant voted.
- Agreement does not require unanimous attendance or a percentage-based voting quorum. At least one eligible vote is required in each category, and the organizer may choose when to attempt confirmation without seeing voting participation totals beforehand.
- Attendance responses can change until Meeting begins, but proposals and votes close when the agreement is confirmed. A later detail change requires reopening rather than silently editing the confirmed result.
- Reopening a confirmed agreement is permitted only before Meeting and introduces a Confirmed-to-Planning lifecycle transition for this feature.
- Removing participants and cancelling, completing, or archiving outings remain Phase 3 capabilities. This feature allows only the outing creator to request early permanent removal in any lifecycle status and also allows app-observed cleanup after a 12-hour grace period; both paths clean up all agreement data owned by the outing.
- Location remains free-text in Phase 4. Map search, coordinates, travel estimates, and map-provider integration are outside scope.
- Chat belongs to Phase 5, live meetup status and location belong to Phase 6, and notifications belong to Phase 7.
