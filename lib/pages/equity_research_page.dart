import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/chips/moneyfy_pill.dart';
import '../components/feedback/app_snackbar.dart';
import '../components/panels/app_inner_panel.dart';
import '../components/section_card.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../services/equity_research_service.dart';
import '../widgets/moneyfy_ui.dart';

class EquityResearchPage extends StatefulWidget {
  const EquityResearchPage({super.key});

  @override
  State<EquityResearchPage> createState() => _EquityResearchPageState();
}

class _EquityResearchPageState extends State<EquityResearchPage> {
  late Future<_EquityResearchPageData> _pageFuture;
  final TextEditingController _searchController = TextEditingController();
  int? _selectedReportId;
  String? _selectedTicker;
  DateTime? _selectedReportDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _pageFuture = _loadPageData();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<_EquityResearchPageData> _loadPageData() async {
    final reports = await EquityResearchService.instance.fetchReports();
    final selectedReport = _selectedReport(reports);
    final detail = selectedReport == null
        ? null
        : await EquityResearchService.instance.fetchReportDetail(
            selectedReport.id,
          );
    return _EquityResearchPageData(
      reports: reports,
      selectedReport: selectedReport,
      detail: detail,
    );
  }

  EquityResearchReportSummary? _selectedReport(
    List<EquityResearchReportSummary> reports,
  ) {
    final scopedReports = _filterReportsForScope(
      reports,
      ticker: _selectedTicker,
      reportDate: _selectedReportDate,
    );
    if (scopedReports.isEmpty) return null;
    final selectedId = _selectedReportId;
    if (selectedId != null) {
      for (final report in scopedReports) {
        if (report.id == selectedId) return report;
      }
    }
    _selectedReportId = scopedReports.first.id;
    return scopedReports.first;
  }

  Future<void> _reloadPage() async {
    final future = _loadPageData();
    setState(() {
      _pageFuture = future;
    });
    await future;
  }

  void _selectReport(int reportId) {
    if (_selectedReportId == reportId) return;
    setState(() {
      _selectedReportId = reportId;
      _pageFuture = _loadPageData();
    });
  }

  void _resetSearch() {
    setState(_searchController.clear);
  }

  void _selectTicker(
    String? ticker,
    List<EquityResearchReportSummary> reports,
  ) {
    _applyReportScope(
      ticker: ticker,
      reportDate: _selectedReportDate,
      reports: reports,
    );
  }

  void _selectReportDate(
    DateTime? reportDate,
    List<EquityResearchReportSummary> reports,
  ) {
    _applyReportScope(
      ticker: _selectedTicker,
      reportDate: reportDate,
      reports: reports,
    );
  }

  void _resetReportScope(List<EquityResearchReportSummary> reports) {
    _applyReportScope(ticker: null, reportDate: null, reports: reports);
  }

  void _applyReportScope({
    required String? ticker,
    required DateTime? reportDate,
    required List<EquityResearchReportSummary> reports,
  }) {
    final scopedReports = _filterReportsForScope(
      reports,
      ticker: ticker,
      reportDate: reportDate,
    );
    setState(() {
      _selectedTicker = ticker;
      _selectedReportDate = reportDate;
      _selectedReportId = scopedReports.isEmpty ? null : scopedReports.first.id;
      _pageFuture = _loadPageData();
    });
  }

  List<EquityResearchReportSummary> _filterReports(
    List<EquityResearchReportSummary> reports, {
    bool includeSearch = true,
  }) {
    final scopedReports = _filterReportsForScope(
      reports,
      ticker: _selectedTicker,
      reportDate: _selectedReportDate,
    );
    if (!includeSearch) return scopedReports;
    return scopedReports
        .where((report) => report.matches(_searchController.text))
        .toList(growable: false);
  }

  List<EquityResearchReportSummary> _filterReportsForScope(
    List<EquityResearchReportSummary> reports, {
    required String? ticker,
    required DateTime? reportDate,
  }) {
    return reports
        .where((report) {
          final matchesTicker = ticker == null || report.ticker == ticker;
          final matchesDate =
              reportDate == null || _sameDate(report.reportDate, reportDate);
          return matchesTicker && matchesDate;
        })
        .toList(growable: false);
  }

