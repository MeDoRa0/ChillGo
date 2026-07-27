# Feature Specification: Outing Chat

**Feature Branch**: `codex/005-outing-chat`

**Created**: 2026-07-22

**Status**: Draft

**Input**: User description: "Read `main_plan.md` and create a specification for Phase 5 — Outing Chat."

## Clarifications

### Session 2026-07-22

- Q: What retention action should occur when a chat message reaches 24 hours of age? → A: Make it unavailable immediately and permanently delete it through automatic trusted cleanup.
- Q: How should an attempted message send be handled while the participant is offline? → A: Mark it failed and require manual retry.
- Q: What message rate limit should apply? → A: Allow 30 accepted messages per participant per outing per rolling minute.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Exchange Outing Messages (Priority: P1)

A current outing participant sends a text message in that outing's dedicated chat and sees messages from other participants, keeping coordination attached to the outing instead of moving it to an external messaging application.

**Why this priority**: Exchanging outing-specific messages is the core value of Phase 5. Without it, message history, read state, and cleanup have nothing useful to manage.

**Independent Test**: Can be fully tested by adding two current crew members to an active outing, having each send a message, and verifying that both participants see one consistently ordered conversation while a participant in another outing does not.

**Acceptance Scenarios**:

1. **Given** two users are current participants in the same active outing and remain members of its crew, **When** one participant sends a valid text message, **Then** the message appears in that outing's chat for both participants with the sender and send time identified.
2. **Given** multiple participants send messages close together, **When** their chat views update, **Then** every participant sees the same messages in a stable chronological order.
3. **Given** a participant submits an empty, whitespace-only, or over-limit message, **When** the participant attempts to send it, **Then** no message is created and the participant receives a correction message.
4. **Given** delivery of a submitted message is delayed or fails, including because the participant is offline, **When** the sender remains in the chat, **Then** the sender can distinguish sending, sent, and failed outcomes and can manually retry a failed send without creating duplicate messages; the system does not automatically send it after connectivity returns.
5. **Given** a current crew member is not a participant in the outing, **When** that member attempts to open or send to the outing chat, **Then** access is denied without revealing any message content or chat metadata.
6. **Given** a participant has created 30 accepted messages in the same outing during the preceding rolling minute, **When** that participant attempts another send before the rate falls below the limit, **Then** the message is rejected without affecting other participants and the sender is told when sending can be retried.

---

### User Story 2 - Review Recent Conversation History (Priority: P2)

A participant opens an outing chat and reviews its still-available message history so recent decisions and coordination context are not lost when the participant leaves the screen or uses another supported device.

**Why this priority**: Persistent recent history turns isolated real-time messages into a dependable outing communication channel.

**Independent Test**: Can be fully tested by sending enough messages to require older-history loading, closing and reopening the outing on another signed-in session, and verifying that all unexpired messages appear once in the same order while expired messages do not appear.

**Acceptance Scenarios**:

1. **Given** an outing chat contains unexpired messages, **When** an eligible participant opens it, **Then** the newest available messages are shown and the participant can progressively review older available messages.
2. **Given** a participant closes the chat and later reopens it on any supported platform, **When** the history loads, **Then** the same unexpired messages are available with their original authors, content, and send times.
3. **Given** a new participant is added to an outing and remains a current crew member, **When** that participant opens the chat, **Then** the participant can review the outing's currently unexpired message history.
4. **Given** a message has reached its retention limit, **When** any participant loads or refreshes history, **Then** that message is not shown or retrievable through the product.

---

### User Story 3 - Keep Track of Unread Messages (Priority: P3)

A participant can tell when an outing has unread messages, see an accurate unread count, and resume from the first unread message when opening the chat.

**Why this priority**: Read state helps participants catch up efficiently without introducing the broader notification capabilities reserved for Phase 7.

**Independent Test**: Can be fully tested by leaving one participant outside the chat while another sends messages, verifying the first participant's unread count and resume point, then opening the chat and confirming the count clears consistently across sessions.

**Acceptance Scenarios**:

1. **Given** other participants send three messages while a participant is not viewing the chat, **When** the participant next views the outing, **Then** the chat shows three unread messages and opening it resumes at the first unread message.
2. **Given** a participant opens the chat and views all currently available messages, **When** the participant returns to the outing and later signs in on another supported platform, **Then** the chat shows no unread messages until another participant sends a new message.
3. **Given** a participant sends a message, **When** unread state is calculated for that sender, **Then** the sender's own message does not increase their unread count.
4. **Given** an unread message expires or is removed with its outing, **When** unread state is next shown, **Then** that unavailable message is not counted and does not leave an invalid resume point.

