import 'package:flutter/material.dart';

import '../cubit/meetup_point_editor/meetup_point_editor_cubit.dart';
import '../../domain/services/map_provider.dart';

class MeetupPointEditor extends StatefulWidget {
  const MeetupPointEditor({
    super.key,
    required this.state,
    required this.onSearch,
    required this.onSelect,
    required this.onConfirm,
    required this.onSave,
  });
  final MeetupPointEditorState state;
  final ValueChanged<String> onSearch;
  final ValueChanged<PlaceCandidate> onSelect;
  final ValueChanged<bool> onConfirm;
  final VoidCallback onSave;

  @override
  State<MeetupPointEditor> createState() => _MeetupPointEditorState();
}

class _MeetupPointEditorState extends State<MeetupPointEditor> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.status == MeetupPointEditorStatus.unavailable ||
        widget.state.status == MeetupPointEditorStatus.initial ||
        widget.state.status == MeetupPointEditorStatus.loading) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set exact meetup point',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Confirmed location: ${widget.state.locationText ?? ''}'),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Search location'),
              onSubmitted: widget.onSearch,
            ),
            for (final result in widget.state.results)
              ListTile(
                leading: Icon(
                  widget.state.selection == result
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(result.label),
                onTap: () => widget.onSelect(result),
              ),
            if (widget.state.selection != null)
              CheckboxListTile(
                value: widget.state.confirmed,
                onChanged: (value) => widget.onConfirm(value ?? false),
                title: Text(
                  'This point is for “${widget.state.locationText ?? ''}”.',
                ),
              ),
            FilledButton(
              onPressed:
                  widget.state.selection != null && widget.state.confirmed
                  ? widget.onSave
                  : null,
              child: const Text('Save meetup point'),
            ),
            if (widget.state.failure != null)
              Text(widget.state.failure!.message),
          ],
        ),
      ),
    );
  }
}
