import 'package:flutter/material.dart';

import '../theme/chillgo_colors.dart';

part 'sunshine_background/background_spot.dart';

class SunshineBackground extends StatelessWidget {
  const SunshineBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChillGoColors.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -90,
            right: -70,
            child: _BackgroundSpot(
              diameter: 240,
              color: ChillGoColors.sunshineSoft,
            ),
          ),
          const Positioned(
            left: -100,
            bottom: 40,
            child: _BackgroundSpot(diameter: 250, color: ChillGoColors.skySoft),
          ),
          child,
        ],
      ),
    );
  }
}
