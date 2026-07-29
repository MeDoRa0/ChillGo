# Contract: Firestore Rules and Authorization

## Client-readable data

| Collection | Get/list condition |
|---|---|
| `notifications` | Authenticated recipient only; record unexpired; category-specific current source authorization passes. List is recipient-scoped, newest-first, and bounded. |
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

Rules never filter stale client results. Emulator tests must prove exact get/list denial after every access loss, cross-user isolation, malformed command/preference rejection, direct record/summary/device/event mutation denial, bounded-query constraints, and expiry behavior.
