# Contract: Agreement Repository

Presentation Cubits depend on this provider-neutral contract. Concrete Firestore command and snapshot behavior remains in the data layer.

## Read Operations

```text
streamAgreement(outingId) -> Stream<AgreementDetail?>
streamMyVotes(roundId) -> Stream<List<AgreementVote>>
streamCommand(commandId) -> Stream<AgreementCommand?>
```

`AgreementDetail` includes the outing/attendance summary, active or historical round, proposals, the signed-in participant's own votes, and aggregate results only when permitted. It never contains other participants' ballot documents.

## Attendance Operations

```text
respondToOuting(outingId, attendanceStatus) -> Future<void>
```

The repository rejects `invited` as an explicit response and maps permission/state failures to stable domain failures.

## Vote Operations

```text
castVote(roundId, category, proposalId) -> Future<void>
withdrawVote(roundId, category) -> Future<void>
```

Vote writes use predictable IDs and affect only the signed-in user's ballot. The repository performs fast local validation, while Security Rules remain authoritative.

## Command Operations

Each method creates a command and returns its identifier immediately. The UI observes completion through `streamCommand` and exposes pending, success, retryable failure, and terminal failure states.

```text
openRound(outingId) -> Future<String commandId>
createTimeProposal(outingId, timeValue) -> Future<String commandId>
createLocationProposal(outingId, locationText) -> Future<String commandId>
previewConfirmation(outingId) -> Future<String commandId>
confirmRound(
  outingId,
  selectedTimeProposalId?,
  selectedLocationProposalId?
) -> Future<String commandId>
reopenRound(outingId, reason) -> Future<String commandId>
cancelOuting(outingId, reason) -> Future<String commandId>
deleteOuting(outingId) -> Future<String commandId>
```

## Domain Failure Mapping

- Authentication or membership failure -> `AgreementAccessDenied`
- Invalid attendance/outing/round state -> `AgreementStateConflict`
- Invalid proposal or vote -> `AgreementValidationFailure`
- Proposal cap -> `AgreementProposalLimitReached`
- Confirmation changed after preview -> `AgreementConfirmationChanged`
- Offline Firestore write failure -> `AgreementNetworkFailure`
- Function terminal internal failure -> `AgreementServiceFailure`

## Integration with Outing Management

- `OutingRepository.acceptOuting` is replaced by explicit attendance response semantics; it no longer creates a participant as the Phase 4 acceptance action.
- Phase 3 participant addition creates an `invited` participant; the outing creator is created as `accepted`.
- Agreement-controlled lifecycle transitions route through `AgreementRepository`. Existing direct `changeLifecycleStatus` must reject Draft-to-Planning and Planning-to-Confirmed after Phase 4 wiring.
- Existing direct outing detail editing may change scheduled time and location only in Draft. From Planning onward, those fields change only through agreement confirmation or reopening; title and description retain their Phase 3 permissions.
- Existing cancellation routes through the agreement command so the outing and open round close atomically.
- Permanent removal routes through the agreement command, is available only to the outing creator in every lifecycle status, and cascades across all participant and agreement records owned by the outing.
