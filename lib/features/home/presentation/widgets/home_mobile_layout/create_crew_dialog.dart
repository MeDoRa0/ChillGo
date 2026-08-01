part of '../home_mobile_layout.dart';

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
