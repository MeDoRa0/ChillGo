# Research: Crew Management Features

This document details the architectural research and decisions for implementing Phase 2: Crew Management.

## 1. Firestore Schema Strategy

### Options Considered
1. **Option A (Subcollections)**: Store memberships and invitations as subcollections under `/crews/{crewId}`.
   - *Pros*: Natural hierarchy; deleting a crew makes it easy for cascading deletion of subcollections in Cloud Functions or client helper.
   - *Cons*: Listing a user's crews requires a Collection Group query across all `memberships` subcollections, which requires creating index exclusions/configurations and is less performant.
2. **Option B (Top-level Collections)**: Store memberships and invitations in top-level collections: `/crew_memberships` and `/crew_invitations`.
   - *Pros*: Simple, direct queries to find a user's memberships (`where('userId', '==', uid)`) or invitations (`where('invitedUserId', '==', uid)`). Predictable document IDs (e.g., `{crewId}_{userId}`) can be used to prevent duplicates and simplify security rules.
   - *Cons*: Requires separate queries to fetch. Cascading deletions are not automatic and must be executed in a client batch or Cloud Function.

### Decision
**Option B (Top-level Collections)** with structured Document IDs.
- `/crews/{crewId}`
- `/crew_memberships/{crewId}_{userId}`
- `/crew_invitations/{crewId}_{invitedUserId}`

### Rationale
Using predictable Document IDs of the form `{crewId}_{userId}` enforces uniqueness at the database level (preventing duplicate memberships or invitations) and allows O(1) checks inside Firestore Security Rules using `exists()` without running additional queries.

---

## 2. Firestore Security Rules Design

### Rules Draft
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Existing rules...

    // Crews Collection
    match /crews/{crewId} {
      allow read: if request.auth != null && 
        exists(/databases/$(database)/documents/crew_memberships/$(crewId)_$(request.auth.uid));
      allow create: if request.auth != null && 
        request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null && 
        resource.data.ownerId == request.auth.uid;
    }

    // Crew Memberships Collection
    match /crew_memberships/{membershipId} {
      // membershipId format is assumed to be {crewId}_{userId}
      allow read: if request.auth != null && 
        exists(/databases/$(database)/documents/crew_memberships/$(resource.data.crewId)_$(request.auth.uid));
      
      // Creating a membership: Either Owner creating their own when creating the crew,
      // or a User accepting an invitation.
      allow create: if request.auth != null && 
        request.resource.data.userId == request.auth.uid && 
        (
          request.resource.data.role == 'owner' || 
          (
            request.resource.data.role == 'member' && 
            exists(/databases/$(database)/documents/crew_invitations/$(request.resource.data.crewId)_$(request.auth.uid))
          )
        );
      
      // Deleting a membership:
      // 1. The member themselves leaving (must not be the owner)
      // 2. The crew owner removing them
      allow delete: if request.auth != null && 
        (
          (resource.data.userId == request.auth.uid && resource.data.role != 'owner') ||
          get(/databases/$(database)/documents/crews/$(resource.data.crewId)).data.ownerId == request.auth.uid
        );
    }

    // Crew Invitations Collection
    match /crew_invitations/{invitationId} {
      // invitationId format is assumed to be {crewId}_{invitedUserId}
      allow read: if request.auth != null && 
        (
          resource.data.invitedUserId == request.auth.uid || 
          get(/databases/$(database)/documents/crews/$(resource.data.crewId)).data.ownerId == request.auth.uid
        );
      
      // Only the crew owner can invite users
      allow create: if request.auth != null && 
        get(/databases/$(database)/documents/crews/$(request.resource.data.crewId)).data.ownerId == request.auth.uid && 
        request.resource.data.invitedByUserId == request.auth.uid;
      
      // The invited user accepts/rejects, or the crew owner revokes
      allow delete: if request.auth != null && 
        (
          resource.data.invitedUserId == request.auth.uid || 
          get(/databases/$(database)/documents/crews/$(resource.data.crewId)).data.ownerId == request.auth.uid
        );
    }
  }
}
```

---

## 3. Username Lookup and Cache Denormalization

### Invitation Workflow
1. User enters username `john_doe` in UI.
2. System queries `/usernames/john_doe` to verify existence and get the target `uid`.
   - If not found, show "Username not found".
3. Check if membership already exists: `/crew_memberships/{crewId}_{targetUid}`.
   - If exists, show "User is already a member".
4. Check if invitation already exists: `/crew_invitations/{crewId}_{targetUid}`.
   - If exists, show "User already has a pending invitation".
5. Write `/crew_invitations/{crewId}_{targetUid}` containing `crewId`, `invitedUserId`, `invitedByUserId`, and `createdAt`.

### Member List Cache
To render member lists quickly (showing names, usernames, and avatars) without N secondary reads, the `crew_memberships` document will cache:
- `username`
- `displayName`
- `avatarUrl`
This matches the existing profile attributes and avoids fetching each user's full profile document dynamically.
Since usernames, display names, and avatars can update, any future profile update in Phase 1 (already existing profile features) can propagate updates asynchronously, or we can update them on crew load. For MVP, cached data on join is sufficient.

---

## 4. Multi-Platform Support
Flutter's Firestore client SDK compiles to all target platforms (Android, iOS, Web, Windows). Standard responsive UI layouts using `LayoutBuilder` or `MediaQuery` will ensure clean layouts across mobile and desktop environments. No platform-specific native plugins are required beyond the core Firebase plugins already configured.
