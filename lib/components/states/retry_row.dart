import 'package:flutter/material.dart';

import '../../design_system/spec.dart';
import '../../design_system/context_extensions.dart';
import '../buttons/app_buttons.dart';

class RetryRow extends StatelessWidget {
  const RetryRow({
    super.key,
    required this.message,
    required this.onRetry,
    this.label = CopySpec.retry,
    this.useSecondaryButton = false,
  });

  final String message;
  final VoidCallback onRetry;
  final String label;
  final bool useSecondaryButton;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: context.typography.meta.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: context.spacing.sm),
          useSecondaryButton
              ? AppSecondaryButton(
                  label: label,
                  onPressed: onRetry,
                  expand: false,
                )
              : AppGhostButton(label: label, onPressed: onRetry),
        ],
      ),
    );
  }
}
