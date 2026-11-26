import 'package:moneyfy/widgets/app_refresh_indicator.dart';
import 'package:moneyfy/utils/monthly_pivot.dart';
import 'package:moneyfy/components/charts/value_history_card.dart';
import 'package:moneyfy/features/account/widgets/total_asset_history_card.dart';

import 'package:flutter/material.dart';

import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';
import 'package:moneyfy/features/portfolio/screens/snapshot_detail_page.dart';

class AnnualAssetAnalysisPage extends StatefulWidget {
  const AnnualAssetAnalysisPage({
    super.key,
    required this.snapshots,
    required this.items,
  });

  final List<DailyPortfolioSnapshot> snapshots;
  final List<DailyPortfolioSnapshotItem> items;

  @override
  State<AnnualAssetAnalysisPage> createState() =>
      _AnnualAssetAnalysisPageState();
}

class _AnnualAssetAnalysisPageState extends State<AnnualAssetAnalysisPage> {
  late final List<int> years;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    final validSnapshots = widget.snapshots
        .where((snapshot) => !_isFutureSnapshotDate(snapshot.snapshotDate))
        .toList(growable: false);
    years =
        validSnapshots
            .map((snapshot) => DateTime.parse(snapshot.snapshotDate).year)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    selectedYear = years.isEmpty ? DateTime.now().year : years.first;
  }

  void _moveYear(int delta) {
    final currentIndex = years.indexOf(selectedYear);
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= years.length) return;
    setState(() {
      selectedYear = years[nextIndex];
    });
  }

  Future<void> _refreshPage() async {
    await MarketDataService.instance.refreshAllMarketData();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final snapshots =
        widget.snapshots
            .where(
              (snapshot) =>
                  DateTime.parse(snapshot.snapshotDate).year == selectedYear &&
                  !_isFutureSnapshotDate(snapshot.snapshotDate),
            )
            .toList()
          ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
    final bundle = _buildYearBundle(
      year: selectedYear,
      snapshots: snapshots,
      items: widget.items,
    );

    return Scaffold(
      backgroundColor: context.colors.neutralBackground,
      appBar: AppBar(
        title: const Text('연도별 자산 분석'),
        backgroundColor: context.colors.neutralBackground,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 250) {
              _moveYear(1);
            } else if (velocity < -250) {
              _moveYear(-1);
            }
          },
          child: AppRefreshIndicator(
            onRefresh: _refreshPage,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                context.spacing.md + context.spacing.xs / 2,
              ),
              children: [
                _YearHeader(
                  year: selectedYear,
                  canMovePrev: years.indexOf(selectedYear) < years.length - 1,
                  canMoveNext: years.indexOf(selectedYear) > 0,
                  onPrev: () => _moveYear(1),
                  onNext: () => _moveYear(-1),
                ),
                SizedBox(height: context.spacing.md),
                TotalAssetHistoryCard(
                  key: ValueKey(selectedYear),
                  snapshots: snapshots,
                  initialPeriod: HistoryPeriod.year,
                  loadItems: (dates) async {
                    final requestedDates = dates.toSet();
                    final ids = {
                      for (final s in snapshots)
                        if (requestedDates.contains(s.snapshotDate)) s.id,
                    };
                    return widget.items
                        .where((item) => ids.contains(item.snapshotId))
                        .toList();
                  },
                ),
                SizedBox(height: context.spacing.md),
                _AnnualGrowthSummaryCard(bundle: bundle),
                SizedBox(height: context.spacing.md),
                _AssetAverageCard(bundle: bundle),
                SizedBox(height: context.spacing.md),
                _MonthlyNavigationCard(bundle: bundle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({
    required this.year,
    required this.canMovePrev,
    required this.canMoveNext,
    required this.onPrev,
    required this.onNext,
  });

  final int year;
  final bool canMovePrev;
  final bool canMoveNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          tooltip: '이전 연도',
          onPressed: canMovePrev ? onPrev : null,
          icon: const AppIcon(AppIconName.chevronLeft),
        ),
        Expanded(
          child: Center(
            child: Text('$year년', style: theme.textTheme.headlineSmall),
          ),
        ),
        IconButton(
          tooltip: '다음 연도',
          onPressed: canMoveNext ? onNext : null,
          icon: const AppIcon(AppIconName.chevronRight),
        ),
      ],
    );
  }
}

