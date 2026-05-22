import 'package:flutter/material.dart';

import '../design_system/spec.dart';
import '../design_system/context_extensions.dart';
import 'separators/app_divider.dart';

enum SectionCardVariant { base, raised, outline }

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.headerTrailing,
    required this.child,
    this.footer,
    this.padding,
    this.dense = false,
    this.showDividerBetweenHeaderAndBody = false,
    this.useSectionTitle = true,
    this.variant = SectionCardVariant.base,
  });

  final String? title;
  final Widget? headerTrailing;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final bool dense;
  final bool showDividerBetweenHeaderAndBody;
  final bool useSectionTitle;
  final SectionCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedPadding =
        padding ?? EdgeInsets.all(context.cardPadding(dense: dense));

    final headerStyle = useSectionTitle
        ? context.typography.sectionTitle
        : context.typography.cardTitle;

    final color = switch (variant) {
      SectionCardVariant.base => VisualSpec.surface.cardBase(brightness),
      SectionCardVariant.raised => VisualSpec.surface.cardRaised(brightness),
      SectionCardVariant.outline => VisualSpec.surface.cardBase(brightness),
    };
    final borderRadius = BorderRadius.circular(VisualSpec.surface.radiusCard);
    final borderColor = switch (variant) {
      SectionCardVariant.outline => colorScheme.outlineVariant.withValues(
        alpha: brightness == Brightness.dark ? 0.88 : 1,
      ),
      SectionCardVariant.raised => colorScheme.outlineVariant.withValues(
        alpha: brightness == Brightness.dark ? 0.52 : 0.30,
      ),
      SectionCardVariant.base => colorScheme.outlineVariant.withValues(
        alpha: brightness == Brightness.dark ? 0.44 : 0.20,
      ),
    };
    final shadowColor = switch (variant) {
      SectionCardVariant.raised => Colors.black.withValues(alpha: 0.10),
      _ => Colors.black.withValues(alpha: 0.06),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.98),
            color,
          ],
        ),
        border: Border.all(color: borderColor, width: VisualSpec.surface.borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: variant == SectionCardVariant.raised ? 18 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: resolvedPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null || headerTrailing != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: headerStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ...?(headerTrailing != null
                          ? <Widget>[headerTrailing!]
                          : null),
                    ],
                  ),
                  SizedBox(height: context.spacing.md),
                  if (showDividerBetweenHeaderAndBody) ...[
                    AppDivider(),
                    SizedBox(height: context.spacing.md),
                  ],
                ],
                // If you render a ListView inside this card, use shrinkWrap=true and
                // NeverScrollableScrollPhysics to avoid nested-scroll conflicts.
                child,
                if (footer != null) ...[
                  SizedBox(height: context.spacing.md),
                  AppDivider(),
                  SizedBox(height: context.spacing.md),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
