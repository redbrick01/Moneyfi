import 'package:flutter/material.dart';

import '../components/section_card.dart';
import '../db/app_database.dart';
import '../design_system/context_extensions.dart';
import '../models/asset_item.dart';
import '../services/benchmark_price_service.dart';
import '../theme/moneyfy_theme.dart';
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
        _DateRangeSelector(
          selectedRange: _selectedRange,
          onSelected: _selectRange,
        ),
        SizedBox(height: context.spacing.sectionGap),
        FutureBuilder<_InvestmentPerformanceReport>(
          future: _reportFuture,
          builder: (context, snapshot) {
            final report =
                snapshot.data ?? const _InvestmentPerformanceReport.empty();
            return Column(
              children: [
                _PerformanceSummaryCard(
                  report: report,
                  rangeLabel: _selectedRange.label,
                ),
                SizedBox(height: context.spacing.sectionGap),
                _PerformanceBreakdownCard(report: report),
                SizedBox(height: context.spacing.sectionGap),
                _AdvancedPerformanceCard(report: report.advancedPerformance),
                SizedBox(height: context.spacing.sectionGap),
                _CashFlowExclusionCard(report: report),
                SizedBox(height: context.spacing.sectionGap),
                _MonthlyPerformanceCard(items: report.monthlyPerformance),
                SizedBox(height: context.spacing.sectionGap),
                _RealizedProfitRankingCard(items: report.realizedRankings),
                SizedBox(height: context.spacing.sectionGap),
                _HoldingPerformanceCard(
                  items: report.holdings,
                  totalPerformanceBasis: report.pureInvestmentPerformance,
                  sortMode: _holdingSortMode,
                  onSortModeChanged: (mode) {
                    setState(() => _holdingSortMode = mode);
                  },
                ),
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

class _PerformanceSummaryCard extends StatelessWidget {
  const _PerformanceSummaryCard({
    required this.report,
    required this.rangeLabel,
  });

  final _InvestmentPerformanceReport report;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final performanceText = _formatSignedCurrency(
      report.pureInvestmentPerformance,
    );
    final performanceRateText = _formatSignedPercent(
      report.pureInvestmentPerformanceRate,
    );
    return SectionCard(
      title: '순 투자성과',
      headerTrailing: Text(
        rangeLabel,
        style: context.typography.meta.copyWith(
          color: MoneyfyPalette.tertiaryText,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            performanceText,
            style: context.typography.pageTitle.copyWith(
              color: moneyfyValueColor(
                performanceText,
                defaultColor: MoneyfyPalette.ink,
              ),
            ),
          ),
          if (performanceRateText != null) ...[
            SizedBox(height: context.spacing.xs),
            Text(
              performanceRateText,
              style: context.typography.sectionTitle.copyWith(
                color: moneyfyValueColor(
                  performanceRateText,
                  defaultColor: MoneyfyPalette.ink,
                ),
              ),
            ),
          ],
          SizedBox(height: context.spacing.xs),
          Text(
            '입출금과 내부 이동 제외 · 매수 원금 대비',
            style: context.typography.meta.copyWith(
              color: MoneyfyPalette.tertiaryText,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.xs,
            children: [
              _SummaryMetricChip(
                label: '실현',
                value: _formatSignedCurrency(report.pureRealizedPerformance),
              ),
              _SummaryMetricChip(
                label: '미실현',
                value: _formatSignedCurrency(report.unrealizedProfit),
              ),
              _SummaryMetricChip(
                label: '배당/이자',
                value: _formatSignedCurrency(report.incomeAmount),
              ),
              _SummaryMetricChip(
                label: '비용',
                value: _formatSignedCurrency(-report.totalExpenseAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricChip extends StatelessWidget {
  const _SummaryMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(context.radius.rSm),
      ),
      child: Text(
        '$label $value',
        style: context.typography.meta.copyWith(
          color: moneyfyValueColor(value, defaultColor: colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _PerformanceBreakdownCard extends StatelessWidget {
  const _PerformanceBreakdownCard({required this.report});

  final _InvestmentPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '성과 구성',
      child: Column(
        children: [
          _MetricRow(
            label: '실현손익',
            value: _formatSignedCurrency(report.realizedProfit),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '미실현손익',
            value: _formatSignedCurrency(report.unrealizedProfit),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '배당/이자',
            value: _formatSignedCurrency(report.incomeAmount),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '수수료',
            value: _formatSignedCurrency(-report.feeAmount),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '세금',
            value: _formatSignedCurrency(-report.taxAmount),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '순 실현성과',
            value: _formatSignedCurrency(report.pureRealizedPerformance),
            trailing: _formatSignedPercent(report.pureRealizedPerformanceRate),
          ),
          const Divider(height: 20),
          _MetricRow(
            label: '순 투자성과',
            value: _formatSignedCurrency(report.pureInvestmentPerformance),
            trailing: _formatSignedPercent(
              report.pureInvestmentPerformanceRate,
            ),
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

class _AdvancedPerformanceCard extends StatelessWidget {
  const _AdvancedPerformanceCard({required this.report});

  final _AdvancedPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '고급 성과',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdvancedMetricRow(
            label: '입출금 보정 기간 수익률',
            value: _formatSignedRatePercent(report.periodReturn),
            description: '입금과 출금을 제외하고 투자 자체가 만든 기간 수익률입니다.',
          ),
          const Divider(height: 22),
          _AdvancedMetricRow(
            label: '벤치마크',
            value: report.benchmarkReturn == null
                ? null
                : '${report.benchmarkLabel} ${_formatSignedRatePercent(report.benchmarkReturn)}',
            description: '선택한 기간의 시작값과 끝값으로 계산한 시장 기준 수익률입니다.',
          ),
          const Divider(height: 22),
          _AdvancedMetricRow(
            label: '초과수익률',
            value: _formatSignedPercentagePoint(report.excessReturn),
            description: '내 포트폴리오가 기준 시장보다 얼마나 더 높거나 낮았는지 보여줍니다.',
          ),
          const Divider(height: 22),
          _AdvancedMetricRow(
            label: '변동성',
            value: _formatAnnualizedPercent(report.annualizedVolatility),
            description: '기간 중 수익률이 얼마나 크게 흔들렸는지 나타냅니다.',
          ),
          const Divider(height: 22),
          _AdvancedMetricRow(
            label: '무위험수익률',
            value: _formatAnnualizedPercent(report.riskFreeRate),
            description: report.isRiskFreeRateFallback
                ? '금리 데이터를 가져오지 못해 0% 기준으로 Sharpe Ratio를 계산했습니다.'
                : '미국 13주 T-Bill 금리를 무위험수익률 기준으로 반영했습니다.',
          ),
          const Divider(height: 22),
          _AdvancedMetricRow(
            label: 'Sharpe Ratio',
            value: _formatDecimal(report.sharpeRatio),
            description:
                '변동성 대비 성과를 보는 지표입니다. ${report.riskFreeRateLabel}을 제외한 초과성과 기준입니다.',
          ),
          const Divider(height: 22),
          _AdvancedMetricRow(
            label: '최대 낙폭',
            value: _formatSignedRatePercent(report.maxDrawdown),
            description: '기간 중 고점에서 가장 깊게 하락했던 비율입니다.',
          ),
        ],
      ),
    );
  }
}

class _AdvancedMetricRow extends StatelessWidget {
  const _AdvancedMetricRow({
    required this.label,
    required this.value,
    required this.description,
  });

  final String label;
  final String? value;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value ?? '데이터 부족';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          displayValue,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleMedium?.copyWith(
            color: value == null
                ? MoneyfyPalette.tertiaryText
                : moneyfyValueColor(
                    displayValue,
                    defaultColor: MoneyfyPalette.ink,
                  ),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
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

class _HoldingPerformanceCard extends StatelessWidget {
  const _HoldingPerformanceCard({
    required this.items,
    required this.totalPerformanceBasis,
    required this.sortMode,
    required this.onSortModeChanged,
  });

  final List<_HoldingPerformance> items;
  final double totalPerformanceBasis;
  final _HoldingSortMode sortMode;
  final ValueChanged<_HoldingSortMode> onSortModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return SectionCard(
        title: '보유 항목별 성과',
        child: Text(
          '분석할 투자 거래가 아직 없습니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: MoneyfyPalette.tertiaryText,
          ),
        ),
      );
    }

    final sortedItems = _sortHoldingPerformance(items, sortMode);
    return SectionCard(
      title: '보유 항목별 성과',
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
        children: [
          for (var index = 0; index < sortedItems.length; index++) ...[
            _HoldingPerformanceRow(
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

class _RealizedProfitRankingCard extends StatelessWidget {
  const _RealizedProfitRankingCard({required this.items});

  final List<_HoldingPerformance> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return SectionCard(
        title: '종목별 실현손익',
        child: Text(
          '실현손익이 발생한 매도 거래가 아직 없습니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: MoneyfyPalette.tertiaryText,
          ),
        ),
      );
    }

    final visibleItems = items.take(10).toList(growable: false);
    return SectionCard(
      title: '종목별 실현손익',
      child: Column(
        children: [
          for (var index = 0; index < visibleItems.length; index++) ...[
            _RealizedProfitRankingRow(
              rank: index + 1,
              item: visibleItems[index],
            ),
            if (index != visibleItems.length - 1) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _RealizedProfitRankingRow extends StatelessWidget {
  const _RealizedProfitRankingRow({required this.rank, required this.item});

  final int rank;
  final _HoldingPerformance item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultText = _formatSignedCurrency(item.realizedProfit);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$rank',
            style: theme.textTheme.titleMedium?.copyWith(
              color: MoneyfyPalette.tertiaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                [
                  item.assetName,
                  if (item.symbol.trim().isNotEmpty) item.symbol,
                  item.currencyCode,
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          resultText,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleMedium?.copyWith(
            color: moneyfyValueColor(
              resultText,
              defaultColor: MoneyfyPalette.ink,
            ),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MonthlyPerformanceCard extends StatelessWidget {
  const _MonthlyPerformanceCard({required this.items});

  final List<_MonthlyPerformance> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return SectionCard(
        title: '월별 실현성과',
        child: Text(
          '월별로 집계할 실현 손익이 아직 없습니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: MoneyfyPalette.tertiaryText,
          ),
        ),
      );
    }

    final visibleItems = items.take(12).toList(growable: false);
    return SectionCard(
      title: '월별 실현성과',
      child: Column(
        children: [
          for (var index = 0; index < visibleItems.length; index++) ...[
            _MonthlyPerformanceRow(item: visibleItems[index]),
            if (index != visibleItems.length - 1) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _MonthlyPerformanceRow extends StatelessWidget {
  const _MonthlyPerformanceRow({required this.item});

  final _MonthlyPerformance item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultText = _formatSignedCurrency(item.pureRealizedPerformance);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.month, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '실현 ${_formatSignedCurrency(item.realizedProfit)} · 수입 ${_formatSignedCurrency(item.incomeAmount)} · 비용 ${_formatSignedCurrency(-item.totalExpenseAmount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          resultText,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleMedium?.copyWith(
            color: moneyfyValueColor(
              resultText,
              defaultColor: MoneyfyPalette.ink,
            ),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HoldingPerformanceRow extends StatelessWidget {
  const _HoldingPerformanceRow({
    required this.item,
    required this.totalPerformanceBasis,
  });

  final _HoldingPerformance item;
  final double totalPerformanceBasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text(item.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                [
                  item.assetName,
                  if (item.symbol.trim().isNotEmpty) item.symbol,
                  item.currencyCode,
                ].join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MoneyfyPalette.tertiaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '실현 ${_formatSignedCurrency(item.realizedProfit)} · 미실현 ${_formatSignedCurrency(item.unrealizedProfit)} · 수입 ${_formatSignedCurrency(item.incomeAmount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              resultText,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium?.copyWith(
                color: moneyfyValueColor(
                  resultText,
                  defaultColor: MoneyfyPalette.ink,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (contributionText != null) ...[
              const SizedBox(height: 4),
              Text(
                contributionText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.tertiaryText,
                ),
              ),
            ],
          ],
        ),
      ],
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
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium?.copyWith(
                color: moneyfyValueColor(
                  value,
                  defaultColor: MoneyfyPalette.ink,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(height: 3),
              Text(
                trailing!,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: moneyfyValueColor(
                    trailing!,
                    defaultColor: MoneyfyPalette.tertiaryText,
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
