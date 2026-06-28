import 'package:flutter/material.dart';

import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/components/panels/app_inner_panel.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/features/analysis/services/company_news_summary_service.dart';

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
    final reportParagraphs = _companyReportParagraphs(sortedIssues);
    final collapsedTitle = summaryText.isNotEmpty
        ? summaryText
        : sortedIssues.isNotEmpty
        ? '${sortedIssues.first['title'] ?? ''}'.trim()
        : item.symbol;

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
                AppInnerPanel(
                  dense: true,
                  tone: AppInnerPanelTone.raised,
                  showBorder: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompanyReportSectionLabel(label: '핵심 결론'),
                      SizedBox(height: context.spacing.xs),
                      Text(
                        summaryText,
                        style: context.typography.body.copyWith(
                          color: context.colors.neutralText,
                          fontWeight: AppFontWeights.semibold,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (reportParagraphs.isNotEmpty) ...[
                SizedBox(height: context.spacing.sm),
                _CompanyReportBodyPanel(paragraphs: reportParagraphs),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CompanyReportBodyPanel extends StatelessWidget {
  const _CompanyReportBodyPanel({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.raised,
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompanyReportSectionLabel(label: '리포트 본문'),
          SizedBox(height: context.spacing.xs),
          for (var index = 0; index < paragraphs.length; index++) ...[
            Text(
              paragraphs[index],
              style: context.typography.body.copyWith(
                color: context.colors.neutralTextMuted,
                height: 1.55,
              ),
            ),
            if (index != paragraphs.length - 1)
              SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CompanyReportSectionLabel extends StatelessWidget {
  const _CompanyReportSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.typography.caption.copyWith(
        color: context.colors.neutralTextMuted,
        fontWeight: AppFontWeights.semibold,
      ),
    );
  }
}

List<String> _companyReportParagraphs(List<Map> issues) {
  final rawText = issues
      .map((issue) => '${issue['summary'] ?? ''}'.trim())
      .where((value) => value.isNotEmpty)
      .join('\n\n');
  return _splitCompanyReportParagraphs(rawText);
}

List<String> _splitCompanyReportParagraphs(String value) {
  return value
      .split(RegExp(r'\n\s*\n'))
      .map((paragraph) => paragraph.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList(growable: false);
}
