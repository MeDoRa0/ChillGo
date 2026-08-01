part of '../../screens/agreement_screen.dart';

class _ReopenControl extends StatefulWidget {
  const _ReopenControl({required this.outingId});
  final String outingId;
  @override
  State<_ReopenControl> createState() => _ReopenControlState();
}

class _ReopenControlState extends State<_ReopenControl> {
  final reason = TextEditingController();
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: reason,
            decoration: const InputDecoration(
              labelText: 'Reason for reopening',
            ),
          ),
          FilledButton(
            onPressed: () => context.read<AgreementCommandCubit>().run(
              () => sl<AgreementRepository>().reopenRound(
                widget.outingId,
                reason.text,
              ),
            ),
            child: const Text('Reopen agreement'),
          ),
        ],
      ),
    ),
  );
}
