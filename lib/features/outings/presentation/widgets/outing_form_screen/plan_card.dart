part of '../../screens/outing_form_screen.dart';

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ChillGoColors.outline),
        boxShadow: [
          BoxShadow(
            color: ChillGoColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanCardTitle(icon: icon, title: title),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
