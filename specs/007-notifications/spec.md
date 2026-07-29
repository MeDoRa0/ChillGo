# Feature Specification: Notifications

**Feature Branch**: `codex/007-notifications`

**Created**: 2026-07-29

**Status**: Draft

**Input**: User description: "Read `main_plan.md` and create a specification for Phase 7 — Notifications only."

## Clarifications

### Session 2026-07-29

- Q: Which device-alert categories may a user mute? → A: Invitations, agreement confirmed, and agreement reopened cannot be muted; voting, outing-change, and arrival alerts can be muted.
- Q: What happens to a notification when its source access is lost or the source is removed? → A: Immediately delete invalidated notifications; they disappear from the notification center and unread count.
- Q: Which devices receive an eligible device alert? → A: Attempt delivery on every eligible registered device or browser.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive Invitations Promptly (Priority: P1)

A user receives a clear, actionable alert when they are invited to join a crew or an outing, so they can respond without repeatedly checking every crew or outing.

**Why this priority**: Invitations are the entry point to the collaborative workflows. Missing them prevents the recipient from participating at all.

**Independent Test**: Can be fully tested by inviting a user to a crew and then to an outing, verifying that each intended recipient gets one actionable notification, and completing or invalidating each invitation.

**Acceptance Scenarios**:

1. **Given** a crew invitation is successfully created for a registered user, **When** the recipient becomes eligible to see it, **Then** the recipient receives one crew-invitation notification that identifies the inviting crew and opens the pending invitation.
2. **Given** an outing invitation is successfully created for a current crew member, **When** the recipient becomes eligible to see it, **Then** the recipient receives one outing-invitation notification that identifies the outing and opens its invitation response.
3. **Given** an invitation has already been accepted, declined, revoked, expired, or otherwise made unavailable, **When** notification access next refreshes, **Then** its notification is removed from the recipient's notification center and unread count and does not expose stale invitation details.
4. **Given** the source action is retried or its notification processing is retried, **When** the action represents the same successful invitation, **Then** the recipient has no duplicate invitation notification or duplicate device alert.

---

### User Story 2 - Stay Current on an Outing (Priority: P1)

A current outing participant receives relevant updates when the outing's plan changes or when the group reaches a voting outcome, so they can act on the current plan without monitoring the outing continuously.

**Why this priority**: A timely final plan and material changes are essential to coordinating an outing successfully.

**Independent Test**: Can be fully tested by changing an outing's material details, creating a new voting choice, confirming or reopening an agreement, and verifying recipients, message meaning, navigation, and preference behavior.

**Acceptance Scenarios**:

1. **Given** a current participant is eligible for an outing, **When** an authorized organizer successfully changes its title, description, scheduled time, or confirmed location, **Then** the participant receives one update notification that identifies the outing and describes only the changed field or fields.
2. **Given** a Planning outing receives a new eligible time or location proposal, **When** the proposal is accepted, **Then** the other current eligible voters receive a voting-update notification that opens the relevant agreement round without revealing another participant's ballot.
3. **Given** an agreement is successfully confirmed or reopened, **When** the resulting outing state is available, **Then** every current outing participant receives one notification that opens the confirmed result or the new planning round, as applicable.
4. **Given** a participant has disabled optional voting or outing-change alerts, **When** one of those events occurs, **Then** no device alert is delivered for that category while the participant can still view the current outing when authorized.

---

### User Story 3 - Know When Attendees Arrive (Priority: P2)

An accepted participant in a Meeting outing can opt into arrival alerts from other accepted attendees, allowing the group to coordinate the final moments of the meetup without disclosing locations.

**Why this priority**: Arrival is a high-value, time-sensitive update, but it is relevant only during an active meetup and must respect each person's alert preference.

**Independent Test**: Can be fully tested by enabling and disabling arrival alerts, having eligible attendees set Arrived, and verifying the alert is delivered once to the correct recipients without exposing a location.

**Acceptance Scenarios**:

