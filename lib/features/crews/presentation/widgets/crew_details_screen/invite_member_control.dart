part of '../../screens/crew_details_screen.dart';

class _InviteMemberControl extends StatelessWidget {
  final VoidCallback onPressed;

  const _InviteMemberControl({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MemberAvatar._itemWidth,
      child: Column(
        children: [
          SizedBox.square(
            dimension: _MemberAvatar._avatarRadius * 2,
            child: OutlinedButton(
              key: const Key('add-crew-member-button'),
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: ChillGoColors.coral,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                side: const BorderSide(color: ChillGoColors.coral),
              ),
              child: const Icon(Icons.person_add_alt_1_outlined, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invite',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(color: ChillGoColors.ink, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
