import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';

class MetricRow extends StatelessWidget {
  const MetricRow({
    super.key,
    required this.label,
    required this.value,
    this.subvalue,
    this.trailing,
    this.onTap,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? subvalue;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      style: context.typography.cardTitle.copyWith(color: valueColor),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.rSm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: context.typography.meta)),
            SizedBox(width: context.spacing.sm),
            valueText,
            if (subvalue != null) ...[
              SizedBox(width: context.spacing.xs),
              Text(subvalue!, style: context.typography.meta),
            ],
            if (trailing != null) ...[
              SizedBox(width: context.spacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
