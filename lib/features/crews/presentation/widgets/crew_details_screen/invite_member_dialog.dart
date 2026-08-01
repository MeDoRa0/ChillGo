part of '../../screens/crew_details_screen.dart';

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
