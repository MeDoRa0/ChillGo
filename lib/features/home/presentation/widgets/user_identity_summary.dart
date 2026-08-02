import 'package:flutter/material.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';

class UserIdentitySummary extends StatelessWidget {
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final bool compact;
  final VoidCallback onAvatarTap;

  const UserIdentitySummary({
    super.key,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.compact = false,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedDisplayName = _resolvedDisplayName;
    final resolvedUsername = username?.trim();
    final resolvedAvatarUrl = avatarUrl?.trim();
    final hasAvatar = resolvedAvatarUrl?.isNotEmpty == true;

    return Row(
      children: [
        Tooltip(
          message: 'Profile options',
          child: InkWell(
            key: const Key('home-user-avatar-button'),
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              key: const Key('home-user-avatar'),
              radius: compact ? 18 : 22,
              backgroundColor: ChillGoColors.coralSoft,
              backgroundImage: hasAvatar
                  ? NetworkImage(resolvedAvatarUrl!)
                  : null,
              child: hasAvatar
                  ? null
                  : Icon(
                      Icons.person,
                      color: ChillGoColors.coral,
                      size: compact ? 20 : 24,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resolvedDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ChillGoColors.ink,
                  fontSize: compact ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (resolvedUsername != null && resolvedUsername.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '@$resolvedUsername',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ChillGoColors.inkMuted,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String get _resolvedDisplayName {
    final trimmed = displayName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }

    return 'Welcome back!';
  }
}
