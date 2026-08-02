import 'package:flutter/material.dart';

Future<bool> confirmOutingCancellation(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => const _OutingCancellationDialog(),
      ) ??
      false;
}

class _OutingCancellationDialog extends StatelessWidget {
  const _OutingCancellationDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cancel outing?'),
    content: const Text('Are you sure you want to cancel this outing?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Keep outing'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Cancel outing'),
      ),
    ],
  );
}
