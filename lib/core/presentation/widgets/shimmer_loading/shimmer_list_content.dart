part of '../shimmer_loading.dart';

class _ShimmerListContent extends StatelessWidget {
  const _ShimmerListContent({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading content',
      liveRegion: true,
      child: ExcludeSemantics(
        child: ShimmerLoading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ShimmerShape(width: 136, height: 24, borderRadius: 8),
              const SizedBox(height: 16),
              for (var index = 0; index < itemCount; index++) ...[
                const _ShimmerCard(),
                if (index != itemCount - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
