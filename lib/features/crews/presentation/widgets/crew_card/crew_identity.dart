part of '../crew_card.dart';

class _CrewIdentity extends StatelessWidget {
  const _CrewIdentity({
    required this.crewName,
    required this.memberStream,
    required this.invitationStream,
    required this.dense,
  });

  final String crewName;
  final Stream<List<CrewMembership>> memberStream;
  final Stream<List<CrewInvitation>>? invitationStream;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final iconDiameter = dense ? 30.0 : 36.0;
    final avatarDiameter = dense ? 28.0 : 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconDiameter,
                  height: iconDiameter,
                  decoration: BoxDecoration(
                    color: ChillGoColors.surface.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups,
                    color: ChillGoColors.sky,
                    size: dense ? 17 : 20,
                  ),
                ),
                SizedBox(height: dense ? 2 : 4),
                Text(
                  crewName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: dense ? 15 : 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: dense ? 2 : 4),
                _CrewMembersSummary(
                  memberStream: memberStream,
                  invitationStream: invitationStream,
                  avatarDiameter: avatarDiameter,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