1. **Given** an outing is in Meeting and two users are current crew members, current outing participants, and Accepted attendees, **When** one user explicitly sets their status to Arrived, **Then** the other user receives one arrival notification that identifies the arriving attendee and the outing but does not include a precise location.
2. **Given** a user has disabled arrival alerts, **When** another eligible attendee arrives, **Then** that user does not receive a device alert but may still see the current arrival status in Live Meetup when authorized.
3. **Given** a user selects Getting Ready or On My Way, **When** the live status is accepted, **Then** no arrival notification is created.
4. **Given** an attendee changes to Arrived more than once, **When** the subsequent status updates are accepted, **Then** each recipient receives at most one arrival notification for that attendee and outing during the same Meeting period.

---

### User Story 4 - Review and Control Notifications (Priority: P2)

A user can review recent notifications in one place, distinguish unread items, navigate safely to the relevant current information, and choose which optional device alerts they receive.

**Why this priority**: A reviewable in-app record makes important updates dependable when a device alert is missed, while preferences prevent unwanted interruptions.

**Independent Test**: Can be fully tested by generating notifications across categories, reading and opening them on another supported device, changing preferences, and verifying that unavailable sources reveal no protected details.

**Acceptance Scenarios**:

1. **Given** a user has new available notifications, **When** they open the notification center, **Then** they see their notifications in newest-first order with a clear unread state and can open each available target.
2. **Given** a user opens an unread notification or explicitly marks it as read, **When** the action succeeds, **Then** its read state is reflected in later sessions on every supported platform.
3. **Given** a user changes a preference for voting updates, outing changes, or arrival alerts, **When** the preference is saved, **Then** later optional device alerts follow the new preference and invitations remain enabled.
4. **Given** the user has denied device-alert permission or is using a platform that cannot show device alerts, **When** a notification is created, **Then** it remains available in the in-app notification center and the user receives clear, non-blocking guidance when permission can be enabled.

### Edge Cases

