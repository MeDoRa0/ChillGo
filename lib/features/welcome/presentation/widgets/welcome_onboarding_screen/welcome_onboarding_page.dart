part of '../../screens/welcome_onboarding_screen.dart';

class _WelcomeOnboardingPage extends StatelessWidget {
  const _WelcomeOnboardingPage({
    required this.artwork,
    required this.title,
    required this.description,
  });

  final Widget artwork;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 270,
                  width: double.infinity,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1,
                    child: artwork,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 72,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ChillGoColors.coral,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
