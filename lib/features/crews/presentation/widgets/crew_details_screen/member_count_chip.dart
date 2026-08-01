part of '../../screens/crew_details_screen.dart';

class _MemberCountChip extends StatelessWidget {
  final int count;

  const _MemberCountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? 'member' : 'members';
    return Container(
      key: const Key('crew-member-count'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ChillGoColors.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, color: ChillGoColors.coral, size: 18),
          const SizedBox(width: 7),
          Text(
            '$count $label',
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
