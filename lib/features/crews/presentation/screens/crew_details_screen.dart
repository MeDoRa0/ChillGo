import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';

class CrewDetailsScreen extends StatelessWidget {
  final String crewId;

  const CrewDetailsScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context) {
    final repository = sl<CrewRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Crew Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<Crew?>(
        stream: repository.streamCrew(crewId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            );
          }

          if (snapshot.hasError) {
            return _CenteredMessage(message: snapshot.error.toString());
          }

          final crew = snapshot.data;
          if (crew == null) {
            return const _CenteredMessage(message: 'Crew not found.');
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CrewHeader(crew: crew),
              const SizedBox(height: 16),
              _CreateOutingButton(crewName: crew.name),
              const SizedBox(height: 24),
              const Text(
                'Members',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _MembersList(repository: repository, crewId: crew.id),
            ],
          );
        },
      ),
    );
  }
}

class _CrewHeader extends StatelessWidget {
  final Crew crew;

  const _CrewHeader({required this.crew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E4F)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups, color: Color(0xFF6366F1), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crew.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${_formatCreatedDate(crew.createdAt)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreatedDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.year}-${_twoDigits(localDate.month)}-${_twoDigits(localDate.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _CreateOutingButton extends StatelessWidget {
  final String crewName;

  const _CreateOutingButton({required this.crewName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Create outing for $crewName')),
          );
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Create outing'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  final CrewRepository repository;
  final String crewId;

  const _MembersList({required this.repository, required this.crewId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewMembership>>(
      stream: repository.streamMembers(crewId),
      initialData: const <CrewMembership>[],
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InlineMessage(message: snapshot.error.toString());
        }

        final members = snapshot.data ?? const <CrewMembership>[];
        if (members.isEmpty) {
          return const _InlineMessage(message: 'No members yet.');
        }

        final sortedMembers = [...members]
          ..sort(
            (a, b) =>
                a.role == b.role ? 0 : (a.role == CrewRole.owner ? -1 : 1),
          );

        return Column(
          children: [
            for (var index = 0; index < sortedMembers.length; index++) ...[
              _MemberTile(member: sortedMembers[index]),
              if (index < sortedMembers.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CrewMembership member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final title = member.displayName.trim().isNotEmpty
        ? member.displayName.trim()
        : 'Member';
    final subtitle = member.username.trim().isNotEmpty
        ? '@${member.username.trim()}'
        : member.userId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E4F)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6366F1),
            backgroundImage: member.avatarUrl?.isNotEmpty == true
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl?.isNotEmpty == true
                ? null
                : Text(
                    title[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          _RoleBadge(role: member.role),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final CrewRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == CrewRole.owner;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOwner
            ? const Color(0xFFF59E0B).withValues(alpha: 0.16)
            : const Color(0xFF10B981).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOwner ? 'Owner' : 'Member',
        style: TextStyle(
          color: isOwner ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final String message;

  const _CenteredMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;

  const _InlineMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E4F)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }
}
