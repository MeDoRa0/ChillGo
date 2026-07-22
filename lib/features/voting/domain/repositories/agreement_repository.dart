import '../../../outings/domain/entities/attendance_status.dart';
import '../entities/agreement_category.dart';
import '../entities/agreement_command.dart';
import '../entities/agreement_proposal.dart';
import '../entities/agreement_result.dart';
import '../entities/agreement_round.dart';
import '../entities/agreement_vote.dart';

class AgreementDetail {
  const AgreementDetail({
    this.activeRound,
    this.rounds = const [],
    this.proposals = const [],
    this.myVotes = const [],
    this.results = const [],
  });
  final AgreementRound? activeRound;
  final List<AgreementRound> rounds;
  final List<AgreementProposal> proposals;
  final List<AgreementVote> myVotes;
  final List<AgreementResult> results;
}

abstract interface class AgreementRepository {
  Stream<AgreementDetail?> streamAgreement(String outingId);
  Stream<List<AgreementVote>> streamMyVotes(String roundId);
  Stream<AgreementCommand?> streamCommand(String commandId);
  Future<void> respondToOuting(String outingId, AttendanceStatus status);
  Future<void> castVote(
    String roundId,
    AgreementCategory category,
    String proposalId,
  );
  Future<void> withdrawVote(String roundId, AgreementCategory category);
  Future<String> openRound(String outingId);
  Future<String> createTimeProposal(String outingId, DateTime value);
  Future<String> createLocationProposal(String outingId, String value);
  Future<String> previewConfirmation(String outingId);
  Future<String> confirmRound(
    String outingId, {
    String? selectedTimeProposalId,
    String? selectedLocationProposalId,
  });
  Future<String> reopenRound(String outingId, String reason);
  Future<String> cancelOuting(String outingId, String reason);
  Future<String> deleteOuting(String outingId);
  Future<String> requestOutingExpiry(String outingId);
}
