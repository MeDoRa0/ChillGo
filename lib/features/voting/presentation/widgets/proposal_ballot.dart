import 'package:flutter/material.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_proposal.dart';
import '../../domain/entities/agreement_vote.dart';

class ProposalBallot extends StatefulWidget {
  const ProposalBallot({
    super.key,
    required this.category,
    required this.proposals,
    required this.myVote,
    required this.enabled,
    required this.onVote,
    required this.onWithdraw,
    this.onProposeLocation,
    this.onProposeTime,
  });
  final AgreementCategory category;
  final List<AgreementProposal> proposals;
  final AgreementVote? myVote;
  final bool enabled;
  final ValueChanged<String> onVote;
  final VoidCallback onWithdraw;
  final ValueChanged<String>? onProposeLocation;
  final ValueChanged<DateTime>? onProposeTime;
  @override
  State<ProposalBallot> createState() => _ProposalBallotState();
}

class _ProposalBallotState extends State<ProposalBallot> {
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.category.value} choices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          RadioGroup<String>(
            groupValue: widget.myVote?.proposalId,
            onChanged: (value) {
              if (widget.enabled && value != null) widget.onVote(value);
            },
            child: Column(
              children: [
                for (final proposal in widget.proposals)
                  RadioListTile<String>(
                    value: proposal.id,
                    enabled:
                        widget.enabled && proposal.isEligibleAt(DateTime.now()),
                    title: Text(
                      proposal.category == AgreementCategory.time
                          ? proposal.timeValue?.toLocal().toString() ??
                                'Expired'
                          : proposal.locationText ?? '',
                    ),
                    subtitle: Text(
                      'Suggested by ${proposal.authorDisplayName}${proposal.isExpiredAt(DateTime.now()) ? ' - expired' : ''}',
                    ),
                  ),
              ],
            ),
          ),
          if (widget.myVote != null)
            TextButton(
              onPressed: widget.enabled ? widget.onWithdraw : null,
              child: const Text('Withdraw vote'),
            ),
          if (widget.category == AgreementCategory.location &&
              widget.onProposeLocation != null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    decoration: const InputDecoration(
                      labelText: 'Suggest a location',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.enabled
                      ? () {
                          widget.onProposeLocation!(text.text);
                          text.clear();
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          if (widget.category == AgreementCategory.time &&
              widget.onProposeTime != null)
            TextButton(
              onPressed: widget.enabled
                  ? () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (date != null) widget.onProposeTime!(date);
                    }
                  : null,
              child: const Text('Suggest a time'),
            ),
        ],
      ),
    ),
  );
}
