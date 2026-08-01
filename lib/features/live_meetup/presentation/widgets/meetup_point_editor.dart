import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/shimmer_loading.dart';
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
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      widget.onSearch(query);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => widget.onSearch(query),
    );
  }

  void _searchNow(String query) {
    _searchDebounce?.cancel();
    widget.onSearch(query);
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
            const SizedBox(height: 4),
            Text('Confirmed location: ${widget.state.locationText ?? ''}'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Search for a place',
                hintText: 'Start typing a venue, landmark, or address',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onQueryChanged,
              onSubmitted: _searchNow,
            ),
            if (widget.state.status == MeetupPointEditorStatus.searching ||
                widget.state.status == MeetupPointEditorStatus.resolving)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: ShimmerBox(
                  height: 4,
                  borderRadius: 2,
                  semanticLabel: 'Searching meetup points',
                ),
              ),
            if (widget.state.results.isNotEmpty) ...[
              const SizedBox(height: 8),
              Semantics(
                label: 'Place suggestions',
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final result in widget.state.results)
                        ListTile(
                          leading: Icon(
                            widget.state.selection?.id == result.id
                                ? Icons.place
                                : Icons.location_on_outlined,
                          ),
                          title: Text(result.label),
                          onTap:
                              widget.state.status ==
                                  MeetupPointEditorStatus.resolving
                              ? null
                              : () => widget.onSelect(result),
                        ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Powered by Google'),
              ),
            ] else if (widget.state.query.length >= 3 &&
                widget.state.status == MeetupPointEditorStatus.ready)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('No matching places found.'),
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
                  widget.state.selection?.coordinate != null &&
                      widget.state.confirmed
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
