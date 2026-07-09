import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chillgo/features/crews/domain/entities/crew.dart';
import 'package:chillgo/features/crews/presentation/blocs/crews_list/crews_list_cubit.dart';
import 'package:chillgo/features/crews/presentation/widgets/crew_card.dart';
import 'sign_out_icon_button.dart';
import 'user_identity_summary.dart';

class HomeMobileLayout extends StatelessWidget {
  final String? displayName;
  final String? username;

  const HomeMobileLayout({super.key, this.displayName, this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.mail_outline, color: Colors.white),
                  tooltip: 'Invitations',
                  onPressed: () => context.push('/invitations'),
                ),
                const SignOutIconButton(),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'ChillGo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserIdentitySummary(
                      displayName: displayName,
                      username: username,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coordinate and chill with your crews.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    _buildYourCrewsSection(context),
                    const SizedBox(height: 24),
                  ],
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
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filled(
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: () => _showCreateCrewDialog(context),
              icon: const Icon(Icons.groups),
              tooltip: 'Create Crew',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                  backgroundColor: Colors.redAccent,
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
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
                  color: const Color(0xFF1E1E2F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E2E4F)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Color(0xFF6366F1),
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
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a crew to start coordinating with friends.',
                            style: TextStyle(
                              color: Colors.grey[400],
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

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: crews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final crew = crews[index];
                return CrewCard(
                  crew: crew,
                  onTap: () => context.push('/crews/${crew.id}'),
                );
              },
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
      backgroundColor: const Color(0xFF1E1E2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _crewNameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Friend username').copyWith(
                    prefixText: '@',
                    prefixStyle: const TextStyle(color: Colors.white70),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6366F1),
                              ),
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
                        color: const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6366F1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_add_alt_1,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '@$_matchingUsername',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const Icon(Icons.add, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_memberError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _memberError!,
                    style: const TextStyle(color: Colors.redAccent),
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
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _createCrew,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
      hintStyle: TextStyle(color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFF0F0F1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      counterStyle: TextStyle(color: Colors.grey[600]),
    );
  }
}
