import '../../../../core/data/firestore_timestamp.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_vote.dart';

class AgreementVoteModel extends AgreementVote {
  const AgreementVoteModel({
    required super.id,
    required super.roundId,
    required super.outingId,
    required super.crewId,
    required super.userId,
    required super.category,
    required super.proposalId,
    required super.createdAt,
    required super.updatedAt,
  });
  factory AgreementVoteModel.fromMap(Map<String, dynamic> m, String id) =>
      AgreementVoteModel(
        id: id,
        roundId: m['roundId'] as String,
        outingId: m['outingId'] as String,
        crewId: m['crewId'] as String,
        userId: m['userId'] as String,
        category: AgreementCategory.fromValue(m['category'] as String),
        proposalId: m['proposalId'] as String,
        createdAt: readFirestoreTimestamp(m['createdAt'])!,
        updatedAt: readFirestoreTimestamp(m['updatedAt'])!,
      );
  Map<String, dynamic> toMap() => {
    'roundId': roundId,
    'outingId': outingId,
    'crewId': crewId,
    'userId': userId,
    'category': category.value,
    'proposalId': proposalId,
    'createdAt': writeFirestoreTimestamp(createdAt),
    'updatedAt': writeFirestoreTimestamp(updatedAt),
  };
}
