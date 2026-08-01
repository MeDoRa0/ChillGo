part of '../shimmer_loading.dart';

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChillGoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ChillGoColors.outline),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerShape(width: 48, height: 48, shape: BoxShape.circle),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerShape(height: 16, borderRadius: 6),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: _ShimmerShape(height: 12, borderRadius: 6),
                ),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.46,
                  child: _ShimmerShape(height: 12, borderRadius: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
