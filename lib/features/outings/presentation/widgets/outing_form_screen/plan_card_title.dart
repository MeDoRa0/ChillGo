part of '../../screens/outing_form_screen.dart';

class _PlanCardTitle extends StatelessWidget {
  const _PlanCardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: ChillGoColors.canvas,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ChillGoColors.coral),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
