import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../cubit/location_sharing/location_sharing_cubit.dart';

class LocationSharingControl extends StatelessWidget {
  const LocationSharingControl({
    super.key,
    required this.outingId,
    required this.state,
    required this.onStart,
    required this.onTransfer,
    required this.onStop,
  });
  final String outingId;
  final LocationSharingState state;
  final VoidCallback onStart;
  final VoidCallback onTransfer;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Sharing is off by default. If you start, only current Accepted '
            'meetup participants can see your latest point. It expires after '
            'two minutes and pauses whenever ChillGo is not in the foreground.',
          ),
          const SizedBox(height: 12),
          if (state.status == LocationSharingStatus.off ||
              state.status == LocationSharingStatus.failed)
            FilledButton.icon(
              key: const Key('start-location-sharing'),
              onPressed: onStart,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Start sharing'),
            ),
          if (state.status == LocationSharingStatus.transferConfirmation) ...[
            const Text('Another device is sharing. Transfer to this device?'),
            FilledButton(
              key: const Key('confirm-location-transfer'),
              onPressed: onTransfer,
              child: const Text('Transfer sharing'),
            ),
          ],
          if (state.status == LocationSharingStatus.active ||
              state.status == LocationSharingStatus.paused ||
              state.status == LocationSharingStatus.stopping)
            FilledButton.tonalIcon(
              key: const Key('stop-location-sharing'),
              onPressed: state.status == LocationSharingStatus.stopping
                  ? null
                  : onStop,
              icon: const Icon(Icons.location_off_outlined),
              label: Text(
                state.status == LocationSharingStatus.stopping
                    ? 'Stopping…'
                    : 'Stop sharing',
              ),
            ),
          if (state.status == LocationSharingStatus.starting)
            const ShimmerBox(
              height: 4,
              borderRadius: 2,
              semanticLabel: 'Starting location sharing',
            ),
          if (state.status == LocationSharingStatus.paused)
            const Text('Paused while ChillGo is not in the foreground.'),
          if (state.failure != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(state.failure!.message),
            ),
        ],
      ),
    ),
  );
}
