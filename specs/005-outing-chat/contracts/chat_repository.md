# Contract: Chat Repository

Presentation Cubits depend on this provider-neutral contract. Firestore queries, transactions, command documents, aggregate counts, authentication, and timestamps remain in the data layer.

## Domain Values

```text
ChatMessageCursor(acceptedAt, messageId)
ChatPage(messages, oldestCursor, newestCursor, hasMore)
ChatSummary(unreadCount, hasUnread, isWritable)
ChatSendAttempt(clientMessageId, commandId?, status, failure?)
```

No public contract exposes Firestore snapshots, document references, query cursors, or raw Firebase exceptions.

The data layer also provides a `ChatClock` implementation backed by an online, owner-private server-time probe. Expiry and query cutoffs never use raw device wall time. If a trusted clock cannot be established on a new offline session, remote chat history remains unavailable rather than risking display of expired content.

## History Operations

```text
watchLatestMessages(outingId, limit = 50) -> Stream<ChatPage>
loadOlderMessages(outingId, before, limit = 50) -> Future<ChatPage>
```

- Latest history uses a bounded realtime listener.
- Older pages are one-shot reads using the same stable `(acceptedAt, messageId)` order.
- The repository excludes expired messages, deduplicates IDs across realtime/page boundaries, and returns chronological domain messages.
- Access revocation maps to a domain access failure and causes presentation state to clear protected content.

## Send Operations

```text
newClientMessageId() -> String
sendMessage(outingId, clientMessageId, text) -> Future<String commandId>
watchCommand(commandId) -> Stream<ChatCommand?>
```

`sendMessage` trims/validates locally, then creates the command in an online-only Firestore transaction. Offline/server-unreachable transactions map to `ChatNetworkFailure` and are not queued. Presentation retains the local text and stable client message ID for an explicit manual retry.

The command stream exposes pending, processing, success, `rate_limited` with retry time, retryable service failure, and terminal validation/access failure. A success resolves to the immutable server message.

## Read-State Operations

```text
watchMyReadState(outingId) -> Stream<ChatReadState?>
markReadThrough(outingId, cursor) -> Future<void>
getUnreadCount(outingId) -> Future<int>
watchChatSummary(outingId) -> Stream<ChatSummary>
```

- `markReadThrough` only advances the signed-in user's private cursor and never creates cross-user receipts.
- `getUnreadCount` counts currently available messages after the effective cursor and subtracts the current user's own count.
- Count queries are bounded to the feature maximum of 5,000 available messages; ordinary history pages remain capped at 50.
- `watchChatSummary` refreshes the count when newest-message, personal cursor, access, or reconnect signals change; it does not promise push-notification behavior.
- If the cursor expires or disappears, the effective lower bound becomes the current 24-hour retention cutoff.

## Pagination and Expiry Behavior

- Page size is capped at 50.
- New messages do not force the user's scroll position away from older history; presentation may show a new-message affordance.
- A domain expiry timer removes the next expiring message at its trusted `expiresAt` even if physical deletion has not yet reached the client listener.
- Expired messages never contribute to pages, unread counts, or resume points.

## Domain Failure Mapping

- Authentication, membership, participant, or read-state privacy failure -> `ChatAccessDenied`
- Completed/Archived/Cancelled or deleting outing send -> `ChatReadOnly`
- Invalid/over-limit text -> `ChatValidationFailure`
- Offline transaction or unavailable service -> `ChatNetworkFailure`
- Rolling-window rejection -> `ChatRateLimited(retryAt)`
- Stable identity reused with conflicting content -> `ChatIdentityConflict`
- Outing/message absence or expiry -> `ChatNotFound`
- Unknown terminal backend failure -> `ChatServiceFailure`

Failures contain no protected chat content or other participants' private state.

## Integration Contract

- Register datasource/repository as lazy singletons and chat/summary Cubits as factories in `lib/core/di/injection_container.dart`.
- Add `/outings/:outingId/chat` in `lib/core/routes/app_router.dart`.
- Add chat entry/read-only state/unread badge to the shared `InteractiveOutingCard` without coupling outing domain code to Firestore.
- Outing and agreement repositories remain unchanged except that creator/expiry removal continues through the existing trusted outing-deletion path, now extended for chat data.
