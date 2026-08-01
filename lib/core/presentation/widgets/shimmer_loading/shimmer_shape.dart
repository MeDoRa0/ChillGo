part of '../shimmer_loading.dart';

class _ShimmerShape extends StatelessWidget {
  const _ShimmerShape({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ChillGoColors.outline,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
    );
  }
}
