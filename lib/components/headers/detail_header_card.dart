import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';
import '../section_card.dart';

class DetailHeaderCard extends StatelessWidget {
  const DetailHeaderCard({
    super.key,
    required this.title,
    this.chips,
    required this.primaryText,
    this.secondaryRows = const [],
    this.footerMeta,
    this.trailingMeta,
  });

  final String title;
  final List<Widget>? chips;
  final String primaryText;
  final List<Widget> secondaryRows;
  final String? footerMeta;
  final Widget? trailingMeta;

  @override
  Widget build(BuildContext context) {
    final resolvedChips = chips ?? const <Widget>[];
    return SectionCard(
      padding: EdgeInsets.all(context.cardPadding()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resolvedChips.isNotEmpty || trailingMeta != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: context.spacing.xs,
                    runSpacing: context.spacing.xs,
                    children: resolvedChips,
                  ),
                ),
                if (trailingMeta != null) ...[
                  SizedBox(width: context.spacing.sm),
                  trailingMeta!,
                ],
              ],
            ),
          if (resolvedChips.isNotEmpty || trailingMeta != null)
            SizedBox(height: context.spacing.sm),
          Text(
            title,
            style: context.typography.sectionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            primaryText,
            style: context.typography.heroNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (secondaryRows.isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            for (var i = 0; i < secondaryRows.length; i++) ...[
              secondaryRows[i],
              if (i != secondaryRows.length - 1)
                SizedBox(height: context.spacing.xs),
            ],
          ],
          if ((footerMeta ?? '').trim().isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Text(footerMeta!, style: context.typography.caption),
          ],
        ],
      ),
    );
  }
}
