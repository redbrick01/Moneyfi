import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.typography.meta,
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Flexible(
            child: valueWidget ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: context.typography.cardTitle.copyWith(
                    color: valueColor,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
