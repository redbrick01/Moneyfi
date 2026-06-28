import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';

enum SkeletonCardPreset { homeSummary, chartCard, calendarCard }

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, this.height = 120, this.radius});

  final double height;
  final double? radius;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHigh;
    final pulseColor = colorScheme.surfaceContainerHighest;
    final resolvedRadius = widget.radius ?? context.radius.rMd;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color.lerp(baseColor, pulseColor, _controller.value),
            borderRadius: BorderRadius.circular(resolvedRadius),
          ),
        );
      },
    );
  }
}

class SkeletonPresetCard extends StatelessWidget {
  const SkeletonPresetCard({super.key, required this.preset});

  final SkeletonCardPreset preset;

  @override
  Widget build(BuildContext context) {
    final height = switch (preset) {
      SkeletonCardPreset.homeSummary => 176.0,
      SkeletonCardPreset.chartCard => 248.0,
      SkeletonCardPreset.calendarCard => 336.0,
    };
    return SkeletonCard(height: height);
  }
}

class SkeletonTextLine extends StatelessWidget {
  const SkeletonTextLine({super.key, this.widthFactor = 1, this.height});

  final double widthFactor;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor.clamp(0.2, 1.0),
      child: SkeletonCard(
        height: height ?? context.spacing.sm,
        radius: context.radius.rSm,
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.rows,
    this.count,
    this.rowHeight = 64,
    this.hasLeading = true,
    this.trailingLines = 2,
  });

  final int? rows;
  final int? count;
  final double rowHeight;
  final bool hasLeading;
  final int trailingLines;

  @override
  Widget build(BuildContext context) {
    final resolvedCount = rows ?? count ?? 4;
    return Column(
      children: [
        for (var i = 0; i < resolvedCount; i++) ...[
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: rowHeight),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasLeading) ...[
                  SizedBox(
                    width: context.spacing.xxxl,
                    height: context.spacing.xxxl,
                    child: SkeletonCard(
                      height: context.spacing.xxxl,
                      radius: context.radius.rMd,
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonTextLine(widthFactor: 0.64),
                      SizedBox(height: context.spacing.xs / 2),
                      if (trailingLines > 1)
                        const SkeletonTextLine(widthFactor: 0.36),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (i != resolvedCount - 1) SizedBox(height: context.spacing.sm),
        ],
      ],
    );
  }
}
