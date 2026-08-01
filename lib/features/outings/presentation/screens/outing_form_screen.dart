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

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: ShimmerBox(
      height: 4,
      borderRadius: 2,
      semanticLabel: 'Loading outing',
    ),
  );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(message, style: const TextStyle(color: ChillGoColors.danger)),
  );
}

class _LockedOutingMessage extends StatelessWidget {
  const _LockedOutingMessage();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Text(
      'This outing can no longer be edited.',
      style: TextStyle(color: ChillGoColors.inkMuted),
    ),
  );
}

class _FormIntroduction extends StatelessWidget {
  const _FormIntroduction({required this.isEditMode});

  final bool isEditMode;

  @override
  Widget build(BuildContext context) => Text(
    isEditMode
        ? 'Update the details for your crew.'
        : 'A couple taps and the crew is in the loop ✨',
    style: const TextStyle(color: ChillGoColors.inkMuted, fontSize: 16),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ChillGoColors.outline),
        boxShadow: [
          BoxShadow(
            color: ChillGoColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanCardTitle(icon: icon, title: title),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _PlanCardTitle extends StatelessWidget {
  const _PlanCardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: ChillGoColors.canvas,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ChillGoColors.coral),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.controller,
    required this.enabled,
    required this.selectedMapLocation,
    required this.onChooseMap,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? selectedMapLocation;
  final VoidCallback? onChooseMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Place name',
          style: TextStyle(
            color: ChillGoColors.inkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _PlaceField(controller: controller, enabled: enabled),
        const SizedBox(height: 16),
        _MapPickerPanel(
          selectedMapLocation: selectedMapLocation,
          onPressed: onChooseMap,
        ),
      ],
    );
  }
}

class _PlaceField extends StatelessWidget {
  const _PlaceField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: _validateLocation,
      style: const TextStyle(color: ChillGoColors.ink),
      decoration: const InputDecoration(hintText: 'e.g. Cafe in Downtown'),
    );
  }

  String? _validateLocation(String? input) {
    final placeName = input?.trim() ?? '';
    if (placeName.isEmpty || placeName.length > 120) {
      return 'Location must be between 1 and 120 characters.';
    }
    return null;
  }
}

class _MapPickerPanel extends StatelessWidget {
  const _MapPickerPanel({
    required this.selectedMapLocation,
    required this.onPressed,
  });

  final String? selectedMapLocation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = selectedMapLocation == null
        ? 'Choose on map'
        : 'Change map location';
    return Column(
      children: [
        _MapPreview(
          selectedMapLocation: selectedMapLocation,
          onPressed: onPressed,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.map_outlined),
          label: Text(buttonLabel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.selectedMapLocation,
    required this.onPressed,
  });

  final String? selectedMapLocation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: selectedMapLocation ?? 'Choose location on map',
        child: Material(
          color: ChillGoColors.canvas,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: _MapPreviewPainter()),
                  const Align(
                    alignment: Alignment(0, -0.2),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: ChillGoColors.coral,
                      size: 44,
                    ),
                  ),
                  if (selectedMapLocation != null)
                    _SelectedMapLabel(selectedMapLocation!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMapLabel extends StatelessWidget {
  const _SelectedMapLabel(this.mapLocation);

  final String mapLocation;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 12,
    right: 12,
    bottom: 10,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChillGoColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        mapLocation,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ChillGoColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.scheduledAt, required this.onChanged});

  final DateTime scheduledAt;
  final ValueChanged<DateTime>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SchedulePickerTile(
            icon: Icons.calendar_month_rounded,
            label: 'Date',
            displayText: _dateLabel(scheduledAt),
            onPressed: onChanged == null ? null : () => _pickDate(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SchedulePickerTile(
            icon: Icons.schedule_rounded,
            label: 'Time',
            displayText: _timeLabel(scheduledAt),
            onPressed: onChanged == null ? null : () => _pickTime(context),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = scheduledAt.isBefore(today) ? today : scheduledAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;
    onChanged!(
      DateTime(
        date.year,
        date.month,
        date.day,
        scheduledAt.hour,
        scheduledAt.minute,
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledAt),
    );
    if (time == null || !context.mounted) return;
    onChanged!(
      DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
        time.hour,
        time.minute,
      ),
    );
  }
}

class _SchedulePickerTile extends StatelessWidget {
  const _SchedulePickerTile({
    required this.icon,
    required this.label,
    required this.displayText,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String displayText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChillGoColors.canvas,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ChillGoColors.coral),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: ChillGoColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayText,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ChillGoColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormActionBar extends StatelessWidget {
  const _FormActionBar({
    required this.isEditMode,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isEditMode;
  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ChillGoColors.canvas,
        border: Border(top: BorderSide(color: ChillGoColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: isSubmitting
                    ? const ShimmerBox(
                        width: 20,
                        height: 20,
                        shape: BoxShape.circle,
                        semanticLabel: 'Saving outing',
                      )
                    : Text(isEditMode ? 'Save changes' : 'Share with crew'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime scheduledAt) =>
    '${_monthName(scheduledAt.month)} ${scheduledAt.day}, ${scheduledAt.year}';

String _timeLabel(DateTime scheduledAt) {
  final hour = scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12;
  final period = scheduledAt.hour < 12 ? 'AM' : 'PM';
  return '$hour:${scheduledAt.minute.toString().padLeft(2, '0')} $period';
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