  List<String> _tickers(List<EquityResearchReportSummary> reports) {
    final values =
        reports
            .map((report) => report.ticker)
            .where((ticker) => ticker.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    return values;
  }

  List<DateTime> _reportDates(List<EquityResearchReportSummary> reports) {
    final seen = <String>{};
    final values = <DateTime>[];
    for (final report in reports) {
      final date = report.reportDate;
      if (date == null) continue;
      final normalized = DateTime(date.year, date.month, date.day);
      if (seen.add(_formatDate(normalized))) {
        values.add(normalized);
      }
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EquityResearchPageData>(
      future: _pageFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _EquityResearchPageData.empty();
        final reports = data.reports;
        final visibleReports = _filterReports(reports);
        final selectedReport = data.selectedReport;
        final detail = data.detail;

        return MoneyfyPage(
          title: '기업 리서치',
          subtitle: 'equity_research 스키마',
          onRefresh: _reloadPage,
          children: [
            _ResearchToolbar(
              totalCount: reports.length,
              visibleCount: visibleReports.length,
              searchController: _searchController,
              tickers: _tickers(reports),
              reportDates: _reportDates(reports),
              selectedTicker: _selectedTicker,
              selectedReportDate: _selectedReportDate,
              onTickerSelected: (ticker) => _selectTicker(ticker, reports),
              onReportDateSelected: (date) => _selectReportDate(date, reports),
              onReset: _resetSearch,
              onScopeReset: () => _resetReportScope(reports),
            ),
            SizedBox(height: context.spacing.sectionGap),
            if (snapshot.hasError)
              const _ResearchEmptyState(
                title: '리서치를 불러오지 못했어요',
                message: '로그인 상태, Supabase 노출 스키마, RLS 권한을 확인해 주세요.',
              )
            else if (snapshot.connectionState == ConnectionState.waiting &&
                selectedReport == null)
              const _ResearchLoadingState()
            else if (reports.isEmpty)
              const _ResearchEmptyState(
                title: '표시할 리포트가 없어요',
                message: 'equity_research.research_reports에 데이터가 쌓이면 표시됩니다.',
              )
            else if (visibleReports.isEmpty)
              const _ResearchEmptyState(
                title: '검색 결과가 없어요',
                message: '티커, 회사명, 결론 키워드를 조금 넓혀 보세요.',
              )
            else if (selectedReport != null && detail != null)
              _ResearchContent(
                reports: visibleReports,
                selectedReport: selectedReport,
                detail: detail,
                onReportSelected: _selectReport,
              ),
          ],
        );
      },
    );
  }
}

class _EquityResearchPageData {
  const _EquityResearchPageData({
    required this.reports,
    required this.selectedReport,
    required this.detail,
  });

  const _EquityResearchPageData.empty()
    : reports = const [],
      selectedReport = null,
      detail = null;

  final List<EquityResearchReportSummary> reports;
  final EquityResearchReportSummary? selectedReport;
  final EquityResearchReportDetail? detail;
}

class _ResearchContent extends StatelessWidget {
  const _ResearchContent({
    required this.reports,
    required this.selectedReport,
    required this.detail,
    required this.onReportSelected,
  });

