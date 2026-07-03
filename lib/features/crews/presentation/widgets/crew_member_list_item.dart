import 'package:flutter/material.dart';
import '../../domain/entities/crew_membership.dart';
import '../../domain/entities/crew_role.dart';

class CrewMemberListItem extends StatelessWidget {
  final CrewMembership membership;
  final bool isOwner;
  final bool canRemove;
  final VoidCallback? onRemove;

  const CrewMemberListItem({
    super.key,
    required this.membership,
    required this.isOwner,
    this.canRemove = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUserMember = membership.role == CrewRole.member;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: membership.avatarUrl != null
            ? NetworkImage(membership.avatarUrl!)
            : null,
        backgroundColor: const Color(0xFF6366F1),
        child: membership.avatarUrl == null
            ? Text(
                (membership.displayName.isNotEmpty
                    ? membership.displayName[0]
                    : '?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        membership.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '@${membership.username}',
        style: TextStyle(color: Colors.grey[400], fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: membership.role == CrewRole.owner
                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              membership.role == CrewRole.owner ? 'Owner' : 'Member',
              style: TextStyle(
                color: membership.role == CrewRole.owner
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (canRemove && isCurrentUserMember && onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: onRemove,
              tooltip: 'Remove member',
            ),
          ],
        ],
      ),
    );
  }
}
