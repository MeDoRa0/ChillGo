import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/voting/domain/services/agreement_visibility_policy.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_round.dart';

AgreementRound round(AgreementRoundStatus s) => AgreementRound(
  id: 'r',
  outingId: 'o',
  crewId: 'c',
  sequence: 1,
  status: s,
  createdByUserId: 'u',
  createdAt: DateTime.utc(2030),
);
void main() {
  const p = AgreementVisibilityPolicy();
  test(
    'open aggregates remain sealed',
    () => expect(p.canSeeAggregate(round(AgreementRoundStatus.open)), isFalse),
  );
  test(
    'closed aggregates become visible',
    () => expect(
      p.canSeeAggregate(round(AgreementRoundStatus.confirmed)),
      isTrue,
    ),
  );
  test('individual ballots stay owner private', () {
    expect(p.canSeeIndividualVote(viewerId: 'u', voterId: 'u'), isTrue);
    expect(
      p.canSeeIndividualVote(viewerId: 'organizer', voterId: 'u'),
      isFalse,
    );
  });
}
