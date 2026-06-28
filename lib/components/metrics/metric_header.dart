import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';

enum MetricPrimaryStyle { hero, title }

class MetricHeader extends StatelessWidget {
  const MetricHeader({
    super.key,
    this.leading,
    required this.title,
    required this.primaryText,
    this.secondary = const <Widget>[],
    this.trailing,
    this.footerMeta,
    this.toggle,
    this.primaryStyle = MetricPrimaryStyle.hero,
  });

  final Widget? leading;
  final String title;
  final String primaryText;
  final List<Widget> secondary;
  final Widget? trailing;
  final String? footerMeta;
  final Widget? toggle;
  final MetricPrimaryStyle primaryStyle;

  @override
  Widget build(BuildContext context) {
    final primaryTypography = primaryStyle == MetricPrimaryStyle.hero
        ? context.typography.heroNumber
        : context.typography.pageTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: context.spacing.sm),
            ],
            Expanded(child: Text(title, style: context.typography.meta)),
            ...?(trailing != null ? <Widget>[trailing!] : null),
          ],
        ),
        SizedBox(height: context.spacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            primaryText,
            style: primaryTypography,
            textAlign: TextAlign.right,
          ),
        ),
        if (toggle != null) ...[
          SizedBox(height: context.spacing.sm),
          Align(alignment: Alignment.centerRight, child: toggle!),
        ],
        if (secondary.isNotEmpty) ...[
          SizedBox(height: context.spacing.md),
          ...secondary.take(2),
        ],
        if (footerMeta != null) ...[
          SizedBox(height: context.spacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              footerMeta!,
              style: context.typography.caption.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
