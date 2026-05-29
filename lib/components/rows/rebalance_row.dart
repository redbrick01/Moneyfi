import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';

class RebalanceRow extends StatelessWidget {
  const RebalanceRow({
    super.key,
    required this.icon,
    required this.title,
    this.helper,
    required this.value,
    this.valueColor,
    this.singleLine = false,
  });

  final IconData icon;
  final String title;
  final String? helper;
  final String value;
  final Color? valueColor;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm + context.spacing.xs / 2,
      ),
      child: Row(
        crossAxisAlignment: singleLine
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.neutralSurfaceRaised,
              borderRadius: BorderRadius.circular(context.radius.rMd),
            ),
            child: Icon(icon, size: VisualSpec.icon.sizeSmall),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: singleLine
                ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.neutralText,
                          ),
                        ),
                        if (helper != null)
                          TextSpan(
                            text: '  $helper',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.colors.neutralTextMuted,
                              fontSize: context.fontSizes.s12,
                            ),
                          ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.bodyMedium),
                      if (helper != null) ...[
                        SizedBox(height: context.spacing.xs / 2),
                        Text(
                          helper!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.colors.neutralTextMuted,
                            fontSize: context.fontSizes.s12,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          SizedBox(width: context.spacing.sm),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor ?? context.colors.neutralText,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
