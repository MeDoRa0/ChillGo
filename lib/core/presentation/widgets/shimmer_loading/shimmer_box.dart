part of '../shimmer_loading.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
    this.semanticLabel = 'Loading',
  });

  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ShimmerLoading(
          child: _ShimmerShape(
            width: width,
            height: height,
            borderRadius: borderRadius,
            shape: shape,
          ),
        ),
      ),
    );
  }
}
