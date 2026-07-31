import 'package:flutter/material.dart';

import '../theme/chillgo_colors.dart';
import '../widgets/sunshine_background.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SunshineBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: ChillGoColors.sunshineSoft,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(
                  dimension: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Getting the good times ready…',
                style: TextStyle(
                  color: ChillGoColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
