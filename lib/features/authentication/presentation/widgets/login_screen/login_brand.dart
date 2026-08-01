part of '../../screens/login_screen.dart';

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: const BoxDecoration(
            color: ChillGoColors.lavender,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(88),
              topRight: Radius.circular(56),
              bottomLeft: Radius.circular(62),
              bottomRight: Radius.circular(92),
            ),
          ),
          child: Column(
            children: [
              const ChillGoBrandMark(),
              const SizedBox(height: 16),
              Text('ChillGo', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text(
                'Good company. Easy meetups.\nBetter days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChillGoColors.inkMuted,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const ChillGoMeetupHighlights(),
      ],
    );
  }
}
