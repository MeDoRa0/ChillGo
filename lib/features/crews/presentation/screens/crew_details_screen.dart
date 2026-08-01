import 'package:flutter/material.dart';
import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_membership.dart';
import 'package:chillgo/features/crews/domain/entities/crew_role.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/outings/domain/entities/outing.dart';
import 'package:chillgo/features/outings/domain/entities/outing_participant.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/features/outings/presentation/widgets/interactive_outing_card.dart';
import 'package:chillgo/features/voting/domain/repositories/agreement_repository.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/core/presentation/widgets/app_back_button.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/shimmer_loading.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';
import 'package:go_router/go_router.dart';

class CrewDetailsScreen extends StatelessWidget {
  final String crewId;

  const CrewDetailsScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context) {
    final repository = sl<CrewRepository>();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Crew details'),
      ),
      body: SunshineBackground(
        child: ResponsiveContent(
          maxWidth: 960,
          child: StreamBuilder<Crew?>(
            stream: repository.streamCrew(crewId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const ShimmerListPlaceholder(itemCount: 3);
              }

              if (snapshot.hasError) {
                return _CenteredMessage(message: snapshot.error.toString());
              }

              final crew = snapshot.data;
              if (crew == null) {
                return const _CenteredMessage(message: 'Crew not found.');
              }
              final currentUserId =
                  sl<AuthRepository>().currentCredentials?.uid;
              final canInviteMembers = currentUserId == crew.ownerId;

              return _CrewDetailsContent(
                crew: crew,
                repository: repository,
                canInviteMembers: canInviteMembers,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CrewDetailsContent extends StatelessWidget {
  const _CrewDetailsContent({
    required this.crew,
    required this.repository,
    required this.canInviteMembers,
  });

  final Crew crew;
  final CrewRepository repository;
  final bool canInviteMembers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= 760 ? _wideLayout() : _compactLayout();
      },
    );
  }

  Widget _compactLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_planPanel(), const SizedBox(height: 24), _membersPanel()],
    );
  }

  Widget _wideLayout() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _planPanel()),
            const SizedBox(width: 24),
            Expanded(flex: 4, child: _membersPanel()),
          ],
        ),
      ],
    );
  }

  Widget _planPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CrewHeader(crew: crew),
        const SizedBox(height: 16),
        _CreateOutingButton(crewId: crew.id),
        const SizedBox(height: 20),
        _CrewOutings(crewId: crew.id),
      ],
    );
  }

  Widget _membersPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MembersSectionHeader(
          crewId: crew.id,
          repository: repository,
          canInviteMembers: canInviteMembers,
        ),
        const SizedBox(height: 12),
        _MembersList(repository: repository, crewId: crew.id),
      ],
    );
  }
}

class _MembersSectionHeader extends StatelessWidget {
  final String crewId;
  final CrewRepository repository;
  final bool canInviteMembers;

  const _MembersSectionHeader({
    required this.crewId,
    required this.repository,
    required this.canInviteMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Members',
            style: TextStyle(
              color: ChillGoColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (canInviteMembers)
          TextButton.icon(
            key: const Key('add-crew-member-button'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) =>
                  _InviteMemberDialog(crewId: crewId, repository: repository),
            ),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Add member'),
            style: TextButton.styleFrom(foregroundColor: ChillGoColors.coral),
          ),
      ],
    );
  }
}

class _InviteMemberDialog extends StatefulWidget {
  final String crewId;
  final CrewRepository repository;

