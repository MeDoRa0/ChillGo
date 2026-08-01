# Contract: Firestore Rules and Authorization

## Client-readable data

| Collection | Get/list condition |
|---|---|
| `notifications` | Exact authenticated-recipient get only when the record is unexpired and its category-specific current source authorization passes. Direct list access is denied; the center uses the trusted `notificationCenterPage` callable. |
| `notification_summaries` | Exact authenticated owner only. |
| `notification_preferences` | Exact authenticated owner only. |
| `notification_commands` | Exact requester get of known command only; list denied. |

## Client writes

| Collection | Allowed writes |
|---|---|
| `notification_preferences` | Owner create/update with exact allowlisted booleans and `updatedAt == request.time`; no operational preference fields. |
| `notification_commands` | Owner create of exact allowlisted pending command; immutable after creation. |
| `notifications`, `notification_summaries`, `notification_devices`, `notification_events`, `notification_recipient_work`, `notification_transitions` | Denied. |

## Source-aware eligibility

- Crew invitation: invitation exists, remains pending, and names the recipient.
- Outing invitation, voting, agreement, and outing change: source outing exists and is not deletion/notification-cleanup pending; recipient remains a current crew member and outing participant.
- Arrival: previous conditions plus `attendanceStatus == accepted`, outing `status == meeting`, and live-meetup cleanup boundaries are clear.
- Any source/crew/outing/participant/membership cleanup-pending state denies the record before physical cleanup completes.

Rules never filter stale client results. The App Check-protected center callable authenticates the requester, performs bounded newest-first server scans, rechecks every record's expiry and current source authorization, and returns only the safe page projection. Emulator tests must prove exact-get denial after every access loss, direct-list denial, cross-user isolation, malformed command/preference rejection, direct record/summary/device/event mutation denial, and expiry behavior.
