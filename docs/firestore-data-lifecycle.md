# Firestore data lifecycle

This document is the ownership and retention reference for Chillgo's Firestore
collections. Query sizes are intentionally bounded to the current product limits:
100 crews, members, invitations, outings, rounds, results, or participant records
per parent; agreement proposals remain limited by the 50-per-category service
rule.

| Collection | Owner / partition | Primary read pattern | Retention |
| --- | --- | --- | --- |
| `users`, `usernames` | User | Document lookup by UID or normalized username | Persistent while the account exists |
| `crews` | Crew | Document lookup after membership stream | Persistent until crew deletion |
| `crew_memberships` | Crew and user | Equality by `userId` or `crewId` | Until membership or crew deletion |
| `crew_invitations` | Crew and invited user | Equality by `crewId` or `invitedUserId` | Until accepted, rejected, revoked, or crew deletion |
| `outings` | Crew | Equality by `crewId` | Until explicit or expiry cleanup |
| `outing_participants` | Outing and crew | Equality by `outingId`; targeted cleanup by `crewId` and `userId` | Until participant, outing, membership, or crew deletion |
| `agreement_rounds`, `agreement_proposals`, `agreement_votes`, `agreement_results` | Outing | Equality by `outingId` or `roundId` | Until outing deletion |
| `agreement_commands` | Outing | Direct document status stream | Terminal payload is scrubbed; TTL on `purgeAt` after 24 hours |
| `chat_messages` | Outing | `outingId` ordered by accepted time | TTL on `expiresAt` |
| `chat_commands` | Outing | Direct command status and worker status/time query | TTL on `deleteAt` |
| `chat_read_states`, `chat_rate_limits` | Outing and user | Direct document lookup | TTL on their cursor/rate-limit expiry fields |
| `live_meetup_statuses`, `live_meetup_shares`, `live_locations`, `meetup_points` | Outing | Equality by `outingId` or direct document lookup | Location data expires by TTL; remaining records are removed at outing cleanup |
| `live_meetup_commands`, `live_meetup_transitions` | Outing | Direct command stream and worker status/lease query | TTL on `purgeAt` |
| Notification collections | Recipient or transition | Recipient/time and worker status/time queries | Definitions are staged in `firestore.indexes.json`; deploy with the notification feature |

Application startup configuration is device-local in `SharedPreferences`. The app
does not read or write a Firestore `config` collection.

`firestore.indexes.json` is the source of truth for composite indexes and TTL
field overrides. Changes to that file and Cloud Functions must be deployed before
the console will reflect them.

## Follow-up optimization

Crew cards now keep their member, invitation, and outing streams stable across
widget rebuilds. If the home screen grows beyond the current scale, replace the
per-card preview listeners with a shared home-level summary read model so one
subscription can feed all cards.
