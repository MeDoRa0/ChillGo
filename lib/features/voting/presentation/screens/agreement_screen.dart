import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../outings/domain/entities/outing_status.dart';
import '../../../outings/domain/repositories/outing_repository.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_command.dart';
import '../../domain/repositories/agreement_repository.dart';
import '../cubit/agreement_command/agreement_command_cubit.dart';
import '../cubit/agreement_detail/agreement_detail_cubit.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/confirmed_result_summary.dart';
import '../widgets/proposal_ballot.dart';

class AgreementScreen extends StatelessWidget {
  const AgreementScreen({super.key, required this.outingId});
  final String outingId;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<AgreementDetailCubit>()..watch(outingId)),
      BlocProvider(create: (_) => sl<AgreementCommandCubit>()),
    ],
    child: _AgreementBody(outingId: outingId),
  );
}

class _AgreementBody extends StatelessWidget {
  const _AgreementBody({required this.outingId});
  final String outingId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Group agreement')),
    body: StreamBuilder<OutingDetail?>(
      stream: sl<OutingRepository>().streamOutingDetail(outingId),
      builder: (context, outingSnapshot) {
        final outing = outingSnapshot.data;
        if (outing == null) {
          return const Center(child: CircularProgressIndicator());
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
                  outing.outing.status == OutingStatus.planning && open != null;
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
                            () => sl<AgreementRepository>().openRound(outingId),
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
                                        .createTimeProposal(outingId, value),
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
  );
}

class _OrganizerControls extends StatefulWidget {
  const _OrganizerControls({required this.outingId});
  final String outingId;
  @override
  State<_OrganizerControls> createState() => _OrganizerControlsState();
}

class _OrganizerControlsState extends State<_OrganizerControls> {
  String? time, location;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AgreementCommandCubit, AgreementCommandState>(
        builder: (context, state) {
          final result =
              state is AgreementCommandSucceeded &&
                  state.command.type == AgreementCommandType.previewConfirmation
              ? state.command.result
              : null;
          final times =
              (result?['timeTiedProposalIds'] as List?)?.cast<String>() ??
              const <String>[];
          final locations =
              (result?['locationTiedProposalIds'] as List?)?.cast<String>() ??
              const <String>[];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (result == null)
                    FilledButton(
                      onPressed: () =>
                          context.read<AgreementCommandCubit>().run(
                            () => sl<AgreementRepository>().previewConfirmation(
                              widget.outingId,
                            ),
                          ),
                      child: const Text('Preview confirmation'),
                    ),
                  if (times.isNotEmpty)
                    DropdownButton<String>(
                      hint: const Text('Choose tied time'),
                      value: time,
                      items: [
                        for (final id in times)
                          DropdownMenuItem(value: id, child: Text(id)),
                      ],
                      onChanged: (v) => setState(() => time = v),
                    ),
                  if (locations.isNotEmpty)
                    DropdownButton<String>(
                      hint: const Text('Choose tied location'),
                      value: location,
                      items: [
                        for (final id in locations)
                          DropdownMenuItem(value: id, child: Text(id)),
                      ],
                      onChanged: (v) => setState(() => location = v),
                    ),
                  if (result != null)
                    FilledButton(
                      onPressed: () =>
                          context.read<AgreementCommandCubit>().run(
                            () => sl<AgreementRepository>().confirmRound(
                              widget.outingId,
                              selectedTimeProposalId: time,
                              selectedLocationProposalId: location,
                            ),
                          ),
                      child: const Text('Confirm agreement'),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _ReopenControl extends StatefulWidget {
  const _ReopenControl({required this.outingId});
  final String outingId;
  @override
  State<_ReopenControl> createState() => _ReopenControlState();
}

class _ReopenControlState extends State<_ReopenControl> {
  final reason = TextEditingController();
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: reason,
            decoration: const InputDecoration(
              labelText: 'Reason for reopening',
            ),
          ),
          FilledButton(
            onPressed: () => context.read<AgreementCommandCubit>().run(
              () => sl<AgreementRepository>().reopenRound(
                widget.outingId,
                reason.text,
              ),
            ),
            child: const Text('Reopen agreement'),
          ),
        ],
      ),
    ),
  );
}
