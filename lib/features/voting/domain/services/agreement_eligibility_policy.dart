import '../../../outings/domain/entities/attendance_status.dart';
import '../../../outings/domain/entities/outing_status.dart';
import '../entities/agreement_category.dart';
import '../entities/agreement_proposal.dart';
import '../entities/agreement_round.dart';

class AgreementEligibilityPolicy {
  const AgreementEligibilityPolicy();
  bool canParticipate({
    required bool isCrewMember,
    required AttendanceStatus attendance,
    required OutingStatus outingStatus,
    required AgreementRound round,
  }) =>
      isCrewMember &&
      attendance == AttendanceStatus.accepted &&
      outingStatus == OutingStatus.planning &&
      round.isOpen;
  bool canVote({
    required bool isCrewMember,
    required AttendanceStatus attendance,
    required OutingStatus outingStatus,
    required AgreementRound round,
    required AgreementProposal proposal,
    required AgreementCategory category,
    required DateTime now,
  }) =>
      canParticipate(
        isCrewMember: isCrewMember,
        attendance: attendance,
        outingStatus: outingStatus,
        round: round,
      ) &&
      proposal.roundId == round.id &&
      proposal.category == category &&
      proposal.isEligibleAt(now);
}
