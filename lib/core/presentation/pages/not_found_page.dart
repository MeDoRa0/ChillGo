import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chillgo_colors.dart';
import '../widgets/responsive_content.dart';
import '../widgets/sunshine_background.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SunshineBackground(
        child: ResponsiveContent(
          maxWidth: 520,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: ChillGoColors.coral,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '404 - Page Not Found',
                    style: TextStyle(
                      color: ChillGoColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The page you are looking for does not exist or has been moved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ChillGoColors.inkMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/');
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
