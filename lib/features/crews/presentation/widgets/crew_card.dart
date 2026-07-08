import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';

class CrewCard extends StatelessWidget {
  final Crew crew;

  const CrewCard({super.key, required this.crew});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            _MemberAvatars(crewId: crew.id),
          ],
        ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  final String crewId;

  const _MemberAvatars({required this.crewId});

  @override
  Widget build(BuildContext context) {
    final repository = sl<CrewRepository>();
    return StreamBuilder<List<CrewMembership>>(
      stream: repository.streamMembers(crewId),
      builder: (context, snapshot) {
        final members = snapshot.data;
        if (members == null || members.isEmpty) {
          return const SizedBox.shrink();
        }
        return _MemberAvatarRow(members: members);
      },
    );
  }
}

class _MemberAvatarRow extends StatelessWidget {
  final List<CrewMembership> members;

  static const int _maxVisible = 5;

  const _MemberAvatarRow({required this.members});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(_maxVisible).toList();
    final overflow = members.length - _maxVisible;

    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 20.0,
              child: _buildAvatar(visible[i]),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * 20.0,
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
