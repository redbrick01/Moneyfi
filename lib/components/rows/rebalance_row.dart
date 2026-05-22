import 'package:flutter/material.dart';

import '../../design_system/spec.dart';
import '../../theme/moneyfy_theme.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: singleLine
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MoneyfyPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: VisualSpec.icon.sizeSmall),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: singleLine
                ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: MoneyfyPalette.ink,
                          ),
                        ),
                        if (helper != null)
                          TextSpan(
                            text: '  $helper',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: MoneyfyPalette.tertiaryText,
                              fontSize: 12,
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
                        const SizedBox(height: 4),
                        Text(
                          helper!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: MoneyfyPalette.tertiaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor ?? MoneyfyPalette.ink,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