- An event succeeds while its recipient is signed out, offline, or has no registered device; the notification appears in the recipient's in-app notification center once they next have access, without replaying an already-viewed alert as a new event.
- A source event is accepted concurrently with a recipient leaving a crew, being removed from an outing, declining an outing, or an outing being removed; delivery and later opening recheck authorization, and no protected source details are revealed after access ends.
- An authorized organizer changes several outing fields in one successful edit; each eligible participant receives one consolidated outing-change notification rather than one notification per field.
- A proposal is accepted and the agreement is confirmed almost immediately; recipients may receive both meaningful events, but no alert exposes hidden vote totals, voter identities, or another participant's current ballot.
- A recipient opens an alert after an outing has been cancelled, archived, completed, or removed; the app shows only the current allowed destination or a non-sensitive unavailable state.
- The same account uses multiple supported devices; notification read state and preferences remain one user-level state, while device delivery is attempted only on devices currently able and permitted to receive it.
- A device alert is delayed, duplicated, or arrives out of order; the in-app notification center remains the authoritative newest-first record, and duplicate delivery does not create duplicate notification items.
- An attendee loses Accepted attendance or Meeting ends before an arrival alert is delivered; the alert is suppressed or made unavailable rather than disclosing a stale live-meetup status.
- A user has more than 100 retained notifications; the center remains usable, initially showing the newest available items and allowing access to older retained items without changing their ordering.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create recipient-specific notifications only after the underlying crew, outing, agreement, or live-meetup action has successfully become authoritative; failed, rejected, and purely local actions MUST NOT create notifications.
- **FR-002**: System MUST support exactly these notification event categories in Phase 7: crew invitation, outing invitation, voting update, agreement confirmed, agreement reopened, outing change, and attendee arrival.
- **FR-003**: A crew-invitation notification MUST be created only for the user named by a newly created pending crew invitation and MUST provide an authorized path to that invitation.
- **FR-004**: An outing-invitation notification MUST be created only for each newly invited current crew member who is a current participant of that outing and MUST provide an authorized path to that participant's invitation response.
- **FR-005**: A voting-update notification MUST be created for other current, Accepted outing participants when an eligible new time or location proposal is accepted during Planning. It MUST identify the outing and relevant proposal category, but MUST NOT reveal individual votes, vote totals, leading choices, ties, or the proposer unless that information is otherwise visible in the agreement view.
- **FR-006**: An agreement-confirmed notification MUST be created for every current outing participant when a final agreement succeeds and MUST identify the final scheduled time and free-text location that the recipient is authorized to view.
- **FR-007**: An agreement-reopened notification MUST be created for every current outing participant when an authorized organizer successfully reopens a confirmed agreement and MUST identify that voting is available again without exposing prior private ballots.
- **FR-008**: An outing-change notification MUST be created for every current outing participant when an authorized organizer successfully changes the outing title, description, scheduled time, or confirmed free-text location. One successful edit affecting multiple fields MUST create at most one consolidated notification per recipient and MUST identify only the fields that changed.
- **FR-009**: An attendee-arrival notification MUST be created only when an Accepted attendee explicitly changes to Arrived while the outing is in Meeting. Its recipients MUST be the other current crew members who are current outing participants and Accepted attendees; it MUST not include precise location, location-sharing state, or location freshness.
- **FR-010**: System MUST create no attendee-arrival notification for Getting Ready, On My Way, automatic location changes, map-point changes, or a repeated Arrived status from the same attendee during one continuous Meeting period.
- **FR-011**: System MUST make the following device-alert preferences independently controllable and enabled by default: voting updates, outing changes, and attendee arrivals. Crew invitations, outing invitations, agreement confirmations, and agreement reopenings MUST remain enabled and cannot be muted because they require or materially affect participant action.
- **FR-012**: A preference MUST control future device alerts only; it MUST NOT change the recipient's access to the underlying crew, outing, agreement, or Live Meetup information, and it MUST NOT prevent creation of the recipient's authorized in-app notification record.
- **FR-013**: System MUST provide each authenticated user a notification center that shows that user's currently available notifications in stable newest-first order, marks each item read or unread, and provides a current authorized destination for every item.
- **FR-014**: System MUST allow a recipient to mark an available notification as read explicitly or by opening it. Read state MUST be private to that recipient and remain consistent across their supported devices.
- **FR-015**: Every notification MUST have one stable identity, intended recipient, event category, creation time, read state, source reference, and only the minimum display information needed for that category. Processing retries, duplicate device delivery, and duplicate source-event observation MUST NOT create more than one notification record for the same recipient and authoritative event.
- **FR-016**: Before creating a notification, attempting device delivery, displaying its details, or opening its destination, the system MUST verify the recipient's then-current authorization for the referenced information. If authorization, source availability, or required invitation state no longer exists, it MUST suppress delivery and immediately delete the notification so it no longer appears in the notification center or unread count.
- **FR-017**: System MUST not expose notification content, event metadata, unread counts, preferences, delivery state, or destinations to another user. A source action MUST never disclose to its actor whether a particular recipient's device received or opened an alert.
- **FR-018**: System MUST provide a clear, non-blocking outcome when device alerts are unavailable because permission is denied, delivery is unsupported, or a device is offline. The in-app notification center MUST remain available whenever the user is otherwise authorized.
- **FR-019**: System MUST retain an available notification for 30 days from its creation, after which it MUST no longer appear in supported clients and MUST be automatically removed. Earlier invalidation, permanent removal of the source, or access loss MUST take precedence and immediately remove the notification as required by FR-016.
- **FR-020**: System MUST keep no more than one unread count per recipient and MUST update it when a notification becomes available, is read, expires, or becomes unavailable. The count MUST include only currently available unread notifications.
- **FR-021**: System MUST support notification-center access and preference management on Android, iOS, Web, and Windows. Device-alert delivery MUST be attempted on every supported, registered device and browser for the recipient that has granted permission; lack of device-alert support on any device or platform MUST not make the feature unusable.
- **FR-022**: System MUST map blocked notification interactions to stable, non-sensitive explanation categories: sign-in required, notification unavailable, notification expired, device alerts unavailable, or notification service unavailable. Explanations MUST advise the appropriate corrective action without revealing whether a protected crew, outing, participant, invitation, or live status exists.
- **FR-023**: Phase 7 MUST NOT add direct messages, notification replies, social follows, marketing campaigns, contact import, background location tracking, live-location content in alerts, per-message chat alerts, reactions, or notification-based changes to crews, outings, votes, or attendance.

### Key Entities *(include if feature involves data)*

