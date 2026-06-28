import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/components/feedback/app_snackbar.dart';
import 'package:moneyfy/components/panels/app_inner_panel.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/empty_state.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/analysis/services/equity_research_metric_presenter.dart';
import 'package:moneyfy/features/analysis/services/equity_research_service.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';

class EquityResearchPage extends StatefulWidget {
  const EquityResearchPage({super.key, this.initialTicker});

  final String? initialTicker;

  @override
  State<EquityResearchPage> createState() => _EquityResearchPageState();
}

class _EquityResearchPageState extends State<EquityResearchPage> {
  late Future<_EquityResearchPageData> _pageFuture;
  final TextEditingController _searchController = TextEditingController();
  int? _selectedReportId;
  String? _selectedTicker;
  DateTime? _selectedReportDate;
  bool _showResearchFilters = false;

  bool get _isTickerScopedEntry =>
      (widget.initialTicker?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    final initialTicker = widget.initialTicker?.trim().toUpperCase();
    if (initialTicker != null && initialTicker.isNotEmpty) {
      _selectedTicker = initialTicker;
    }
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
    setState(() {
      _selectedReportId = null;
      _pageFuture = _loadPageData();
    });
  }

  Future<_EquityResearchPageData> _loadPageData() async {
    final results = await Future.wait<Object>([
      EquityResearchService.instance.fetchReports(),
      _fetchHoldingTickers(),
    ]);
    final reports = results[0] as List<EquityResearchReportSummary>;
    final holdingTickers = results[1] as Set<String>;
    final selectedReport = _selectedReport(reports, holdingTickers);
    final detail = selectedReport == null
        ? null
        : await EquityResearchService.instance.fetchReportDetail(
            selectedReport.id,
          );
    final currentPrice = selectedReport == null
        ? null
        : await _fetchCurrentPrice(selectedReport.ticker);
    return _EquityResearchPageData(
      reports: reports,
      holdingTickers: holdingTickers,
      selectedReport: selectedReport,
      detail: detail,
      currentPrice: currentPrice,
    );
  }

  Future<Set<String>> _fetchHoldingTickers() async {
    final symbolAssetTypes = await AppDatabase.instance
        .fetchVisibleHoldingSymbolAssetTypes();
    return symbolAssetTypes.keys
        .map((ticker) => ticker.trim().toUpperCase())
        .where((ticker) => ticker.isNotEmpty)
        .toSet();
  }

  Future<_ResearchPriceSnapshot?> _fetchCurrentPrice(String ticker) async {
    final normalizedTicker = ticker.trim().toUpperCase();
    if (normalizedTicker.isEmpty) return null;
    final assets = await AppDatabase.instance.fetchAssets();
    for (final asset in assets) {
      if (asset.isHidden) continue;
      for (final holding in asset.holdings) {
        if (holding.isHidden || holding.quantity <= 0) continue;
        if (holding.symbol.trim().toUpperCase() != normalizedTicker) continue;
        if (holding.currentPrice <= 0) return null;
        return _ResearchPriceSnapshot(
          value: holding.currentPrice,
          currency: holding.currencyCode,
        );
      }
    }
    return null;
  }

  EquityResearchReportSummary? _selectedReport(
    List<EquityResearchReportSummary> reports,
    Set<String> holdingTickers,
  ) {
    final visibleReports = _filterReports(
      reports,
      holdingTickers: holdingTickers,
    );
    if (visibleReports.isEmpty) return null;
    final selectedId = _selectedReportId;
    if (selectedId != null) {
      for (final report in visibleReports) {
        if (report.id == selectedId) return report;
      }
    }
    _selectedReportId = visibleReports.first.id;
    return visibleReports.first;
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
    _searchController.clear();
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

  void _resetResearchControls(List<EquityResearchReportSummary> reports) {
    _searchController.clear();
    _applyReportScope(ticker: null, reportDate: null, reports: reports);
  }

  void _toggleResearchFilters() {
    setState(() {
      _showResearchFilters = !_showResearchFilters;
    });
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
    required Set<String> holdingTickers,
    bool includeSearch = true,
  }) {
    final query = _searchController.text.trim();
    final usesSearch = includeSearch && query.isNotEmpty;
    final shouldUseDefaultHoldings =
        !_isTickerScopedEntry &&
        selectedTickerIsDefault &&
        _selectedReportDate == null &&
        !usesSearch;

    final scopedReports = shouldUseDefaultHoldings
        ? reports
              .where((report) => holdingTickers.contains(report.ticker))
              .toList(growable: false)
        : _filterReportsForScope(
            reports,
            ticker: _selectedTicker,
            reportDate: _selectedReportDate,
          );
    if (!includeSearch) return scopedReports;
    return scopedReports
        .where((report) => report.matches(query))
        .toList(growable: false);
  }

