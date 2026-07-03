import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/authentication/domain/repositories/auth_repository.dart';
import '../blocs/crew_detail/crew_detail_cubit.dart';
import '../widgets/crew_member_list_item.dart';
import '../widgets/invite_member_dialog.dart';
import '../../domain/entities/crew_membership.dart';
import '../../domain/entities/crew_invitation.dart';
import '../../domain/entities/crew_role.dart';

class CrewDetailsScreen extends StatelessWidget {
  final String crewId;
  const CrewDetailsScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CrewDetailCubit>()..loadCrew(crewId),
      child: _CrewDetailsView(crewId: crewId),
    );
  }
}

class _CrewDetailsView extends StatelessWidget {
  final String crewId;
  const _CrewDetailsView({required this.crewId});

  @override
  Widget build(BuildContext context) {
    final currentUid = sl<AuthRepository>().currentCredentials?.uid ?? '';

    return BlocConsumer<CrewDetailCubit, CrewDetailState>(
      listener: (context, state) {
        if (state is CrewDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crew action completed.')),
          );
          context.go('/crews');
        } else if (state is CrewDetailActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state is CrewDetailLoaded) {
          // Re-emit loaded after action succeeds — snackbar handled separately
        }
      },
      builder: (context, state) {
        if (state is CrewDetailLoading || state is CrewDetailInitial) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }

        if (state is CrewDetailError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        if (state is! CrewDetailLoaded) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }

        final crew = state.crew;
        final members = state.members;
        final pendingInvitations = state.pendingInvitations;
        final isOwner = crew.ownerId == currentUid;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0F1A),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              crew.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  tooltip: 'Edit crew name',
                  onPressed: () => _showEditNameDialog(context, crew.name),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Delete crew',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Members Section ---
              _SectionHeader(
                title: 'Members (${members.length})',
                trailing: isOwner
                    ? TextButton.icon(
                        onPressed: () => _showInviteDialog(context),
                        icon: const Icon(
                          Icons.person_add,
                          size: 18,
                          color: Color(0xFF6366F1),
                        ),
                        label: const Text(
                          'Invite',
                          style: TextStyle(color: Color(0xFF6366F1)),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              _buildMembersCard(
                context,
                members,
                crew.ownerId,
                currentUid,
                isOwner,
              ),

              // --- Pending Invitations Section (owner only) ---
              if (isOwner && pendingInvitations.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Pending Invitations (${pendingInvitations.length})',
                ),
                const SizedBox(height: 8),
                _buildPendingInvitationsCard(context, pendingInvitations),
              ],

              // --- Leave crew (member only) ---
              if (!isOwner) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _confirmLeave(context),
                  icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                  label: const Text(
                    'Leave Crew',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersCard(
    BuildContext context,
    List<CrewMembership> members,
    String ownerId,
    String currentUid,
    bool isOwner,
  ) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E4F)),
        ),
        child: Text(
          'No members yet.',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E4F)),
      ),
      child: Column(
        children: members.map((m) {
          return CrewMemberListItem(
            membership: m,
            isOwner: m.role == CrewRole.owner,
            canRemove: isOwner && m.role != CrewRole.owner,
            onRemove: isOwner && m.role != CrewRole.owner
                ? () => _confirmRemoveMember(context, m.userId, m.displayName)
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingInvitationsCard(
    BuildContext context,
    List<CrewInvitation> invitations,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E4F)),
      ),
      child: Column(
        children: invitations.map((inv) {
          // Prefer the captured `@username`; fall back to a short prefix of
          // the UID for older invitation records that pre-date this field.
          final preview = inv.invitedUserId.substring(
            0,
            inv.invitedUserId.length.clamp(0, 6),
          );
          final displayHandle = inv.invitedUsername.isNotEmpty
              ? '@${inv.invitedUsername}'
              : '@$preview…';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              child: const Icon(
                Icons.hourglass_empty,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            title: Text(
              displayHandle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Pending',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              tooltip: 'Revoke invitation',
              onPressed: () =>
                  context.read<CrewDetailCubit>().revokeInvitation(inv.id),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CrewDetailCubit>(),
        child: const InviteMemberDialog(),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) async {
    final cubit = context.read<CrewDetailCubit>();
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Crew Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 50,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F0F1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'Name must be at least 3 characters.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.of(dialogContext).pop();
                        cubit.updateCrewName(controller.text.trim());
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  void _confirmDelete(BuildContext context) {
    final cubit = context.read<CrewDetailCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text('Delete Crew', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete this crew? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.deleteCrew();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    final cubit = context.read<CrewDetailCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text('Leave Crew', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this crew?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.leaveCrew();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(
    BuildContext context,
    String userId,
    String displayName,
  ) {
    final cubit = context.read<CrewDetailCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text(
          'Remove Member',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove $displayName from this crew?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.removeMember(userId);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