- **Notification**: One recipient-private record of a successfully completed, relevant event. It contains a stable identity, category, recipient, minimal authorized display information, source reference, creation time, read state, and expiration time.
- **Notification Preference**: A recipient's user-level choice for future optional device alerts in the voting-update, outing-change, and attendee-arrival categories.
- **Notification Delivery Attempt**: A non-authoritative attempt to show a device alert for one notification on a device or browser capable of receiving it. Its outcome never changes the notification's in-app availability or exposes recipient behavior to other users.
- **Notification Source Event**: The authoritative crew, outing, agreement, or arrival change that may produce recipient notifications. It supplies the stable event identity used to prevent duplicate records.
- **Eligible Recipient**: A user who satisfies the category-specific invitation, crew membership, outing participation, attendance, and outing-lifecycle requirements when notification access or delivery is evaluated.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Under a network profile with round-trip latency no greater than 100 milliseconds and packet loss below 1%, at least 95% of notifications for successfully completed source actions appear in an eligible recipient's in-app notification center within 5 seconds across at least 100 trials per event category.
- **SC-002**: In at least 95% of 100 device-alert trials per enabled category on permission-granted, supported devices, the backend hands an eligible generic alert to the provider within 10 seconds of notification creation; every trial remains reviewable in the in-app center regardless of provider-delivery outcome. Physical-device receipt is validated separately through user-approved smoke checks.
- **SC-003**: At least 90% of representative participants can open a new invitation or identify the current plan from an agreement-confirmed notification in under 20 seconds without assistance.
- **SC-004**: In 100% of duplicate-processing and multi-device tests, each recipient has at most one notification record for one authoritative source event and sees a consistent read state and unread count on later supported sessions.
- **SC-005**: In 100% of authorization tests, no user can read another user's notification records, preferences, unread count, delivery state, or protected source details; users who lose source access cannot recover those details from a prior notification.
- **SC-006**: In 100% of arrival tests, only the other eligible Accepted attendees receive at most one arrival notification for an attendee in one Meeting period, and no arrival notification contains a precise location or is produced for another live status.
- **SC-007**: In 100% of retention-boundary tests, notifications are absent from supported clients at or after 30 days from creation, unavailable notifications are excluded from unread counts, and automatic cleanup completes without user action.
- **SC-008**: At least 90% of representative participants can find their alert preferences, turn one optional category off, and correctly predict which future device alerts will be muted without assistance.

## Assumptions

- Phase 1 Authentication & Profiles through Phase 6 Live Meetup are available, including registered users, crew invitations, crew membership, outing participants, attendance responses, agreement actions, outing lifecycle transitions, and explicit arrival status.
- "Outing changes" means successful organizer edits to title, description, scheduled time, or confirmed free-text location. Cancellation, completion, archival, participant-removal, and crew-membership changes are outside the Phase 7 notification event list unless added by a later specification.
- "Voting updates" means accepted new time or location proposals, final agreement confirmation, and agreement reopening. Individual votes, vote changes, totals, leading choices, and ballot identities remain private as defined by Phase 4.
- The notification center is the durable, recipient-private record for this phase. Device alerts are a best-effort prompt governed by platform capability, permission, connectivity, and user preference; they are not proof of delivery or reading.
- Each eligible device alert is attempted on every supported, registered device or browser for the recipient that has granted permission. Multiple delivery attempts never create duplicate notification-center records or disclose recipient behavior to another user.
- Invitation, agreement-confirmed, and agreement-reopened alerts are operational updates and therefore cannot be disabled in this phase. Optional preferences control only future device alerts for voting updates, outing changes, and attendee arrivals.
- Arrival alerts apply only to a participant's first explicit Arrived status during one continuous Meeting period. A new Meeting period after a valid lifecycle transition may produce a new arrival alert.
- Notification content is deliberately minimal and never includes precise coordinates, location-sharing data, chat text, private votes, or information not visible through the authorized destination.
- Notifications are retained for 30 days unless their source or authorization becomes unavailable sooner; invalidated notifications are immediately deleted rather than retained as generic unavailable entries. Their retention is separate from the 24-hour chat-message lifecycle and the immediate live-meetup data cleanup rules.
