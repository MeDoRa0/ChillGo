part of '../../screens/crew_details_screen.dart';

class _CrewOutings extends StatelessWidget {
  final String crewId;

  const _CrewOutings({required this.crewId});

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<OutingRepository>()) return const SizedBox.shrink();
    final outingRepository = sl<OutingRepository>();
    return StreamBuilder<List<Outing>>(
      stream: outingRepository.streamCrewOutings(crewId),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final outings = (snapshot.data ?? const <Outing>[])
            .where((outing) => outing.isCurrentCrewPlanAt(now))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Crew plans',
                    style: TextStyle(
                      color: ChillGoColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/crews/$crewId/outings'),
                  child: const Text('See all'),
                ),
              ],
            ),
            if (snapshot.hasError)
              const Text(
                'Couldn’t load plans right now.',
                style: TextStyle(color: ChillGoColors.inkMuted),
              )
            else if (outings.isEmpty)
              const _InlineMessage(message: 'No plans yet — start the vibe.')
            else
              for (final outing in outings.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InteractiveOutingCard(
                    outing: outing,
                    outingRepository: outingRepository,
                    currentUserId: sl<AuthRepository>().currentCredentials?.uid,
                    agreementRepository: sl.isRegistered<AgreementRepository>()
                        ? sl<AgreementRepository>()
                        : null,
                  ),
                ),
          ],
        );
      },
    );
  }
}
