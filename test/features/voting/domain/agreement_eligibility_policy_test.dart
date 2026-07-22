import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/voting/domain/services/agreement_eligibility_policy.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_round.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_proposal.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_category.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';
import 'package:chillgo/features/outings/domain/entities/outing_status.dart';

void main() {
  final now = DateTime.utc(2030);
  final round = AgreementRound(
    id: 'r',
    outingId: 'o',
    crewId: 'c',
    sequence: 1,
    status: AgreementRoundStatus.open,
    createdByUserId: 'u',
    createdAt: now,
  );
  AgreementProposal proposal(DateTime time) => AgreementProposal(
    id: 'p',
    roundId: 'r',
    outingId: 'o',
    crewId: 'c',
    category: AgreementCategory.time,
    createdByUserId: 'u',
    authorDisplayName: 'U',
    normalizedValue: 'x',
    createdAt: now,
    timeValue: time,
  );
  test(
    'accepted current member can vote for active future proposal',
    () => expect(
      const AgreementEligibilityPolicy().canVote(
        isCrewMember: true,
        attendance: AttendanceStatus.accepted,
        outingStatus: OutingStatus.planning,
        round: round,
        proposal: proposal(now.add(const Duration(days: 1))),
        category: AgreementCategory.time,
        now: now,
      ),
      isTrue,
    ),
  );
  test('rejects expired proposal and lost eligibility', () {
    const p = AgreementEligibilityPolicy();
    expect(
      p.canVote(
        isCrewMember: true,
        attendance: AttendanceStatus.accepted,
        outingStatus: OutingStatus.planning,
        round: round,
        proposal: proposal(now),
        category: AgreementCategory.time,
        now: now,
      ),
      isFalse,
    );
    expect(
      p.canParticipate(
        isCrewMember: false,
        attendance: AttendanceStatus.accepted,
        outingStatus: OutingStatus.planning,
        round: round,
      ),
      isFalse,
    );
    expect(
      p.canParticipate(
        isCrewMember: true,
        attendance: AttendanceStatus.declined,
        outingStatus: OutingStatus.planning,
        round: round,
      ),
      isFalse,
    );
  });
}
