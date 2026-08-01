part of '../../screens/crew_details_screen.dart';

class _CrewHeader extends StatelessWidget {
  final Crew crew;
  final int memberCount;

  const _CrewHeader({required this.crew, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ChillGoColors.coral.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: ChillGoColors.surface, width: 2),
            ),
            child: const Icon(
              Icons.groups,
              color: ChillGoColors.coral,
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crew.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _MemberCountChip(count: memberCount),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
