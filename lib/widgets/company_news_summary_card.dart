import 'package:flutter/material.dart';

import '../components/chips/moneyfy_pill.dart';
import '../components/panels/app_inner_panel.dart';
import '../components/section_card.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../services/company_news_summary_service.dart';

class CompanyNewsSummaryCard extends StatelessWidget {
  const CompanyNewsSummaryCard({
    required this.items,
    this.title = '종목별 뉴스',
    this.emptyMessage =
        '종목 뉴스 요약을 불러오지 못했어요. 저장된 캐시가 없거나 외부 API가 일시적으로 응답하지 않습니다.',
    super.key,
  });

  final List<CompanyNewsSummaryItem> items;
  final String title;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
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

    return SectionCard(
      variant: SectionCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(title, style: context.typography.sectionTitle),
              ),
              if (hasHeaderMeta)
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (latestSummaryDate != null)
                        Flexible(
                          child: Text(
                            latestSummaryDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: context.typography.caption.copyWith(
                              color: context.colors.neutralTextMuted,
                            ),
                          ),
                        ),
                      if (latestSummaryDate != null && latestModel != null)
                        SizedBox(width: context.spacing.xs),
                      if (latestModel != null)
                        Flexible(
                          child: Text(
                            latestModel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: context.typography.caption.copyWith(
                              color: context.colors.neutralTextMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          if (items.isEmpty)
            SizedBox(
              width: double.infinity,
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: context.typography.body.copyWith(
                  color: context.colors.neutralTextMuted,
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
                  SizedBox(height: context.spacing.sm),
              ],
              if (sectionIndex != sections.length - 1)
                SizedBox(height: context.spacing.md + context.spacing.xs / 4),
            ],
        ],
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
      borderRadius: BorderRadius.circular(context.radius.rMd),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AppInnerPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MoneyfyBadge(
                  label: item.symbol,
                  size: MoneyfyPillSize.sm,
                  backgroundColor: context.surfaces.surfaceRaised,
                  textColor: context.colors.neutralText,
                ),
                SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
                Expanded(
                  child: Text(
                    collapsedTitle.isEmpty ? item.symbol : collapsedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.cardTitle.copyWith(
                      color: context.colors.neutralText,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                ),
                SizedBox(width: context.spacing.xs),
                if ((item.summaryDate ?? '').isNotEmpty)
                  Text(
                    item.summaryDate!,
                    style: context.typography.caption.copyWith(
                      color: context.colors.neutralTextMuted,
                    ),
                  ),
                SizedBox(width: context.spacing.xs / 2),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: context.motion.fast,
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
            if (_isExpanded) ...[
              if (summaryText.isNotEmpty) ...[
                SizedBox(height: context.spacing.sm),
                Text(
                  summaryText,
                  style: context.typography.body.copyWith(
                    color: context.colors.neutralTextMuted,
                    height: 1.45,
                  ),
                ),
              ],
              if (sortedIssues.isNotEmpty) ...[
                SizedBox(height: context.spacing.sm),
                for (var index = 0; index < sortedIssues.length; index++) ...[
                  _CompanyIssueRow(
                    issue: Map<String, dynamic>.from(
                      sortedIssues[index].map(
                        (key, value) => MapEntry('$key', value),
                      ),
                    ),
                  ),
                  if (index != sortedIssues.length - 1)
                    SizedBox(
                      height: context.spacing.xs + context.spacing.xs / 4,
                    ),
                ],
              ],
              if (outlook.isNotEmpty) ...[
                SizedBox(height: context.spacing.sm),
                _CompanyOutlookRow(
                  label: '사업 영향',
                  value: '${outlook['business_impact'] ?? ''}'.trim(),
                ),
                SizedBox(height: context.spacing.xs),
                _CompanyOutlookRow(
                  label: '시장 시각',
                  value: '${outlook['market_view'] ?? ''}'.trim(),
                ),
                SizedBox(height: context.spacing.xs),
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
    final title = '${issue['title'] ?? ''}'.trim();
    final summary = '${issue['summary'] ?? ''}'.trim();
    final importance = '${issue['importance'] ?? ''}'.trim();
    final importanceStyle = _companyImportanceStyle(context, importance);

    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.raised,
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: VisualSpec.icon.chipIcon / 2,
                  color: importanceStyle.color,
                ),
                SizedBox(width: context.spacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: context.typography.body.copyWith(
                      color: context.colors.neutralText,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                ),
                MoneyfyBadge(
                  label: importanceStyle.label,
                  size: MoneyfyPillSize.sm,
                  backgroundColor: importanceStyle.background,
                  textColor: importanceStyle.color,
                ),
              ],
            ),
          if (title.isNotEmpty && summary.isNotEmpty) ...[
            SizedBox(height: context.spacing.xs - context.spacing.xs / 4),
            Text(
              summary,
              style: context.typography.caption.copyWith(
                color: context.colors.neutralTextMuted,
                height: 1.45,
              ),
            ),
          ],
          if (title.isEmpty && summary.isNotEmpty)
            Text(
              summary,
              style: context.typography.caption.copyWith(
                color: context.colors.neutralTextMuted,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }
}

_CompanyIssueImportanceStyle _companyImportanceStyle(
  BuildContext context,
  String value,
) {
  final numeric = int.tryParse(value);
  if (numeric == 3) {
    return _CompanyIssueImportanceStyle(
      label: '높음',
      color: context.colors.negativeOn,
      background: context.colors.neutralSurfaceBase,
    );
  }
  if (numeric == 2) {
    return _CompanyIssueImportanceStyle(
      label: '보통',
      color: context.colors.warningOn,
      background: context.colors.neutralSurfaceBase,
    );
  }
  if (numeric == 1) {
    return _CompanyIssueImportanceStyle(
      label: '낮음',
      color: context.colors.primary,
      background: context.colors.neutralSurfaceBase,
    );
  }
  return _CompanyIssueImportanceStyle(
    label: '미정',
    color: context.colors.neutralTextMuted,
    background: context.colors.neutralSurfaceBase,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.spacing.xxxl - context.spacing.xs + 2,
          child: Text(
            label,
            style: context.typography.caption.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.typography.caption.copyWith(
              color: context.colors.neutralTextMuted,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
