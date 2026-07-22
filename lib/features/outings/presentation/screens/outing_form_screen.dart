import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../domain/entities/outing.dart';
import '../../domain/repositories/outing_repository.dart';
import '../cubit/outing_form/outing_form_cubit.dart';

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
            context.go('/crews/${widget.crewId}/outings');
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
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              elevation: 0,
              leading: AppBackButton(fallbackRoute: '/crews/${widget.crewId}'),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                _isEditMode ? 'Edit outing' : 'Make a plan',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isLoadingOuting)
                    const LinearProgressIndicator(color: Color(0xFF6366F1)),
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _loadError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  if (_isEditMode &&
                      outing != null &&
                      !outing.status.isEditable)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'This outing can no longer be edited.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  Text(
                    _isEditMode
                        ? 'Update the details for your crew.'
                        : 'A couple taps and the crew is in the loop ✨',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const _QuestionLabel('Where do you want to go?'),
                  const SizedBox(height: 10),
                  _Field(
                    controller: _locationController,
                    label: 'e.g. the new ramen spot',
                    enabled: isEditable,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty || text.length > 120) {
                        return 'Location must be between 1 and 120 characters.';
                      }
                      return null;
                    },
                  ),
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
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditMode ? 'Save changes' : 'Share with crew',
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
    final locationText = _locationController.text.trim();
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

  const _Field({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E1E2F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: Color(0xFFB8A7FF)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${_dateLabel(scheduledAt)} • ${_timeLabel(scheduledAt)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Choose date and time',
            onPressed: onChanged == null ? null : () => _pickSchedule(context),
            icon: const Icon(
              Icons.edit_calendar_rounded,
              color: Color(0xFFB8A7FF),
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
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
  );
}
