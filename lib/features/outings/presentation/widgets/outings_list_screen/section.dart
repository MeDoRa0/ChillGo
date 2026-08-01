part of '../../screens/outings_list_screen.dart';

class _Section extends StatelessWidget {
  final String title;
  final List<Outing> outings;

  const _Section({required this.title, required this.outings});

  @override
  Widget build(BuildContext context) {
    if (outings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ChillGoColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final outing in outings)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InteractiveOutingCard(
              outing: outing,
              outingRepository: sl<OutingRepository>(),
              currentUserId: sl<AuthRepository>().currentCredentials?.uid,
              agreementRepository: sl.isRegistered<AgreementRepository>()
                  ? sl<AgreementRepository>()
                  : null,
            ),
          ),
      ],
    );
  }
}
