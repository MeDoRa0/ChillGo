import 'package:flutter/material.dart';

class UserIdentitySummary extends StatelessWidget {
  final String? displayName;
  final String? username;
  final bool compact;

  const UserIdentitySummary({
    super.key,
    this.displayName,
    this.username,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedDisplayName = _resolvedDisplayName;
    final resolvedUsername = username?.trim();

    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 18 : 22,
          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.18),
          child: Icon(
            Icons.person,
            color: const Color(0xFF818CF8),
            size: compact ? 20 : 24,
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
                  color: Colors.white,
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
                    color: Colors.grey[400],
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
