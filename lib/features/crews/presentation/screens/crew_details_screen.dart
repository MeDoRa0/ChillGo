import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/core/presentation/widgets/app_back_button.dart';
import 'package:go_router/go_router.dart';

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
        leading: const AppBackButton(),
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
              _CreateOutingButton(crewId: crew.id),
              const SizedBox(height: 20),
              _CrewOutings(crewId: crew.id),
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
  final String crewId;

  const _CreateOutingButton({required this.crewId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          context.go('/crews/$crewId/outings/new');
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

class _CrewOutings extends StatelessWidget {
  final String crewId;

  const _CrewOutings({required this.crewId});

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<OutingRepository>()) return const SizedBox.shrink();
    final outingRepository = sl<OutingRepository>();
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentCredentials?.uid
        : null;
    return StreamBuilder<List<Outing>>(
      stream: outingRepository.streamCrewOutings(crewId),
      builder: (context, snapshot) {
        final outings = snapshot.data ?? const <Outing>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Crew plans', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => context.go('/crews/$crewId/outings'),
                  child: const Text('See all'),
                ),
              ],
            ),
            if (snapshot.hasError)
              const Text('Couldn’t load plans right now.', style: TextStyle(color: Colors.white70))
            else if (outings.isEmpty)
              const _InlineMessage(message: 'No plans yet — start the vibe.' )
            else
              for (final outing in outings.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OutingCard(
                    outing: outing,
                    repository: outingRepository,
                    currentUserId: currentUserId,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _OutingCard extends StatelessWidget {
  final Outing outing;
  final OutingRepository repository;
  final String? currentUserId;

  const _OutingCard({required this.outing, required this.repository, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingDetail?>(
      stream: repository.streamOutingDetail(outing.id),
      builder: (context, snapshot) {
        final participants = snapshot.data?.participants ?? const <OutingParticipant>[];
        final hasAccepted = currentUserId != null && participants.any((member) => member.userId == currentUserId);
        return InkWell(
          onTap: () => context.go('/outings/${outing.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B3560)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        outing.locationText,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (outing.createdByUserId == currentUserId)
                      IconButton(
                        tooltip: 'Delete outing',
                        onPressed: () => _confirmDeletion(context),
                        icon: const Icon(Icons.delete_outline, color: Colors.white70),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_scheduleLabel(outing.scheduledAt), style: const TextStyle(color: Color(0xFFB8A7FF), fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _AcceptedAvatars(participants: participants)),
                    if (currentUserId != null && !hasAccepted)
                      FilledButton(
                        onPressed: () => repository.acceptOuting(outingId: outing.id),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C5CFC), foregroundColor: Colors.white),
                        child: const Text('I’m in'),
                      )
                    else if (hasAccepted)
                      const Text('You’re in ✨', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletion(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete outing?'),
        content: const Text('This permanently removes the outing for every crew member.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete == true) await repository.deleteOuting(outingId: outing.id);
  }

  String _scheduleLabel(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.month}/${local.day} • $hour:${local.minute.toString().padLeft(2, '0')} $period';
  }
}

class _AcceptedAvatars extends StatelessWidget {
  final List<OutingParticipant> participants;

  const _AcceptedAvatars({required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const Text('Be the first one in', style: TextStyle(color: Colors.white54));
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
                backgroundColor: const Color(0xFFB8A7FF),
                backgroundImage: shown[index].avatarUrl?.isNotEmpty == true ? NetworkImage(shown[index].avatarUrl!) : null,
                child: shown[index].avatarUrl?.isNotEmpty == true ? null : Text(shown[index].displayName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF161324), fontWeight: FontWeight.bold)),
              ),
            ),
          if (participants.length > shown.length)
            Positioned(left: shown.length * 22.0, child: CircleAvatar(radius: 17, backgroundColor: const Color(0xFF3B3560), child: Text('+${participants.length - shown.length}', style: const TextStyle(color: Colors.white, fontSize: 11)))),
        ],
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
