import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/features/voting/presentation/widgets/attendance_summary.dart';
import 'package:chillgo/features/voting/presentation/widgets/proposal_ballot.dart';
import 'package:chillgo/features/voting/presentation/widgets/confirmed_result_summary.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/domain/entities/attendance_status.dart';
import 'package:chillgo/features/voting/domain/entities/agreement_category.dart';

OutingParticipant participant(String id, AttendanceStatus s) =>
    OutingParticipant(
      id: 'o_$id',
      outingId: 'o',
      crewId: 'c',
      userId: id,
      username: id,
      displayName: id,
      addedByUserId: 'u',
      addedAt: DateTime.utc(2030),
      isCreatorParticipant: id == 'u',
      attendanceStatus: s,
    );
void main() {
  testWidgets('shows separate attendance counts and response controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceSummary(
            participants: [
              participant('u', AttendanceStatus.accepted),
              participant('v', AttendanceStatus.invited),
              participant('w', AttendanceStatus.declined),
            ],
            currentUserId: 'u',
            canRespond: true,
            onRespond: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Invited 1'), findsOneWidget);
    expect(find.text('Accepted 1'), findsOneWidget);
    expect(find.text('Declined 1'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
  });
  testWidgets('ballot hides aggregates and renders immutable empty choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalBallot(
            category: AgreementCategory.location,
            proposals: const [],
            myVote: null,
            enabled: true,
            onVote: (_) {},
            onWithdraw: () {},
            onProposeLocation: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('location choices'), findsOneWidget);
    expect(find.textContaining('total'), findsNothing);
    expect(find.text('Suggest a location'), findsOneWidget);
  });
  testWidgets('confirmed summary exposes aggregate participation only', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfirmedResultSummary(results: [], proposals: []),
        ),
      ),
    );
    expect(find.text('Confirmed agreement'), findsOneWidget);
  });
}
