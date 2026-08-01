import 'package:flutter/material.dart';

import '../theme/chillgo_colors.dart';

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final position = (_controller.value * 3) - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(position - 1, 0),
            end: Alignment(position + 1, 0),
            colors: const [
              ChillGoColors.outline,
              ChillGoColors.surface,
              ChillGoColors.outline,
            ],
            stops: const [0.2, 0.5, 0.8],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

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

class ShimmerListPlaceholder extends StatelessWidget {
  const ShimmerListPlaceholder({
    super.key,
    this.itemCount = 3,
    this.padding = const EdgeInsets.all(16),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: _ShimmerListContent(itemCount: itemCount),
    );
  }
}

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
