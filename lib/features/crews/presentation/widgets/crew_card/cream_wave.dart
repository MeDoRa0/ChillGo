part of '../crew_card.dart';

class _CreamWave extends StatelessWidget {
  const _CreamWave();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _CreamWaveClipper(),
      child: const ColoredBox(color: ChillGoColors.surface),
    );
  }
}