  bool get selectedTickerIsDefault => _selectedTicker == null;

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
        final visibleReports = _filterReports(
          reports,
          holdingTickers: data.holdingTickers,
        );
        final hasSearchQuery = _searchController.text.trim().isNotEmpty;
        final selectedReport = data.selectedReport;
        final detail = data.detail;

        return MoneyfyPage(
          title: '기업 리서치',
          onRefresh: _reloadPage,
          children: [
            if (!_isTickerScopedEntry) ...[
              _ResearchToolbar(
                totalCount: reports.length,
                visibleCount: visibleReports.length,
                searchController: _searchController,
                tickers: _tickers(reports),
                reportDates: _reportDates(reports),
                selectedTicker: _selectedTicker,
                selectedReportDate: _selectedReportDate,
                showFilters: _showResearchFilters,
                onFilterPressed: _toggleResearchFilters,
                onTickerSelected: (ticker) => _selectTicker(ticker, reports),
                onReportDateSelected: (date) =>
                    _selectReportDate(date, reports),
                onReset: _resetSearch,
                onResetAll: () => _resetResearchControls(reports),
              ),
              SizedBox(height: context.spacing.sectionGap),
            ],
            if (snapshot.hasError)
              const _ResearchEmptyState(
                title: '리서치를 불러오지 못했어요',
                message: '로그인 상태, Supabase 노출 스키마, RLS 권한을 확인해 주세요.',
              )
            else if (snapshot.connectionState == ConnectionState.waiting &&
                selectedReport == null)
              const _ResearchLoadingState()
            else if (reports.isEmpty)
              _ResearchEmptyState(
                title: '표시할 리포트가 없어요',
                message: _isTickerScopedEntry
                    ? '${_selectedTicker ?? ''} 리포트가 생성되면 여기에 표시됩니다.'
                    : 'equity_research.research_reports에 데이터가 쌓이면 표시됩니다.',
              )
            else if (visibleReports.isEmpty)
              _ResearchEmptyState(
                title: hasSearchQuery
                    ? '검색 결과가 없어요'
                    : _isTickerScopedEntry
                    ? '${_selectedTicker ?? ''} 리포트가 없어요'
                    : '보유 종목 리포트가 없어요',
                message: hasSearchQuery
                    ? '티커, 회사명, 결론 키워드를 조금 넓혀 보세요.'
                    : _isTickerScopedEntry
                    ? '${_selectedTicker ?? ''}에 연결된 리포트가 아직 없습니다.'
                    : '검색어를 입력하면 보유하지 않은 종목의 리포트도 확인할 수 있어요.',
              )
            else if (selectedReport != null && detail != null)
              _ResearchContent(
                reports: visibleReports,
                selectedReport: selectedReport,
                detail: detail,
                currentPrice: data.currentPrice,
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
    required this.holdingTickers,
    required this.selectedReport,
    required this.detail,
    required this.currentPrice,
  });

  const _EquityResearchPageData.empty()
    : reports = const [],
      holdingTickers = const {},
      selectedReport = null,
      detail = null,
      currentPrice = null;

  final List<EquityResearchReportSummary> reports;
  final Set<String> holdingTickers;
  final EquityResearchReportSummary? selectedReport;
  final EquityResearchReportDetail? detail;
  final _ResearchPriceSnapshot? currentPrice;
}

class _ResearchContent extends StatelessWidget {
  const _ResearchContent({
    required this.reports,
    required this.selectedReport,
    required this.detail,
    required this.currentPrice,
    required this.onReportSelected,
  });

