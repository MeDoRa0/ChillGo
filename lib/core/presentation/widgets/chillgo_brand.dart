import 'package:flutter/material.dart';

import '../theme/chillgo_colors.dart';

class ChillGoBrandMark extends StatelessWidget {
  const ChillGoBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ChillGo people-together logo',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 96,
          height: 90,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.08,
                child: Container(
                  width: 84,
                  height: 78,
                  decoration: const BoxDecoration(
                    color: ChillGoColors.sunshine,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(34),
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F35172F),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.groups_rounded,
                size: 42,
                color: ChillGoColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChillGoMeetupHighlights extends StatelessWidget {
  const ChillGoMeetupHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Grab a coffee, meet friends, and enjoy the day',
      child: const ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HighlightIcon(
              icon: Icons.coffee_rounded,
              backgroundColor: ChillGoColors.coralSoft,
            ),
            SizedBox(width: 12),
            _HighlightIcon(
              icon: Icons.forum_rounded,
              backgroundColor: ChillGoColors.skySoft,
            ),
            SizedBox(width: 12),
            _HighlightIcon(
              icon: Icons.sentiment_satisfied_alt_rounded,
              backgroundColor: ChillGoColors.leafSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightIcon extends StatelessWidget {
  const _HighlightIcon({required this.icon, required this.backgroundColor});

  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, size: 21, color: ChillGoColors.ink),
    );
  }
}
