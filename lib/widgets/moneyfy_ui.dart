import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:moneyfy/widgets/app_refresh_indicator.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';

class MoneyfyPage extends StatelessWidget {
  const MoneyfyPage({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onRefresh,
    this.scrollController,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final horizontalPadding = context.contentHorizontalPadding;
    final canPop = Navigator.canPop(context);
    final scrollView = SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        context.spacing.pageTop,
        horizontalPadding,
        context.spacing.pageBottomInset + bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canPop) ...[
                IconButton(
                  tooltip: '뒤로',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                SizedBox(width: context.spacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.typography.pageTitle),
                    if (subtitle != null) ...[
                      SizedBox(height: context.spacing.xs),
                      Text(
                        subtitle!,
                        style: context.typography.body.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
          SizedBox(height: context.spacing.sectionGap),
          ...children,
        ],
      ),
    );

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: onRefresh == null
            ? scrollView
            : AppRefreshIndicator(onRefresh: onRefresh!, child: scrollView),
      ),
    );
  }
}

class MoneyfySectionHeader extends StatelessWidget {
  const MoneyfySectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: context.typography.sectionTitle),
        const Spacer(),
        ...?trailing == null ? null : [trailing!],
      ],
    );
  }
}

class MoneyfySurfaceCard extends StatelessWidget {
  const MoneyfySurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = MoneyfySurfaceCardVariant.base,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final MoneyfySurfaceCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ?? EdgeInsets.all(context.cardPadding());
    final sectionVariant = switch (variant) {
      MoneyfySurfaceCardVariant.base => SectionCardVariant.base,
      MoneyfySurfaceCardVariant.raised => SectionCardVariant.raised,
      MoneyfySurfaceCardVariant.outline => SectionCardVariant.outline,
    };

    return SectionCard(
      variant: sectionVariant,
      padding: resolvedPadding,
      child: child,
    );
  }
}

enum MoneyfySurfaceCardVariant { base, raised, outline }

class MoneyfyCardHeader extends StatelessWidget {
  const MoneyfyCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottomSpacing = 16,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.7,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.typography.sectionTitle),
                if (subtitle != null) ...[
                  SizedBox(height: context.spacing.xs / 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...?trailing == null
              ? null
              : [
                  SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
                  Container(width: 1, height: 24, color: dividerColor),
                  SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
                  trailing!,
                ],
        ],
      ),
    );
  }
}

class MoneyfySectionCard extends StatelessWidget {
  const MoneyfySectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding,
    this.headerBottomSpacing = 16,
    this.variant = MoneyfySurfaceCardVariant.base,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double headerBottomSpacing;
  final MoneyfySurfaceCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return MoneyfySurfaceCard(
      variant: variant,
      padding: padding ?? EdgeInsets.all(context.cardPadding()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoneyfyCardHeader(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            bottomSpacing: headerBottomSpacing,
          ),
          child,
        ],
      ),
    );
  }
}

class MoneyfyIconButtonSurface extends StatelessWidget {
  const MoneyfyIconButtonSurface({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.rPill),
      child: Ink(
        width: context.spacing.xl + context.spacing.sm,
        height: context.spacing.xl + context.spacing.sm,
        decoration: BoxDecoration(
          color: context.colors.neutralSurfaceBase,
          borderRadius: BorderRadius.circular(context.radius.rPill),
          border: Border.all(color: context.colors.neutralOutline),
        ),
        child: Icon(icon),
      ),
    );
  }
}

ActionPane moneyfySingleSlideActionPane({
  required VoidCallback onPressed,
  required IconData icon,
  required Color iconColor,
  String? semanticLabel,
  Color? backgroundColor,
}) {
  return ActionPane(
    motion: const StretchMotion(),
    extentRatio: 0.22,
    children: [
      CustomSlidableAction(
        onPressed: (_) => onPressed(),
        backgroundColor: backgroundColor ?? VisualSpec.surface.transparent,
        padding: VisualSpec.surface.swipeActionPadding,
        borderRadius: BorderRadius.zero,
        child: Align(
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            semanticLabel: semanticLabel,
            size: VisualSpec.icon.sizeDefault,
          ),
        ),
      ),
    ],
  );
}