---

### User Story 4 - End Chat Access Safely (Priority: P4)

Participants can rely on the outing chat becoming read-only when the outing is no longer active, automatically forgetting old messages, and becoming inaccessible when their participation or the outing ends.

**Why this priority**: A bounded lifecycle protects crew privacy, follows the project's temporary-data policy, and prevents inactive outings from accumulating permanent chat history.

**Independent Test**: Can be fully tested by exercising participant removal, crew removal, terminal outing states, the 24-hour message boundary, and permanent outing removal, then verifying that sends are blocked and unavailable chat data cannot be accessed.

**Acceptance Scenarios**:

1. **Given** an outing moves to Completed, Archived, or Cancelled, **When** a participant opens its chat before existing messages expire, **Then** the available history is read-only and new messages cannot be sent.
2. **Given** a user is removed from the outing or leaves or is removed from the crew, **When** that user attempts to open the chat or use previously loaded chat controls, **Then** access is revoked immediately and no further message content is returned.
3. **Given** a message reaches 24 hours of age, **When** an eligible participant attempts to load it through a supported client, **Then** it is unavailable, and automatic cleanup completes without requiring an organizer action.
4. **Given** the outing creator permanently removes the outing or the existing scheduled outing cleanup removes it, **When** any former participant attempts to access the chat, **Then** the chat messages and read states are inaccessible and no chat action can recreate them.

### Edge Cases

- A participant is viewing a chat when they are removed from the outing or crew; subsequent reads and sends are denied, and already displayed content is cleared when access loss is observed.
- A participant is added, removed, and later re-added; after re-addition, only messages that are still within the 24-hour retention window are available, and old read state does not reveal expired content.
- Two messages receive the same displayed send time; a stable secondary ordering keeps every participant's conversation in the same order.
- A sender retries after losing connectivity immediately after submission; at most one copy of that submitted message appears.
- A message expires while a participant is reading older history; it disappears on the next history update and unread state advances to the next available message.
- New messages arrive while a participant is reviewing older messages; the participant's reading position is preserved and new-message context is surfaced without forcing the view away from the older content.
- An outing changes from an active to a terminal status while a message is being submitted; either the already-accepted message is preserved until expiry or the send is rejected, but no message is created after chat closure.
- An outing is permanently removed while message or read-state work is in flight; the work cannot restore the outing chat or leave accessible orphaned data.
- A participant reaches the rate limit while other participants continue chatting; only that participant's additional sends are blocked, and eligibility returns automatically as accepted messages leave the rolling one-minute window.
- A participant sends text containing emoji, right-to-left text, line breaks, or links; the content remains readable text and does not become an attachment or executable content.
- Device time is incorrect; displayed ordering and the 24-hour retention boundary remain based on the authoritative accepted send time rather than the participant's device clock.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every outing MUST have exactly one logically dedicated chat channel associated with that outing and its owning crew.
- **FR-002**: System MUST allow chat access only to authenticated users who are both current participants in the outing and current members of the outing's crew.
- **FR-003**: Chat eligibility MUST be independent of an outing participant's Invited, Accepted, or Declined attendance response while that user remains a current participant and crew member.
- **FR-004**: System MUST allow eligible participants to send messages only while the outing is in Draft, Planning, Confirmed, or Meeting status.
- **FR-005**: System MUST make chat read-only in Completed, Archived, and Cancelled outings until remaining messages expire or the outing is permanently removed.
- **FR-006**: Each message MUST contain non-whitespace text of 1 to 2,000 Unicode scalar values after surrounding Unicode whitespace is removed.
- **FR-007**: Each message MUST identify its outing, owning crew, author, authoritative accepted send time, content, and a stable identity that prevents one submission from appearing more than once.
- **FR-008**: System MUST present available messages in a stable chronological order and MUST preserve that order when older history or newly arriving messages are added to the view.
- **FR-009**: Eligible participants MUST be able to load the newest available messages first and progressively load older messages that remain within the retention window.
- **FR-010**: System MUST expose a clear sending, sent, or failed outcome for the acting sender, MUST mark an offline submission as failed rather than queueing it for automatic delivery, and MUST allow the sender to retry manually without duplicating a previously accepted submission.
- **FR-011**: System MUST preserve accepted message content, author, and send time unchanged until the message expires or its outing is permanently removed.
- **FR-012**: System MUST maintain one personal read position per eligible participant per outing chat.
- **FR-013**: System MUST show each participant an unread count based on available messages from other participants after that participant's read position, and MUST NOT count the participant's own messages as unread.
- **FR-014**: When an eligible participant views available messages through the newest message, the system MUST advance that participant's read position and reflect the updated unread state in later sessions on every supported platform.
- **FR-015**: Opening a chat with unread messages MUST make the first available unread message easy to locate without preventing access to earlier available history.
- **FR-016**: Read state MUST be private to its participant; Phase 5 MUST NOT expose who has read another participant's message or provide per-message read receipts to other users.
- **FR-017**: Every chat message MUST become unavailable in supported clients exactly when `expiresAt = acceptedAt + 24 hours`. Trusted scheduled cleanup MUST permanently delete expired message records automatically without participant or organizer action, and Firestore TTL MUST provide a retry backstop.
- **FR-018**: Cleanup of expired messages MUST also prevent expired messages from contributing to unread counts or resume positions and MUST NOT leave accessible orphaned read-state references.
- **FR-019**: When a user stops being an outing participant or current crew member, the next server authorization evaluation MUST deny new chat reads, history loads, sends, and read-state changes. After a supported client observes the participant/membership removal or a permission-denied result, it MUST clear already displayed protected chat content within one second and before accepting any later chat state.
- **FR-020**: When an outing is permanently removed through creator-requested removal or scheduled outing cleanup, the system MUST remove or render inaccessible all of its chat messages and read states, and in-flight chat actions MUST NOT recreate them.
- **FR-021**: System MUST map every blocked chat action to one of the stable, non-sensitive explanation categories below. Explanations MUST identify the corrective action when one exists, MUST expose `retryAt` only to the acting rate-limited participant, and MUST NOT reveal whether an inaccessible outing, participant, membership, message, or another participant's private read state exists.
- **FR-022**: System MUST support the outing chat and its read state consistently on Android, iOS, Web, and Windows.
- **FR-023**: Phase 5 MUST support plain-text messages only and MUST NOT add message editing, manual message deletion, attachments, voice notes, reactions, threaded replies, mentions, search, moderation tools, typing indicators, online presence, live meetup status, live location, maps, automatic notifications, or push notifications.
- **FR-024**: System MUST allow each participant to create no more than 30 accepted messages in one outing during any rolling one-minute window, MUST reject only that participant's excess sends, and MUST communicate when the participant may retry.

