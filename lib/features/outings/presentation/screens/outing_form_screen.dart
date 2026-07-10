import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
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
  final _descriptionController = TextEditingController();
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
    _descriptionController.dispose();
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
            context.go('/outings/${state.outingId}');
          } else if (state is OutingFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is OutingFormSubmitting;
          final outing = _outing;
          final isEditable = !_isEditMode || (outing?.status.isEditable ?? false);
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Outing',
                style: TextStyle(color: Colors.white),
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
                  if (_isEditMode && outing != null && !outing.status.isEditable)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'This outing can no longer be edited.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  _Field(
                    controller: _titleController,
                    label: 'Title',
                    enabled: isEditable,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 3 || text.length > 80) {
                        return 'Title must be between 3 and 80 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 3,
                    enabled: isEditable,
                    validator: (value) {
                      if ((value ?? '').trim().length > 500) {
                        return 'Description must be 500 characters or fewer.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _locationController,
                    label: 'Location',
                    enabled: isEditable,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty || text.length > 120) {
                        return 'Location must be between 1 and 120 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _ScheduleTile(
                    scheduledAt: _scheduledAt,
                    onChanged: isEditable
                        ? (value) => setState(() => _scheduledAt = value)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isSubmitting || !isEditable || (_isEditMode && outing == null)
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
                        : Text(_isEditMode ? 'Save changes' : 'Create outing'),
                  ),
                  if (_isEditMode && outing != null && outing.status.isCancellable) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isSubmitting ? null : () => _showCancelDialog(context),
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
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final locationText = _locationController.text.trim();
    final cubit = context.read<OutingFormCubit>();
    final outing = _outing;
    if (_isEditMode && outing != null) {
      cubit.updateOuting(
        outing: outing,
        title: title,
        description: description,
        scheduledAt: _scheduledAt,
        locationText: locationText,
      );
    } else {
      cubit.createOuting(
        crewId: widget.crewId,
        title: title,
        description: description,
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
                _descriptionController.text = outing.description ?? '';
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
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
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
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${scheduledAt.toLocal()}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: onChanged == null
                ? null
                : () => onChanged!(DateTime.now().add(const Duration(days: 1))),
            child: const Text('Tomorrow'),
          ),
        ],
      ),
    );
  }
}