  final List<EquityResearchReportSummary> reports;
  final EquityResearchReportSummary selectedReport;
  final EquityResearchReportDetail detail;
  final _ResearchPriceSnapshot? currentPrice;
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
        _ReportOverviewCard(report: selectedReport),
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
          _ValuationCard(
            views: detail.valuationViews,
            currentPrice: currentPrice,
          ),
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
    required this.showFilters,
    required this.onFilterPressed,
    required this.onTickerSelected,
    required this.onReportDateSelected,
    required this.onReset,
    required this.onResetAll,
  });

  final int totalCount;
  final int visibleCount;
  final TextEditingController searchController;
  final List<String> tickers;
  final List<DateTime> reportDates;
  final String? selectedTicker;
  final DateTime? selectedReportDate;
  final bool showFilters;
  final VoidCallback onFilterPressed;
  final ValueChanged<String?> onTickerSelected;
  final ValueChanged<DateTime?> onReportDateSelected;
  final VoidCallback onReset;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasScope = selectedTicker != null || selectedReportDate != null;
    final activeFilterCount =
        (selectedTicker == null ? 0 : 1) + (selectedReportDate == null ? 0 : 1);
    final summary = _researchActiveFilterSummary(
      query: searchController.text,
      selectedTicker: selectedTicker,
      selectedReportDate: selectedReportDate,
      visibleCount: visibleCount,
      totalCount: totalCount,
    );
    return SectionCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  style: context.typography.body,
                  decoration: InputDecoration(
                    hintText: '리포트 검색',
                    prefixIcon: const Icon(Icons.search_rounded, size: 24),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: context.spacing.xl + context.spacing.sm,
                      minHeight: context.spacing.xxl,
                    ),
                    suffixIcon: searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            onPressed: onReset,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    suffixIconConstraints: BoxConstraints(
                      minWidth: context.spacing.xxl,
                      minHeight: context.spacing.xxl,
                    ),
                    constraints: BoxConstraints(
                      minHeight: context.spacing.xxl,
                      maxHeight: context.spacing.xxl,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.spacing.sm,
                      vertical: context.spacing.sm,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.spacing.xs),
              _ResearchFilterButton(
                activeCount: activeFilterCount,
                expanded: showFilters || hasScope,
                onPressed: onFilterPressed,
              ),
            ],
          ),
          if (showFilters || hasScope) ...[
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
          ],
          if (summary != null) ...[
            SizedBox(height: context.spacing.sm),
            _ResearchActiveFilterSummary(summary: summary, onReset: onResetAll),
          ],
        ],
      ),
    );
  }
}

class _ResearchFilterButton extends StatelessWidget {
  const _ResearchFilterButton({
    required this.activeCount,
    required this.expanded,
    required this.onPressed,
  });