  final List<EquityResearchReportSummary> reports;
  final EquityResearchReportSummary selectedReport;
  final EquityResearchReportDetail detail;
  final ValueChanged<int> onReportSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (reports.length > 1) ...[
          _ReportChoiceStrip(
            reports: reports,
            selectedReportId: selectedReport.id,
            onSelected: onReportSelected,
          ),
          SizedBox(height: context.spacing.md),
        ],
        _ReportOverviewCard(report: selectedReport, detail: detail),
        SizedBox(height: context.spacing.md),
        if (detail.metrics.isNotEmpty) ...[
          _MetricCard(metrics: detail.metrics),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.theses.isNotEmpty) ...[
          _ThesisCard(theses: detail.theses),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.valuationViews.isNotEmpty) ...[
          _ValuationCard(views: detail.valuationViews),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.risks.isNotEmpty) ...[
          _RiskCard(risks: detail.risks),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.catalysts.isNotEmpty) ...[
          _CatalystCard(catalysts: detail.catalysts),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.scenarios.isNotEmpty) ...[
          _ScenarioCard(scenarios: detail.scenarios),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.monitoringIndicators.isNotEmpty) ...[
          _MonitoringCard(indicators: detail.monitoringIndicators),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.sourceDocuments.isNotEmpty) ...[
          _SourceDocumentCard(documents: detail.sourceDocuments),
          SizedBox(height: context.spacing.md),
        ],
        if (detail.sections.isNotEmpty)
          _SectionDigestCard(sections: detail.sections),
      ],
    );
  }
}

class _ResearchToolbar extends StatelessWidget {
  const _ResearchToolbar({
    required this.totalCount,
    required this.visibleCount,
    required this.searchController,
    required this.tickers,
    required this.reportDates,
    required this.selectedTicker,
    required this.selectedReportDate,
    required this.onTickerSelected,
    required this.onReportDateSelected,
    required this.onReset,
    required this.onScopeReset,
  });

  final int totalCount;
  final int visibleCount;
  final TextEditingController searchController;
  final List<String> tickers;
  final List<DateTime> reportDates;
  final String? selectedTicker;
  final DateTime? selectedReportDate;
  final ValueChanged<String?> onTickerSelected;
  final ValueChanged<DateTime?> onReportDateSelected;
  final VoidCallback onReset;
  final VoidCallback onScopeReset;

  @override
  Widget build(BuildContext context) {
    final hasScope = selectedTicker != null || selectedReportDate != null;
    return SectionCard(
      dense: true,
      variant: SectionCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '리포트 ${visibleCount.toString()} / ${totalCount.toString()}',
                  style: context.typography.sectionTitle,
                ),
              ),
              MoneyfyBadge(
                label: 'remote',
                size: MoneyfyPillSize.sm,
                variant: MoneyfyPillVariant.outline,
                backgroundColor: context.colors.neutralSurfaceBase,
                textColor: context.colors.neutralTextMuted,
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: context.typography.body,
            decoration: InputDecoration(
              hintText: '티커, 회사명, 결론 검색',
              prefixIcon: const Icon(Icons.search_rounded, size: 24),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: onReset,
                      icon: const Icon(Icons.close_rounded),
                    ),
              isDense: true,
              filled: true,
              fillColor: context.colors.neutralSurfaceBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
                borderSide: BorderSide(color: context.colors.neutralOutline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
                borderSide: BorderSide(color: context.colors.neutralOutline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
                borderSide: BorderSide(color: context.colors.primary),
              ),
            ),
          ),
          SizedBox(height: context.spacing.sm),
          _FilterRow(
            children: [
              _ChoiceChip(
                label: '전체 심볼',
                selected: selectedTicker == null,
                onPressed: () => onTickerSelected(null),
              ),
              for (final ticker in tickers)
                _ChoiceChip(
                  label: ticker,
                  selected: selectedTicker == ticker,
                  onPressed: () => onTickerSelected(ticker),
                ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          _FilterRow(
            children: [
              _ChoiceChip(
                label: '전체 날짜',
                selected: selectedReportDate == null,
                onPressed: () => onReportDateSelected(null),
              ),
              for (final date in reportDates)
                _ChoiceChip(
                  label: _formatDate(date),
                  selected: _sameDate(selectedReportDate, date),
                  onPressed: () => onReportDateSelected(date),
                ),
            ],
          ),
          if (hasScope) ...[
            SizedBox(height: context.spacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onScopeReset,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
                  minimumSize: Size(0, context.spacing.xl),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('필터 초기화'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final child in children) ...[
            child,
            if (child != children.last) SizedBox(width: context.spacing.xs),
          ],
        ],
      ),
    );
  }
}

class _ReportChoiceStrip extends StatelessWidget {
  const _ReportChoiceStrip({
    required this.reports,
    required this.selectedReportId,
    required this.onSelected,
  });

