# Contract: Notification Repository and Device Alerts

## NotificationRepository

The domain repository exposes platform-neutral behavior:

| Operation | Required behavior |
|---|---|
| Watch newest notifications | Emit only currently authorized, unexpired recipient records in stable newest-first order; use a bounded cursor/page and clear protected state on access loss. |
| Load older notifications | Continue from the stable cursor without duplicate IDs or ordering changes. |
| Watch unread summary | Emit the recipient-private count; unavailable/auth loss clears it. |
| Mark read / open | Submit a requester-private command; opening yields either an authorized semantic destination or a non-sensitive unavailable outcome. |
| Watch/update preferences | Expose only the three optional categories and persist owner changes. |
| Start/stop device registration | Delegate to `DeviceAlertService`, then submit registration/unregistration commands without exposing a token to Cubits/widgets. |

No repository method returns raw FCM token, provider message, delivery attempt, another user's preferences, or unauthorized source metadata.

## DeviceAlertService

| Capability | Android/iOS/Web adapter | Windows adapter |
|---|---|---|
| Report support and permission state | Uses platform capability and current permission | Reports unsupported |
| Request permission | Only when the user explicitly selects enable device alerts | Returns non-blocking unavailable; never prompts |
| Observe target/token refresh | Emits a supported registration target after authorization | Emits no target |
| Receive foreground/opened alert | Emits opaque notification ID/category for repository reauthorization | Emits no device event |
| Clear local registration | Stops token association at sign-out | Safe no-op |

Permission is not requested during bootstrap. The app starts the service only after authentication and uses `getInitialMessage`/opened-message/foreground streams to route through the repository. A background handler never navigates or writes protected data directly.

## UI contract

- The home toolbar shows an accessible unread badge and opens `/notifications`.
- The center has loading, empty, error, pagination, read/unread, and unavailable states; an unavailable alert never shows stale source text.
- Preferences explain the three optional categories and the platform availability state; operational categories are shown as required rather than mutable.
- Notification target mapping is semantic and reauthorized: crew invitation -> invitations; outing invitation/voting/confirmed/reopened -> agreement; arrival -> Live Meetup. Routes remain responsible for their own eligibility checks.