  const _InviteMemberDialog({required this.crewId, required this.repository});

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSearching = false;
  int _searchGeneration = 0;
  String? _matchingUsername;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _searchUsername(String input) async {
    final username = input.trim().toLowerCase();
    final generation = ++_searchGeneration;

    setState(() {
      _matchingUsername = null;
      _errorMessage = null;
      _isSearching = username.length >= 3;
    });
    if (username.length < 3) return;

    try {
      final exists = await widget.repository.usernameExists(username);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _isSearching = false;
        _matchingUsername = exists ? username : null;
        _errorMessage = exists ? null : 'No account found with this username.';
      });
    } on Exception {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _isSearching = false;
        _errorMessage = 'Could not search for this username. Try again.';
      });
    }
  }

  Future<void> _sendInvitation() async {
    final username = _matchingUsername!;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.inviteUser(widget.crewId, username);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invitation sent to @$username.')));
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Could not send the invitation. Check the username and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ChillGoColors.surface,
      title: const Text('Add a member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('invite-member-username-field'),
            controller: _usernameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: _searchUsername,
            onSubmitted: (_) {
              if (!_isSubmitting && _matchingUsername != null) {
                _sendInvitation();
              }
            },
            style: const TextStyle(color: ChillGoColors.ink),
            decoration: InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              errorText: _errorMessage,
              labelStyle: const TextStyle(color: ChillGoColors.inkMuted),
              prefixStyle: const TextStyle(color: ChillGoColors.inkMuted),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: ShimmerBox(
                        width: 18,
                        height: 18,
                        shape: BoxShape.circle,
                        semanticLabel: 'Searching usernames',
                      ),
                    )
                  : null,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: ChillGoColors.outline),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: ChillGoColors.coral),
              ),
            ),
          ),
          if (_matchingUsername != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('matching-member-account'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChillGoColors.canvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ChillGoColors.coral),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: ChillGoColors.coral),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '@$_matchingUsername',
                      style: const TextStyle(color: ChillGoColors.ink),
                    ),
                  ),
                  const Icon(Icons.check_circle, color: ChillGoColors.leaf),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('send-member-invite-button'),
          onPressed: _isSubmitting || _matchingUsername == null
              ? null
              : _sendInvitation,
          style: FilledButton.styleFrom(
            backgroundColor: ChillGoColors.coral,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const ShimmerBox(
                  width: 18,
                  height: 18,
                  shape: BoxShape.circle,
                  semanticLabel: 'Sending invitation',
                )
              : const Text('Send invite'),
        ),
      ],
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
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ChillGoColors.coral.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups,
              color: ChillGoColors.coral,
              size: 28,
            ),
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
                    color: ChillGoColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${_formatCreatedDate(crew.createdAt)}',
                  style: const TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: 12,
                  ),
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
          backgroundColor: ChillGoColors.coral,
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
    return StreamBuilder<List<Outing>>(
      stream: outingRepository.streamCrewOutings(crewId),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final outings = (snapshot.data ?? const <Outing>[])
            .where((outing) => outing.isCurrentCrewPlanAt(now))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Crew plans',
                    style: TextStyle(
                      color: ChillGoColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/crews/$crewId/outings'),
                  child: const Text('See all'),
                ),
              ],
            ),
            if (snapshot.hasError)
              const Text(
                'Couldn’t load plans right now.',
                style: TextStyle(color: ChillGoColors.inkMuted),
              )
            else if (outings.isEmpty)
              const _InlineMessage(message: 'No plans yet — start the vibe.')
            else
              for (final outing in outings.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InteractiveOutingCard(
                    outing: outing,
                    outingRepository: outingRepository,
                    currentUserId: sl<AuthRepository>().currentCredentials?.uid,
                    agreementRepository: sl.isRegistered<AgreementRepository>()
                        ? sl<AgreementRepository>()
                        : null,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class OutingCard extends StatelessWidget {
  final Outing outing;
  final OutingRepository repository;
  final String? currentUserId;

  const OutingCard({
    super.key,
    required this.outing,
    required this.repository,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OutingDetail?>(
      stream: repository.streamOutingDetail(outing.id),
      builder: (context, snapshot) {
        final participants =
            snapshot.data?.participants ?? const <OutingParticipant>[];
        final hasAccepted =
            currentUserId != null &&
            participants.any((member) => member.userId == currentUserId);
        return InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChillGoColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ChillGoColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        outing.locationText,
                        style: const TextStyle(
                          color: ChillGoColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (outing.createdByUserId == currentUserId)
                      IconButton(
                        tooltip: 'Delete outing',
                        onPressed: () => _confirmDeletion(context),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: ChillGoColors.inkMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _scheduleLabel(outing.scheduledAt),
                  style: const TextStyle(
                    color: ChillGoColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AcceptedAvatars(participants: participants),
                    ),
                    if (currentUserId != null && !hasAccepted)
                      FilledButton(
                        onPressed: () =>
                            repository.acceptOuting(outingId: outing.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: ChillGoColors.coral,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('I’m in'),
                      )
                    else if (hasAccepted)
                      const Text(
                        'You’re in ✨',
                        style: TextStyle(color: ChillGoColors.inkMuted),
                      ),
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
        content: const Text(
          'This permanently removes the outing for every crew member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await repository.deleteOuting(outingId: outing.id);
    }
  }

  String _scheduleLabel(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.month}/${local.day} • $hour:${local.minute.toString().padLeft(2, '0')} $period';
  }
}

class AcceptedAvatars extends StatelessWidget {
  final List<OutingParticipant> participants;

  const AcceptedAvatars({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Text(
        'Be the first one in',
        style: TextStyle(color: ChillGoColors.inkMuted),
      );
    }
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
                backgroundColor: ChillGoColors.coralSoft,
                backgroundImage: shown[index].avatarUrl?.isNotEmpty == true
                    ? NetworkImage(shown[index].avatarUrl!)
                    : null,
                child: shown[index].avatarUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        shown[index].displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: ChillGoColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          if (participants.length > shown.length)
            Positioned(
              left: shown.length * 22.0,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: ChillGoColors.plum,
                child: Text(
                  '+${participants.length - shown.length}',
                  style: const TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
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

        return _MemberAvatarStrip(members: sortedMembers);
      },
    );
  }
}

class _MemberAvatarStrip extends StatelessWidget {
  final List<CrewMembership> members;

  static const _avatarDiameter = 60.0;
  static const _avatarSpacing = 8.0;
  static const _allMembersControlWidth = 128.0;
  static const _overflowControlSpacing = 12.0;

  const _MemberAvatarStrip({required this.members});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final membersFitWithoutControl =
            ((constraints.maxWidth + _avatarSpacing) /
                    (_avatarDiameter + _avatarSpacing))
                .floor();
        final allMembersFit = members.length <= membersFitWithoutControl;
        final availableAvatarWidth =
            constraints.maxWidth -
            _allMembersControlWidth -
            _overflowControlSpacing;
        final visibleMemberCount = allMembersFit
            ? members.length
            : availableAvatarWidth < _avatarDiameter
            ? 0
            : ((availableAvatarWidth + _avatarSpacing) /
                      (_avatarDiameter + _avatarSpacing))
                  .floor()
                  .clamp(0, members.length);
        final visibleMembers = members.take(visibleMemberCount).toList();

        return Row(
          children: [
            for (var index = 0; index < visibleMembers.length; index++) ...[
              _MemberAvatar(member: visibleMembers[index]),
              if (index < visibleMembers.length - 1)
                const SizedBox(width: _avatarSpacing),
            ],
            if (!allMembersFit) ...[
              if (visibleMembers.isNotEmpty)
                const SizedBox(width: _overflowControlSpacing),
              SizedBox(
                width: _allMembersControlWidth,
                child: TextButton.icon(
                  key: const Key('see-all-members-button'),
                  onPressed: () => _showAllMembers(context, members),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('See all members'),
                  style: TextButton.styleFrom(
                    foregroundColor: ChillGoColors.coral,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

void _showAllMembers(BuildContext context, List<CrewMembership> members) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: ChillGoColors.surface,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Members',
                style: TextStyle(
                  color: ChillGoColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: members.length,
                itemBuilder: (context, index) =>
                    _MemberTile(member: members[index]),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MemberAvatar extends StatelessWidget {
  final CrewMembership member;

  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final label = member.displayName.trim().isNotEmpty
        ? member.displayName.trim()
        : member.username.trim().isNotEmpty
        ? '@${member.username.trim()}'
        : 'Member';
    final hasPhoto = member.avatarUrl?.isNotEmpty == true;

    return Semantics(
      label: label,
      child: CircleAvatar(
        key: Key('crew-member-avatar-${member.userId}'),
        radius: _MemberAvatarStrip._avatarDiameter / 2,
        backgroundColor: ChillGoColors.coral,
        backgroundImage: hasPhoto ? NetworkImage(member.avatarUrl!) : null,
        child: hasPhoto
            ? null
            : Text(
                label[0].toUpperCase(),
                style: const TextStyle(
                  color: ChillGoColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
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
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ChillGoColors.coral,
            backgroundImage: member.avatarUrl?.isNotEmpty == true
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl?.isNotEmpty == true
                ? null
                : Text(
                    title[0].toUpperCase(),
                    style: const TextStyle(
                      color: ChillGoColors.ink,
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
                    color: ChillGoColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: 12,
                  ),
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
        color: isOwner ? ChillGoColors.sunshineSoft : ChillGoColors.leafSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOwner ? 'Owner' : 'Member',
        style: TextStyle(
          color: isOwner ? ChillGoColors.ink : ChillGoColors.leaf,
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
          style: const TextStyle(color: ChillGoColors.inkMuted),
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
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: Text(
        message,
        style: const TextStyle(color: ChillGoColors.inkMuted),
      ),
    );
  }
}