class _AssetAverageCard extends StatelessWidget {
  const _AssetAverageCard({required this.bundle});

  final _YearBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MoneyfySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('자산별 연평균', style: theme.textTheme.titleLarge),
          SizedBox(height: context.spacing.md),
          for (var i = 0; i < bundle.assetAverages.length; i++) ...[
            _ValueRow(
              label: bundle.assetAverages[i].label,
              value: _formatCurrency(bundle.assetAverages[i].averageValue),
            ),
            if (i != bundle.assetAverages.length - 1)
              SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
          ],
        ],
      ),
    );
  }
}

class _AnnualGrowthSummaryCard extends StatelessWidget {
  const _AnnualGrowthSummaryCard({required this.bundle});

  final _YearBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!bundle.hasAnnualComparison) {
      return MoneyfySurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('연 자산 증가 요약', style: theme.textTheme.titleLarge),
            SizedBox(height: context.spacing.sm),
            Text(
              '연도 비교를 위한 스냅샷 데이터가 부족합니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.neutralTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    final growthColor = _valueTextColor(context, bundle.annualGrowthAmount);
    return MoneyfySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('연 자산 증가 요약', style: theme.textTheme.titleLarge),
          SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
          _ValueRow(
            label: '연초 총자산',
            value: _formatCurrency(bundle.startTotalValue),
          ),
          SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
          _ValueRow(
            label: '연말 총자산',
            value: _formatCurrency(bundle.endTotalValue),
          ),
          SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '연 증가 금액',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.neutralTextMuted,
                  ),
                ),
              ),
              Text(
                _formatSignedCurrency(bundle.annualGrowthAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: growthColor,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '연 증가율',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.neutralTextMuted,
                  ),
                ),
              ),
              Text(
                _formatSignedPercent(bundle.annualGrowthRate),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: growthColor,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyNavigationCard extends StatelessWidget {
  const _MonthlyNavigationCard({required this.bundle});

  final _YearBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MoneyfySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월별 정리', style: theme.textTheme.titleLarge),
          SizedBox(height: context.spacing.md),
          for (var i = 0; i < bundle.monthRows.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(context.radius.rMd),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SnapshotDetailPage(
                      snapshot: bundle.monthRows[i].snapshot,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        bundle.monthRows[i].label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      _formatCurrency(bundle.monthRows[i].value),
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(width: context.spacing.xs),
                    AppIcon(
                      AppIconName.chevronRight,
                      color: context.colors.neutralTextMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (i != bundle.monthRows.length - 1)
              SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
          ],
        ],
      ),
    );
  }
}

