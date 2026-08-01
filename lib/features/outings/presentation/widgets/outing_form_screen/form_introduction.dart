part of '../../screens/outing_form_screen.dart';

class _FormIntroduction extends StatelessWidget {
  const _FormIntroduction({required this.isEditMode});

  final bool isEditMode;

  @override
  Widget build(BuildContext context) => Text(
    isEditMode
        ? 'Update the details for your crew.'
        : 'A couple taps and the crew is in the loop ✨',
    style: const TextStyle(color: ChillGoColors.inkMuted, fontSize: 16),
  );
}