  final int activeCount;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = activeCount > 0;
    return Semantics(
      button: true,
      label: '리포트 필터',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              expanded ? Icons.expand_less_rounded : Icons.tune_rounded,
              size: 20,
            ),
            label: const Text('필터'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, context.spacing.xxl),
              padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
              foregroundColor: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              side: BorderSide(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
              ),
            ),
          ),
          if (isActive)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: VisualSpec.icon.sizeBadge - context.spacing.xs / 4,
                  minHeight: VisualSpec.icon.sizeBadge - context.spacing.xs / 4,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xs - context.spacing.xs / 4,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(context.radius.rPill),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Text(
                  '$activeCount',
                  style: context.typography.meta.copyWith(
                    color: colorScheme.onPrimary,
                    fontSize: context.fontSizes.s12,
                    fontWeight: AppFontWeights.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResearchActiveFilterSummary extends StatelessWidget {
  const _ResearchActiveFilterSummary({
    required this.summary,
    required this.onReset,
  });

  final String summary;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.meta.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: context.spacing.xs),
        TextButton(
          onPressed: onReset,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
            minimumSize: Size(0, context.spacing.xl),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('초기화'),
        ),
      ],
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
  const _ReportOverviewCard({required this.report});

  final EquityResearchReportSummary report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      variant: SectionCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              if (report.ticker.isNotEmpty)
                _Badge(report.ticker, tone: _BadgeTone.primary),
              if (report.reportDate != null)
                _Badge(_formatDate(report.reportDate!)),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            _heroReportTitle(report),
            style: context.typography.sectionTitle.copyWith(
              fontWeight: AppFontWeights.bold,
            ),
          ),
          if (report.oneLineConclusion.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _CalloutBlock(body: report.oneLineConclusion),
          ],
          if (report.summary.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            Text(report.summary, style: context.typography.body),
          ],
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
    final presentedMetrics = metrics
        .take(8)
        .map(presentEquityResearchMetric)
        .toList(growable: false);
    final numericMetrics = presentedMetrics
        .where((metric) => !metric.isTextOnly)
        .toList(growable: false);
    final textMetrics = presentedMetrics
        .where((metric) => metric.isTextOnly)
        .toList(growable: false);

    return SectionCard(
      title: '핵심 지표',
      variant: SectionCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (numericMetrics.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = context.spacing.sm;
                final columnCount = constraints.maxWidth < 300 ? 1 : 2;
                final tileWidth =
                    (constraints.maxWidth - (gap * (columnCount - 1))) /
                    columnCount;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final metric in numericMetrics)
                      _MetricTile(
                        width: tileWidth,
                        title: metric.label,
                        value: metric.value,
                      ),
                  ],
                );
              },
            ),
          if (numericMetrics.isNotEmpty && textMetrics.isNotEmpty)
            SizedBox(height: context.spacing.sm),
          for (final metric in textMetrics) ...[
            _MetricTextPanel(metric: metric),
            if (metric != textMetrics.last)
              SizedBox(height: context.spacing.sm),
          ],
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
      variant: SectionCardVariant.base,
      child: Column(
        children: [
          for (final thesis in theses) ...[
            _TextItem(
              title: thesis.title,
              body: thesis.text,
              badges: const [],
              tone: _toneForSide(thesis.side),
              titleBadge: thesis.importanceScore > 0
                  ? '${thesis.importanceScore}'
                  : null,
              titleBadgeTone: _toneForSide(thesis.side),
            ),
            if (thesis != theses.last) SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ValuationCard extends StatelessWidget {
  const _ValuationCard({required this.views, required this.currentPrice});

  final List<EquityResearchValuationView> views;
  final _ResearchPriceSnapshot? currentPrice;

  @override
  Widget build(BuildContext context) {
    final groups = _valuationGroups(views);
    final analysisPrice = _analysisPrice(views);
    return SectionCard(
      title: '밸류에이션',
      variant: SectionCardVariant.base,
      child: Column(
        children: [
          if (currentPrice != null || analysisPrice != null) ...[
            _ValuationCurrentPricePanel(
              currentPrice: currentPrice,
              analysisPrice: analysisPrice,
            ),
            if (groups.isNotEmpty) SizedBox(height: context.spacing.sm),
          ],
          for (final group in groups) ...[
            _ValuationMethodPanel(group: group),
            if (group != groups.last) SizedBox(height: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ValuationCurrentPricePanel extends StatelessWidget {
  const _ValuationCurrentPricePanel({
    required this.currentPrice,
    required this.analysisPrice,
  });

  final _ResearchPriceSnapshot? currentPrice;
  final _ResearchPriceSnapshot? analysisPrice;

  @override
  Widget build(BuildContext context) {
    final values = [
      if (currentPrice != null)
        _InfoValue(
          '현재가',
          _formatMoney(currentPrice!.value, currentPrice!.currency),
        ),
      if (analysisPrice != null)
        _InfoValue(
          '분석 당시',
          _formatMoney(analysisPrice!.value, analysisPrice!.currency),
        ),
      if (currentPrice != null &&
          analysisPrice != null &&
          analysisPrice!.value > 0)
        _InfoValue(
          '분석가 대비',
          _formatPercent(
            ((currentPrice!.value - analysisPrice!.value) /
                    analysisPrice!.value) *
                100,
          ),
          tone: currentPrice!.value > analysisPrice!.value
              ? _ValueTone.positive
              : currentPrice!.value < analysisPrice!.value
              ? _ValueTone.negative
              : _ValueTone.neutral,
        ),
    ];

    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('가격', style: context.typography.cardTitle),
          SizedBox(height: context.spacing.xs),
          _ValuationValueGrid(values: values),
        ],
      ),
    );
  }
}

class _ValuationMethodPanel extends StatelessWidget {
  const _ValuationMethodPanel({required this.group});

  final _ValuationGroup group;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.title, style: context.typography.cardTitle),
          SizedBox(height: context.spacing.xs),
          for (final view in group.views) ...[
            _ValuationViewRow(view: view),
            if (view != group.views.last) ...[
              SizedBox(height: context.spacing.xs),
            ],
          ],
        ],
      ),
    );
  }
}

class _ValuationViewRow extends StatelessWidget {
  const _ValuationViewRow({required this.view});

  final EquityResearchValuationView view;

  @override
  Widget build(BuildContext context) {
    final rating = equityResearchDisplayLabel(view.rating);
    final stance = equityResearchDisplayLabel(view.stance);
    final values = _valuationValues(view);
    final summary = [
      if (rating.isNotEmpty) rating,
      if (stance.isNotEmpty) stance,
    ].join(' · ');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.isNotEmpty) _ValuationSummaryText(summary: summary),
          if (values.isNotEmpty) ...[
            SizedBox(height: context.spacing.xs),
            _ValuationValueGrid(values: values),
          ],
        ],
      ),
    );
  }
}

