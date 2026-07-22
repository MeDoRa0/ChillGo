import '../entities/agreement_round.dart';

class AgreementVisibilityPolicy {
  const AgreementVisibilityPolicy();
  bool canSeeOwnVote({required String viewerId, required String voterId}) =>
      viewerId == voterId;
  bool canSeeAggregate(AgreementRound round) => !round.isOpen;
  bool canSeeIndividualVote({
    required String viewerId,
    required String voterId,
  }) => viewerId == voterId;
}
