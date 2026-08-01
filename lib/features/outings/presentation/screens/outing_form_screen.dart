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
import '../../../live_meetup/domain/services/device_location_service.dart';
import '../../../live_meetup/domain/services/map_provider.dart';
import '../../domain/entities/outing.dart';
import '../../domain/repositories/outing_repository.dart';
import '../cubit/outing_form/outing_form_cubit.dart';
import '../widgets/outing_location_picker.dart';

part '../widgets/outing_form_screen/loading_indicator.dart';
part '../widgets/outing_form_screen/error_message.dart';
part '../widgets/outing_form_screen/locked_outing_message.dart';
part '../widgets/outing_form_screen/form_introduction.dart';
part '../widgets/outing_form_screen/plan_card.dart';
part '../widgets/outing_form_screen/plan_card_title.dart';
part '../widgets/outing_form_screen/location_section.dart';
part '../widgets/outing_form_screen/place_field.dart';
part '../widgets/outing_form_screen/map_picker_panel.dart';
part '../widgets/outing_form_screen/map_preview.dart';
part '../widgets/outing_form_screen/selected_map_label.dart';
part '../widgets/outing_form_screen/schedule_card.dart';
part '../widgets/outing_form_screen/schedule_picker_tile.dart';
part '../widgets/outing_form_screen/form_action_bar.dart';

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
        listener: _onFormStateChanged,
        builder: _buildScreen,
      ),
    );
  }

  void _onFormStateChanged(BuildContext context, OutingFormState state) {
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
  }

  Widget _buildScreen(BuildContext context, OutingFormState state) {
    final isSubmitting = state is OutingFormSubmitting;
    final outing = _outing;
    final isEditable = !_isEditMode || (outing?.status.isEditable ?? false);
    final canSubmit =
        !isSubmitting && isEditable && (!_isEditMode || outing != null);
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(fallbackRoute: '/crews/${widget.crewId}'),
        title: Text(_isEditMode ? 'Edit outing' : 'Make a plan'),
      ),
      body: _buildFormBody(context, isSubmitting, isEditable, outing),
      bottomNavigationBar: _FormActionBar(
        isEditMode: _isEditMode,
        isSubmitting: isSubmitting,
        onPressed: canSubmit ? () => _submit(context) : null,
      ),
    );
  }

  Widget _buildFormBody(
    BuildContext context,
    bool isSubmitting,
    bool isEditable,
    Outing? outing,
  ) {
    return SunshineBackground(
      child: ResponsiveContent(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: _formChildren(context, isSubmitting, isEditable, outing),
          ),
        ),
      ),
    );
  }

  List<Widget> _formChildren(
    BuildContext context,
    bool isSubmitting,
    bool isEditable,
    Outing? outing,
  ) {
    return [
      if (_isLoadingOuting) const _LoadingIndicator(),
      if (_loadError != null) _ErrorMessage(_loadError!),
      if (_isEditMode && outing != null && !outing.status.isEditable)
        const _LockedOutingMessage(),
      _FormIntroduction(isEditMode: _isEditMode),

      if (!_isEditMode) const SizedBox(height: 20),
      _PlanCard(
        icon: Icons.location_on_rounded,
        title: 'Where are we going?',
        child: _LocationSection(
          controller: _locationController,
          enabled: isEditable,
          selectedMapLocation: _selectedMapLocation,
          onChooseMap: isEditable ? _chooseLocationOnMap : null,
        ),
      ),
      const SizedBox(height: 18),
      _PlanCard(
        icon: Icons.calendar_month_rounded,
        title: 'When?',
        child: _ScheduleCard(
          scheduledAt: _scheduledAt,
          onChanged: isEditable
              ? (scheduledAt) => setState(() => _scheduledAt = scheduledAt)
              : null,
        ),
      ),
      if (_isEditMode && outing != null && outing.status.isCancellable) ...[
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: isSubmitting ? null : () => _showCancelDialog(context),
          child: const Text('Cancel outing'),
        ),
      ],
    ];
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
          deviceLocationService: sl<DeviceLocationService>(),
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

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final river = Paint()
      ..color = ChillGoColors.skySoft
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = ChillGoColors.surface
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-12, size.height * 0.9),
      Offset(size.width + 12, size.height * 0.35),
      river,
    );
    canvas.drawLine(
      Offset(-8, size.height * 0.25),
      Offset(size.width + 8, size.height * 0.72),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.27, -8),
      Offset(size.width * 0.45, size.height + 8),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, -8),
      Offset(size.width * 0.58, size.height + 8),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) => false;
}
