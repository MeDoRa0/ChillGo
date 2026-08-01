part of '../../screens/outing_form_screen.dart';

class _MapPickerPanel extends StatelessWidget {
  const _MapPickerPanel({
    required this.selectedMapLocation,
    required this.onPressed,
  });

  final String? selectedMapLocation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = selectedMapLocation == null
        ? 'Choose on map'
        : 'Change map location';
    return Column(
      children: [
        _MapPreview(
          selectedMapLocation: selectedMapLocation,
          onPressed: onPressed,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.map_outlined),
          label: Text(buttonLabel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}
