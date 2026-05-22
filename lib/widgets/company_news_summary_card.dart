import 'package:flutter/material.dart';

import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../services/company_news_summary_service.dart';
import '../theme/moneyfy_theme.dart';

class CompanyNewsSummaryCard extends StatelessWidget {
  const CompanyNewsSummaryCard({
    required this.items,
    this.title = '종목별 뉴스',
    this.emptyMessage = '표시할 종목 뉴스가 없습니다.',
    super.key,
  });

  final List<CompanyNewsSummaryItem> items;
  final String title;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockItems = items
        .where((item) => item.assetType == '주식')
        .toList(growable: false);
    final coinItems = items
        .where((item) => item.assetType == '코인')
        .toList(growable: false);
    final sections = <_NewsSection>[
      if (stockItems.isNotEmpty) _NewsSection(label: '주식', items: stockItems),
      if (coinItems.isNotEmpty) _NewsSection(label: '코인', items: coinItems),
    ];
    final latestSummaryDate = _findLatestSummaryDate(items);
    final latestModel = _findLatestModel(items);
    final hasHeaderMeta = latestSummaryDate != null || latestModel != null;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
        boxShadow: context.shadows.level3,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 22),
                  ),
                ),
                if (hasHeaderMeta)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (latestSummaryDate != null)
                        Text(
                          latestSummaryDate,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: MoneyfyPalette.tertiaryText,
                          ),
                        ),
                      if (latestSummaryDate != null && latestModel != null)
                        const SizedBox(width: 8),
                      if (latestModel != null)
                        Text(
                          latestModel,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: MoneyfyPalette.tertiaryText,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              SizedBox(
                width: double.infinity,
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MoneyfyPalette.tertiaryText,
                  ),
                ),
              )
            else
              for (
                var sectionIndex = 0;
                sectionIndex < sections.length;
                sectionIndex++
              ) ...[
                for (
                  var itemIndex = 0;
                  itemIndex < sections[sectionIndex].items.length;
                  itemIndex++
                ) ...[
                  _CompanyNewsSummaryTile(
                    item: sections[sectionIndex].items[itemIndex],
                  ),
                  if (itemIndex != sections[sectionIndex].items.length - 1)
                    const SizedBox(height: 12),
                ],
                if (sectionIndex != sections.length - 1)
                  const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

String? _findLatestSummaryDate(List<CompanyNewsSummaryItem> items) {
  DateTime? latest;
  String? latestRaw;
  for (final item in items) {
    final raw = (item.summaryDate ?? '').trim();
    if (raw.isEmpty) continue;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      latestRaw ??= raw;
      continue;
    }
    if (latest == null || parsed.isAfter(latest)) {
      latest = parsed;
      latestRaw = _formatSummaryDate(raw);
    }
  }
  return latestRaw;
}

String? _findLatestModel(List<CompanyNewsSummaryItem> items) {
  CompanyNewsSummaryItem? latestItem;
  DateTime? latestTime;
  for (final item in items) {
    final model = (item.model ?? '').trim();
    if (model.isEmpty) continue;
    final parsed = DateTime.tryParse((item.updatedAt ?? '').trim());
    if (latestItem == null) {
      latestItem = item;
      latestTime = parsed;
      continue;
    }
    if (parsed != null && (latestTime == null || parsed.isAfter(latestTime))) {
      latestItem = item;
      latestTime = parsed;
    }
  }
  final resolved = (latestItem?.model ?? '').trim();
  return resolved.isEmpty ? null : resolved;
}

String _formatSummaryDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.split('T').first;
  }
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  return '${parsed.year}-$month-$day';
}

class _NewsSection {
  const _NewsSection({required this.label, required this.items});

  final String label;
  final List<CompanyNewsSummaryItem> items;
}

class _CompanyNewsSummaryTile extends StatefulWidget {
  const _CompanyNewsSummaryTile({required this.item});

  final CompanyNewsSummaryItem item;

  @override
  State<_CompanyNewsSummaryTile> createState() =>
      _CompanyNewsSummaryTileState();
}