### Failure Explanation Categories

| Failure source | User-facing category | Required guidance |
|---|---|---|
| Missing authentication | Sign-in required | Ask the user to sign in before retrying |
| Missing/removed participation or crew membership, missing/deleting outing, or protected not-found result | Chat unavailable | Return to the outing list; do not reveal which eligibility check failed |
| Completed, Archived, or Cancelled outing | Chat is read-only | Explain that available history can still be reviewed but new messages cannot be sent |
| Empty, whitespace-only, over-limit, or otherwise invalid message content | Message needs correction | Preserve only the acting user's local draft and identify the valid plain-text limit |
| Stable message identity reused with different outing, author, or text | Message could not be retried | Preserve the acting user's local draft, create a fresh local message identity, and offer explicit resend without exposing internal identifiers |
| Offline or unreachable service before command creation | Connection failed | Explain that nothing was queued and offer explicit manual retry |
| Expired message or history boundary | Message no longer available | Explain that outing chat history expires after 24 hours |
| Rolling-window rejection | Too many messages | Show the acting participant's safe `retryAt` time |
| Unknown trusted processing failure | Chat service unavailable | Offer a safe explicit retry without exposing backend details |

### Key Entities *(include if feature involves data)*

- **Outing Chat Channel**: The logical communication space owned by exactly one outing and crew. Its availability and writeability are governed by outing existence, outing lifecycle status, participant membership, and crew membership.
- **Chat Message**: One immutable text contribution to an outing chat. Key attributes include stable identity, outing and crew association, author, content, authoritative accepted send time, and expiration time.
- **Chat Read State**: One participant's private progress within one outing chat. It identifies the participant, outing, latest available message read, and the time that progress changed; it supports unread counts without exposing read receipts to other participants.
- **Outing Participant**: A current crew member included in a specific outing. Current participant and crew membership jointly determine chat access; attendance response does not change that access by itself.
- **Outing**: The crew event that owns the chat. Its lifecycle status determines whether participants can send or only review available history, and its permanent removal ends all chat access.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 95% of eligible participants can open an outing chat and send a valid first message in under 30 seconds during usability testing.
- **SC-002**: Under a network profile with round-trip latency no greater than 100 milliseconds and packet loss below 1%, at least 95% of accepted messages appear as sent to the sender and become visible to another participant who has the chat open within 3 seconds, measured across at least 100 message trials.
- **SC-003**: In 100% of validation scenarios, all eligible participants see the same accepted messages in the same order with no duplicate created by submission retries.
- **SC-004**: In 100% of read-state validation scenarios, unread counts exclude the participant's own and expired messages, opening the chat locates the first available unread message, and viewing through the newest message reduces the count to zero across later sessions.
- **SC-005**: In 100% of authorization tests, non-participants, former participants, and non-members cannot read message content, send messages, inspect read state, or infer protected chat metadata.
- **SC-006**: In 100% of retention-boundary tests, a message is available in supported clients immediately before `expiresAt`, becomes unavailable in supported clients at `expiresAt`, is selected by the first successful scheduled cleanup invocation after expiry, and requires no participant or organizer action.
- **SC-007**: For an outing with up to 100 participants and 5,000 unexpired messages, at least 95% of history-opening trials show the newest available conversation content within 3 seconds under the network conditions defined in SC-002.
- **SC-008**: At least 90% of test participants can identify whether an outing has unread messages, open the chat at the unread boundary, and determine whether the chat is writable or read-only without assistance.
- **SC-009**: In 100% of permanent outing-removal tests, no chat message or read state remains accessible and no overlapping chat action recreates outing-owned chat data.
- **SC-010**: In 100% of rate-limit boundary tests, the first 30 eligible messages from one participant in one outing during a rolling minute can be accepted, further messages are rejected until the rolling count falls below 30, and other eligible participants remain able to send.

