part of '../../screens/outing_form_screen.dart';

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
