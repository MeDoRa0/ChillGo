part of '../../screens/crew_details_screen.dart';

class _CreateOutingButton extends StatelessWidget {
  final String crewId;

  const _CreateOutingButton({required this.crewId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          context.go('/crews/$crewId/outings/new');
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Create outing'),
        style: FilledButton.styleFrom(
          backgroundColor: ChillGoColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
