# Research: Notifications

## Recipient-private center with trusted outbox

**Decision**: Create one durable record per `(authoritative source event, recipient)` through a server-owned `notification_events` outbox and deterministic record identity. Trusted source transactions write their event atomically; narrow triggers cover existing direct crew-invitation, outing-participant, and material-outing-update writes.

**Rationale**: Firestore event delivery is at least once and unordered. Deterministic event/record identities make retries safe, retain a reliable center item, and separate exactly-once UI state from best-effort delivery.

**Alternatives considered**: Direct client creation is untrusted and misses recipients; direct sends from every source trigger duplicate alerts; topic broadcasts cannot meet per-recipient privacy.

## Delivery targets and payload

**Decision**: Store at most 10 current registrations per user, keyed by random per-installation IDs. Use Messaging through a `DeviceAlertService` adapter on Android, iOS, and Web only. Revalidate source access and preferences before sending generic copy with only an opaque notification ID/category/schema version. Windows has an unsupported adapter and uses the center.

**Rationale**: The installed Flutter Messaging plugin has no Windows implementation. Generic payloads stay safe if a platform delays delivery after access loss. Server-only token access prevents another user from learning device state.

**Alternatives considered**: Payload source details cannot be recalled; latest-device-only conflicts with the clarification; FCM handoff is not a delivery/read receipt.

## Source event mapping

**Decision**: Use invitation creation, non-creator invited-participant creation, proposal ID, confirmed round ID, reopened round ID, one outing update version with its changed-field set, and a deterministic `(outingId, attendeeId)` first-arrival marker. Agreement and Live Meetup Functions emit events in their successful transactions; arrival requires explicit Arrived transition and Meeting eligibility.

**Rationale**: Stable identities stop repeat arrival alerts and protect Phase 4 ballot privacy.

**Alternatives considered**: Every vote/status write is noisy and can leak social pressure; location-derived arrival violates Phase 6.

## Access loss and retention

**Decision**: Source-aware Rules fail closed immediately. A resumable transition sets a cleanup-pending denial boundary, deletes affected records/work, verifies emptiness, and only then finalizes an access-ending source action. A minutely bounded cleanup worker enforces 30 days; TTL is recovery only.

**Rationale**: Firestore TTL and ordinary trigger processing are asynchronous, so neither can satisfy exact expiry or immediate privacy by themselves.

**Alternatives considered**: TTL-only, generic invalidated entries, and client-side filtering all fail the specification or security boundary.

## Read state, permissions, and foreground behavior

**Decision**: Maintain a trusted unread summary transactionally; requester-private commands serialize read/open and registration actions. Preferences are exact-shape owner configuration. Ask device permission only from an intentional preferences action; resync token at authenticated startup, permission grant, and token refresh; unregister on sign-out. Foreground messages update the center and show an in-app banner instead of a second local-notification system.

**Rationale**: This avoids full-list badge reads, permission prompts at startup, and token association across users on a shared device.

**Sources**:

- [Firebase Messaging Flutter setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [Flutter message receipt and permission behavior](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Firebase Messaging token management](https://firebase.google.com/docs/cloud-messaging/manage-tokens)
- [Firebase Admin multicast delivery](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk)
- [Firestore event-trigger semantics](https://firebase.google.com/docs/functions/firestore-events)
- [Firestore TTL behavior](https://firebase.google.com/docs/firestore/ttl)