  final List<EquityResearchReportSummary> reports;
  final int selectedReportId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final report in reports) ...[
            _ChoiceChip(
              label: _reportChoiceLabel(report),
              selected: report.id == selectedReportId,
              onPressed: () => onSelected(report.id),
            ),
            if (report != reports.last) SizedBox(width: context.spacing.xs),
          ],
        ],
      ),
    );
  }
}

class _ReportOverviewCard extends StatelessWidget {
  const _ReportOverviewCard({required this.report, required this.detail});

  final EquityResearchReportSummary report;
  final EquityResearchReportDetail detail;

  @override
  Widget build(BuildContext context) {
    final company = report.company;
    return SectionCard(
      variant: SectionCardVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              if (report.ticker.isNotEmpty)
                _Badge(report.ticker, tone: _BadgeTone.primary),
              if (company?.exchange.isNotEmpty ?? false)
                _Badge(company!.exchange),
              if (company?.sector.isNotEmpty ?? false) _Badge(company!.sector),
              if (report.reportDate != null)
                _Badge(_formatDate(report.reportDate!)),
              if (report.confidenceLevel.isNotEmpty)
                _Badge('신뢰도 ${report.confidenceLevel}'),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            report.displayTitle,
            style: context.typography.sectionTitle.copyWith(
              fontWeight: AppFontWeights.bold,
            ),
          ),
          if (report.companyName.isNotEmpty) ...[
            SizedBox(height: context.spacing.xs / 2),
            Text(
              report.companyName,
              style: context.typography.meta.copyWith(
                color: context.colors.neutralTextMuted,
              ),
            ),
          ],
          if (report.oneLineConclusion.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _CalloutBlock(
              icon: Icons.auto_awesome_rounded,
              title: '결론',
              body: report.oneLineConclusion,
            ),
          ],
          if (report.summary.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            Text(report.summary, style: context.typography.body),
          ],
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              _CountPill(label: '섹션', count: detail.sections.length),
              _CountPill(label: '논지', count: detail.theses.length),
              _CountPill(label: '리스크', count: detail.risks.length),
              _CountPill(label: '촉매', count: detail.catalysts.length),
              _CountPill(label: '출처', count: detail.sourceDocuments.length),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metrics});

  final List<EquityResearchMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '핵심 지표',
      variant: SectionCardVariant.outline,
      child: Wrap(
        spacing: context.spacing.sm,
        runSpacing: context.spacing.sm,
        children: [
          for (final metric in metrics.take(8))
            _MetricTile(
              title: metric.name,
              value: _metricValue(metric),
              meta: metric.fiscalPeriod,
            ),
        ],
      ),
    );
  }
}

class _ThesisCard extends StatelessWidget {
  const _ThesisCard({required this.theses});

