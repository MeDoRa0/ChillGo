part of '../../screens/outing_form_screen.dart';

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.controller,
    required this.enabled,
    required this.selectedMapLocation,
    required this.onChooseMap,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? selectedMapLocation;
  final VoidCallback? onChooseMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Place name',
          style: TextStyle(
            color: ChillGoColors.inkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _PlaceField(controller: controller, enabled: enabled),
        const SizedBox(height: 16),
        _MapPickerPanel(
          selectedMapLocation: selectedMapLocation,
          onPressed: onChooseMap,
        ),
      ],
    );
  }
}
