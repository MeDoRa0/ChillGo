part of '../../screens/welcome_onboarding_screen.dart';

class _WelcomeProgress extends StatelessWidget {
  const _WelcomeProgress({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Onboarding page ${currentPage + 1} of $pageCount',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pageCount,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == currentPage ? 24 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == currentPage
                    ? ChillGoColors.coral
                    : ChillGoColors.outline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