_YearBundle _buildYearBundle({
  required int year,
  required List<DailyPortfolioSnapshot> snapshots,
  required List<DailyPortfolioSnapshotItem> items,
}) {
  final trendSnapshots =
      snapshots
          .where(
            (snapshot) => MonthlyPivot.current.matches(
              DateTime.parse(snapshot.snapshotDate),
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

  final validSnapshotIds = snapshots.map((snapshot) => snapshot.id).toSet();
  final snapshotIdToItems = <int, List<DailyPortfolioSnapshotItem>>{};
  for (final item in items) {
    if (!validSnapshotIds.contains(item.snapshotId)) continue;
    snapshotIdToItems.putIfAbsent(item.snapshotId, () => []).add(item);
  }

  final totals = <int, double>{};
  final labels = <int, String>{};
  for (final snapshot in trendSnapshots) {
    for (final item
        in snapshotIdToItems[snapshot.id] ??
            const <DailyPortfolioSnapshotItem>[]) {
      totals.update(
        item.assetId,
        (v) => v + item.totalValuationAmount,
        ifAbsent: () => item.totalValuationAmount,
      );
      labels.putIfAbsent(item.assetId, () => item.assetTitle);
    }
  }
  final assetAverages = [
    for (final entry in totals.entries)
      _AssetAverage(
        label: labels[entry.key]!,
        averageValue: entry.value / trendSnapshots.length,
      ),
  ]..sort((a, b) => b.averageValue.compareTo(a.averageValue));

  final monthRows = trendSnapshots.map((snapshot) {
    final date = DateTime.parse(snapshot.snapshotDate);
    final total =
        (snapshotIdToItems[snapshot.id] ?? const <DailyPortfolioSnapshotItem>[])
            .fold<double>(0, (sum, item) => sum + item.totalValuationAmount);
    return _MonthNavigationRow(
      label: '$year년 ${date.month}월',
      value: total,
      snapshot: snapshot,
    );
  }).toList();

  final startTotalValue = monthRows.firstOrNull?.value ?? 0.0;
  final endTotalValue = monthRows.lastOrNull?.value ?? 0.0;
  final hasAnnualComparison = monthRows.length >= 2;
  final annualGrowthAmount = hasAnnualComparison
      ? endTotalValue - startTotalValue
      : 0.0;
  final annualGrowthRate = !hasAnnualComparison || startTotalValue == 0
      ? 0.0
      : (annualGrowthAmount / startTotalValue) * 100;

  return _YearBundle(
    assetAverages: assetAverages,
    monthRows: monthRows,
    hasAnnualComparison: hasAnnualComparison,
    startTotalValue: startTotalValue,
    endTotalValue: endTotalValue,
    annualGrowthAmount: annualGrowthAmount,
    annualGrowthRate: annualGrowthRate,
  );
}

bool _isFutureSnapshotDate(String snapshotDate) {
  final parsed = DateTime.tryParse(snapshotDate);
  if (parsed == null) return false;
  final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return dateOnly.isAfter(today);
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: _valueStringColor(context, value),
          ),
        ),
      ],
    );
  }
}

class _YearBundle {
  const _YearBundle({
    required this.assetAverages,
    required this.monthRows,
    required this.hasAnnualComparison,
    required this.startTotalValue,
    required this.endTotalValue,
    required this.annualGrowthAmount,
    required this.annualGrowthRate,
  });

  final List<_AssetAverage> assetAverages;
  final List<_MonthNavigationRow> monthRows;
  final bool hasAnnualComparison;
  final double startTotalValue;
  final double endTotalValue;
  final double annualGrowthAmount;
  final double annualGrowthRate;
}

class _AssetAverage {
  const _AssetAverage({required this.label, required this.averageValue});

  final String label;
  final double averageValue;
}

class _MonthNavigationRow {
  const _MonthNavigationRow({
    required this.label,
    required this.value,
    required this.snapshot,
  });

  final String label;
  final double value;
  final DailyPortfolioSnapshot snapshot;
}

String _formatCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}

String _formatSignedCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

String _formatSignedPercent(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(1)}%';
}

Color _valueTextColor(BuildContext context, double value) {
  if (value > 0) return context.colors.gainOn;
  if (value < 0) return context.colors.lossOn;
  return context.colors.neutralTextMuted;
}

Color _valueStringColor(BuildContext context, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return context.colors.neutralText;
  if (normalized.startsWith('-') || normalized.startsWith('−')) {
    return context.colors.lossOn;
  }
  if (normalized.startsWith('+')) return context.colors.gainOn;
  if (normalized.startsWith('(') && normalized.endsWith(')')) {
    return context.colors.lossOn;
  }
  if (normalized.contains('-') || normalized.contains('−')) {
    return context.colors.lossOn;
  }
  if (normalized.contains('+')) return context.colors.gainOn;
  return context.colors.neutralText;
}
