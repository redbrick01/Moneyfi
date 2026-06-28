import 'package:flutter/material.dart';

import 'package:moneyfy/components/panels/app_inner_panel.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/features/analysis/services/market_news_summary_service.dart';

Future<MarketNewsSummary?> fetchMarketNewsSummary({
  String category = 'general',
  String? summaryDate,
  bool forceRefresh = false,
}) async {
  final response = await MarketNewsSummaryService.instance.fetchSummary(
    category: category,
    summaryDate: summaryDate,
    forceRefresh: forceRefresh,
  );
  if (response == null || !response.found) {
    return null;
  }

  return MarketNewsSummary.fromJson(
    response.summary,
    model: response.model,
    newsCount: response.newsCount,
    updatedAt: response.updatedAt,
  );
}

class MarketNewsSummary {
  const MarketNewsSummary({
    required this.marketSummary,
    required this.issues,
    required this.keyRisk,
    required this.riskAssets,
    required this.safeAssets,
    this.model,
    this.newsCount,
    this.updatedAt,
  });

  factory MarketNewsSummary.fromJson(
    Map<String, dynamic>? json, {
    String? model,
    int? newsCount,
    String? updatedAt,
  }) {
    final payload = json ?? const <String, dynamic>{};
    final overall = payload['overall_assessment'] is Map
        ? Map<String, dynamic>.from(
            (payload['overall_assessment'] as Map).map(
              (key, value) => MapEntry('$key', value),
            ),
          )
        : const <String, dynamic>{};
    final issues = payload['issues'] is List
        ? (payload['issues'] as List)
              .whereType<Map>()
              .map(
                (row) => MarketIssue.fromJson(
                  row.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList(growable: false)
        : const <MarketIssue>[];
    final sortedIssues = [...issues]
      ..sort((a, b) {
        final aValue = int.tryParse(a.importance.trim()) ?? 0;
        final bValue = int.tryParse(b.importance.trim()) ?? 0;
        return bValue.compareTo(aValue);
      });

    return MarketNewsSummary(
      marketSummary: '${payload['market_summary'] ?? ''}',
      issues: sortedIssues,
      keyRisk: '${overall['key_risk'] ?? ''}',
      riskAssets: '${overall['risk_assets'] ?? ''}',
      safeAssets: '${overall['safe_assets'] ?? ''}',
      model: model,
      newsCount: newsCount,
      updatedAt: updatedAt,
    );
  }

  final String marketSummary;
  final List<MarketIssue> issues;
  final String keyRisk;
  final String riskAssets;
  final String safeAssets;
  final String? model;
  final int? newsCount;
  final String? updatedAt;
}

class MarketIssue {
  const MarketIssue({
    required this.title,
    required this.summary,
    required this.importance,
    required this.stocks,
    required this.bondsRates,
    required this.fx,
    required this.crypto,
  });

  factory MarketIssue.fromJson(Map<String, dynamic> json) {
    final marketImpact = json['market_impact'] is Map
        ? Map<String, dynamic>.from(
            (json['market_impact'] as Map).map(
              (key, value) => MapEntry('$key', value),
            ),
          )
        : const <String, dynamic>{};

    return MarketIssue(
      title: '${json['title'] ?? ''}',
      summary: '${json['summary'] ?? ''}',
      importance: '${json['importance'] ?? ''}',
      stocks: marketImpact['stocks']?.toString(),
      bondsRates: marketImpact['bonds_rates']?.toString(),
      fx: marketImpact['fx']?.toString(),
      crypto: marketImpact['crypto']?.toString(),
    );
  }

  final String title;
  final String summary;
  final String importance;
  final String? stocks;
  final String? bondsRates;
  final String? fx;
  final String? crypto;
}

class MarketNewsSummaryCard extends StatefulWidget {
  const MarketNewsSummaryCard({required this.summary, super.key});

  final MarketNewsSummary? summary;

  @override
  State<MarketNewsSummaryCard> createState() => _MarketNewsSummaryCardState();
}

class _MarketNewsSummaryCardState extends State<MarketNewsSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final reportParagraphs = summary == null
        ? const <String>[]
        : _marketReportParagraphs(summary);
    final canExpand = reportParagraphs.isNotEmpty;

    return SectionCard(
      variant: SectionCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('종합 뉴스', style: context.typography.sectionTitle),
              ),
              if (summary?.newsCount != null)
                Text(
                  '${summary!.newsCount}건',
                  style: context.typography.caption.copyWith(
                    color: context.colors.neutralTextMuted,
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
            ],
          ),
          if (summary?.updatedAt != null ||
              (summary?.model ?? '').trim().isNotEmpty) ...[
            SizedBox(height: context.spacing.xs - context.spacing.xs / 4),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs / 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (summary?.updatedAt != null)
                  Text(
                    '업데이트 ${_formatSummaryDate(summary!.updatedAt!)}',
                    style: context.typography.caption.copyWith(
                      color: context.colors.neutralTextMuted,
                    ),
                  ),
                if ((summary?.model ?? '').trim().isNotEmpty)
                  Text(
                    '(${summary!.model})',
                    style: context.typography.caption.copyWith(
                      color: context.colors.neutralTextMuted,
                    ),
                  ),
              ],
            ),
          ],
          SizedBox(height: context.spacing.md),
          if (summary == null)
            SizedBox(
              width: double.infinity,
              child: Text(
                '시장 뉴스 요약을 불러오지 못했어요. 저장된 캐시가 없거나 외부 API가 일시적으로 응답하지 않습니다.',
                textAlign: TextAlign.center,
                style: context.typography.body.copyWith(
                  color: context.colors.neutralTextMuted,
                ),
              ),
            )
          else ...[
            if (summary.marketSummary.trim().isNotEmpty) ...[
              AppInnerPanel(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.sm + context.spacing.xs / 4,
                  vertical: context.spacing.md + context.spacing.xs / 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReportSectionLabel(label: '핵심 결론'),
                    SizedBox(height: context.spacing.xs),
                    Text(
                      summary.marketSummary,
                      style: context.typography.cardTitle.copyWith(
                        color: context.colors.neutralText,
                        fontWeight: AppFontWeights.semibold,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isExpanded && reportParagraphs.isNotEmpty) ...[
              SizedBox(height: context.spacing.sm),
              _ReportBodyPanel(paragraphs: reportParagraphs),
            ],
            if (canExpand) ...[
              SizedBox(height: context.spacing.xs),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: context.motion.fast,
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  label: Text(_isExpanded ? '리포트 접기' : '전체 리포트 보기'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportBodyPanel extends StatelessWidget {
  const _ReportBodyPanel({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      tone: AppInnerPanelTone.raised,
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportSectionLabel(label: '리포트 본문'),
          SizedBox(height: context.spacing.sm),
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

class _ReportSectionLabel extends StatelessWidget {
  const _ReportSectionLabel({required this.label});

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

List<String> _marketReportParagraphs(MarketNewsSummary summary) {
  final rawText = summary.issues
      .map((issue) => issue.summary.trim())
      .where((value) => value.isNotEmpty)
      .join('\n\n');
  final fallback = summary.marketSummary.trim();
  return _splitReportParagraphs(rawText.isEmpty ? fallback : rawText);
}

List<String> _splitReportParagraphs(String value) {
  return value
      .split(RegExp(r'\n\s*\n'))
      .map((paragraph) => paragraph.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList(growable: false);
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
