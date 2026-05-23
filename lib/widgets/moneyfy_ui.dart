import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/section_card.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../theme/moneyfy_theme.dart';

class MoneyfySpacing {
  static const double pageHorizontal = 20;
  static const double pageTop = 24;
  static const double pageBottomInset = 132;
  static const double headerGap = 32;
  static const double sectionGap = 32;
  static const double cardPadding = 24;
  static const double compactCardPadding = 24;
  static const double cardRadius = 18;
  static const double controlRadius = 9999;
}

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
            : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
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
                  const SizedBox(height: 4),
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
                  const SizedBox(width: 10),
                  Container(width: 1, height: 24, color: dividerColor),
                  const SizedBox(width: 10),
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
    this.padding = const EdgeInsets.all(MoneyfySpacing.cardPadding),
    this.headerBottomSpacing = 16,
    this.variant = MoneyfySurfaceCardVariant.base,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double headerBottomSpacing;
  final MoneyfySurfaceCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return MoneyfySurfaceCard(
      variant: variant,
      padding: padding,
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
      borderRadius: BorderRadius.circular(MoneyfySpacing.controlRadius),
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MoneyfyPalette.surface,
          borderRadius: BorderRadius.circular(MoneyfySpacing.controlRadius),
          border: Border.all(color: MoneyfyPalette.border),
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
  Color? backgroundColor,
}) {
  return ActionPane(
    motion: const StretchMotion(),
    extentRatio: 0.22,
    children: [
      CustomSlidableAction(
        onPressed: (_) => onPressed(),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: BorderRadius.zero,
        child: Align(
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: VisualSpec.icon.sizeDefault,
          ),
        ),
      ),
    ],
  );
}

Color moneyfyValueColor(
  String value, {
  Color defaultColor = MoneyfyPalette.ink,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return defaultColor;

  // Explicit leading sign.
  if (trimmed.startsWith('-') || trimmed.startsWith('−')) {
    return MoneyfyPalette.negative;
  }
  if (trimmed.startsWith('+')) {
    return MoneyfyPalette.positive;
  }

  // Accounting-style negative numbers, e.g. "(1,234)".
  if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
    return MoneyfyPalette.negative;
  }

  // Currency symbols can appear before the sign, e.g. "₩-1,000".
  if (trimmed.contains('-') || trimmed.contains('−')) {
    return MoneyfyPalette.negative;
  }
  if (trimmed.contains('+')) {
    return MoneyfyPalette.positive;
  }
  return defaultColor;
}
