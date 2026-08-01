part of '../../screens/agreement_screen.dart';

class _AgreementBody extends StatelessWidget {
  const _AgreementBody({required this.outingId});
  final String outingId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Group agreement')),
    body: SunshineBackground(
      child: ResponsiveContent(
        maxWidth: 900,
        child: StreamBuilder<OutingDetail?>(
          stream: sl<OutingRepository>().streamOutingDetail(outingId),
          builder: (context, outingSnapshot) {
            final outing = outingSnapshot.data;
            if (outing == null) {
              return const ShimmerListPlaceholder(itemCount: 3);
            }
            final uid = sl<AuthRepository>().currentCredentials?.uid ?? '';
            return BlocListener<AgreementCommandCubit, AgreementCommandState>(
              listener: (context, state) {
                if (state is AgreementCommandFailed) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: BlocBuilder<AgreementDetailCubit, AgreementDetailState>(
                builder: (context, state) {
                  final agreement = state is AgreementDetailLoaded
                      ? state.detail
                      : null;
                  final open = agreement?.activeRound;
                  final planning =
                      outing.outing.status == OutingStatus.planning &&
                      open != null;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AttendanceSummary(
                        participants: outing.participants,
                        currentUserId: uid,
                        canRespond: ![
                          OutingStatus.meeting,
                          OutingStatus.completed,
                          OutingStatus.archived,
                          OutingStatus.cancelled,
                        ].contains(outing.outing.status),
                        onRespond: (status) =>
                            sl<OutingRepository>().respondToOuting(
                              outingId: outingId,
                              attendanceStatus: status,
                            ),
                      ),
                      if (outing.outing.status == OutingStatus.draft)
                        FilledButton(
                          onPressed: () =>
                              context.read<AgreementCommandCubit>().run(
                                () => sl<AgreementRepository>().openRound(
                                  outingId,
                                ),
                              ),
                          child: const Text('Open agreement round'),
                        ),
                      if (open != null && agreement != null)
                        for (final category in AgreementCategory.values)
                          ProposalBallot(
                            category: category,
                            proposals: agreement.proposals
                                .where(
                                  (p) =>
                                      p.roundId == open.id &&
                                      p.category == category,
                                )
                                .toList(),
                            myVote: agreement.myVotes
                                .where((v) => v.category == category)
                                .firstOrNull,
                            enabled: planning,
                            onVote: (proposalId) => sl<AgreementRepository>()
                                .castVote(open.id, category, proposalId),
                            onWithdraw: () => sl<AgreementRepository>()
                                .withdrawVote(open.id, category),
                            onProposeLocation:
                                category == AgreementCategory.location
                                ? (value) =>
                                      context.read<AgreementCommandCubit>().run(
                                        () => sl<AgreementRepository>()
                                            .createLocationProposal(
                                              outingId,
                                              value,
                                            ),
                                      )
                                : null,
                            onProposeTime: category == AgreementCategory.time
                                ? (value) =>
                                      context.read<AgreementCommandCubit>().run(
                                        () => sl<AgreementRepository>()
                                            .createTimeProposal(
                                              outingId,
                                              value,
                                            ),
                                      )
                                : null,
                          ),
                      if (planning) _OrganizerControls(outingId: outingId),
                      if (outing.outing.status == OutingStatus.confirmed)
                        _ReopenControl(outingId: outingId),
                      if (agreement?.results.isNotEmpty == true)
                        ConfirmedResultSummary(
                          results: agreement!.results,
                          proposals: agreement.proposals,
                        ),
                      if (agreement?.rounds.isNotEmpty == true)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Agreement history'),
                                for (final round in agreement!.rounds)
                                  Text(
                                    'Round ${round.sequence}: ${round.status.value}${round.reopenReason == null ? '' : ' - ${round.reopenReason}'}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    ),
  );
}
