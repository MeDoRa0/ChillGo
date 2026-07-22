import 'agreement_category.dart';

class AgreementResult {
  const AgreementResult({
    required this.id,
    required this.roundId,
    required this.outingId,
    required this.crewId,
    required this.category,
    required this.selectedProposalId,
    required this.voteTotals,
    required this.eligibleParticipantCount,
    required this.participatingVoterCount,
    required this.confirmedAt,
  });
  final String id, roundId, outingId, crewId, selectedProposalId;
  final AgreementCategory category;
  final Map<String, int> voteTotals;
  final int eligibleParticipantCount, participatingVoterCount;
  final DateTime confirmedAt;
}
