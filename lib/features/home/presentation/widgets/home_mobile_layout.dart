import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/domain/entities/crew_invitation.dart';
import 'package:chillgo/features/crews/domain/repositories/crew_repository.dart';
import 'package:chillgo/features/notifications/domain/entities/outing_review_notification.dart';
import 'package:chillgo/features/notifications/domain/repositories/outing_review_notification_repository.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/crews/presentation/widgets/crew_card.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/shimmer_loading.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';
import 'sign_out_icon_button.dart';
import 'user_identity_summary.dart';

class HomeMobileLayout extends StatelessWidget {
  final String? displayName;
  final String? username;
  final OutingReviewNotificationRepository? outingNotificationRepository;

  const HomeMobileLayout({
    super.key,
    this.displayName,
    this.username,
    this.outingNotificationRepository,
  });

  @override
  Widget build(BuildContext context) {
    final crewRepository = context.read<CrewsListCubit>().crewRepository;

    return Scaffold(
      body: SunshineBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: ChillGoColors.canvas.withValues(alpha: 0.96),
              foregroundColor: ChillGoColors.ink,
              expandedHeight: 152,
              floating: false,
              pinned: true,
              actions: [
                _InvitationNotificationButton(
                  repository: crewRepository,
                  outingNotificationRepository: outingNotificationRepository,
                ),
                const SignOutIconButton(),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'ChillGo',
                  style: TextStyle(
                    color: ChillGoColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                background: const _SunshineHeader(),
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 20,
                  bottom: 16,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ResponsiveContent(
                includeSafeArea: false,
                maxWidth: 1080,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserIdentitySummary(
                        displayName: displayName,
                        username: username,
                      ),
                      const SizedBox(height: 18),
                      const _WelcomeCard(),
                      const SizedBox(height: 28),
                      _buildYourCrewsSection(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourCrewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Crews',
                style: TextStyle(
                  color: ChillGoColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showCreateCrewDialog(context),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Create Crew'),
              style: FilledButton.styleFrom(
                backgroundColor: ChillGoColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocConsumer<CrewsListCubit, CrewsListState>(
          listener: (context, state) {
            if (state is CrewCreateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: ChillGoColors.danger,
                ),
              );
            }
            if (state is CrewCreated &&
                state.failedInviteUsernames.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _inviteFailureMessage(state.failedInviteUsernames),
                  ),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CrewsListLoading) {
              return const ShimmerListSectionPlaceholder(
                itemCount: 2,
                padding: EdgeInsets.zero,
              );
            }

            final crews = switch (state) {
              CrewsListLoaded(:final crews) => crews,
              CrewCreating(:final crews) => crews,
              CrewCreated(:final crews) => crews,
              _ => <Crew>[],
            };

            if (crews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ChillGoColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ChillGoColors.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ChillGoColors.skySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: ChillGoColors.sky,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No crews yet',
                            style: TextStyle(
                              color: ChillGoColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a crew to start coordinating with friends.',
                            style: TextStyle(
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

            return ResponsiveGrid(
              children: [
                for (final crew in crews)
                  CrewCard(
                    crew: crew,
                    onTap: () => context.push('/crews/${crew.id}'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showCreateCrewDialog(BuildContext context) async {
    final cubit = context.read<CrewsListCubit>();

    await showDialog<void>(
      context: context,
      builder: (_) =>
          _CreateCrewDialog(cubit: cubit, currentUsername: username),
    );
  }

  String _inviteFailureMessage(List<String> failedInviteUsernames) {
    final failedLabels = failedInviteUsernames.map((username) => '@$username');
    return 'Crew created, but invites failed for ${failedLabels.join(', ')}.';
  }
}

class _InvitationNotificationButton extends StatelessWidget {
  final CrewRepository repository;
  final OutingReviewNotificationRepository? outingNotificationRepository;

  const _InvitationNotificationButton({
    required this.repository,
    required this.outingNotificationRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CrewInvitation>>(
      stream: repository.streamReceivedInvitations(),
      builder: (context, snapshot) {
        final hasCrewInvitations = snapshot.data?.isNotEmpty ?? false;
        final outingRepository = outingNotificationRepository;
        if (outingRepository == null) {
          return _NotificationBell(hasUnread: hasCrewInvitations);
        }
        return StreamBuilder<List<OutingReviewNotification>>(
          stream: outingRepository.watchNotifications(),
          builder: (context, outingSnapshot) {
            final hasUnreadOutings = (outingSnapshot.data ?? const []).any(
              (notification) => !notification.isRead,
            );
            return _NotificationBell(
              hasUnread: hasCrewInvitations || hasUnreadOutings,
            );
          },
        );
      },
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final bool hasUnread;

  const _NotificationBell({required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('invitations-button'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            hasUnread ? Icons.notifications_active : Icons.notifications,
            color: ChillGoColors.ink,
          ),
          if (hasUnread)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                key: const Key('unread-invitations-badge'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ChillGoColors.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: ChillGoColors.canvas, width: 2),
                ),
              ),
            ),
        ],
      ),
      tooltip: hasUnread ? 'New notifications' : 'Notifications',
      onPressed: () => context.push('/invitations'),
    );
  }
}

class _CreateCrewDialog extends StatefulWidget {
  final CrewsListCubit cubit;
  final String? currentUsername;

  const _CreateCrewDialog({required this.cubit, required this.currentUsername});

  @override
  State<_CreateCrewDialog> createState() => _CreateCrewDialogState();
}

class _CreateCrewDialogState extends State<_CreateCrewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _crewNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final List<String> _selectedUsernames = [];
  String? _matchingUsername;
  String? _memberError;
  bool _isSearching = false;
  bool _isSubmitting = false;
  int _searchGeneration = 0;

  @override
  void dispose() {
    _crewNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _searchUsername(String value) async {
    final normalized = value.trim().toLowerCase();
    final generation = ++_searchGeneration;

    setState(() {
      _matchingUsername = null;
      _memberError = null;
      _isSearching = normalized.length >= 3;
    });

    if (normalized.length < 3) {
      setState(() => _isSearching = false);
      return;
    }

    if (normalized == widget.currentUsername?.trim().toLowerCase()) {
      setState(() {
        _isSearching = false;
        _memberError = 'You are already the crew owner.';
      });
      return;
    }

    if (_selectedUsernames.contains(normalized)) {
      setState(() {
        _isSearching = false;
        _memberError = 'This member is already added.';
      });
      return;
    }

    late final bool exists;
    try {
      exists = await widget.cubit.usernameExists(normalized);
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _isSearching = false;
        // Username search is advisory; keep the dialog open for retry.
        _memberError = 'Could not search usernames right now.';
      });
      return;
    }

    if (!mounted || generation != _searchGeneration) return;

    setState(() {
      _isSearching = false;
      _matchingUsername = exists ? normalized : null;
      _memberError = exists ? null : 'No user found with that username.';
    });
  }

  void _addMatchingUsername() {
    final username = _matchingUsername;
    if (username == null) return;
    setState(() {
      _selectedUsernames.add(username);
      _matchingUsername = null;
      _memberError = null;
      _usernameController.clear();
    });
  }

  void _createCrew() {
    if (_isSubmitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);
    Navigator.of(context).pop();
    widget.cubit.createCrewWithInvites(
      _crewNameController.text.trim(),
      List<String>.unmodifiable(_selectedUsernames),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ChillGoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a Crew',
                  style: TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _crewNameController,
                  autofocus: true,
                  style: const TextStyle(color: ChillGoColors.ink),
                  maxLength: 50,
                  decoration: _inputDecoration('e.g. Weekend Hikers'),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Name must be at least 3 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: ChillGoColors.ink),
                  decoration: _inputDecoration('Friend username').copyWith(
                    prefixText: '@',
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
                  ),
                  onChanged: _searchUsername,
                ),
                if (_matchingUsername != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _addMatchingUsername,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ChillGoColors.canvas,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ChillGoColors.coral),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_add_alt_1,
                            color: ChillGoColors.coral,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '@$_matchingUsername',
                              style: const TextStyle(color: ChillGoColors.ink),
                            ),
                          ),
                          const Icon(Icons.add, color: ChillGoColors.inkMuted),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_memberError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _memberError!,
                    style: const TextStyle(color: ChillGoColors.danger),
                  ),
                ],
                if (_selectedUsernames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final username in _selectedUsernames)
                        InputChip(
                          label: Text('@$username'),
                          onDeleted: () {
                            setState(() {
                              _selectedUsernames.remove(username);
                            });
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: const TextStyle(color: ChillGoColors.inkMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _createCrew,
                      style: FilledButton.styleFrom(
                        backgroundColor: ChillGoColors.coral,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: ChillGoColors.inkMuted),
      filled: true,
      fillColor: ChillGoColors.canvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ChillGoColors.outline),
      ),
      counterStyle: const TextStyle(color: ChillGoColors.inkMuted),
    );
  }
}

class _SunshineHeader extends StatelessWidget {
  const _SunshineHeader();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: ChillGoColors.sunshineSoft),
        Positioned(
          right: 24,
          bottom: 16,
          child: Transform.rotate(
            angle: -0.12,
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: ChillGoColors.sunshine,
              size: 62,
            ),
          ),
        ),
        const Positioned(
          right: 96,
          top: 28,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: ChillGoColors.coral,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ChillGoColors.coralSoft,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(28),
        ),
        border: Border.all(color: ChillGoColors.coral.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A6D3A72),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good plans. Great stories.',
                  style: TextStyle(
                    color: ChillGoColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Bring your favorite people together and start the next adventure.',
                  style: TextStyle(color: ChillGoColors.inkMuted, height: 1.35),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          CircleAvatar(
            radius: 30,
            backgroundColor: ChillGoColors.sunshine,
            child: Icon(
              Icons.explore_rounded,
              color: ChillGoColors.ink,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
