# Research: Agreement System

## Decision: Creator-Only Permanent Outing Removal Uses a Trusted Command

**Decision**: Add an idempotent `delete_outing` command that only the outing creator may request in any lifecycle status. Trusted processing removes the outing and all participant and agreement records owned by it, while preventing overlapping agreement commands from recreating deleted data.

**Rationale**: Permanent removal crosses several top-level collections that direct client deletion cannot clean up safely. A trusted command centralizes creator authorization, correlated cleanup, race handling, and consistent behavior on every supported client platform.

**Alternatives considered**:

- Keep the existing client batch that deletes only the outing and participant roster: rejected because agreement rounds, proposals, votes, results, and commands would be orphaned.
- Allow the crew owner to remove any outing: rejected because the clarified product rule reserves permanent removal for the outing creator.
- Limit removal to active or terminal statuses: rejected because the creator must be able to remove the outing at any time.

This document records Phase 0 decisions for implementing Phase 4 while preserving the clarified sealed-ballot behavior and all ChillGo target platforms.

## Decision 1: Use Firestore Commands with Trusted Event-Driven Processing

**Decision**: Clients create immutable, narrowly validated documents in `agreement_commands`. A second-generation Cloud Function triggered on command creation validates authorization and current state, applies the command transactionally, and records a sanitized success or failure result on the command.

**Rationale**: Sealed votes cannot be safely tallied or used to enforce leading-choice confirmation on an untrusted client. The Flutter `cloud_functions` package currently lists Android, iOS, macOS, and Web but not Windows, whereas ChillGo requires Windows. Firestore is already available on every project target. Firebase documents that Firestore event triggers are delivered at least once, so command processing will use transactional status checks and idempotent deterministic writes. See [Cloud Firestore triggers](https://firebase.google.com/docs/functions/firestore-events) and the [Cloud Functions retry guidance](https://firebase.google.com/docs/functions/retries).

**Alternatives considered**:

- Flutter callable functions plugin: simpler request/response flow, rejected because its current supported-platform list omits Windows.
- Direct client aggregation: rejected because it exposes other participants' votes or trusts a tamperable client.
- Platform-specific callable adapter for Windows: rejected because it creates two client command paths and unnecessary authentication/protocol code.

## Decision 2: Use Node.js 22 and TypeScript for Second-Generation Functions

**Decision**: Add a TypeScript Functions project using the v2 Firestore trigger API and Node.js 22.

**Rationale**: Node.js 22 is a supported Firebase runtime, TypeScript is officially supported, and the v2 API is the recommended modular interface. The Dart Functions SDK remains experimental and has callable limitations, so it is not selected for security-critical agreement processing. See [supported Node.js runtimes](https://firebase.google.com/docs/functions/manage-functions) and [TypeScript Functions setup](https://firebase.google.com/docs/functions/typescript).

**Alternatives considered**:

- Experimental Dart Functions SDK: rejected because the official documentation describes production limitations and experimental Firestore trigger support.
- JavaScript without types: viable, but rejected because typed command schemas and result shapes reduce security-sensitive validation errors.

## Decision 3: Separate Private Votes from Public Aggregate Results

**Decision**: Store one predictable vote document per round/category/user in `agreement_votes`. Security Rules permit only that voter to read their ballot. On confirmation, the trusted function writes aggregate per-proposal documents to `agreement_results`; crew members may read those results only after the round closes.

**Rationale**: This directly enforces the clarified rule that participants see only their own selections during voting, aggregate results appear after confirmation, and individual ballots never become public. Predictable vote IDs enforce one vote per category without collection scans.

**Alternatives considered**:

- Store votes under proposals and allow crew reads: rejected because voter identities and live totals can be reconstructed.
- Store all counts on the open round: rejected because it leaks participation and leaders.
- Make ballots anonymous to the backend: rejected because eligibility changes and one-vote enforcement require a stable voter identity.

## Decision 4: Process Confirmation and Reopening as Transactions

**Decision**: The command processor uses Firestore transactions to re-read the outing, active round, current participants, memberships, proposals, and votes; derive eligible totals; validate required participation and tie selections; write aggregate results; close or supersede the round; and update the outing lifecycle and final details atomically.

**Rationale**: Confirmation races with vote changes and membership changes. A trusted transaction prevents partial outcomes and makes repeated delivery safe. Server client libraries bypass Security Rules, so the function must explicitly repeat all authorization and validation checks; IAM and least-privilege deployment remain required. See [Firestore Rules conditions and server-client behavior](https://firebase.google.com/docs/firestore/security/rules-conditions).

**Alternatives considered**:

- Multiple independent writes: rejected because partial confirmation could expose aggregates without updating the outing or vice versa.
- Client batch writes: rejected because the client cannot read private ballots and must not choose arbitrary winners.

## Decision 5: Use Top-Level Collections and Predictable Identity Where It Improves Rules

**Decision**: Keep agreement records in top-level collections with `crewId`, `outingId`, and `roundId` denormalized. Round IDs use `${outingId}_${sequence}`; vote IDs use `${roundId}_${category}_${userId}`; result IDs use `${roundId}_${category}_${proposalId}`. Proposals and commands use server/client-generated document IDs but immutable payloads.

**Rationale**: This matches the existing top-level outing schema, supports collection queries, and keeps common authorization checks O(1) through predictable participant and membership paths. Denormalized ownership fields are validated against authoritative outing and round records.

**Alternatives considered**:

- Deep subcollections: workable, but inconsistent with the existing repository and less convenient for cross-round history queries.
- One large round document containing proposals and results: rejected because of concurrent updates, document-size growth, and coarse security visibility.

## Decision 6: Migrate Existing Participant Records Safely

**Decision**: Extend `outing_participants` with `attendanceStatus` and `respondedAt`. Existing creator participants backfill to `accepted`; other existing participants backfill to `invited`. Model readers temporarily apply the same defaults for legacy documents until the emulator-validated migration completes.

**Rationale**: Phase 3 data already exists and lacks attendance fields. A staged reader plus migration prevents runtime parsing failures while producing the Phase 4 invariant of exactly one attendance state per participant.

**Alternatives considered**:

- Treat every existing participant as accepted: rejected because Phase 3 roster inclusion did not represent an explicit response except for the creator default.
- Require destructive recreation of participant records: rejected because it loses roster history and is unnecessary.

## Decision 7: Bound Proposal Volume Per Round

**Decision**: Support at most 50 time proposals and 50 location proposals per round for MVP validation.

**Rationale**: Crews are capped at 100 members for validation, and confirmation must tally and publish results transactionally. The cap bounds reads/writes, UI complexity, and transaction cost while remaining far above normal friend-group use.

**Alternatives considered**:

- Unlimited proposals: rejected because it creates unbounded confirmation work and poor ballot usability.
- One proposal per participant per category: rejected because immutable corrections may legitimately require a second proposal.
