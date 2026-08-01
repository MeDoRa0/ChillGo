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

class _CrewCardLayout extends StatelessWidget {
  const _CrewCardLayout({
    required this.crewName,
    required this.memberStream,
    required this.invitationStream,
    required this.outingState,
  });

  final String crewName;
  final Stream<List<CrewMembership>> memberStream;
  final Stream<List<CrewInvitation>>? invitationStream;
  final _UpcomingOutingState outingState;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 210;
        final upcomingOuting = outingState.outing;
        final hasUpcomingOuting = upcomingOuting != null;
        final footerHeight = hasUpcomingOuting
            ? (compact ? 76.0 : constraints.maxHeight * 0.42)
            : (compact ? 56.0 : constraints.maxHeight * 0.32);
        final identityBottom = footerHeight - (hasUpcomingOuting ? 12 : 8);

        return Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: ChillGoColors.skySoft),
            ),
            Positioned(
              top: compact ? 6 : 14,
              left: 16,
              right: 16,
              bottom: identityBottom,
              child: _CrewIdentity(
                crewName: crewName,
                memberStream: memberStream,
                invitationStream: invitationStream,
                dense: compact && hasUpcomingOuting,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: footerHeight,
              child: upcomingOuting == null
                  ? KeyedSubtree(
                      key: const ValueKey('crew-card-no-upcoming-outing'),
                      child: _NoUpcomingOutingFooter(compact: compact),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('crew-card-upcoming-outing'),
                      child: _UpcomingOutingFooter(
                        outing: upcomingOuting,
                        now: outingState.observedAt,
                        compact: compact,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

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
    final avatarDiameter = dense ? 24.0 : 28.0;

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

class _NoUpcomingOutingFooter extends StatelessWidget {
  const _NoUpcomingOutingFooter({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _CreamWave()),
        Positioned(
          left: 16,
          right: compact ? 54 : 64,
          top: compact ? 16 : 22,
          bottom: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: ChillGoColors.sky,
                size: compact ? 18 : 22,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'No plans in the next 24h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: compact ? 8 : 12,
          bottom: compact ? 6 : 10,
          child: _CalendarAction(compact: compact),
        ),
      ],
    );
  }
}

class _UpcomingOutingFooter extends StatelessWidget {
  const _UpcomingOutingFooter({
    required this.outing,
    required this.now,
    required this.compact,
  });

  final Outing outing;
  final DateTime now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final countdown = _formatCountdown(outing.scheduledAt.difference(now));
    final schedule = _formatSchedule(context, outing.scheduledAt, now);

    return Semantics(
      label: 'Active outing',
      container: true,
      explicitChildNodes: true,
      child: Stack(
        children: [
          const Positioned.fill(child: _CreamWave()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                label: 'Starts in $countdown',
                child: _CountdownBadge(countdown: countdown, compact: compact),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: compact ? 52 : 66,
            top: compact ? 40 : 52,
            bottom: compact ? 2 : 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  outing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 1 : 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        schedule,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ChillGoColors.inkMuted,
                          fontSize: compact ? 9 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(
                      Icons.location_on_rounded,
                      color: ChillGoColors.sky,
                      size: compact ? 11 : 14,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        outing.locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ChillGoColors.inkMuted,
                          fontSize: compact ? 9 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: compact ? 8 : 12,
            bottom: compact ? 6 : 10,
            child: _CalendarAction(compact: compact),
          ),
        ],
      ),
    );
  }
}

class _CreamWave extends StatelessWidget {
  const _CreamWave();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _CreamWaveClipper(),
      child: const ColoredBox(color: ChillGoColors.surface),
    );
  }
}

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

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.countdown, required this.compact});

  final String countdown;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 52.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ChillGoColors.sunshine,
        shape: BoxShape.circle,
        border: Border.all(color: ChillGoColors.surface, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33FFC83D), blurRadius: 8)],
      ),
      child: Text(
        countdown,
        style: TextStyle(
          color: ChillGoColors.ink,
          fontSize: compact ? 15 : 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarAction extends StatelessWidget {
  const _CalendarAction({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 50.0;
    final circleSize = compact ? 34.0 : 42.0;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: ChillGoColors.sunshine,
                shape: BoxShape.circle,
                border: Border.all(color: ChillGoColors.surface, width: 2),
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: compact ? 17 : 21,
                color: ChillGoColors.ink,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.arrow_outward_rounded,
                color: ChillGoColors.ink,
                size: compact ? 17 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCountdown(Duration remaining) {
  if (remaining.inMinutes < 60) {
    return '${remaining.inMinutes.clamp(1, 59)}m';
  }
  return '${remaining.inHours.clamp(1, 24)}h';
}

String _formatSchedule(
  BuildContext context,
  DateTime scheduledAt,
  DateTime now,
) {
  final localScheduledAt = scheduledAt.toLocal();
  final localNow = now.toLocal();
  final scheduledDate = DateUtils.dateOnly(localScheduledAt);
  final today = DateUtils.dateOnly(localNow);
  final dayLabel = scheduledDate == today ? 'Today' : 'Tomorrow';
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(localScheduledAt));
  return '$dayLabel · $time';
}

class _CrewMembersSummary extends StatelessWidget {
  final Stream<List<CrewMembership>> memberStream;
  final Stream<List<CrewInvitation>>? invitationStream;
  final double avatarDiameter;

  const _CrewMembersSummary({
    required this.memberStream,
    required this.invitationStream,
    required this.avatarDiameter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StreamBuilder<List<CrewMembership>>(
          stream: memberStream,
          initialData: const <CrewMembership>[],
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <CrewMembership>[];
            final acceptedMembers = members
                .where((member) => member.role == CrewRole.member)
                .toList();
            if (acceptedMembers.isEmpty) {
              return const Text(
                'No members yet',
                style: TextStyle(color: ChillGoColors.inkMuted, fontSize: 11),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MemberAvatarRow(
                  members: acceptedMembers,
                  avatarDiameter: avatarDiameter,
                ),
                const SizedBox(height: 2),
                Text(
                  acceptedMembers.length == 1
                      ? '1 member'
                      : '${acceptedMembers.length} members',
                  style: const TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        ),
        if (invitationStream != null)
          _PendingInvitesSummary(stream: invitationStream!),
      ],
    );
  }
}

class _PendingInvitesSummary extends StatelessWidget {
  final Stream<List<CrewInvitation>> stream;

  const _PendingInvitesSummary({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewInvitation>>(
      stream: stream,
      builder: (context, snapshot) {
        final invitations = snapshot.data ?? const <CrewInvitation>[];
        if (invitations.isEmpty) return const SizedBox.shrink();

        final usernames = invitations
            .map(_invitationLabel)
            .where((label) => label.isNotEmpty)
            .take(3)
            .toList();
        final overflow = invitations.length - usernames.length;
        final suffix = overflow > 0 ? ' +$overflow more' : '';

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: ChillGoColors.inkMuted,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Invited ${usernames.join(', ')}$suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _invitationLabel(CrewInvitation invitation) {
    final username = invitation.invitedUsername.trim();
    if (username.isNotEmpty) return '@$username';
    return invitation.invitedUserId.trim();
  }
}

class _MemberAvatarRow extends StatelessWidget {
  final List<CrewMembership> members;
  final double avatarDiameter;

  static const int _maxVisible = 5;

  const _MemberAvatarRow({required this.members, required this.avatarDiameter});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(_maxVisible).toList();
    final overflow = members.length - _maxVisible;
    final avatarCount = visible.length + (overflow > 0 ? 1 : 0);
    final avatarOffset = avatarDiameter * 0.72;
    final width = avatarCount <= 1
        ? avatarDiameter
        : avatarDiameter + ((avatarCount - 1) * avatarOffset);

    return SizedBox(
      width: width,
      height: avatarDiameter,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(left: i * avatarOffset, child: _buildAvatar(visible[i])),
          if (overflow > 0)
            Positioned(
              left: visible.length * avatarOffset,
              child: _buildOverflowCircle(overflow),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(CrewMembership member) {
    final hasPhoto = member.avatarUrl != null && member.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: avatarDiameter / 2,
      backgroundColor: ChillGoColors.coral,
      backgroundImage: hasPhoto ? NetworkImage(member.avatarUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildOverflowCircle(int count) {
    return CircleAvatar(
      radius: avatarDiameter / 2,
      backgroundColor: ChillGoColors.plum,
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
