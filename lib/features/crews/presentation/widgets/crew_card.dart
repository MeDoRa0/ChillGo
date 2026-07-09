import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';

class CrewCard extends StatelessWidget {
  final Crew crew;
  final VoidCallback? onTap;

  const CrewCard({super.key, required this.crew, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentUid = sl<AuthRepository>().currentCredentials?.uid;
    final canViewPendingInvites =
        currentUid != null && crew.ownerId == currentUid;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E2E4F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      crew.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CrewMembersSummary(
                crewId: crew.id,
                showPendingInvites: canViewPendingInvites,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrewMembersSummary extends StatelessWidget {
  final String crewId;
  final bool showPendingInvites;

  const _CrewMembersSummary({
    required this.crewId,
    required this.showPendingInvites,
  });

  @override
  Widget build(BuildContext context) {
    final repository = sl<CrewRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<CrewMembership>>(
          stream: repository.streamMembers(crewId),
          initialData: const <CrewMembership>[],
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <CrewMembership>[];
            final acceptedMembers = members
                .where((member) => member.role == CrewRole.member)
                .toList();
            if (acceptedMembers.isEmpty) {
              return const Text(
                'No members yet',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              );
            }
            return Row(
              children: [
                _MemberAvatarRow(members: acceptedMembers),
                const SizedBox(width: 10),
                Expanded(child: _MemberNames(members: acceptedMembers)),
              ],
            );
          },
        ),
        if (showPendingInvites)
          _PendingInvitesSummary(repository: repository, crewId: crewId),
      ],
    );
  }
}

class _PendingInvitesSummary extends StatelessWidget {
  final CrewRepository repository;
  final String crewId;

  const _PendingInvitesSummary({
    required this.repository,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewInvitation>>(
      stream: repository.streamPendingInvitationsForCrew(crewId),
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
              const Icon(Icons.schedule, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Invited ${usernames.join(', ')}$suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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

class _MemberNames extends StatelessWidget {
  final List<CrewMembership> members;

  const _MemberNames({required this.members});

  @override
  Widget build(BuildContext context) {
    final visibleNames = members
        .take(3)
        .map(_memberLabel)
        .where((name) => name.isNotEmpty)
        .toList();
    final overflow = members.length - visibleNames.length;
    final suffix = overflow > 0 ? ' +$overflow more' : '';
    final countLabel = members.length == 1
        ? '1 member'
        : '${members.length} members';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          countLabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${visibleNames.join(', ')}$suffix',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  String _memberLabel(CrewMembership member) {
    if (member.displayName.trim().isNotEmpty) {
      return member.displayName.trim();
    }
    if (member.username.trim().isNotEmpty) {
      return '@${member.username.trim()}';
    }
    return 'Member';
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
      backgroundColor: const Color(0xFF6366F1),
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
      backgroundColor: const Color(0xFF2E2E4F),
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
