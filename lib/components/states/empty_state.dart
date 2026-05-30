import 'package:flutter/material.dart';

import '../../design_system/spec.dart';
import '../../design_system/context_extensions.dart';
import '../../services/auth_service.dart';
import '../icons/app_icon.dart';
import '../buttons/app_buttons.dart';
import '../section_card.dart';

enum EmptyStateVariant { embedded, standalone }

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = AppIconName.inbox,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.variant = EmptyStateVariant.embedded,
    this.cardVariant = SectionCardVariant.raised,
  });

  final String title;
  final String description;
  final AppIconName icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EmptyStateVariant variant;
  final SectionCardVariant cardVariant;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.currentUser != null;
    final colorScheme = Theme.of(context).colorScheme;
    final alpha = Theme.of(context).brightness == Brightness.dark
        ? VisualSpec.icon.emptyIconAlphaDark
        : VisualSpec.icon.emptyIconAlphaLight;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppIcon(
          icon,
          size: VisualSpec.icon.iconSizeLarge,
          color: colorScheme.onSurfaceVariant.withValues(alpha: alpha),
        ),
        SizedBox(height: context.spacing.sm),
        Text(
          title,
          style: context.typography.cardTitle.copyWith(
            fontWeight: AppFontWeights.semibold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          description,
          style: context.typography.meta,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: context.spacing.md),
          AppPrimaryButton(
            label: actionLabel!,
            onPressed: onAction,
            expand: !isLoggedIn,
          ),
        ],
        if (secondaryActionLabel != null && onSecondaryAction != null) ...[
          SizedBox(height: context.spacing.xs),
          AppGhostButton(
            label: secondaryActionLabel!,
            onPressed: onSecondaryAction,
            expand: !isLoggedIn,
          ),
        ],
      ],
    );

    final card = SizedBox(
      width: double.infinity,
      child: SectionCard(
        variant: cardVariant,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
          child: content,
        ),
      ),
    );

    return variant == EmptyStateVariant.standalone
        ? Padding(
            padding: EdgeInsets.only(bottom: context.spacing.xl),
            child: card,
          )
        : card;
  }
}
