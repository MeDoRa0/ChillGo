import 'package:flutter/material.dart';

part 'responsive_content/responsive_grid.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 840,
    this.includeSafeArea = true,
  });

  final Widget child;
  final double maxWidth;
  final bool includeSafeArea;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = switch (width) {
      < 600 => 16.0,
      < 1024 => 24.0,
      _ => 32.0,
    };
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
    return includeSafeArea ? SafeArea(child: content) : content;
  }
}
