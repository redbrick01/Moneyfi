import 'package:flutter/material.dart';

import '../components/section_card.dart';
import '../db/app_database.dart';
import '../design_system/context_extensions.dart';
import '../models/asset_item.dart';
import '../services/benchmark_price_service.dart';
import '../utils/display_currency.dart';
import '../utils/risk_adjusted_performance_calculator.dart';
import '../widgets/moneyfy_ui.dart';

class InvestmentPerformancePage extends StatefulWidget {
  const InvestmentPerformancePage({super.key});

  @override
  State<InvestmentPerformancePage> createState() =>
      _InvestmentPerformancePageState();
}

class _InvestmentPerformancePageState extends State<InvestmentPerformancePage> {
  late _PerformanceDateRange _selectedRange;
  late Future<_InvestmentPerformanceReport> _reportFuture;
  _HoldingSortMode _holdingSortMode = _HoldingSortMode.totalDesc;
  _HoldingFilterMode _holdingFilterMode = _HoldingFilterMode.all;

  @override
  void initState() {
    super.initState();
    _selectedRange = _PerformanceDateRange.yearToDate(DateTime.now());
    _reportFuture = _loadInvestmentPerformanceReport(_selectedRange);
  }

  void _selectRange(_PerformanceDateRange range) {
    setState(() {
      _selectedRange = range;
      _reportFuture = _loadInvestmentPerformanceReport(range);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MoneyfyPage(
      title: '투자성과 분석',
      children: [
        FutureBuilder<_InvestmentPerformanceReport>(
          future: _reportFuture,
          builder: (context, snapshot) {
            final report =
                snapshot.data ?? const _InvestmentPerformanceReport.empty();
            return Column(
              children: [
                _PerformanceCockpitCard(
                  report: report,
                  selectedRange: _selectedRange,
                  onRangeSelected: _selectRange,
                ),
                SizedBox(height: context.spacing.sectionGap),
                _PerformanceAttributionCard(report: report),
                SizedBox(height: context.spacing.sectionGap),
                _MarketAndRiskCard(report: report.advancedPerformance),
                SizedBox(height: context.spacing.sectionGap),
                _MonthlyTrendCard(items: report.monthlyPerformance),
                SizedBox(height: context.spacing.sectionGap),
                _HoldingContributionCard(
                  items: report.holdings,
                  totalPerformanceBasis: report.pureInvestmentPerformance,
                  filterMode: _holdingFilterMode,
                  sortMode: _holdingSortMode,
                  onFilterModeChanged: (mode) {
                    setState(() => _holdingFilterMode = mode);
                  },
                  onSortModeChanged: (mode) {
                    setState(() => _holdingSortMode = mode);
                  },
                ),
                SizedBox(height: context.spacing.sectionGap),
                _CashFlowExclusionCard(report: report),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.selectedRange,
    required this.onSelected,
  });

  final _PerformanceDateRange selectedRange;
  final ValueChanged<_PerformanceDateRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final ranges = _PerformanceDateRange.presets(DateTime.now());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < ranges.length; index++) ...[
            ChoiceChip(
              label: Text(ranges[index].label),
              selected: ranges[index].preset == selectedRange.preset,
              onSelected: (_) => onSelected(ranges[index]),
            ),
            if (index != ranges.length - 1) SizedBox(width: context.spacing.xs),
          ],
        ],
      ),
    );
  }
}

class _PerformanceCockpitCard extends StatelessWidget {
  const _PerformanceCockpitCard({
    required this.report,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  final _InvestmentPerformanceReport report;
  final _PerformanceDateRange selectedRange;
  final ValueChanged<_PerformanceDateRange> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    final performanceText = _formatSignedCurrency(
      report.pureInvestmentPerformance,
    );
    final performanceRateText = _formatSignedPercent(
      report.pureInvestmentPerformanceRate,
    );
    final benchmarkText = _benchmarkNarrative(report.advancedPerformance);

    return SectionCard(
      variant: SectionCardVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateRangeSelector(
            selectedRange: selectedRange,
            onSelected: onRangeSelected,
          ),
          SizedBox(height: context.spacing.md),
          Text(
            '순 투자성과',
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              performanceText,
              maxLines: 1,
              style: context.typography.heroNumber.copyWith(
                color: _valueColor(context, report.pureInvestmentPerformance),
              ),
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.xs,
            children: [
              _StatusPill(
                label: performanceRateText == null
                    ? '매수 원금 대비 수익률 데이터 부족'
                    : '$performanceRateText 매수 원금 대비',
                value: report.pureInvestmentPerformanceRate,
              ),
              _StatusPill(
                label: benchmarkText,
                value: report.advancedPerformance.excessReturn,
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            '입출금과 내부 이동 제외 기준',
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
          SizedBox(height: context.spacing.md),
          _MiniMetricGrid(
            metrics: [
              _MiniMetricData(
                label: '순 실현',
                value: report.pureRealizedPerformance,
              ),
              _MiniMetricData(label: '미실현', value: report.unrealizedProfit),
              _MiniMetricData(label: '배당/이자', value: report.incomeAmount),
              _MiniMetricData(label: '비용', value: -report.totalExpenseAmount),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final color = hasValue
        ? _valueColor(context, value!)
        : context.colors.neutralTextMuted;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceOverlay.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(context.radius.rPill),
        border: Border.all(
          color: context.colors.neutralOutline.withValues(alpha: 0.52),
        ),
      ),
      child: Text(
        label,
        style: context.typography.meta.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniMetricGrid extends StatelessWidget {
  const _MiniMetricGrid({required this.metrics});

  final List<_MiniMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 1 : 2;
        final gap = context.spacing.sm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _MiniMetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({required this.metric});

  final _MiniMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceBase,
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(
          color: context.colors.neutralOutline.withValues(alpha: 0.44),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: context.typography.caption.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
          SizedBox(height: context.spacing.xs / 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatSignedCurrency(metric.value),
              maxLines: 1,
              style: context.typography.cardTitle.copyWith(
                color: _valueColor(context, metric.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricData {
  const _MiniMetricData({required this.label, required this.value});

  final String label;
  final double value;
}

class _PerformanceAttributionCard extends StatelessWidget {
  const _PerformanceAttributionCard({required this.report});

  final _InvestmentPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    final entries = [
      _AttributionData(label: '실현손익', amount: report.realizedProfit),
      _AttributionData(label: '미실현손익', amount: report.unrealizedProfit),
      _AttributionData(label: '배당/이자', amount: report.incomeAmount),
      _AttributionData(label: '수수료', amount: -report.feeAmount),
      _AttributionData(label: '세금', amount: -report.taxAmount),
    ];
    final maxAbsComponent = entries.fold<double>(
      0,
      (maxValue, item) =>
          item.amount.abs() > maxValue ? item.amount.abs() : maxValue,
    );

    return SectionCard(
      title: '성과 원인',
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _AttributionRow(
              item: entries[index],
              basis: report.pureInvestmentPerformance,
              maxAbsComponent: maxAbsComponent,
            ),
            if (index != entries.length - 1) const Divider(height: 22),
          ],
          const Divider(height: 28),
          _MetricRow(
            label: '순 투자성과',
            value: _formatSignedCurrency(report.pureInvestmentPerformance),
            trailing: _formatSignedPercent(
              report.pureInvestmentPerformanceRate,
            ),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '순 실현성과',
            value: _formatSignedCurrency(report.pureRealizedPerformance),
            trailing: _formatSignedPercent(report.pureRealizedPerformanceRate),
          ),
          const Divider(height: 20),
          _MetricRow(label: '매수 원금', value: _formatCurrency(report.buyAmount)),
          const Divider(height: 20),
          _MetricRow(
            label: '매도 회수금',
            value: _formatCurrency(report.sellAmount),
          ),
        ],
      ),
    );
  }
}

class _AttributionRow extends StatelessWidget {
  const _AttributionRow({
    required this.item,
    required this.basis,
    required this.maxAbsComponent,
  });

  final _AttributionData item;
  final double basis;
  final double maxAbsComponent;

  @override
  Widget build(BuildContext context) {
    final valueText = _formatSignedCurrency(item.amount);
    final shareText = _formatContribution(item.amount, basis);
    final fraction = maxAbsComponent <= 0
        ? 0.0
        : (item.amount.abs() / maxAbsComponent).clamp(0.0, 1.0);
    final color = _valueColor(context, item.amount);
    final backgroundColor = item.amount == 0
        ? context.colors.neutralSurfaceOverlay
        : item.amount > 0
        ? context.colors.positiveContainer
        : context.colors.negativeContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(item.label, style: context.typography.meta)),
            SizedBox(width: context.spacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valueText,
                  textAlign: TextAlign.right,
                  style: context.typography.cardTitle.copyWith(color: color),
                ),
                if (shareText != null)
                  Text(
                    shareText,
                    style: context.typography.caption.copyWith(
                      color: context.colors.neutralTextMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
        SizedBox(height: context.spacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.radius.rPill),
          child: Container(
            height: 8,
            color: context.colors.neutralSurfaceOverlay.withValues(alpha: 0.52),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(color: backgroundColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttributionData {
  const _AttributionData({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _MarketAndRiskCard extends StatelessWidget {
  const _MarketAndRiskCard({required this.report});

  final _AdvancedPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _RiskMetricData(
        label: '기간 수익률',
        value: _formatSignedRatePercent(report.periodReturn),
        numericValue: report.periodReturn,
        caption: '입출금 보정',
      ),
      _RiskMetricData(
        label: report.benchmarkLabel,
        value: _formatSignedRatePercent(report.benchmarkReturn),
        numericValue: report.benchmarkReturn,
        caption: '선택 기간',
      ),
      _RiskMetricData(
        label: '초과수익률',
        value: _formatSignedPercentagePoint(report.excessReturn),
        numericValue: report.excessReturn,
        caption: '시장 대비',
      ),
      _RiskMetricData(
        label: '변동성',
        value: _formatAnnualizedPercent(report.annualizedVolatility),
        numericValue: report.annualizedVolatility,
        caption: '연율화',
      ),
      _RiskMetricData(
        label: 'Sharpe',
        value: _formatDecimal(report.sharpeRatio),
        numericValue: report.sharpeRatio,
        caption: '위험 대비 성과',
      ),
      _RiskMetricData(
        label: '최대 낙폭',
        value: _formatSignedRatePercent(report.maxDrawdown),
        numericValue: report.maxDrawdown,
        caption: '고점 대비',
      ),
    ];

    return SectionCard(
      title: '시장 비교와 위험',
      footer: Text(
        report.isRiskFreeRateFallback
            ? '금리 데이터를 가져오지 못해 0% 기준으로 Sharpe Ratio를 계산했습니다.'
            : '${report.riskFreeRateLabel} 기준 Sharpe Ratio입니다.',
        style: context.typography.caption.copyWith(
          color: context.colors.neutralTextMuted,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 360 ? 1 : 2;
          final gap = context.spacing.sm;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: width,
                  child: _RiskMetricTile(metric: metric),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RiskMetricTile extends StatelessWidget {
  const _RiskMetricTile({required this.metric});

  final _RiskMetricData metric;

  @override
  Widget build(BuildContext context) {
    final value = metric.value ?? '데이터 부족';
    final color = metric.numericValue == null
        ? context.colors.neutralTextMuted
        : _valueColor(context, metric.numericValue!);
    return Container(
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceBase,
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(
          color: context.colors.neutralOutline.withValues(alpha: 0.44),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: context.typography.cardTitle.copyWith(color: color),
            ),
          ),
          SizedBox(height: context.spacing.xs / 2),
          Text(
            metric.caption,
            style: context.typography.caption.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskMetricData {
  const _RiskMetricData({
    required this.label,
    required this.value,
    required this.numericValue,
    required this.caption,
  });

  final String label;
  final String? value;
  final double? numericValue;
  final String caption;
}

class _CashFlowExclusionCard extends StatelessWidget {
  const _CashFlowExclusionCard({required this.report});

  final _InvestmentPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '제외 현금흐름',
      child: Column(
        children: [
          _MetricRow(
            label: '외부 입금',
            value: _formatCurrency(report.externalDepositAmount),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '외부 출금',
            value: _formatSignedCurrency(-report.externalWithdrawalAmount),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '외부 입출금 합계',
            value: _formatSignedCurrency(report.externalCashFlowAmount),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '투자 결제 현금흐름',
            value: _formatSignedCurrency(report.tradeSettlementCashFlowAmount),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '내부 이동',
            value: _formatCurrency(report.internalCashMovementAmount),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.items});

  final List<_MonthlyPerformance> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SectionCard(
        title: '월별 실현성과',
        child: Text(
          '월별로 집계할 실현 손익이 아직 없습니다.',
          style: context.typography.meta.copyWith(
            color: context.colors.neutralTextMuted,
          ),
        ),
      );
    }

    final visibleItems = items.take(12).toList(growable: false);
    final chartItems = visibleItems.reversed.toList(growable: false);
    return SectionCard(
      title: '월별 실현성과',
      headerTrailing: Text(
        '최근 ${visibleItems.length}개월',
        style: context.typography.meta.copyWith(
          color: context.colors.neutralTextMuted,
        ),
      ),
      child: Column(
        children: [
          _MonthlyBarStrip(items: chartItems),
          SizedBox(height: context.spacing.md),
          for (var index = 0; index < visibleItems.length; index++) ...[
            _MonthlyTrendRow(item: visibleItems[index]),
            if (index != visibleItems.length - 1) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _MonthlyBarStrip extends StatelessWidget {
  const _MonthlyBarStrip({required this.items});

  final List<_MonthlyPerformance> items;

  @override
  Widget build(BuildContext context) {
    final maxAbs = items.fold<double>(
      0,
      (maxValue, item) => item.pureRealizedPerformance.abs() > maxValue
          ? item.pureRealizedPerformance.abs()
          : maxValue,
    );
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: _MonthlyBar(
                item: items[index],
                fraction: maxAbs <= 0
                    ? 0
                    : (items[index].pureRealizedPerformance.abs() / maxAbs)
                          .clamp(0.0, 1.0),
              ),
            ),
            if (index != items.length - 1) SizedBox(width: context.spacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MonthlyBar extends StatelessWidget {
  const _MonthlyBar({required this.item, required this.fraction});

  final _MonthlyPerformance item;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final amount = item.pureRealizedPerformance;
    final color = amount > 0
        ? context.colors.positiveContainer
        : amount < 0
        ? context.colors.negativeContainer
        : context.colors.neutralSurfaceOverlay;
    final monthLabel = item.month.length >= 7 ? item.month.substring(5, 7) : '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction <= 0 ? 0.04 : fraction,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(context.radius.rSm),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          monthLabel,
          style: context.typography.caption.copyWith(
            color: context.colors.neutralTextMuted,
          ),
        ),
      ],
    );
  }
}

class _MonthlyTrendRow extends StatelessWidget {
  const _MonthlyTrendRow({required this.item});

  final _MonthlyPerformance item;

  @override
  Widget build(BuildContext context) {
    final resultText = _formatSignedCurrency(item.pureRealizedPerformance);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.month, style: context.typography.cardTitle),
              SizedBox(height: context.spacing.xs / 2),
              Text(
                '실현 ${_formatSignedCurrency(item.realizedProfit)} · 수입 ${_formatSignedCurrency(item.incomeAmount)} · 비용 ${_formatSignedCurrency(-item.totalExpenseAmount)}',
                style: context.typography.meta.copyWith(
                  color: context.colors.neutralTextMuted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Text(
          resultText,
          textAlign: TextAlign.right,
          style: context.typography.cardTitle.copyWith(
            color: _valueColor(context, item.pureRealizedPerformance),
          ),
        ),
      ],
    );
  }
}

class _HoldingContributionCard extends StatelessWidget {
  const _HoldingContributionCard({
    required this.items,
    required this.totalPerformanceBasis,
    required this.filterMode,
    required this.sortMode,
    required this.onFilterModeChanged,
    required this.onSortModeChanged,
  });

  final List<_HoldingPerformance> items;
  final double totalPerformanceBasis;
  final _HoldingFilterMode filterMode;
  final _HoldingSortMode sortMode;
  final ValueChanged<_HoldingFilterMode> onFilterModeChanged;
  final ValueChanged<_HoldingSortMode> onSortModeChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SectionCard(
        title: '종목별 성과',
        child: Text(
          '분석할 투자 거래가 아직 없습니다.',
          style: context.typography.meta.copyWith(
            color: context.colors.neutralTextMuted,
          ),
        ),
      );
    }

    final filteredItems = _filterHoldingPerformance(items, filterMode);
    final sortedItems = _sortHoldingPerformance(filteredItems, sortMode);

    return SectionCard(
      title: '종목별 성과',
      headerTrailing: DropdownButtonHideUnderline(
        child: DropdownButton<_HoldingSortMode>(
          value: sortMode,
          isDense: true,
          items: [
            for (final mode in _HoldingSortMode.values)
              DropdownMenuItem(value: mode, child: Text(mode.label)),
          ],
          onChanged: (mode) {
            if (mode != null) onSortModeChanged(mode);
          },
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (
                  var index = 0;
                  index < _HoldingFilterMode.values.length;
                  index++
                ) ...[
                  ChoiceChip(
                    label: Text(_HoldingFilterMode.values[index].label),
                    selected: _HoldingFilterMode.values[index] == filterMode,
                    onSelected: (_) =>
                        onFilterModeChanged(_HoldingFilterMode.values[index]),
                  ),
                  if (index != _HoldingFilterMode.values.length - 1)
                    SizedBox(width: context.spacing.xs),
                ],
              ],
            ),
          ),
          SizedBox(height: context.spacing.md),
          if (sortedItems.isEmpty)
            Text(
              _emptyHoldingFilterText(filterMode),
              style: context.typography.meta.copyWith(
                color: context.colors.neutralTextMuted,
              ),
            )
          else
            for (var index = 0; index < sortedItems.length; index++) ...[
              _HoldingContributionRow(
                item: sortedItems[index],
                totalPerformanceBasis: totalPerformanceBasis,
              ),
              if (index != sortedItems.length - 1) const Divider(height: 24),
            ],
        ],
      ),
    );
  }
}

class _HoldingContributionRow extends StatelessWidget {
  const _HoldingContributionRow({
    required this.item,
    required this.totalPerformanceBasis,
  });

  final _HoldingPerformance item;
  final double totalPerformanceBasis;

  @override
  Widget build(BuildContext context) {
    final resultText = _formatSignedCurrency(item.totalPerformance);
    final contributionText = _formatContribution(
      item.totalPerformance,
      totalPerformanceBasis,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: context.typography.cardTitle),
              SizedBox(height: context.spacing.xs / 2),
              Text(
                [
                  item.assetName,
                  if (item.symbol.trim().isNotEmpty) item.symbol,
                  item.currencyCode,
                ].join(' · '),
                style: context.typography.meta.copyWith(
                  color: context.colors.neutralTextMuted,
                ),
              ),
              SizedBox(height: context.spacing.xs),
              Wrap(
                spacing: context.spacing.xs,
                runSpacing: context.spacing.xs,
                children: [
                  _MetricPill(label: '실현', value: item.realizedProfit),
                  _MetricPill(label: '미실현', value: item.unrealizedProfit),
                  _MetricPill(label: '수입', value: item.incomeAmount),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                resultText,
                textAlign: TextAlign.right,
                style: context.typography.cardTitle.copyWith(
                  color: _valueColor(context, item.totalPerformance),
                ),
              ),
            ),
            if (contributionText != null) ...[
              SizedBox(height: context.spacing.xs / 2),
              Text(
                contributionText,
                style: context.typography.caption.copyWith(
                  color: context.colors.neutralTextMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: context.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceOverlay.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
      child: Text(
        '$label ${_formatSignedCurrency(value)}',
        style: context.typography.caption.copyWith(
          color: _valueColor(context, value),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(label, style: theme.textTheme.titleMedium)],
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _valueTextColor(context, value),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailing != null) ...[
              SizedBox(height: context.spacing.xs / 2),
              Text(
                trailing!,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _valueTextColor(
                    context,
                    trailing!,
                    defaultColor: context.colors.neutralTextMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

Future<_InvestmentPerformanceReport> _loadInvestmentPerformanceReport(
  _PerformanceDateRange range,
) async {
  final db = AppDatabase.instance;
  final assets = await db.fetchAssets();
  final ledgerPerformanceByHoldingId = await db
      .fetchLedgerHoldingPerformanceByHoldingId(from: range.from, to: range.to);
  final ledgerPortfolioPerformanceByCurrency = await db
      .fetchLedgerPortfolioPerformanceByCurrency(
        from: range.from,
        to: range.to,
      );
  final ledgerMonthlyPerformanceByCurrency = await db
      .fetchLedgerMonthlyPerformanceByCurrency(from: range.from, to: range.to);
  final usdKrwRate = await db.fetchLatestExchangeRate() ?? 1.0;
  final baselineUnrealizedByHoldingId =
      await _fetchBaselineUnrealizedProfitByHoldingId(db, range.from);
  final holdings = assets
      .where((asset) => !asset.isHidden && asset.assetType != '현금')
      .expand((asset) => asset.holdings)
      .where(
        (holding) =>
            !holding.isHidden &&
            holding.assetType != '현금' &&
            (holding.id == null || holding.id! >= 0 || !holding.isCashLike) &&
            ((holding.id != null &&
                    ledgerPerformanceByHoldingId.containsKey(holding.id)) ||
                !holding.isClosedInvestmentPosition),
      )
      .toList(growable: false);

  final items =
      holdings
          .map(
            (holding) => _analyzeHoldingPerformance(
              holding,
              ledgerPerformanceByHoldingId[holding.id],
              baselineUnrealizedProfit:
                  baselineUnrealizedByHoldingId[holding.id],
            ),
          )
          .toList()
        ..sort((a, b) => b.totalPerformance.compareTo(a.totalPerformance));

  return _InvestmentPerformanceReport(
    holdings: items,
    monthlyPerformance: _mergeMonthlyPerformanceAsKrw(
      ledgerMonthlyPerformanceByCurrency,
      usdKrwRate,
    ),
    realizedProfit: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.realizedPnl,
    ),
    unrealizedProfit: items.fold<double>(
      0,
      (sum, item) => sum + item.unrealizedProfit,
    ),
    incomeAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.incomeAmount,
    ),
    feeAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.feeAmount,
    ),
    taxAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.taxAmount,
    ),
    externalCashFlowAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.externalCashFlowAmount,
    ),
    externalDepositAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.externalDepositAmount,
    ),
    externalWithdrawalAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.externalWithdrawalAmount,
    ),
    tradeSettlementCashFlowAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.tradeSettlementCashFlowAmount,
    ),
    internalCashMovementAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.internalCashMovementAmount,
    ),
    buyAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.buyAmount,
    ),
    sellAmount: _sumLedgerPortfolioFieldAsKrw(
      ledgerPortfolioPerformanceByCurrency,
      usdKrwRate,
      (record) => record.sellAmount,
    ),
    advancedPerformance: await _loadAdvancedPerformanceReport(db, range),
  );
}

Future<_AdvancedPerformanceReport> _loadAdvancedPerformanceReport(
  AppDatabase db,
  _PerformanceDateRange range,
) async {
  final from = range.from == null ? null : _dateKey(range.from!);
  final to = range.to == null ? null : _dateKey(range.to!);

  await db.rebuildPortfolioDailyReturns(from: from, to: to);
  final rows = await db.fetchPortfolioDailyReturns(from: from, to: to);
  final dailyReturns = rows
      .map((row) => row.dailyReturn)
      .whereType<double>()
      .toList(growable: false);
  final portfolioValues = rows
      .map((row) => row.portfolioValueKrw)
      .toList(growable: false);
  final benchmarkFrom = from ?? (rows.isEmpty ? null : rows.first.returnDate);
  final benchmarkTo = to ?? (rows.isEmpty ? null : rows.last.returnDate);
  if (benchmarkFrom != null && benchmarkTo != null) {
    await BenchmarkPriceService.instance.ensureBenchmarkPrices(
      benchmarkCode: _defaultBenchmarkCode,
      from: benchmarkFrom,
      to: benchmarkTo,
    );
    await BenchmarkPriceService.instance.ensureRiskFreeRates(
      from: benchmarkFrom,
      to: benchmarkTo,
    );
  }
  final benchmarkComparison = await db.compareBenchmarkPeriodReturn(
    benchmarkCode: _defaultBenchmarkCode,
    from: from,
    to: to,
  );
  final riskFreeRate = benchmarkTo == null
      ? null
      : await BenchmarkPriceService.instance.fetchLatestRiskFreeRate(
          to: benchmarkTo,
        );
  final annualRiskFreeRate = riskFreeRate?.annualRate ?? 0;

  return _AdvancedPerformanceReport(
    benchmarkCode: _defaultBenchmarkCode,
    benchmarkLabel: _defaultBenchmarkLabel,
    periodReturn: calculateCumulativeReturn(dailyReturns),
    benchmarkReturn: benchmarkComparison?.benchmarkPeriodReturn,
    excessReturn: benchmarkComparison?.excessReturn,
    annualizedVolatility: dailyReturns.length < 20
        ? null
        : calculateAnnualizedVolatility(dailyReturns),
    sharpeRatio: calculateSharpeRatio(
      dailyReturns,
      riskFreeRate: annualRiskFreeRate,
    ),
    riskFreeRate: annualRiskFreeRate,
    riskFreeRateSource: riskFreeRate?.source,
    riskFreeRateDate: riskFreeRate?.priceDate,
    isRiskFreeRateFallback: riskFreeRate == null,
    maxDrawdown: calculateMaxDrawdown(portfolioValues)?.maxDrawdown,
  );
}

_HoldingPerformance _analyzeHoldingPerformance(
  HoldingItem holding,
  LedgerHoldingPerformanceRecord? ledgerPerformance, {
  double? baselineUnrealizedProfit,
}) {
  final realizedProfit = _toKrw(
    ledgerPerformance?.realizedPnl ?? 0,
    holding.currencyCode,
    holding.exchangeRate,
  );
  final incomeAmount = _toKrw(
    ledgerPerformance?.incomeAmount ?? 0,
    holding.currencyCode,
    holding.exchangeRate,
  );
  final buyAmount = _toKrw(
    ledgerPerformance?.buyAmount ?? 0,
    holding.currencyCode,
    holding.exchangeRate,
  );
  final sellAmount = _toKrw(
    ledgerPerformance?.sellAmount ?? 0,
    holding.currencyCode,
    holding.exchangeRate,
  );
  final unrealizedProfit = calculatePeriodUnrealizedProfit(
    currentUnrealizedProfit: holding.profitAmount,
    baselineUnrealizedProfit: baselineUnrealizedProfit,
  );

  return _HoldingPerformance(
    assetName: holding.assetTitle ?? '-',
    name: holding.name,
    symbol: holding.symbol,
    currencyCode: holding.currencyCode,
    realizedProfit: realizedProfit,
    unrealizedProfit: unrealizedProfit,
    incomeAmount: incomeAmount,
    buyAmount: buyAmount,
    sellAmount: sellAmount,
  );
}

Future<Map<int, double>> _fetchBaselineUnrealizedProfitByHoldingId(
  AppDatabase db,
  DateTime? from,
) async {
  if (from == null) return const {};

  final baselineSnapshot = await db.fetchPreviousPortfolioSnapshot(
    _dateKey(from),
  );
  if (baselineSnapshot == null) return const {};

  final rows = await db.fetchPortfolioSnapshotHoldingItemsByDates([
    baselineSnapshot.snapshotDate,
  ]);
  final result = <int, double>{};
  for (final row in rows) {
    final holdingId = row.holdingId;
    if (holdingId == null) continue;
    result[holdingId] = (result[holdingId] ?? 0) + row.profitAmount;
  }
  return result;
}

@visibleForTesting
double calculatePeriodUnrealizedProfit({
  required double currentUnrealizedProfit,
  double? baselineUnrealizedProfit,
}) {
  return currentUnrealizedProfit - (baselineUnrealizedProfit ?? 0);
}

@visibleForTesting
double? calculatePerformanceRate(double performanceAmount, double basisAmount) {
  if (basisAmount.abs() < 0.000001) return null;
  return performanceAmount / basisAmount * 100;
}

String _dateKey(DateTime date) {
  final normalized = DateUtils.dateOnly(date);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _InvestmentPerformanceReport {
  const _InvestmentPerformanceReport({
    required this.holdings,
    required this.monthlyPerformance,
    required this.advancedPerformance,
    required this.realizedProfit,
    required this.unrealizedProfit,
    required this.incomeAmount,
    required this.feeAmount,
    required this.taxAmount,
    required this.externalCashFlowAmount,
    required this.externalDepositAmount,
    required this.externalWithdrawalAmount,
    required this.tradeSettlementCashFlowAmount,
    required this.internalCashMovementAmount,
    required this.buyAmount,
    required this.sellAmount,
  });

  const _InvestmentPerformanceReport.empty()
    : holdings = const [],
      monthlyPerformance = const [],
      advancedPerformance = const _AdvancedPerformanceReport.empty(),
      realizedProfit = 0,
      unrealizedProfit = 0,
      incomeAmount = 0,
      feeAmount = 0,
      taxAmount = 0,
      externalCashFlowAmount = 0,
      externalDepositAmount = 0,
      externalWithdrawalAmount = 0,
      tradeSettlementCashFlowAmount = 0,
      internalCashMovementAmount = 0,
      buyAmount = 0,
      sellAmount = 0;

  final List<_HoldingPerformance> holdings;
  final List<_MonthlyPerformance> monthlyPerformance;
  final _AdvancedPerformanceReport advancedPerformance;
  final double realizedProfit;
  final double unrealizedProfit;
  final double incomeAmount;
  final double feeAmount;
  final double taxAmount;
  final double externalCashFlowAmount;
  final double externalDepositAmount;
  final double externalWithdrawalAmount;
  final double tradeSettlementCashFlowAmount;
  final double internalCashMovementAmount;
  final double buyAmount;
  final double sellAmount;

  double get pureRealizedPerformance =>
      realizedProfit + incomeAmount - feeAmount - taxAmount;

  double get pureInvestmentPerformance =>
      pureRealizedPerformance + unrealizedProfit;

  double? get pureRealizedPerformanceRate =>
      calculatePerformanceRate(pureRealizedPerformance, buyAmount);

  double? get pureInvestmentPerformanceRate =>
      calculatePerformanceRate(pureInvestmentPerformance, buyAmount);

  double get totalExpenseAmount => feeAmount + taxAmount;

  List<_HoldingPerformance> get realizedRankings {
    final items = holdings
        .where((item) => item.realizedProfit.abs() > 0.000001)
        .toList(growable: false);
    return items..sort((a, b) => b.realizedProfit.compareTo(a.realizedProfit));
  }
}

class _AdvancedPerformanceReport {
  const _AdvancedPerformanceReport({
    required this.benchmarkCode,
    required this.benchmarkLabel,
    required this.periodReturn,
    required this.benchmarkReturn,
    required this.excessReturn,
    required this.annualizedVolatility,
    required this.sharpeRatio,
    required this.riskFreeRate,
    required this.riskFreeRateSource,
    required this.riskFreeRateDate,
    required this.isRiskFreeRateFallback,
    required this.maxDrawdown,
  });

  const _AdvancedPerformanceReport.empty()
    : benchmarkCode = _defaultBenchmarkCode,
      benchmarkLabel = _defaultBenchmarkLabel,
      periodReturn = null,
      benchmarkReturn = null,
      excessReturn = null,
      annualizedVolatility = null,
      sharpeRatio = null,
      riskFreeRate = 0,
      riskFreeRateSource = null,
      riskFreeRateDate = null,
      isRiskFreeRateFallback = true,
      maxDrawdown = null;

  final String benchmarkCode;
  final String benchmarkLabel;
  final double? periodReturn;
  final double? benchmarkReturn;
  final double? excessReturn;
  final double? annualizedVolatility;
  final double? sharpeRatio;
  final double riskFreeRate;
  final String? riskFreeRateSource;
  final String? riskFreeRateDate;
  final bool isRiskFreeRateFallback;
  final double? maxDrawdown;

  String get riskFreeRateLabel {
    if (isRiskFreeRateFallback) return '0% 무위험수익률';
    final dateText = riskFreeRateDate == null ? '' : ' ${riskFreeRateDate!}';
    return '미국 13주 T-Bill$dateText';
  }
}

class _MonthlyPerformance {
  const _MonthlyPerformance({
    required this.month,
    required this.realizedProfit,
    required this.incomeAmount,
    required this.feeAmount,
    required this.taxAmount,
  });

  final String month;
  final double realizedProfit;
  final double incomeAmount;
  final double feeAmount;
  final double taxAmount;

  double get pureRealizedPerformance =>
      realizedProfit + incomeAmount - feeAmount - taxAmount;

  double get totalExpenseAmount => feeAmount + taxAmount;
}

class _HoldingPerformance {
  const _HoldingPerformance({
    required this.assetName,
    required this.name,
    required this.symbol,
    required this.currencyCode,
    required this.realizedProfit,
    required this.unrealizedProfit,
    required this.incomeAmount,
    required this.buyAmount,
    required this.sellAmount,
  });

  final String assetName;
  final String name;
  final String symbol;
  final String currencyCode;
  final double realizedProfit;
  final double unrealizedProfit;
  final double incomeAmount;
  final double buyAmount;
  final double sellAmount;

  double get totalPerformance =>
      realizedProfit + unrealizedProfit + incomeAmount;
}

enum _PerformanceDatePreset { oneMonth, threeMonths, sixMonths, year, all }

class _PerformanceDateRange {
  const _PerformanceDateRange({
    required this.preset,
    required this.label,
    required this.from,
    required this.to,
  });

  factory _PerformanceDateRange.yearToDate(DateTime today) {
    final normalizedToday = DateUtils.dateOnly(today);
    return _PerformanceDateRange(
      preset: _PerformanceDatePreset.year,
      label: '올해',
      from: DateTime(normalizedToday.year),
      to: normalizedToday,
    );
  }

  final _PerformanceDatePreset preset;
  final String label;
  final DateTime? from;
  final DateTime? to;

  static List<_PerformanceDateRange> presets(DateTime today) {
    final normalizedToday = DateUtils.dateOnly(today);
    return [
      _monthsBack(
        preset: _PerformanceDatePreset.oneMonth,
        label: '1개월',
        today: normalizedToday,
        months: 1,
      ),
      _monthsBack(
        preset: _PerformanceDatePreset.threeMonths,
        label: '3개월',
        today: normalizedToday,
        months: 3,
      ),
      _monthsBack(
        preset: _PerformanceDatePreset.sixMonths,
        label: '6개월',
        today: normalizedToday,
        months: 6,
      ),
      _PerformanceDateRange.yearToDate(normalizedToday),
      _PerformanceDateRange(
        preset: _PerformanceDatePreset.all,
        label: '전체',
        from: null,
        to: null,
      ),
    ];
  }

  static _PerformanceDateRange _monthsBack({
    required _PerformanceDatePreset preset,
    required String label,
    required DateTime today,
    required int months,
  }) {
    return _PerformanceDateRange(
      preset: preset,
      label: label,
      from: DateTime(today.year, today.month - months, today.day),
      to: today,
    );
  }
}

enum _HoldingSortMode {
  totalDesc('총 성과'),
  totalAsc('손실'),
  realizedDesc('실현'),
  unrealizedDesc('미실현'),
  incomeDesc('배당/이자');

  const _HoldingSortMode(this.label);

  final String label;
}

enum _HoldingFilterMode {
  all('전체'),
  realized('실현'),
  loss('손실'),
  income('수입');

  const _HoldingFilterMode(this.label);

  final String label;
}

List<_HoldingPerformance> _filterHoldingPerformance(
  List<_HoldingPerformance> items,
  _HoldingFilterMode filterMode,
) {
  switch (filterMode) {
    case _HoldingFilterMode.all:
      return items;
    case _HoldingFilterMode.realized:
      return items
          .where((item) => item.realizedProfit.abs() > 0.000001)
          .toList(growable: false);
    case _HoldingFilterMode.loss:
      return items
          .where((item) => item.totalPerformance < -0.000001)
          .toList(growable: false);
    case _HoldingFilterMode.income:
      return items
          .where((item) => item.incomeAmount.abs() > 0.000001)
          .toList(growable: false);
  }
}

String _emptyHoldingFilterText(_HoldingFilterMode filterMode) {
  return switch (filterMode) {
    _HoldingFilterMode.all => '분석할 투자 거래가 아직 없습니다.',
    _HoldingFilterMode.realized => '실현손익이 발생한 매도 거래가 아직 없습니다.',
    _HoldingFilterMode.loss => '손실이 발생한 종목이 없습니다.',
    _HoldingFilterMode.income => '배당이나 이자가 발생한 종목이 없습니다.',
  };
}

double _toKrw(double amount, String currencyCode, double exchangeRate) {
  return currencyCode.toUpperCase() == 'USD' ? amount * exchangeRate : amount;
}

double _sumLedgerPortfolioFieldAsKrw(
  Map<String, LedgerPortfolioPerformanceRecord> recordsByCurrency,
  double usdKrwRate,
  double Function(LedgerPortfolioPerformanceRecord record) selectAmount,
) {
  return recordsByCurrency.entries.fold<double>(0, (sum, entry) {
    return sum + _toKrw(selectAmount(entry.value), entry.key, usdKrwRate);
  });
}

List<_MonthlyPerformance> _mergeMonthlyPerformanceAsKrw(
  List<LedgerMonthlyPerformanceRecord> records,
  double usdKrwRate,
) {
  final byMonth = <String, _MutableMonthlyPerformance>{};
  for (final record in records) {
    final bucket = byMonth.putIfAbsent(
      record.month,
      () => _MutableMonthlyPerformance(month: record.month),
    );
    bucket.realizedProfit += _toKrw(
      record.realizedPnl,
      record.currencyCode,
      usdKrwRate,
    );
    bucket.incomeAmount += _toKrw(
      record.incomeAmount,
      record.currencyCode,
      usdKrwRate,
    );
    bucket.feeAmount += _toKrw(
      record.feeAmount,
      record.currencyCode,
      usdKrwRate,
    );
    bucket.taxAmount += _toKrw(
      record.taxAmount,
      record.currencyCode,
      usdKrwRate,
    );
  }

  final items = byMonth.values
      .map(
        (item) => _MonthlyPerformance(
          month: item.month,
          realizedProfit: item.realizedProfit,
          incomeAmount: item.incomeAmount,
          feeAmount: item.feeAmount,
          taxAmount: item.taxAmount,
        ),
      )
      .toList(growable: false);
  return items..sort((a, b) => b.month.compareTo(a.month));
}

List<_HoldingPerformance> _sortHoldingPerformance(
  List<_HoldingPerformance> items,
  _HoldingSortMode sortMode,
) {
  final sorted = items.toList(growable: false);
  switch (sortMode) {
    case _HoldingSortMode.totalDesc:
      sorted.sort((a, b) => b.totalPerformance.compareTo(a.totalPerformance));
      break;
    case _HoldingSortMode.totalAsc:
      sorted.sort((a, b) => a.totalPerformance.compareTo(b.totalPerformance));
      break;
    case _HoldingSortMode.realizedDesc:
      sorted.sort((a, b) => b.realizedProfit.compareTo(a.realizedProfit));
      break;
    case _HoldingSortMode.unrealizedDesc:
      sorted.sort((a, b) => b.unrealizedProfit.compareTo(a.unrealizedProfit));
      break;
    case _HoldingSortMode.incomeDesc:
      sorted.sort((a, b) => b.incomeAmount.compareTo(a.incomeAmount));
      break;
  }
  return sorted;
}

String? _formatContribution(double amount, double basis) {
  if (basis.abs() < 0.000001) return null;
  final percent = amount / basis * 100;
  return '${percent.toStringAsFixed(1)}%';
}

Color _valueColor(BuildContext context, double value) {
  if (value > 0) return context.colors.positiveOn;
  if (value < 0) return context.colors.negativeOn;
  return context.colors.neutralTextMuted;
}

Color _valueTextColor(
  BuildContext context,
  String value, {
  Color? defaultColor,
}) {
  final trimmed = value.trim();
  if (trimmed.startsWith('+')) return context.colors.positiveOn;
  if (trimmed.startsWith('-') || trimmed.startsWith('−')) {
    return context.colors.negativeOn;
  }
  if (trimmed.contains('-') || trimmed.contains('−')) {
    return context.colors.negativeOn;
  }
  if (trimmed.contains('+')) return context.colors.positiveOn;
  return defaultColor ?? context.colors.neutralText;
}

String _benchmarkNarrative(_AdvancedPerformanceReport report) {
  final excessReturnText = _formatSignedPercentagePoint(report.excessReturn);
  if (excessReturnText != null) {
    return '${report.benchmarkLabel}보다 $excessReturnText';
  }

  final benchmarkReturnText = _formatSignedRatePercent(report.benchmarkReturn);
  if (benchmarkReturnText != null) {
    return '${report.benchmarkLabel} $benchmarkReturnText';
  }

  if (report.periodReturn == null) return '입출금 보정 수익률 데이터 부족';
  return '시장 비교 데이터 부족';
}

String? _formatSignedPercent(double? percent) {
  if (percent == null) return null;
  final sign = percent >= 0 ? '+' : '';
  return '$sign${percent.toStringAsFixed(1)}%';
}

class _MutableMonthlyPerformance {
  _MutableMonthlyPerformance({required this.month});

  final String month;
  double realizedProfit = 0;
  double incomeAmount = 0;
  double feeAmount = 0;
  double taxAmount = 0;
}

const String _defaultBenchmarkCode = 'SP500';
const String _defaultBenchmarkLabel = 'S&P 500';

String _formatCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}

String _formatSignedCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

String? _formatSignedRatePercent(double? rate) {
  if (rate == null) return null;
  return _formatSignedPercent(rate * 100);
}

String? _formatAnnualizedPercent(double? rate) {
  final percentText = _formatSignedRatePercent(rate);
  return percentText == null ? null : '연 $percentText';
}

String? _formatPercentagePoint(double? rate) {
  if (rate == null) return null;
  final percent = rate * 100;
  final sign = percent >= 0 ? '+' : '';
  return '$sign${percent.toStringAsFixed(1)}%p';
}

String? _formatSignedPercentagePoint(double? rate) =>
    _formatPercentagePoint(rate);

String? _formatDecimal(double? value) {
  if (value == null) return null;
  return value.toStringAsFixed(2);
}
