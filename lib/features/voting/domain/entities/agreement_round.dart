enum AgreementRoundStatus {
  open('open'),
  confirmed('confirmed'),
  superseded('superseded'),
  cancelled('cancelled');

  const AgreementRoundStatus(this.value);
  final String value;
  static AgreementRoundStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () =>
        throw FormatException('Invalid agreement round status: $value'),
  );
}

class AgreementRound {
  const AgreementRound({
    required this.id,
    required this.outingId,
    required this.crewId,
    required this.sequence,
    required this.status,
    required this.createdByUserId,
    required this.createdAt,
    this.closedAt,
    this.supersededByRoundId,
    this.reopenReason,
    this.seedTimeProposalId,
    this.seedLocationProposalId,
    this.confirmedByUserId,
    this.confirmedAt,
    this.selectedTimeProposalId,
    this.selectedLocationProposalId,
    this.eligibleVoterCount,
    this.timeVoteCount,
    this.locationVoteCount,
  });
  final String id, outingId, crewId, createdByUserId;
  final int sequence;
  final AgreementRoundStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;
  final String? supersededByRoundId, reopenReason;
  final String? seedTimeProposalId, seedLocationProposalId, confirmedByUserId;
  final DateTime? confirmedAt;
  final String? selectedTimeProposalId, selectedLocationProposalId;
  final int? eligibleVoterCount, timeVoteCount, locationVoteCount;
  bool get isOpen => status == AgreementRoundStatus.open;
}
