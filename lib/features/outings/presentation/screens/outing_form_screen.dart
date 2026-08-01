import 'dart:async';

import 'package:flutter/material.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../../core/presentation/widgets/responsive_content.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/sunshine_background.dart';
import '../../../live_meetup/domain/services/map_provider.dart';
import '../../domain/entities/outing.dart';
import '../../domain/repositories/outing_repository.dart';
import '../cubit/outing_form/outing_form_cubit.dart';
import '../widgets/outing_location_picker.dart';

class OutingFormScreen extends StatefulWidget {
  final String crewId;
  final String? outingId;

  const OutingFormScreen({super.key, required this.crewId, this.outingId});

  @override
  State<OutingFormScreen> createState() => _OutingFormScreenState();
}

class _OutingFormScreenState extends State<OutingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  late DateTime _scheduledAt;
  StreamSubscription<OutingDetail?>? _outingSubscription;
  Outing? _outing;
  bool _isLoadingOuting = false;
  String? _loadError;
  String? _selectedMapLocation;

  bool get _isEditMode => widget.outingId != null;

  @override
  void initState() {
    super.initState();
    _scheduledAt = DateTime.now().add(const Duration(days: 1));
    if (_isEditMode) _loadExistingOuting();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _outingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OutingFormCubit(outingRepository: sl<OutingRepository>()),
      child: BlocConsumer<OutingFormCubit, OutingFormState>(
        listener: (context, state) {
          if (state is OutingFormSuccess) {
            context.go(
              _isEditMode
                  ? '/crews/${widget.crewId}/outings'
                  : '/crews/${widget.crewId}',
            );
          } else if (state is OutingFormFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isSubmitting = state is OutingFormSubmitting;
          final outing = _outing;
          final isEditable =
              !_isEditMode || (outing?.status.isEditable ?? false);
          return Scaffold(
            appBar: AppBar(
              leading: AppBackButton(fallbackRoute: '/crews/${widget.crewId}'),
              title: Text(_isEditMode ? 'Edit outing' : 'Make a plan'),
            ),
            body: SunshineBackground(
              child: ResponsiveContent(
                maxWidth: 760,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_isLoadingOuting)
                        const ShimmerBox(
                          height: 4,
                          borderRadius: 2,
                          semanticLabel: 'Loading outing',
                        ),
                      if (_loadError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _loadError!,
                            style: const TextStyle(color: ChillGoColors.danger),
                          ),
                        ),
                      if (_isEditMode &&
                          outing != null &&
                          !outing.status.isEditable)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'This outing can no longer be edited.',
                            style: TextStyle(color: ChillGoColors.inkMuted),
                          ),
                        ),
                      Text(
                        _isEditMode
                            ? 'Update the details for your crew.'
                            : 'A couple taps and the crew is in the loop ✨',
                        style: const TextStyle(
                          color: ChillGoColors.inkMuted,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _QuestionLabel('What is the place name?'),
                      const SizedBox(height: 10),
                      _Field(
                        controller: _locationController,
                        label: 'e.g. Cafe in Downtown',
                        enabled: isEditable,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty || text.length > 120) {
                            return 'Location must be between 1 and 120 characters.';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: isEditable ? _chooseLocationOnMap : null,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(
                          _selectedMapLocation == null
                              ? 'Choose location on map'
                              : 'Change map location',
                        ),
                      ),
                      if (_selectedMapLocation != null) ...[
                        const SizedBox(height: 12),
                        _SelectedLocationPreview(
                          placeName: _locationController.text.trim(),
                          mapLocation: _selectedMapLocation!,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _QuestionLabel('When do you want to go out?'),
                      const SizedBox(height: 10),
                      _ScheduleTile(
                        scheduledAt: _scheduledAt,
                        onChanged: isEditable
                            ? (value) => setState(() => _scheduledAt = value)
                            : null,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed:
                            isSubmitting ||
                                !isEditable ||
                                (_isEditMode && outing == null)
                            ? null
                            : () => _submit(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: ChillGoColors.coral,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? const ShimmerBox(
                                width: 20,
                                height: 20,
                                shape: BoxShape.circle,
                                semanticLabel: 'Saving outing',
                              )
                            : Text(
                                _isEditMode
                                    ? 'Save changes'
                                    : 'Share with crew',
                              ),
                      ),
                      if (_isEditMode &&
                          outing != null &&
                          outing.status.isCancellable) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => _showCancelDialog(context),
                          child: const Text('Cancel outing'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (!_scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a future date and time.')),
      );
      return;
    }
    if (!_isEditMode && _selectedMapLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the place on the map first.')),
      );
      return;
    }
    final placeName = _locationController.text.trim();
    final locationText = _selectedMapLocation == null
        ? placeName
        : '$placeName • $_selectedMapLocation';
    if (locationText.length > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Place name and map location must fit within 120 characters.',
          ),
        ),
      );
      return;
    }
    final title = _isEditMode
        ? _titleController.text.trim()
        : 'Outing at ${locationText.length > 70 ? locationText.substring(0, 70) : locationText}';
    final cubit = context.read<OutingFormCubit>();
    final outing = _outing;
    if (_isEditMode && outing != null) {
      cubit.updateOuting(
        outing: outing,
        title: title,
        description: null,
        scheduledAt: _scheduledAt,
        locationText: locationText,
      );
    } else {
      cubit.createOuting(
        crewId: widget.crewId,
        title: title,
        description: null,
        scheduledAt: _scheduledAt,
        locationText: locationText,
      );
    }
  }

  Future<void> _chooseLocationOnMap() async {
    final location = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OutingLocationPicker(
          mapProvider: sl<MapProvider>(),
          initialQuery: _locationController.text.trim(),
        ),
      ),
    );
    if (location != null && mounted) {
      setState(() => _selectedMapLocation = location);
    }
  }

  void _loadExistingOuting() {
    _isLoadingOuting = true;
    _outingSubscription = sl<OutingRepository>()
        .streamOutingDetail(widget.outingId!)
        .listen(
          (detail) {
            if (!mounted) return;
            final outing = detail?.outing;
            setState(() {
              _isLoadingOuting = false;
              _loadError = outing == null ? 'Outing not found.' : null;
              _outing = outing;
              if (outing != null) {
                _titleController.text = outing.title;
                _locationController.text = outing.locationText;
                _scheduledAt = outing.scheduledAt;
              }
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _isLoadingOuting = false;
              _loadError = error.toString();
            });
          },
        );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel outing'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Keep outing'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Cancel outing'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (reason == null || reason.isEmpty || !context.mounted) return;
    context.read<OutingFormCubit>().cancelOuting(
      outingId: widget.outingId!,
      reason: reason,
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: ChillGoColors.ink),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: ChillGoColors.inkMuted),
        labelStyle: const TextStyle(color: ChillGoColors.inkMuted),
        filled: true,
        fillColor: ChillGoColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _SelectedLocationPreview extends StatelessWidget {
  final String placeName;
  final String mapLocation;

  const _SelectedLocationPreview({
    required this.placeName,
    required this.mapLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placeName,
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: ChillGoColors.coral,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  mapLocation,
                  style: const TextStyle(color: ChillGoColors.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final DateTime scheduledAt;
  final ValueChanged<DateTime>? onChanged;

  const _ScheduleTile({required this.scheduledAt, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: ChillGoColors.coral),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${_dateLabel(scheduledAt)} • ${_timeLabel(scheduledAt)}',
              style: const TextStyle(
                color: ChillGoColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Choose date and time',
            onPressed: onChanged == null ? null : () => _pickSchedule(context),
            icon: const Icon(
              Icons.edit_calendar_rounded,
              color: ChillGoColors.coral,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSchedule(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledAt),
    );
    if (time == null) return;
    onChanged!(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  String _dateLabel(DateTime value) =>
      '${_monthName(value.month)} ${value.day}, ${value.year}';

  String _timeLabel(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '$hour:${value.minute.toString().padLeft(2, '0')} $period';
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class _QuestionLabel extends StatelessWidget {
  final String text;

  const _QuestionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ChillGoColors.ink,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
  );
}
