# Data Model: Crew Management

This document defines the entities, field formats, relationships, and validation rules for Phase 2: Crew Management.

## Entities

### 1. Crew
Represents a persistent coordination group.
- **Path**: `/crews/{crewId}`
- **ID**: Firestore auto-generated string

| Field Name | Type | Description |
|------------|------|-------------|
| `id` | String | Unique identifier |
| `name` | String | Crew name (3 to 50 chars, trimmed) |
| `ownerId` | String | UID of the user who owns this crew |
| `createdAt` | String | ISO 8601 UTC timestamp of creation |

#### Validation Rules:
- `name` MUST be between 3 and 50 characters.
- `ownerId` MUST match the creator's UID.

---

### 2. Crew Membership
Represents a user's membership in a crew.
- **Path**: `/crew_memberships/{crewId}_{userId}`
- **ID**: Predictable string format: `${crewId}_${userId}`

| Field Name | Type | Description |
|------------|------|-------------|
| `id` | String | Unique identifier (`crewId_userId`) |
| `crewId` | String | Identifier of the Crew |
| `userId` | String | UID of the user |
| `role` | String | Role: `'owner'` or `'member'` |
| `joinedAt` | String | ISO 8601 UTC timestamp of joining |
| `username` | String | Cached username for quick list rendering |
| `displayName` | String | Cached display name for quick list rendering |
| `avatarUrl` | String (nullable) | Cached avatar URL for quick list rendering |

#### Validation Rules:
- `role` MUST be either `'owner'` or `'member'`.
- Duplicate memberships are prevented by the unique `${crewId}_${userId}` document ID.

---

### 3. Crew Invitation
Represents a pending invitation sent to a user.
- **Path**: `/crew_invitations/{crewId}_{invitedUserId}`
- **ID**: Predictable string format: `${crewId}_${invitedUserId}`

| Field Name | Type | Description |
|------------|------|-------------|
| `id` | String | Unique identifier (`crewId_invitedUserId`) |
| `crewId` | String | Identifier of the Crew |
| `invitedUserId` | String | UID of the invited user |
| `invitedByUserId` | String | UID of the crew owner who sent the invitation |
| `createdAt` | String | ISO 8601 UTC timestamp of invitation |
| `crewName` | String | Cached crew name to display to the invited user |
| `invitedByUsername` | String | Cached username of the inviter |
| `invitedByDisplayName`| String | Cached display name of the inviter |

#### Validation Rules:
- `invitedUserId` MUST exist in `/users`.
- `invitedByUserId` MUST match the crew owner's UID.
- Duplicate invitations are prevented by the unique `${crewId}_${invitedUserId}` document ID.

---

## State Transitions & Workflows

### Crew Creation
```mermaid
graph TD
    A[Start: User enters Crew Name] --> B{Valid name? 3-50 chars}
    B -- No --> C[Show Validation Error]
    B -- Yes --> D[Run Batch Write]
    D --> E[Create /crews/{crewId}]
    D --> F[Create /crew_memberships/{crewId}_{uid} with role 'owner']
    E --> G[Success: Navigate to Crew Details]
    F --> G
```

### Invitation Flow
```mermaid
graph TD
    A[Owner enters Username] --> B{Verify username exists in /usernames}
    B -- No --> C[Error: Username not found]
    B -- Yes (Get UID) --> D{Is user already a member?}
    D -- Yes --> E[Error: Already a member]
    D -- No --> F{Is user already invited?}
    F -- Yes --> G[Error: Already invited]
    F -- No --> H[Create /crew_invitations/{crewId}_{invitedUid}]
    H --> I[Success: Add to pending list in UI]
```

### Accept Invitation
```mermaid
graph TD
    A[User accepts Invitation] --> B[Run Transaction/Batch]
    B --> C[Create /crew_memberships/{crewId}_{uid} as 'member']
    B --> D[Delete /crew_invitations/{crewId}_{uid}]
    C --> E[Success: Show Crew in Crews list]
    D --> E
```

### Reject/Decline/Revoke Invitation
```mermaid
graph TD
    A[User rejects OR Owner revokes invitation] --> B[Delete /crew_invitations/{crewId}_{uid}]
    B --> C[Success: Remove from list in UI]
```
