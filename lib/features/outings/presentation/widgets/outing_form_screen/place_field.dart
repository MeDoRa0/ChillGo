part of '../../screens/outing_form_screen.dart';

class _PlaceField extends StatelessWidget {
  const _PlaceField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: _validateLocation,
      style: const TextStyle(color: ChillGoColors.ink),
      decoration: const InputDecoration(hintText: 'e.g. Cafe in Downtown'),
    );
  }

  String? _validateLocation(String? input) {
    final placeName = input?.trim() ?? '';
    if (placeName.isEmpty || placeName.length > 120) {
      return 'Location must be between 1 and 120 characters.';
    }
    return null;
  }
}
