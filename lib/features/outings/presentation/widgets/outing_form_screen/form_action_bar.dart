part of '../../screens/outing_form_screen.dart';

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
