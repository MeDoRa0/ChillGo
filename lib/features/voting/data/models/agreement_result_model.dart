import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_result.dart';

class AgreementResultModel extends AgreementResult {
  const AgreementResultModel({
    required super.id,
    required super.roundId,
    required super.outingId,
    required super.crewId,
    required super.category,
    required super.selectedProposalId,
    required super.voteTotals,
    required super.eligibleParticipantCount,
    required super.participatingVoterCount,
    required super.confirmedAt,
  });
  factory AgreementResultModel.fromMap(
    Map<String, dynamic> m,
    String id,
  ) => AgreementResultModel(
    id: id,
    roundId: m['roundId'] as String,
    outingId: m['outingId'] as String,
    crewId: m['crewId'] as String,
    category: AgreementCategory.fromValue(m['category'] as String),
    selectedProposalId: (m['selectedProposalId'] ?? m['proposalId']) as String,
    voteTotals: Map<String, int>.from(
      m['voteTotals'] as Map? ??
          {m['proposalId'] as String: m['voteCount'] as int},
    ),
    eligibleParticipantCount: (m['eligibleParticipantCount'] ?? 0) as int,
    participatingVoterCount: (m['participatingVoterCount'] ?? 0) as int,
    confirmedAt: readFirestoreTimestamp(m['confirmedAt'] ?? m['createdAt'])!,
  );
}
