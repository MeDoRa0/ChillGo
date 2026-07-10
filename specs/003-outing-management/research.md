# Research: Outing Management

This document records implementation planning decisions for Phase 3: Outing Management.

## Decision: Store Outings and Participants in Top-Level Collections

**Decision**: Use top-level `outings` and `outing_participants` collections rather than nesting outings under crews.

**Rationale**: Phase 2 already uses top-level collections with predictable IDs for security-rule checks. Keeping outing records top-level makes it straightforward to query a user's crew outings, validate participant uniqueness, and add Firestore rules that reuse crew membership checks.

**Alternatives considered**:
- Nested `/crews/{crewId}/outings/{outingId}`: readable structure, but participant uniqueness and cross-collection security checks become less consistent with Phase 2.
- Single outing document with embedded participant list: simpler for small rosters, but harder to enforce per-participant uniqueness and update individual participants safely.

## Decision: Use Predictable Participant Document IDs

**Decision**: Store outing participant documents at `/outing_participants/{outingId}_{userId}`.

**Rationale**: Predictable IDs prevent duplicates, support O(1)-style security checks, and match the existing crew membership ID pattern.

**Alternatives considered**:
- Auto-generated participant IDs: simple writes, but duplicate prevention requires additional queries.
- Participant subcollection under outing: keeps records grouped but still needs extra constraints for uniqueness.

## Decision: Creator Participant Is Created Atomically With Outing

**Decision**: Creating an outing also creates the creator's participant record in the same logical operation.

**Rationale**: The clarified specification requires the creator to be the first participant. A combined write prevents a visible outing with an empty roster and gives the UI a consistent initial state.

**Alternatives considered**:
- Add creator participant after outing creation: simpler repository call, but can leave a partial state.
- Let the creator opt in manually: rejected by clarification.

## Decision: Free-Text Location Only

**Decision**: Phase 3 stores location as a trimmed free-text string.

**Rationale**: The clarified specification explicitly excludes selected places, addresses, coordinates, maps, and map-provider behavior from this phase. This keeps Phase 3 focused on outing management and avoids leaking Phase 4/6 map work into the data model.

**Alternatives considered**:
- Structured place object: useful later, but out of scope now.
- Coordinates-only location: too restrictive for casual outing planning and implies map behavior.

## Decision: Manual Lifecycle Transitions Controlled by Creator or Crew Owner

**Decision**: The outing creator and crew owner can manually move outings through the allowed lifecycle transitions.

**Rationale**: Phase 3 owns lifecycle management, while agreement, chat, live meetup, and notifications are later phases. Manual transitions make lifecycle behavior testable without depending on those future systems.

**Alternatives considered**:
- Defer Confirmed/Meeting/Completed to later phases: would weaken Phase 3 lifecycle management.
- Automatically infer statuses from time or votes: depends on future agreement/live meetup behavior and is out of scope.

## Decision: Separate Domain Policy for Status Transitions

**Decision**: Implement lifecycle validation as a domain-level policy/service.

**Rationale**: Status transition rules must be shared by Cubits, repositories, and tests. Keeping them in the domain layer satisfies clean architecture and prevents duplicated conditional logic in UI or Firestore adapters.

**Alternatives considered**:
- Validate only in UI: can be bypassed by repository calls and is hard to test comprehensively.
- Validate only in Firestore rules: protects data but gives poor local UX and duplicates logic in tests.

## Decision: Retain Cancelled, Completed, and Archived Outings

**Decision**: Keep non-active outings as historical records and filter them in the UI rather than deleting them.

**Rationale**: The spec requires cancelled outings to remain visible as history, and archived outings are retained for reference. This also avoids destructive data loss while later phases build on outing history.

**Alternatives considered**:
- Delete cancelled outings: conflicts with the spec.
- Move history to an archive collection: premature for MVP scale and adds migration complexity.

## Decision: Firestore Rules Must Enforce Crew Membership and Manager Actions

**Decision**: Firestore rules must ensure only current crew members can read outings, and only the outing creator or crew owner can edit, cancel, manage participants, or move lifecycle status.

**Rationale**: Crew-first privacy is constitutional. Client UI checks are not sufficient for access control, and emulator tests already exist for validating Firestore rules.

**Alternatives considered**:
- Trust repository-layer checks only: insufficient for security.
- Route all writes through Cloud Functions in Phase 3: stronger centralization but unnecessary for this MVP feature if rules can validate the required invariants.
