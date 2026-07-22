import 'agreement_category.dart';

class AgreementVote {
  const AgreementVote({
    required this.id,
    required this.roundId,
    required this.outingId,
    required this.crewId,
    required this.userId,
    required this.category,
    required this.proposalId,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, roundId, outingId, crewId, userId, proposalId;
  final AgreementCategory category;
  final DateTime createdAt, updatedAt;
  static String documentId(
    String roundId,
    AgreementCategory category,
    String userId,
  ) => '${roundId}_${category.value}_$userId';
}
