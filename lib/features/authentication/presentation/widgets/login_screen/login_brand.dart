part of '../../screens/login_screen.dart';

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: ChillGoColors.sunshine,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.explore_rounded,
            size: 62,
            color: ChillGoColors.ink,
          ),
        ),
        const SizedBox(height: 22),
        Text('ChillGo', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        const Text(
          'Good plans, great people, unforgettable days.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ChillGoColors.inkMuted,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
