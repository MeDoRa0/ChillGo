import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../domain/entities/live_meetup_status.dart';
import '../cubit/live_meetup/live_meetup_cubit.dart';

class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.selected,
    required this.mutationState,
    required this.onSelected,
  });
  final LiveMeetupStatus? selected;
  final StatusMutationState mutationState;
  final ValueChanged<LiveMeetupStatus> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Your arrival status',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      SegmentedButton<LiveMeetupStatus>(
        key: const Key('live-meetup-status-selector'),
        segments: [
          for (final value in LiveMeetupStatus.values)
            ButtonSegment(value: value, label: Text(value.label)),
        ],
        selected: selected == null ? const {} : {selected!},
        emptySelectionAllowed: true,
        onSelectionChanged: mutationState == StatusMutationState.submitting
            ? null
            : (values) {
                if (values.isNotEmpty) onSelected(values.single);
              },
      ),
      if (mutationState == StatusMutationState.submitting)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: ShimmerBox(
            height: 4,
            borderRadius: 2,
            semanticLabel: 'Updating arrival status',
          ),
        ),
      if (mutationState == StatusMutationState.succeeded)
        const Text(
          'Status updated.',
          semanticsLabel: 'Status update succeeded',
        ),
      if (mutationState == StatusMutationState.superseded)
        const Text('A newer status was already saved.'),
      if (mutationState == StatusMutationState.failed)
        const Text('Status was not saved. Try again.'),
    ],
  );
}