  final List<EquityResearchThesis> theses;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '투자 논지',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final thesis in theses) ...[
            _TextItem(
              title: thesis.title,
              body: thesis.text,
              badges: [
                _labelForSide(thesis.side),
                if (thesis.importanceScore > 0) '중요도 ${thesis.importanceScore}',
              ],
              tone: _toneForSide(thesis.side),
            ),
            if (thesis != theses.last) SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ValuationCard extends StatelessWidget {
  const _ValuationCard({required this.views});

  final List<EquityResearchValuationView> views;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '밸류에이션',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final view in views) ...[
            _ValueItem(
              title: view.rating.isEmpty ? view.method : view.rating,
              subtitle: view.method,
              values: [
                if (view.targetPrice != null)
                  _InfoValue(
                    '목표가',
                    _formatMoney(view.targetPrice!, view.currency),
                  ),
                if (view.fairValue != null)
                  _InfoValue(
                    '공정가치',
                    _formatMoney(view.fairValue!, view.currency),
                  ),
                if (view.impliedUpsidePct != null)
                  _InfoValue('업사이드', _formatPercent(view.impliedUpsidePct!)),
              ],
              badge: view.stance,
            ),
            if (view != views.last) SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.risks});

  final List<EquityResearchRisk> risks;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '리스크',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final risk in risks) ...[
            _TextItem(
              title: risk.title,
              body: risk.description,
              badges: [
                risk.category,
                if (risk.probabilityLevel.isNotEmpty)
                  '확률 ${risk.probabilityLevel}',
                if (risk.impactLevel.isNotEmpty) '영향 ${risk.impactLevel}',
              ],
              footer: risk.mitigationOrWatchpoint,
              tone: _BadgeTone.warning,
            ),
            if (risk != risks.last) SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CatalystCard extends StatelessWidget {
  const _CatalystCard({required this.catalysts});

  final List<EquityResearchCatalyst> catalysts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '촉매',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final catalyst in catalysts) ...[
            _TextItem(
              title: catalyst.title,
              body: catalyst.description,
              badges: [
                catalyst.category,
                catalyst.expectedDirection,
                catalyst.expectedTiming,
              ],
              tone: _toneForDirection(catalyst.expectedDirection),
            ),
            if (catalyst != catalysts.last)
              SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenarios});

  final List<EquityResearchScenario> scenarios;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '시나리오',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final scenario in scenarios) ...[
            _TextItem(
              title: scenario.title.isEmpty ? scenario.name : scenario.title,
              body: scenario.summary,
              badges: [scenario.name],
              footer: scenario.expectedOutcome,
              tone: _toneForSide(scenario.name),
            ),
            if (scenario != scenarios.last)
              SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard({required this.indicators});

  final List<EquityResearchMonitoringIndicator> indicators;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '모니터링',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final indicator in indicators) ...[
            _TextItem(
              title: indicator.name,
              body: indicator.positiveSignal,
              badges: [indicator.area, indicator.checkFrequency],
              footer: indicator.negativeSignal,
              tone: _BadgeTone.neutral,
            ),
            if (indicator != indicators.last)
              SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SourceDocumentCard extends StatelessWidget {
  const _SourceDocumentCard({required this.documents});

  final List<EquityResearchSourceDocument> documents;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '출처 문서',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final document in documents) ...[
            _SourceDocumentRow(document: document),
            if (document != documents.last)
              SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SectionDigestCard extends StatelessWidget {
  const _SectionDigestCard({required this.sections});

  final List<EquityResearchSection> sections;

  @override
  Widget build(BuildContext context) {
    final topSections = sections
        .where((section) => section.parentSectionId == null)
        .take(10)
        .toList(growable: false);
    return SectionCard(
      title: '리포트 목차',
      variant: SectionCardVariant.outline,
      child: Column(
        children: [
          for (final section in topSections) ...[
            _TextItem(
              title: [
                if (section.sectionNo.isNotEmpty) section.sectionNo,
                section.title,
              ].join(' '),
              body: _excerpt(section.body),
              badges: [section.sectionType],
              tone: _BadgeTone.neutral,
            ),
            if (section != topSections.last)
              SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.meta,
  });

  final String title;
  final String value;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: AppInnerPanel(
        dense: true,
        tone: AppInnerPanelTone.base,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.typography.meta.copyWith(
                color: context.colors.neutralTextMuted,
              ),
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typography.cardTitle,
            ),
            if (meta.isNotEmpty) ...[
              SizedBox(height: context.spacing.xs / 2),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.meta.copyWith(
                  color: context.colors.neutralTextMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextItem extends StatelessWidget {
  const _TextItem({
    required this.title,
    required this.body,
    required this.badges,
    required this.tone,
    this.footer,
  });

  final String title;
  final String body;
  final List<String> badges;
  final String? footer;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BadgeWrap(labels: badges, tone: tone),
          if (badges.any((label) => label.trim().isNotEmpty))
            SizedBox(height: context.spacing.xs),
          Text(title, style: context.typography.cardTitle),
          if (body.isNotEmpty) ...[
            SizedBox(height: context.spacing.xs),
            Text(body, style: context.typography.body),
          ],
          if (footer != null && footer!.trim().isNotEmpty) ...[
            SizedBox(height: context.spacing.xs),
            Text(
              footer!,
              style: context.typography.meta.copyWith(
                color: context.colors.neutralTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  const _ValueItem({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final List<_InfoValue> values;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: context.typography.cardTitle)),
              if (badge.isNotEmpty)
                _Badge(badge, tone: _toneForDirection(badge)),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: context.spacing.xs / 2),
            Text(
              subtitle,
              style: context.typography.meta.copyWith(
                color: context.colors.neutralTextMuted,
              ),
            ),
          ],
          if (values.isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.xs,
              children: [
                for (final value in values)
                  _MiniValue(label: value.label, value: value.value),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceDocumentRow extends StatelessWidget {
  const _SourceDocumentRow({required this.document});

  final EquityResearchSourceDocument document;

  @override
  Widget build(BuildContext context) {
    final title = document.title.isEmpty ? document.sourceName : document.title;
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.radius.rMd),
        onTap: document.url.isEmpty
            ? null
            : () => _openUrl(context, document.url),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: context.spacing.xs,
                runSpacing: context.spacing.xs,
                children: [
                  if (document.publisher.isNotEmpty) _Badge(document.publisher),
                  if (document.qualityGrade.isNotEmpty)
                    _Badge('등급 ${document.qualityGrade}'),
                  if (document.publishedDate != null)
                    _Badge(_formatDate(document.publishedDate!)),
                ],
              ),
              SizedBox(height: context.spacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title, style: context.typography.cardTitle),
                  ),
                  if (document.url.isNotEmpty) ...[
                    SizedBox(width: context.spacing.xs),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: VisualSpec.icon.sizeDefault,
                      color: context.colors.neutralTextMuted,
                    ),
                  ],
                ],
              ),
              if (document.rating.isNotEmpty ||
                  document.priceTarget != null) ...[
                SizedBox(height: context.spacing.xs),
                Text(
                  [
                    if (document.rating.isNotEmpty) document.rating,
                    if (document.priceTarget != null)
                      _formatMoney(
                        document.priceTarget!,
                        document.priceTargetCurrency,
                      ),
                  ].join(' · '),
                  style: context.typography.meta.copyWith(
                    color: context.colors.neutralTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CalloutBlock extends StatelessWidget {
  const _CalloutBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.raised,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.typography.cardTitle),
                SizedBox(height: context.spacing.xs),
                Text(body, style: context.typography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  const _MiniValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.meta.copyWith(
            color: context.colors.neutralTextMuted,
          ),
        ),
        Text(value, style: context.typography.body),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return _Badge('$label $count');
  }
}

class _BadgeWrap extends StatelessWidget {
  const _BadgeWrap({required this.labels, required this.tone});

  final List<String> labels;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final visible = labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: context.spacing.xs,
      runSpacing: context.spacing.xs,
      children: [for (final label in visible) _Badge(label, tone: tone)],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.tone = _BadgeTone.neutral});

  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _badgeColors(context, tone);
    return MoneyfyBadge(
      label: label,
      size: MoneyfyPillSize.sm,
      variant: tone == _BadgeTone.neutral
          ? MoneyfyPillVariant.outline
          : MoneyfyPillVariant.tonal,
      backgroundColor: colors.background,
      textColor: colors.foreground,
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = MoneyfyPillStyle.resolve(
      context,
      size: MoneyfyPillSize.lg,
      tone: selected ? MoneyfyPillTone.primary : MoneyfyPillTone.neutral,
      variant: selected
          ? MoneyfyPillVariant.selected
          : MoneyfyPillVariant.outline,
    );
    return RawChip(
      avatar: selected
          ? Icon(Icons.check_rounded, size: 16, color: style.foreground)
          : null,
      label: Text(label),
      selected: selected,
      onPressed: onPressed,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: style.background,
      selectedColor: style.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radius),
      ),
      padding: style.padding,
      labelPadding: EdgeInsets.zero,
      side: BorderSide(color: style.border, width: style.borderWidth),
      labelStyle: style.textStyle,
    );
  }
}

class _ResearchLoadingState extends StatelessWidget {
  const _ResearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      variant: SectionCardVariant.outline,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ResearchEmptyState extends StatelessWidget {
  const _ResearchEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      variant: SectionCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.typography.sectionTitle),
          SizedBox(height: context.spacing.xs),
          Text(
            message,
            style: context.typography.body.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoValue {
  const _InfoValue(this.label, this.value);

  final String label;
  final String value;
}

class _BadgeColorPair {
  const _BadgeColorPair(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

enum _BadgeTone { neutral, primary, positive, warning, danger }

_BadgeTone _toneForSide(String side) {
  return switch (side.toLowerCase()) {
    'bull' => _BadgeTone.positive,
    'bear' => _BadgeTone.danger,
    'base' || 'neutral' => _BadgeTone.primary,
    _ => _BadgeTone.neutral,
  };
}

_BadgeTone _toneForDirection(String direction) {
  return switch (direction.toLowerCase()) {
    'positive' || 'very_positive' => _BadgeTone.positive,
    'negative' => _BadgeTone.danger,
    'mixed' => _BadgeTone.warning,
    _ => _BadgeTone.neutral,
  };
}

String _labelForSide(String side) {
  return switch (side.toLowerCase()) {
    'bull' => '상방',
    'bear' => '하방',
    'neutral' => '중립',
    'monitoring' => '관찰',
    _ => side,
  };
}

_BadgeColorPair _badgeColors(BuildContext context, _BadgeTone tone) {
  return switch (tone) {
    _BadgeTone.primary => _BadgeColorPair(
      context.colors.primary.withValues(alpha: 0.13),
      context.colors.primary,
    ),
    _BadgeTone.positive => _BadgeColorPair(
      context.colors.positiveContainer,
      context.colors.positiveOn,
    ),
    _BadgeTone.warning => _BadgeColorPair(
      context.colors.warningContainer,
      context.colors.warningOn,
    ),
    _BadgeTone.danger => _BadgeColorPair(
      context.colors.negativeContainer,
      context.colors.negativeOn,
    ),
    _BadgeTone.neutral => _BadgeColorPair(
      context.colors.neutralSurfaceBase,
      context.colors.neutralTextMuted,
    ),
  };
}

String _metricValue(EquityResearchMetric metric) {
  if (metric.text.isNotEmpty) return metric.text;
  final value = metric.value;
  if (value == null) return '-';
  final formatted = _formatNumber(value);
  final parts = [
    if (metric.currency.isNotEmpty) metric.currency,
    formatted,
    if (metric.unit.isNotEmpty) metric.unit,
  ];
  return parts.join(' ');
}

String _formatMoney(double value, String currency) {
  final prefix = currency.isEmpty ? '' : '$currency ';
  return '$prefix${_formatNumber(value)}';
}

String _formatPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(value.abs() >= 10 ? 0 : 1)}%';
}

String _formatNumber(double value) {
  if (value.abs() >= 1000) return value.toStringAsFixed(0);
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _reportChoiceLabel(EquityResearchReportSummary report) {
  final label = report.ticker.isEmpty ? report.displayTitle : report.ticker;
  final date = report.reportDate;
  if (date == null) return label;
  return '$label · ${_formatDate(date)}';
}

bool _sameDate(DateTime? left, DateTime? right) {
  if (left == null || right == null) return left == right;
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _excerpt(String body) {
  final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 180) return normalized;
  return '${normalized.substring(0, 180)}...';
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    AppSnackBar.showError(context, '링크를 열 수 없어요.', hasFloatingNavInset: true);
    return;
  }
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppSnackBar.showError(context, '링크를 열 수 없어요.', hasFloatingNavInset: true);
  }
}
