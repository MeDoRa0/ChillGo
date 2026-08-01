part of '../interactive_outing_card.dart';

class _PlanChangeDialog extends StatelessWidget {
  const _PlanChangeDialog();

  @override
  Widget build(BuildContext context) => SimpleDialog(
    title: const Text('What would you like to change?'),
    children: [
      SimpleDialogOption(
        onPressed: () => Navigator.of(context).pop(_PlanChange.dateAndTime),
        child: const Text('Date and time'),
      ),
      SimpleDialogOption(
        onPressed: () => Navigator.of(context).pop(_PlanChange.location),
        child: const Text('Location'),
      ),
    ],
  );
}
