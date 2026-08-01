import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';

part 'crew_card/crew_card_layout.dart';
part 'crew_card/crew_identity.dart';
part 'crew_card/no_upcoming_outing_footer.dart';
part 'crew_card/upcoming_outing_footer.dart';
part 'crew_card/cream_wave.dart';
part 'crew_card/countdown_badge.dart';
part 'crew_card/calendar_action.dart';
part 'crew_card/crew_members_summary.dart';
part 'crew_card/pending_invites_summary.dart';
part 'crew_card/member_avatar_row.dart';

class CrewCard extends StatefulWidget {
  final Crew crew;
  final VoidCallback? onTap;

  const CrewCard({super.key, required this.crew, this.onTap});

  @override
  State<CrewCard> createState() => _CrewCardState();
}

class _CrewCardState extends State<CrewCard> {
  late Stream<List<CrewMembership>> _memberStream;
  Stream<List<CrewInvitation>>? _invitationStream;
  Stream<List<Outing>>? _outingStream;

  @override
  void initState() {
    super.initState();
    _bindStreams();
  }

  @override
  void didUpdateWidget(CrewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.crew.id != widget.crew.id ||
        oldWidget.crew.ownerId != widget.crew.ownerId) {
      _bindStreams();
    }
  }

  void _bindStreams() {
    final crew = widget.crew;
    final crewRepository = sl<CrewRepository>();
    final currentUid = sl<AuthRepository>().currentCredentials?.uid;
    _memberStream = crewRepository.streamMembers(crew.id);
    _invitationStream = currentUid != null && crew.ownerId == currentUid
        ? crewRepository.streamPendingInvitationsForCrew(crew.id)
        : null;
    _outingStream = sl.isRegistered<OutingRepository>()
        ? sl<OutingRepository>().streamCrewOutings(crew.id)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final crew = widget.crew;

    return StreamBuilder<List<Outing>>(
      stream: _outingStream,
      initialData: const <Outing>[],
      builder: (context, snapshot) {
        final now = DateTime.now();
        final upcomingOuting = _nextOutingWithin24Hours(
          snapshot.data ?? const <Outing>[],
          now,
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: ChillGoColors.skySoft,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: ChillGoColors.outline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x146D3A72),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: _CrewCardLayout(
                crewName: crew.name,
                memberStream: _memberStream,
                invitationStream: _invitationStream,
                outingState: (outing: upcomingOuting, observedAt: now),
              ),
            ),
          ),
        );
      },
    );
  }
}

Outing? _nextOutingWithin24Hours(List<Outing> outings, DateTime now) {
  final cutoff = now.add(const Duration(hours: 24));
  Outing? next;

  for (final outing in outings) {
    final isUpcoming = outing.scheduledAt.isAfter(now);
    final isWithinWindow = !outing.scheduledAt.isAfter(cutoff);
    if (outing.status.isHistorical || !isUpcoming || !isWithinWindow) {
      continue;
    }
    if (next == null || outing.scheduledAt.isBefore(next.scheduledAt)) {
      next = outing;
    }
  }
  return next;
}

typedef _UpcomingOutingState = ({Outing? outing, DateTime observedAt});

class _CreamWaveClipper extends CustomClipper<Path> {
  const _CreamWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..cubicTo(
        size.width * 0.08,
        -2,
        size.width * 0.15,
        16,
        size.width * 0.25,
        16,
      )
      ..lineTo(size.width, 16)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_CreamWaveClipper oldClipper) => false;
}
