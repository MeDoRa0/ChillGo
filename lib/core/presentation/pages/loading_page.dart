import 'package:flutter/material.dart';

import '../theme/chillgo_colors.dart';
import '../widgets/shimmer_loading.dart';
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
              const ShimmerBox(
                width: 96,
                height: 96,
                shape: BoxShape.circle,
                semanticLabel: 'Getting ChillGo ready',
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
