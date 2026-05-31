import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.minHeight,
    this.dense = false,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;
  final double? minHeight;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor = valueColor ?? context.colors.neutralText;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: minHeight == null
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.typography.meta.copyWith(
            color: context.colors.neutralTextMuted,
            fontWeight: dense ? null : AppFontWeights.semibold,
          ),
        ),
        SizedBox(
          height: dense
              ? context.spacing.xs / 2
              : context.spacing.xs - context.spacing.xs / 4,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: context.typography.cardTitle.copyWith(
              color: resolvedValueColor,
            ),
          ),
        ),
        if ((caption ?? '').trim().isNotEmpty) ...[
          SizedBox(height: context.spacing.xs / 2),
          Text(
            caption!,
            style: context.typography.caption.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
        ],
      ],
    );

    return Container(
      constraints: minHeight == null
          ? const BoxConstraints()
          : BoxConstraints(minHeight: minHeight!),
      padding: dense
          ? EdgeInsets.all(context.spacing.sm)
          : EdgeInsets.symmetric(
              horizontal: context.spacing.sm,
              vertical: context.spacing.xs + context.spacing.xs / 4,
            ),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceRaised,
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(
          color: context.colors.neutralOutline.withValues(alpha: 0.72),
        ),
      ),
      child: content,
    );
  }
}
