part of '../home_mobile_layout.dart';

class _EditorialIntro extends StatelessWidget {
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final VoidCallback onAvatarTap;

  const _EditorialIntro({
    this.displayName,
    this.username,
    this.avatarUrl,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final headlineSize = constraints.maxWidth < 360 ? 38.0 : 44.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    right: 104,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: UserIdentitySummary(
                        displayName: displayName,
                        username: username,
                        avatarUrl: avatarUrl,
                        onAvatarTap: onAvatarTap,
                      ),
                    ),
                  ),
                  const Positioned(
                    top: -28,
                    right: -42,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.wb_sunny_rounded,
                        color: ChillGoColors.sunshine,
                        size: 138,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Good plans.\nGreat stories.',
              style: TextStyle(
                color: ChillGoColors.ink,
                fontSize: headlineSize,
                height: 1.04,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: const Text(
                'Bring your favorite people together and start the next adventure.',
                style: TextStyle(
                  color: ChillGoColors.inkMuted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 4,
              decoration: BoxDecoration(
                color: ChillGoColors.coral,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      },
    );
  }
}
