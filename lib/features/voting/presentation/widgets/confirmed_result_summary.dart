import 'package:flutter/material.dart';
import '../../domain/entities/agreement_proposal.dart';
import '../../domain/entities/agreement_result.dart';

class ConfirmedResultSummary extends StatelessWidget {
  const ConfirmedResultSummary({
    super.key,
    required this.results,
    required this.proposals,
  });
  final List<AgreementResult> results;
  final List<AgreementProposal> proposals;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmed agreement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final result in results) ...[
            Builder(
              builder: (context) {
                final proposal = proposals
                    .where((p) => p.id == result.selectedProposalId)
                    .firstOrNull;
                return Text(
                  '${result.category.value}: ${proposal?.locationText ?? proposal?.timeValue?.toLocal() ?? result.selectedProposalId} (${result.participatingVoterCount}/${result.eligibleParticipantCount} participated)',
                );
              },
            ),
          ],
        ],
      ),
    ),
  );
}