### Usability Measurement Protocol

SC-001 and SC-008 MUST be evaluated with at least 20 representative participants who have not previously completed the measured workflow. Results MUST include at least five trials on each supported platform: Android, iOS, Web, and Windows.

For SC-001, timing begins when the eligible outing entry is visible and ends when the first valid message reaches the sent state. At least 95% of the total sample, and no fewer than 19 participants, MUST finish within 30 seconds without assistance.

For SC-008, at least 90% of the total sample, and no fewer than 18 participants, MUST identify unread state, open the chat at the unread boundary, and identify writable versus read-only status without assistance.

## Assumptions

- Phase 2 Crew Management, Phase 3 Outing Management, and Phase 4 Agreement System are available, including authenticated users, crew membership, outing participant rosters, attendance responses, the full outing lifecycle, and permanent outing-removal behavior.
- A current outing participant who remains a current crew member may use chat regardless of whether their attendance response is Invited, Accepted, or Declined. Removing the participant or crew membership ends access.
- Sending is available only for active outings: Draft, Planning, Confirmed, and Meeting. Completed, Archived, and Cancelled chats retain only read-only, unexpired history.
- Message history is temporary and rolling: each message becomes unavailable in supported clients 24 hours after its authoritative accepted send time and is permanently removed by automatic trusted cleanup rather than being retained until the outing ends.
- Creator-requested permanent outing removal and the existing cleanup performed at least 12 hours after the outing's scheduled time take precedence over the per-message retention window and remove outing-owned chat data sooner when applicable.
- Newly added outing participants may see all messages that are still unexpired when they gain access; the product does not maintain a separate join-time history boundary.
- Read status means a participant's private unread count and resume position. Cross-participant read receipts and “seen by” lists are outside this phase.
- Messages are immutable plain text. Rich media, editing, manual deletion, social engagement features, moderation, live coordination, and notification delivery require later specifications if they are added.
- Offline submissions are not queued for automatic delivery. They remain visibly failed until the participant chooses to retry after connectivity returns.
- The 2,000-Unicode-scalar-value limit includes visible text, emoji, line breaks, and link text after surrounding Unicode whitespace is removed.
- The 5,000-message scale target describes concurrently unexpired history for one outing, not permanent storage, because all messages remain subject to the 24-hour retention rule.
