import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';

enum MoneyfyPillSize { sm, md, lg }

enum MoneyfyPillTone { neutral, primary, success, danger, warning }

enum MoneyfyPillVariant { soft, outline, selected, tonal }

class MoneyfyPillStyle {
  const MoneyfyPillStyle({
    required this.height,
    required this.padding,
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderWidth,
    required this.radius,
    required this.textStyle,
  });

  factory MoneyfyPillStyle.resolve(
    BuildContext context, {
    MoneyfyPillSize size = MoneyfyPillSize.sm,
    MoneyfyPillTone tone = MoneyfyPillTone.neutral,
    MoneyfyPillVariant variant = MoneyfyPillVariant.soft,
    bool disabled = false,
  }) {
    final colors = context.colors;
    final height = switch (size) {
      MoneyfyPillSize.sm => VisualSpec.pill.heightSm,
      MoneyfyPillSize.md => VisualSpec.pill.heightMd,
      MoneyfyPillSize.lg => VisualSpec.pill.heightLg,
    };
    final paddingH = switch (size) {
      MoneyfyPillSize.sm => VisualSpec.pill.paddingHSm,
      MoneyfyPillSize.md => VisualSpec.pill.paddingHMd,
      MoneyfyPillSize.lg => VisualSpec.pill.paddingHLg,
    };
    final baseTextStyle = switch (size) {
      MoneyfyPillSize.sm => context.typography.caption,
      MoneyfyPillSize.md => context.typography.meta,
      MoneyfyPillSize.lg => context.typography.meta,
    };
    final toneForeground = switch (tone) {
      MoneyfyPillTone.neutral => colors.neutralText,
      MoneyfyPillTone.primary => colors.primary,
      MoneyfyPillTone.success => colors.positiveOn,
      MoneyfyPillTone.danger => colors.negativeOn,
      MoneyfyPillTone.warning => colors.warningOn,
    };
    final toneContainer = switch (tone) {
      MoneyfyPillTone.neutral => colors.neutralSurfaceRaised,
      MoneyfyPillTone.primary => colors.primaryContainer,
      MoneyfyPillTone.success => colors.positiveContainer,
      MoneyfyPillTone.danger => colors.negativeContainer,
      MoneyfyPillTone.warning => colors.warningContainer,
    };
    final foreground = disabled
        ? colors.neutralTextMuted.withValues(alpha: 0.62)
        : toneForeground;
    final background = switch (variant) {
      MoneyfyPillVariant.soft => colors.neutralSurfaceRaised,
      MoneyfyPillVariant.outline => colors.neutralBackground,
      MoneyfyPillVariant.selected => colors.neutralBackground,
      MoneyfyPillVariant.tonal => toneContainer,
    };
    final border = switch (variant) {
      MoneyfyPillVariant.soft => colors.neutralOutline.withValues(alpha: 0),
      MoneyfyPillVariant.outline => colors.neutralOutline,
      MoneyfyPillVariant.selected => colors.primary,
      MoneyfyPillVariant.tonal => toneContainer,
    };
    return MoneyfyPillStyle(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: paddingH),
      background: background,
      foreground: foreground,
      border: disabled ? colors.neutralOutline.withValues(alpha: 0.4) : border,
      borderWidth: VisualSpec.pill.borderWidth,
      radius: context.radius.rPill,
      textStyle: baseTextStyle.copyWith(
        color: foreground,
        fontWeight: AppFontWeights.semibold,
      ),
    );
  }

  final double height;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color foreground;
  final Color border;
  final double borderWidth;
  final double radius;
  final TextStyle textStyle;
}

class MoneyfyBadge extends StatelessWidget {
  const MoneyfyBadge({
    super.key,
    required this.label,
    this.size = MoneyfyPillSize.sm,
    this.tone = MoneyfyPillTone.neutral,
    this.variant = MoneyfyPillVariant.soft,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.maxLines = 1,
  });

  final String label;
  final MoneyfyPillSize size;
  final MoneyfyPillTone tone;
  final MoneyfyPillVariant variant;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final style = MoneyfyPillStyle.resolve(
      context,
      size: size,
      tone: tone,
      variant: variant,
    );
    final effectiveTextColor = textColor ?? style.foreground;

    return Container(
      constraints: BoxConstraints(minHeight: style.height),
      padding: style.padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? style.background,
        borderRadius: BorderRadius.circular(style.radius),
        border: Border.all(
          color: borderColor ?? style.border,
          width: style.borderWidth,
        ),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style.textStyle.copyWith(color: effectiveTextColor),
        ),
      ),
    );
  }
}