class _CompanyNewsSummaryTileState extends State<_CompanyNewsSummaryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final summaryText = '${item.summary?['company_summary'] ?? ''}'.trim();
    final issues = item.summary?['issues'] is List
        ? (item.summary!['issues'] as List).whereType<Map>().toList(
            growable: false,
          )
        : const <Map>[];
    final sortedIssues = [...issues]
      ..sort((a, b) {
        final aValue = int.tryParse('${a['importance'] ?? ''}') ?? 0;
        final bValue = int.tryParse('${b['importance'] ?? ''}') ?? 0;
        return bValue.compareTo(aValue);
      });
    final outlook = item.summary?['outlook'] is Map
        ? Map<String, dynamic>.from(
            (item.summary!['outlook'] as Map).map(
              (key, value) => MapEntry('$key', value),
            ),
          )
        : const <String, dynamic>{};
    final collapsedTitle = sortedIssues.isNotEmpty
        ? '${sortedIssues.first['title'] ?? ''}'.trim()
        : summaryText;

    return InkWell(
      borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _companyInnerNewsCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaces.surfaceRaised,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.symbol,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MoneyfyPalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    collapsedTitle.isEmpty ? item.symbol : collapsedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: MoneyfyPalette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if ((item.summaryDate ?? '').isNotEmpty)
                  Text(
                    item.summaryDate!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                    ),
                  ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
            if (_isExpanded) ...[
              if (summaryText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  summaryText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: MoneyfyPalette.secondaryText,
                    height: 1.45,
                  ),
                ),
              ],
              if (sortedIssues.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (var index = 0; index < sortedIssues.length; index++) ...[
                  _CompanyIssueRow(
                    issue: Map<String, dynamic>.from(
                      sortedIssues[index].map(
                        (key, value) => MapEntry('$key', value),
                      ),
                    ),
                  ),
                  if (index != sortedIssues.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
              if (outlook.isNotEmpty) ...[
                const SizedBox(height: 12),
                _CompanyOutlookRow(
                  label: '사업 영향',
                  value: '${outlook['business_impact'] ?? ''}'.trim(),
                ),
                const SizedBox(height: 8),
                _CompanyOutlookRow(
                  label: '시장 시각',
                  value: '${outlook['market_view'] ?? ''}'.trim(),
                ),
                const SizedBox(height: 8),
                _CompanyOutlookRow(
                  label: '체크 포인트',
                  value: '${outlook['watchpoint'] ?? ''}'.trim(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CompanyIssueRow extends StatelessWidget {
  const _CompanyIssueRow({required this.issue});

  final Map<String, dynamic> issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = '${issue['title'] ?? ''}'.trim();
    final summary = '${issue['summary'] ?? ''}'.trim();
    final importance = '${issue['importance'] ?? ''}'.trim();
    final importanceStyle = _companyImportanceStyle(importance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaces.surfaceRaised,
        borderRadius: BorderRadius.circular(context.radius.rMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 8, color: importanceStyle.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: importanceStyle.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    importanceStyle.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: importanceStyle.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          if (title.isNotEmpty && summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MoneyfyPalette.secondaryText,
                height: 1.45,
              ),
            ),
          ],
          if (title.isEmpty && summary.isNotEmpty)
            Text(
              summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MoneyfyPalette.secondaryText,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }
}

_CompanyIssueImportanceStyle _companyImportanceStyle(String value) {
  final numeric = int.tryParse(value);
  if (numeric == 3) {
    return const _CompanyIssueImportanceStyle(
      label: '높음',
      color: MoneyfyPalette.errorStrong,
      background: MoneyfyPalette.errorBg,
    );
  }
  if (numeric == 2) {
    return const _CompanyIssueImportanceStyle(
      label: '보통',
      color: MoneyfyPalette.warningStrong,
      background: Color(0xFFFFF3E0),
    );
  }
  if (numeric == 1) {
    return const _CompanyIssueImportanceStyle(
      label: '낮음',
      color: MoneyfyPalette.info,
      background: MoneyfyPalette.infoBg,
    );
  }
  return const _CompanyIssueImportanceStyle(
    label: '미정',
    color: MoneyfyPalette.tertiaryText,
    background: MoneyfyPalette.surface,
  );
}

class _CompanyIssueImportanceStyle {
  const _CompanyIssueImportanceStyle({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;
}

class _CompanyOutlookRow extends StatelessWidget {
  const _CompanyOutlookRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.secondaryText,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _companyInnerNewsCardDecoration(BuildContext context) {
  return BoxDecoration(
    color: context.surfaces.surfaceBase,
    borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
    boxShadow: context.shadows.level2,
  );
}
