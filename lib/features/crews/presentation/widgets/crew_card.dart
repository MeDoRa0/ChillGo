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
    final accent = _crewAccent(crew.name);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ChillGoColors.outline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x146D3A72),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ChillGoColors.surface.withValues(alpha: 0.78),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups,
                          color: accent.foreground,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          crew.name,
                          style: const TextStyle(
                            color: ChillGoColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CrewMembersSummary(
                    memberStream: _memberStream,
                    invitationStream: _invitationStream,
                  ),
                ],
              ),
            ),
          ),
        ),
        _OutingIndicator(stream: _outingStream),
      ],
    );
  }

  _CrewAccent _crewAccent(String crewName) {
    const accents = [
      _CrewAccent(ChillGoColors.sunshineSoft, ChillGoColors.plum),
      _CrewAccent(ChillGoColors.coralSoft, ChillGoColors.coral),
      _CrewAccent(ChillGoColors.skySoft, ChillGoColors.sky),
      _CrewAccent(ChillGoColors.leafSoft, ChillGoColors.leaf),
      _CrewAccent(ChillGoColors.lavender, ChillGoColors.plum),
    ];
    return accents[crewName.hashCode.abs() % accents.length];
  }
}

class _CrewAccent {
  const _CrewAccent(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _OutingIndicator extends StatelessWidget {
  final Stream<List<Outing>>? stream;

  const _OutingIndicator({required this.stream});

  @override
  Widget build(BuildContext context) {
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<List<Outing>>(
      stream: stream,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final hasActiveOuting = (snapshot.data ?? const <Outing>[]).any(
          (outing) => outing.isCurrentCrewPlanAt(now),
        );
        if (!hasActiveOuting) return const SizedBox.shrink();
        return Positioned(
          top: 8,
          right: 8,
          child: Semantics(
            label: 'Active outing',
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: ChillGoColors.sunshine,
                shape: BoxShape.circle,
                border: Border.all(color: ChillGoColors.surface, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x55FFC83D), blurRadius: 8),
                ],
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 14,
                color: ChillGoColors.ink,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CrewMembersSummary extends StatelessWidget {
  final Stream<List<CrewMembership>> memberStream;
  final Stream<List<CrewInvitation>>? invitationStream;

  const _CrewMembersSummary({
    required this.memberStream,
    required this.invitationStream,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: TextStyle(color: ChillGoColors.inkMuted, fontSize: 12),
              );
            }
            return Row(
              children: [
                _MemberAvatarRow(members: acceptedMembers),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    acceptedMembers.length == 1
                        ? '1 member'
                        : '${acceptedMembers.length} members',
                    style: const TextStyle(
                      color: ChillGoColors.inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

  static const int _maxVisible = 5;
  static const double _avatarDiameter = 28;
  static const double _avatarOffset = 20;

  const _MemberAvatarRow({required this.members});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(_maxVisible).toList();
    final overflow = members.length - _maxVisible;
    final avatarCount = visible.length + (overflow > 0 ? 1 : 0);
    final width = avatarCount <= 1
        ? _avatarDiameter
        : _avatarDiameter + ((avatarCount - 1) * _avatarOffset);

    return SizedBox(
      width: width,
      height: _avatarDiameter,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * _avatarOffset,
              child: _buildAvatar(visible[i]),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * _avatarOffset,
              child: _buildOverflowCircle(overflow),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(CrewMembership member) {
    final hasPhoto = member.avatarUrl != null && member.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 14,
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
      radius: 14,
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
