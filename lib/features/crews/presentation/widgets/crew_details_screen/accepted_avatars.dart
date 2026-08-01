part of '../../screens/crew_details_screen.dart';

class AcceptedAvatars extends StatelessWidget {
  final List<OutingParticipant> participants;

  const AcceptedAvatars({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Text(
        'Be the first one in',
        style: TextStyle(color: ChillGoColors.inkMuted),
      );
    }
    final shown = participants.take(4).toList();
    return SizedBox(
      height: 34,
      child: Stack(
        children: [
          for (var index = 0; index < shown.length; index++)
            Positioned(
              left: index * 22.0,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: ChillGoColors.coralSoft,
                backgroundImage: shown[index].avatarUrl?.isNotEmpty == true
                    ? NetworkImage(shown[index].avatarUrl!)
                    : null,
                child: shown[index].avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        shown[index].displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: ChillGoColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          if (participants.length > shown.length)
            Positioned(
              left: shown.length * 22.0,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: ChillGoColors.plum,
                child: Text(
                  '+${participants.length - shown.length}',
                  style: const TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
