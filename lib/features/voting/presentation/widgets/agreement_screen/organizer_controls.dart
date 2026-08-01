part of '../../screens/agreement_screen.dart';

class _OrganizerControls extends StatefulWidget {
  const _OrganizerControls({required this.outingId});
  final String outingId;
  @override
  State<_OrganizerControls> createState() => _OrganizerControlsState();
}

class _OrganizerControlsState extends State<_OrganizerControls> {
  String? time, location;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AgreementCommandCubit, AgreementCommandState>(
        builder: (context, state) {
          final result =
              state is AgreementCommandSucceeded &&
                  state.command.type == AgreementCommandType.previewConfirmation
              ? state.command.result
              : null;
          final times =
              (result?['timeTiedProposalIds'] as List?)?.cast<String>() ??
              const <String>[];
          final locations =
              (result?['locationTiedProposalIds'] as List?)?.cast<String>() ??
              const <String>[];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (result == null)
                    FilledButton(
                      onPressed: () =>
                          context.read<AgreementCommandCubit>().run(
                            () => sl<AgreementRepository>().previewConfirmation(
                              widget.outingId,
                            ),
                          ),
                      child: const Text('Preview confirmation'),
                    ),
                  if (times.isNotEmpty)
                    DropdownButton<String>(
                      hint: const Text('Choose tied time'),
                      value: time,
                      items: [
                        for (final id in times)
                          DropdownMenuItem(value: id, child: Text(id)),
                      ],
                      onChanged: (v) => setState(() => time = v),
                    ),
                  if (locations.isNotEmpty)
                    DropdownButton<String>(
                      hint: const Text('Choose tied location'),
                      value: location,
                      items: [
                        for (final id in locations)
                          DropdownMenuItem(value: id, child: Text(id)),
                      ],
                      onChanged: (v) => setState(() => location = v),
                    ),
                  if (result != null)
                    FilledButton(
                      onPressed: () =>
                          context.read<AgreementCommandCubit>().run(
                            () => sl<AgreementRepository>().confirmRound(
                              widget.outingId,
                              selectedTimeProposalId: time,
                              selectedLocationProposalId: location,
                            ),
                          ),
                      child: const Text('Confirm agreement'),
                    ),
                ],
              ),
            ),
          );
        },
      );
}
