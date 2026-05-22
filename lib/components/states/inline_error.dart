import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';
import '../icons/app_icon.dart';

class InlineError extends StatelessWidget {
  const InlineError({
    super.key,
    required this.message,
    this.leadingIcon = AppIconName.error,
    this.detail,
    this.trailing,
  });

  final String message;
  final AppIconName leadingIcon;
  final String? detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.errorContainer.withValues(alpha: 0.72)
            : colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(
          color: isDark
              ? colorScheme.error.withValues(alpha: 0.65)
              : colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppIcon(
              leadingIcon,
              size: VisualSpec.icon.sizeDefault,
              color: colorScheme.error,
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    message,
                    style: context.typography.meta.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  if ((detail ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: context.spacing.xs / 2),
                    Text(
                      detail!,
                      style: context.typography.caption.copyWith(
                        color: colorScheme.onErrorContainer.withValues(
                          alpha: 0.88,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...?trailing == null
                ? null
                : [SizedBox(width: context.spacing.sm), trailing!],
          ],
        ),
      ),
    );
  }
}