class _ValuationSummaryText extends StatelessWidget {
  const _ValuationSummaryText({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Text(
      summary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.typography.meta.copyWith(
        color: context.colors.neutralTextMuted,
        fontWeight: AppFontWeights.semibold,
      ),
    );
  }
}

class _ValuationValueGrid extends StatelessWidget {
  const _ValuationValueGrid({required this.values});

  final List<_InfoValue> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = context.spacing.sm;
        final columnCount = values.length == 1 ? 1 : 2;
        final itemWidth =
            (constraints.maxWidth - (gap * (columnCount - 1))) / columnCount;
        return Wrap(
          spacing: gap,
          runSpacing: context.spacing.xs,
          children: [
            for (final value in values)
              SizedBox(width: itemWidth, child: _ValuationValueText(value)),
          ],
        );
      },
    );
  }
}

class _ValuationValueText extends StatelessWidget {
  const _ValuationValueText(this.value);

  final _InfoValue value;

  @override
  Widget build(BuildContext context) {
    final valueColor = switch (value.tone) {
      _ValueTone.positive => context.colors.positiveOn,
      _ValueTone.negative => context.colors.negativeOn,
      _ValueTone.neutral => null,
    };
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: context.typography.body,
        children: [
          TextSpan(
            text: '${value.label} ',
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
          TextSpan(
            text: value.value,
            style: context.typography.body.copyWith(color: valueColor),
          ),
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
      variant: SectionCardVariant.base,
      child: Column(
        children: [
          for (final risk in risks) ...[
            _TextItem(
              title: risk.title,
              body: risk.description,
              badges: const [],
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
      variant: SectionCardVariant.base,
      child: Column(
        children: [
          for (final catalyst in catalysts) ...[
            _TextItem(
              title: catalyst.title,
              body: catalyst.description,
              badges: const [],
              titleBadge: equityResearchDisplayLabel(
                catalyst.expectedDirection,
              ),
              titleBadgeTone: _toneForDirection(catalyst.expectedDirection),
              tone: _BadgeTone.neutral,
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
      variant: SectionCardVariant.base,
      child: Column(
        children: [
          for (final scenario in scenarios) ...[
            _TextItem(
              title: scenario.title.isEmpty
                  ? equityResearchDisplayLabel(scenario.name)
                  : scenario.title,
              body: scenario.summary,
              badges: const [],
              footer: scenario.expectedOutcome,
              tone: _toneForSide(scenario.name),
              titleTone: _toneForSide(scenario.name),
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
      variant: SectionCardVariant.base,
      child: Column(
        children: [
          for (final indicator in indicators) ...[
            _TextItem(
              title: indicator.name,
              body: indicator.positiveSignal,
              badges: const [],
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
      variant: SectionCardVariant.base,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.width,
    required this.title,
    required this.value,
  });

  final double width;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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
          ],
        ),
      ),
    );
  }
}

class _MetricTextPanel extends StatelessWidget {
  const _MetricTextPanel({required this.metric});

  final EquityResearchMetricPresentation metric;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            metric.value,
            style: context.typography.body.copyWith(
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ],
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
    this.titleTone,
    this.titleBadge,
    this.titleBadgeTone,
  });

  final String title;
  final String body;
  final List<String> badges;
  final String? footer;
  final _BadgeTone tone;
  final _BadgeTone? titleTone;
  final String? titleBadge;
  final _BadgeTone? titleBadgeTone;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.typography.cardTitle.copyWith(
                    color: titleTone == null
                        ? null
                        : _badgeColors(context, titleTone!).foreground,
                  ),
                ),
              ),
              if (titleBadge?.trim().isNotEmpty ?? false) ...[
                SizedBox(width: context.spacing.xs),
                _Badge(titleBadge!, tone: titleBadgeTone ?? tone),
              ],
            ],
          ),
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
              if (document.publisher.isNotEmpty) ...[
                Wrap(
                  spacing: context.spacing.xs,
                  runSpacing: context.spacing.xs,
                  children: [_Badge(document.publisher)],
                ),
                SizedBox(height: context.spacing.xs),
              ],
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
  const _CalloutBlock({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: Text(
        body,
        style: context.typography.body.copyWith(color: context.colors.primary),
      ),
    );
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
      variant: SectionCardVariant.base,
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
    return EmptyStateCard(
      title: title,
      description: message,
      cardVariant: SectionCardVariant.base,
    );
  }
}

class _InfoValue {
  const _InfoValue(this.label, this.value, {this.tone = _ValueTone.neutral});

  final String label;
  final String value;
  final _ValueTone tone;
}

class _ResearchPriceSnapshot {
  const _ResearchPriceSnapshot({required this.value, required this.currency});

  final double value;
  final String currency;
}

enum _ValueTone { neutral, positive, negative }

class _ValuationGroup {
  const _ValuationGroup({required this.title, required this.views});

  final String title;
  final List<EquityResearchValuationView> views;
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

List<_ValuationGroup> _valuationGroups(
  List<EquityResearchValuationView> views,
) {
  final groupMap = <String, List<EquityResearchValuationView>>{};
  final groupTitles = <String, String>{};
  for (final view in views) {
    final rawKey = view.method.trim().toLowerCase();
    final key = rawKey.isEmpty ? 'valuation' : rawKey;
    groupMap.putIfAbsent(key, () => <EquityResearchValuationView>[]).add(view);
    groupTitles.putIfAbsent(key, () => equityResearchDisplayLabel(key));
  }

  return [
    for (final entry in groupMap.entries)
      _ValuationGroup(title: groupTitles[entry.key]!, views: entry.value),
  ];
}

List<_InfoValue> _valuationValues(EquityResearchValuationView view) {
  return [
    if (view.targetPrice != null)
      _InfoValue('목표가', _formatMoney(view.targetPrice!, view.currency)),
    if (view.fairValue != null)
      _InfoValue('공정가치', _formatMoney(view.fairValue!, view.currency)),
    if (view.impliedUpsidePct != null)
      _InfoValue(
        equityResearchUpsideLabel(view.impliedUpsidePct!),
        _formatPercent(view.impliedUpsidePct!),
        tone: view.impliedUpsidePct! > 0
            ? _ValueTone.positive
            : view.impliedUpsidePct! < 0
            ? _ValueTone.negative
            : _ValueTone.neutral,
      ),
  ];
}

_ResearchPriceSnapshot? _analysisPrice(
  List<EquityResearchValuationView> views,
) {
  for (final view in views) {
    final value = view.priceAtAnalysis;
    if (value != null && value > 0) {
      return _ResearchPriceSnapshot(value: value, currency: view.currency);
    }
  }
  return null;
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
  return report.ticker.isEmpty ? report.displayTitle : report.ticker;
}

String _heroReportTitle(EquityResearchReportSummary report) {
  final companyName = report.companyName.trim();
  final ticker = report.ticker.trim();
  final subject = companyName.isNotEmpty
      ? companyName
      : ticker.isNotEmpty
      ? ticker
      : 'Company';
  return '$subject Research Report';
}

String? _researchActiveFilterSummary({
  required String query,
  required String? selectedTicker,
  required DateTime? selectedReportDate,
  required int visibleCount,
  required int totalCount,
}) {
  final parts = <String>[];
  final normalizedQuery = query.trim();
  if (normalizedQuery.isNotEmpty) parts.add('검색어: $normalizedQuery');
  if (selectedTicker != null) parts.add('심볼: $selectedTicker');
  if (selectedReportDate != null) {
    parts.add('날짜: ${_formatDate(selectedReportDate)}');
  }
  if (parts.isEmpty) return null;
  return '${parts.join(' · ')} · 리포트 $visibleCount / $totalCount';
}

bool _sameDate(DateTime? left, DateTime? right) {
  if (left == null || right == null) return left == right;
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
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
