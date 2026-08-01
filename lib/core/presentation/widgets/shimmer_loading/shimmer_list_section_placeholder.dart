part of '../shimmer_loading.dart';

class ShimmerListSectionPlaceholder extends StatelessWidget {
  const ShimmerListSectionPlaceholder({
    super.key,
    this.itemCount = 3,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: _ShimmerListContent(itemCount: itemCount),
    );
  }
}
