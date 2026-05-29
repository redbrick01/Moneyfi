import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../design_system/spec.dart';
import '../icons/app_icon.dart';

class ExpandableTile extends StatefulWidget {
  const ExpandableTile({
    super.key,
    this.leading,
    required this.title,
    this.meta,
    this.subtitle,
    this.tags,
    required this.children,
    this.initiallyExpanded = false,
  });

  final Widget? leading;
  final String title;
  final String? meta;
  final String? subtitle;
  final List<Widget>? tags;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<ExpandableTile>
    with TickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTags = widget.tags != null && widget.tags!.isNotEmpty;
    final hasSubtitle = (widget.subtitle ?? '').trim().isNotEmpty;

    return Semantics(
      button: true,
      label: widget.title,
      value: _expanded ? '확장됨' : '축소됨',
      hint: _expanded ? '접기' : '펼치기',
      toggled: _expanded,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaces.surfaceBase,
          borderRadius: BorderRadius.circular(context.radius.rMd),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radius.rMd),
          onTap: _toggle,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.05);
            }
            return null;
          }),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _expanded
                        ? context.surfaces.surfaceRaised
                        : context.surfaces.surfaceBase,
                    borderRadius: BorderRadius.circular(context.radius.rMd),
                  ),
                  padding: EdgeInsets.all(context.spacing.xs),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.leading != null) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              top: context.spacing.xs / 3,
                            ),
                            child: widget.leading!,
                          ),
                          SizedBox(width: context.spacing.sm),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: context.typography.cardTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasSubtitle) ...[
                                SizedBox(height: context.spacing.xs / 2),
                                Text(
                                  widget.subtitle!,
                                  style: context.typography.meta,
                                  maxLines: _expanded ? 6 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: context.spacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if ((widget.meta ?? '').trim().isNotEmpty)
                              Text(
                                widget.meta!,
                                style: context.typography.caption,
                              ),
                            SizedBox(height: context.spacing.xs / 2),
                            AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: context.motion.normal,
                              child: AppIcon(
                                AppIconName.expandMore,
                                size: VisualSpec.icon.sizeDefault,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasTags) ...[
                  SizedBox(height: context.spacing.xs),
                  Wrap(
                    spacing: context.spacing.xs,
                    runSpacing: context.spacing.xs,
                    children: widget.tags!,
                  ),
                ],
                AnimatedSize(
                  duration: context.motion.normal,
                  curve: Curves.easeOut,
                  child: _expanded
                      ? Padding(
                          padding: EdgeInsets.only(top: context.spacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (
                                var i = 0;
                                i < widget.children.length;
                                i++
                              ) ...[
                                widget.children[i],
                                if (i != widget.children.length - 1)
                                  SizedBox(height: context.spacing.sm),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
  }
}

class ExpandableBlock extends StatelessWidget {
  const ExpandableBlock({super.key, required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: context.typography.meta.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: context.spacing.xs / 2),
        Text(body, style: context.typography.body),
      ],
    );
  }
}
