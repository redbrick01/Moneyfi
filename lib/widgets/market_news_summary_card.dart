import 'package:flutter/material.dart';

import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../services/market_news_summary_service.dart';
import '../theme/moneyfy_theme.dart';

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
    final theme = Theme.of(context);
    final summary = widget.summary;
    final hasDetails =
        summary != null &&
        (summary.issues.isNotEmpty || _hasOverallAssessment(summary));

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
              children: [
                Expanded(
                  child: Text(
                    '종합 뉴스',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 22),
                  ),
                ),
                if (summary?.newsCount != null)
                  Text(
                    '${summary!.newsCount}건',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: MoneyfyPalette.tertiaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (summary?.updatedAt != null ||
                (summary?.model ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (summary?.updatedAt != null)
                    Text(
                      '업데이트 ${_formatSummaryDate(summary!.updatedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                  if ((summary?.model ?? '').trim().isNotEmpty)
                    Text(
                      '(${summary!.model})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (summary == null)
              SizedBox(
                width: double.infinity,
                child: Text(
                  '표시할 마켓 뉴스 요약이 없습니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MoneyfyPalette.tertiaryText,
                  ),
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                decoration: _innerNewsCardDecoration(context),
                child: Text(
                  summary.marketSummary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    color: MoneyfyPalette.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              if (hasDetails) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        splashRadius: 16,
                        iconSize: 20,
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        tooltip: _isExpanded ? '세부 기사 요약 접기' : '세부 기사 요약 펼치기',
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                  ),
                ),
              ],
              if (_isExpanded && summary.issues.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (var index = 0; index < summary.issues.length; index++) ...[
                  _MarketIssueTile(item: summary.issues[index]),
                  if (index != summary.issues.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
              if (_isExpanded && _hasOverallAssessment(summary)) ...[
                const SizedBox(height: 16),
                _OverallAssessmentCard(summary: summary),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketIssueTile extends StatelessWidget {
  const _MarketIssueTile({required this.item});

  final MarketIssue item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final importanceStyle = _importanceStyle(item.importance);
    final impacts =
        <_ImpactRowData>[
              _ImpactRowData(label: '주식', value: item.stocks),
              _ImpactRowData(label: '채권/금리', value: item.bondsRates),
              _ImpactRowData(label: '환율', value: item.fx),
              _ImpactRowData(label: '암호화폐', value: item.crypto),
            ]
            .where(
              (entry) =>
                  (entry.value ?? '').trim().isNotEmpty &&
                  entry.value != 'null',
            )
            .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _innerNewsCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: importanceStyle.color,
                ),
              ),
              Expanded(
                child: Text(
                  _formatIssueTitle(item.title),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    color: MoneyfyPalette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: importanceStyle.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  importanceStyle.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: importanceStyle.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (item.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: MoneyfyPalette.secondaryText,
                height: 1.45,
              ),
            ),
          ],
          if (impacts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            for (final impact in impacts) ...[
              _ImpactRow(item: impact),
              if (impact != impacts.last) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _ImpactRowData {
  const _ImpactRowData({required this.label, required this.value});

  final String label;
  final String? value;
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.item});

  final _ImpactRowData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.surfaces.surfaceRaised,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: MoneyfyPalette.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.value ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: MoneyfyPalette.secondaryText,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverallAssessmentCard extends StatelessWidget {
  const _OverallAssessmentCard({required this.summary});

  final MarketNewsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _innerNewsCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '종합 평가',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: MoneyfyPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (summary.keyRisk.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _AssessmentBlock(label: '핵심 리스크', value: summary.keyRisk),
          ],
          if (summary.riskAssets.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _AssessmentBlock(label: '위험자산', value: summary.riskAssets),
          ],
          if (summary.safeAssets.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _AssessmentBlock(label: '안전자산', value: summary.safeAssets),
          ],
        ],
      ),
    );
  }
}

class _AssessmentBlock extends StatelessWidget {
  const _AssessmentBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: MoneyfyPalette.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: MoneyfyPalette.secondaryText,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

bool _hasOverallAssessment(MarketNewsSummary summary) {
  return summary.keyRisk.trim().isNotEmpty ||
      summary.riskAssets.trim().isNotEmpty ||
      summary.safeAssets.trim().isNotEmpty;
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

String _formatIssueTitle(String value) {
  final index = value.indexOf('(');
  if (index <= 0) {
    return value;
  }
  final head = value.substring(0, index).trimRight();
  final tail = value.substring(index).trimLeft();
  return '$head\n$tail';
}

Color _importanceColor(String value) {
  final normalized = value.trim();
  final numeric = int.tryParse(normalized);
  if (numeric == 3) return MoneyfyPalette.errorStrong;
  if (numeric == 2) return MoneyfyPalette.warningStrong;
  if (numeric == 1) return MoneyfyPalette.info;
  return MoneyfyPalette.tertiaryText;
}

_ImportanceStyle _importanceStyle(String value) {
  final color = _importanceColor(value);
  final numeric = int.tryParse(value.trim());
  if (numeric == 3) {
    return _ImportanceStyle(
      label: '높음',
      color: color,
      background: MoneyfyPalette.errorBg,
    );
  }
  if (numeric == 2) {
    return _ImportanceStyle(
      label: '보통',
      color: color,
      background: const Color(0xFFFFF3E0),
    );
  }
  if (numeric == 1) {
    return _ImportanceStyle(
      label: '낮음',
      color: color,
      background: MoneyfyPalette.infoBg,
    );
  }
  return _ImportanceStyle(
    label: '미정',
    color: MoneyfyPalette.tertiaryText,
    background: MoneyfyPalette.surface,
  );
}

class _ImportanceStyle {
  const _ImportanceStyle({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;
}

BoxDecoration _innerNewsCardDecoration(BuildContext context) {
  return BoxDecoration(
    color: context.surfaces.surfaceBase,
    borderRadius: BorderRadius.circular(VisualSpec.surface.radiusCard),
    boxShadow: context.shadows.level2,
  );
}
