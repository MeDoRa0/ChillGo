# Data Model: Notifications

## Notification

- **Path**: `/notifications/{notificationId}`
- **Identity**: deterministic collision-safe derivation of source event ID and recipient UID
- **Client access**: recipient-only, source-aware reads; all direct writes/deletes denied

| Field | Type | Rules |
|---|---|---|
| `recipientUserId` | String | Immutable authenticated recipient |
| `category` | String | One Phase 7 category |
| `sourceEventId` / `sourceVersion` | String | Immutable idempotency and source version keys |
| `crewId` / `outingId` | String/null | Immutable owning references when applicable |
| `target` | Map | Minimal validated navigation intent |
| `display` | Map | Minimal authorized display snapshot; no coordinates, chat, or ballots |
| `createdAt` / `expiresAt` | Timestamp | Trusted creation and exactly +30-day expiry |
| `readAt` | Timestamp/null | Trusted read/open timestamp |

Rules re-evaluate source availability and current recipient authorization on every get/list. Crew invitations require a pending target invitation. Outing and agreement records require current source, crew membership, and participation. Arrival additionally requires Meeting, Accepted attendance, and current live-meetup eligibility. Failed access checks deny immediately; transition cleanup removes the record physically.

## Summary and Preferences

| Entity | Path | Fields and ownership |
|---|---|---|
| Notification Summary | `/notification_summaries/{userId}` | Trusted-only `{userId, unreadCount, updatedAt}`; exact owner read only. The aggregate changes transactionally with create/read/invalidation/expiry and has a repair job. |
| Notification Preferences | `/notification_preferences/{userId}` | Owner-only exact-shape `{votingUpdatesEnabled, outingChangesEnabled, arrivalAlertsEnabled, updatedAt}`; absent fields default enabled. Operational categories cannot be muted. |

## Device Registration and Commands

| Entity | Path | Fields and ownership |
|---|---|---|
| Device Registration | `/notification_devices/{userId}_{installationId}` | Trusted-only `{userId, installationId, token, platform, permissionState, createdAt, updatedAt, lastSeenAt, expiresAt}`. Installation ID is random, never hardware-derived. Max 10 per user. |
| Notification Command | `/notification_commands/{commandId}` | Requester-private command for `mark_read`, `open`, `register_device`, or `unregister_device`; exact pending payload, Rules-bound times, trusted terminal state, payload scrubbed. |

Clients never read registrations or tokens. Supported registrations are Android/iOS/Web only. Token refresh, invalid-provider response, sign-out, and 30-day inactivity unregister a target.

## Trusted Event, Work, and Transition

| Entity | Path | Purpose |
|---|---|---|
| Notification Event | `/notification_events/{sourceEventId}` | Immutable server-only outbox category/source/version and recipient-selection inputs. |
| Recipient Work | `/notification_recipient_work/{sourceEventId}_{recipientUserId}` | Server-only claim, deterministic target record, terminal state, and short retention. |
| Notification Transition | `/notification_transitions/{transitionId}` | Resumable cleanup-pending, delete, verify, finalize coordination for access-ending lifecycle work. |

## Source Event Mapping

| Category | Stable source | Recipients |
|---|---|---|
| Crew invitation | invitation creation version | named target while pending |
| Outing invitation | participant creation version | newly invited non-creator current crew member |
| Voting update | proposal ID | other current Accepted Planning participants |
| Agreement confirmed | confirmed round ID | current outing participants |
| Agreement reopened | new round ID | current outing participants |
| Outing change | outing update version | current outing participants; consolidated changed fields |
| Attendee arrival | outing plus attendee first-arrival marker | other current Accepted Meeting attendees |

## Lifecycle, Queries, and Indexes

```text
authoritative source -> immutable event -> recipient work claim/recheck
  -> notification + unread-summary transaction -> optional generic device send

record -> trusted read/open -> read
record -> source loss -> Rules denial -> cleanup transition -> deleted
record -> expiry boundary -> client/Rules exclusion -> scheduled cleanup -> deleted
```

Center queries use `recipientUserId == currentUser`, `createdAt desc`, document ID desc, page size 50. Indexes cover center pages and bounded server cleanup by expiry, source IDs, outing, crew, and recipient. TTL overrides apply to record expiry and short-lived command/event/work/device fields; scheduled cleanup, not TTL, provides the product boundary.
