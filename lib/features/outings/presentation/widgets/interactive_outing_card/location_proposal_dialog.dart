part of '../interactive_outing_card.dart';

class _LocationProposalDialog extends StatefulWidget {
  const _LocationProposalDialog();

  @override
  State<_LocationProposalDialog> createState() =>
      _LocationProposalDialogState();
}

class _LocationProposalDialogState extends State<_LocationProposalDialog> {
  String _location = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Suggest a new location'),
    content: TextField(
      autofocus: true,
      maxLength: 120,
      onChanged: (text) => _location = text.trim(),
      decoration: const InputDecoration(labelText: 'Location'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Back'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_location),
        child: const Text('Suggest location'),
      ),
    ],
  );
}
