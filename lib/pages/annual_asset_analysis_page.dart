import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/market_data_service.dart';
import '../theme/moneyfy_theme.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';
import 'snapshot_detail_page.dart';

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
      appBar: AppBar(
        title: const Text('연도별 자산분석'),
        backgroundColor: MoneyfyPalette.background,
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
          child: RefreshIndicator(
            onRefresh: _refreshPage,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _YearHeader(
                  year: selectedYear,
                  canMovePrev: years.indexOf(selectedYear) < years.length - 1,
                  canMoveNext: years.indexOf(selectedYear) > 0,
                  onPrev: () => _moveYear(1),
                  onNext: () => _moveYear(-1),
                ),
                const SizedBox(height: 16),
                _AnnualTrendCard(bundle: bundle),
                const SizedBox(height: 16),
                _AnnualGrowthSummaryCard(bundle: bundle),
                const SizedBox(height: 16),
                _AssetAverageCard(bundle: bundle),
                const SizedBox(height: 16),
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
          onPressed: canMovePrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Center(
            child: Text('$year년', style: theme.textTheme.headlineSmall),
          ),
        ),
        IconButton(
          onPressed: canMoveNext ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _AnnualTrendCard extends StatefulWidget {
  const _AnnualTrendCard({required this.bundle});

  final _YearBundle bundle;

  @override
  State<_AnnualTrendCard> createState() => _AnnualTrendCardState();
}

class _AnnualTrendCardState extends State<_AnnualTrendCard> {
  int? selectedIndex;

  @override
  void didUpdateWidget(covariant _AnnualTrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (selectedIndex == null) return;
    if (widget.bundle.monthLabels.isEmpty) {
      selectedIndex = null;
      return;
    }

    final maxIndex = widget.bundle.monthLabels.length - 1;
    if (selectedIndex! > maxIndex) {
      selectedIndex = maxIndex;
    }
  }

  void _handleSelection(Offset localPosition, double chartWidth) {
    if (widget.bundle.monthLabels.isEmpty || chartWidth <= 0) return;

    final safeDx = localPosition.dx.clamp(0.0, chartWidth);
    final denominator = math.max(widget.bundle.monthLabels.length - 1, 1);
    final index = ((safeDx / chartWidth) * denominator).round().clamp(
      0,
      widget.bundle.monthLabels.length - 1,
    );

    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartSeries = [
      widget.bundle.totalSeries,
      ...widget.bundle.assetSeries,
    ];
    final yAxisLabels = _buildYAxisLabels(chartSeries);

    return MoneyfySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월별 자산 변화', style: theme.textTheme.titleLarge),
          if (selectedIndex != null) ...[
            const SizedBox(height: 12),
            _SelectedValueRow(
              month: widget.bundle.monthLabels[selectedIndex!],
              values: [
                for (final item in chartSeries)
                  _SelectedSeriesValue(
                    label: item.label,
                    color: item.color,
                    value: '${item.values[selectedIndex!].toStringAsFixed(1)}M',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final label in yAxisLabels)
                          Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: MoneyfyPalette.tertiaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _handleSelection(
                          details.localPosition,
                          constraints.maxWidth,
                        ),
                        onHorizontalDragUpdate: (details) => _handleSelection(
                          details.localPosition,
                          constraints.maxWidth,
                        ),
                        child: CustomPaint(
                          painter: _MonthlyTrendPainter(
                            series: chartSeries,
                            selectedIndex: selectedIndex,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (
                                  var i = 0;
                                  i < widget.bundle.monthLabels.length;
                                  i++
                                )
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Text(
                                        widget.bundle.monthLabels[i],
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontSize: 12,
                                              color: selectedIndex == i
                                                  ? MoneyfyPalette.ink
                                                  : MoneyfyPalette.tertiaryText,
                                              fontWeight: selectedIndex == i
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final item in chartSeries)
                  _LegendTextItem(color: item.color, label: item.label),
              ],
            ),
          ),
        ],
      ),
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
          const SizedBox(height: 16),
          for (var i = 0; i < bundle.assetAverages.length; i++) ...[
            _ValueRow(
              label: bundle.assetAverages[i].label,
              value: _formatCurrency(bundle.assetAverages[i].averageValue),
            ),
            if (i != bundle.assetAverages.length - 1)
              const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            Text(
              '연도 비교를 위한 스냅샷 데이터가 부족합니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MoneyfyPalette.tertiaryText,
              ),
            ),
          ],
        ),
      );
    }

    final growthColor = _valueColor(bundle.annualGrowthAmount);
    return MoneyfySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('연 자산 증가 요약', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          _ValueRow(
            label: '연초 총자산',
            value: _formatCurrency(bundle.startTotalValue),
          ),
          const SizedBox(height: 10),
          _ValueRow(
            label: '연말 총자산',
            value: _formatCurrency(bundle.endTotalValue),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '연 증가 금액',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MoneyfyPalette.tertiaryText,
                  ),
                ),
              ),
              Text(
                _formatSignedCurrency(bundle.annualGrowthAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: growthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '연 증가율',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MoneyfyPalette.tertiaryText,
                  ),
                ),
              ),
              Text(
                _formatSignedPercent(bundle.annualGrowthRate),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: growthColor,
                  fontWeight: FontWeight.w600,
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
          const SizedBox(height: 16),
          for (var i = 0; i < bundle.monthRows.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SnapshotDetailPage(
                      snapshot: bundle.monthRows[i].snapshot,
                      items: bundle.monthRows[i].items,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: MoneyfyPalette.tertiaryText,
                    ),
                  ],
                ),
              ),
            ),
            if (i != bundle.monthRows.length - 1) const SizedBox(height: 10),
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
          .where((snapshot) => DateTime.parse(snapshot.snapshotDate).day == 20)
          .toList(growable: false)
        ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

  final validSnapshotIds = snapshots.map((snapshot) => snapshot.id).toSet();
  final snapshotIdToItems = <int, List<DailyPortfolioSnapshotItem>>{};
  for (final item in items) {
    if (!validSnapshotIds.contains(item.snapshotId)) continue;
    snapshotIdToItems.putIfAbsent(item.snapshotId, () => []).add(item);
  }

  final snapshotAssetTotals = <int, Map<String, double>>{};
  final assetLabelByKey = <String, String>{};
  final assetIdByKey = <String, int>{};
  for (final entry in snapshotIdToItems.entries) {
    final perAsset = <String, double>{};
    for (final item in entry.value) {
      final key = _annualAssetKey(item);
      perAsset[key] = (perAsset[key] ?? 0) + item.totalValuationAmount;
      assetLabelByKey.putIfAbsent(key, () => item.assetTitle);
      assetIdByKey.putIfAbsent(key, () => item.assetId);
    }
    snapshotAssetTotals[entry.key] = perAsset;
  }

  final monthLabels = trendSnapshots
      .map((snapshot) => '${DateTime.parse(snapshot.snapshotDate).month}월')
      .toList();

  final assetKeys =
      trendSnapshots
          .expand(
            (snapshot) =>
                (snapshotAssetTotals[snapshot.id] ?? const <String, double>{})
                    .keys,
          )
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));

  final assetSeries = assetKeys.map((assetKey) {
    final values = trendSnapshots.map((snapshot) {
      final totalForAsset =
          (snapshotAssetTotals[snapshot.id] ??
              const <String, double>{})[assetKey] ??
          0;
      return totalForAsset / 1000000;
    }).toList();
    final label = assetLabelByKey[assetKey] ?? '-';

    return _MonthlyAssetSeries(
      label: label,
      color: MoneyfyChartPalette.colorForAsset(
        label,
        assetId: assetIdByKey[assetKey],
        fallback: MoneyfyPalette.secondaryText,
      ),
      values: values,
    );
  }).toList()..sort((a, b) => a.label.compareTo(b.label));

  final totalSeries = _MonthlyAssetSeries(
    label: '총자산',
    color: MoneyfyPalette.ink,
    values: trendSnapshots.map((snapshot) {
      final total =
          (snapshotIdToItems[snapshot.id] ??
                  const <DailyPortfolioSnapshotItem>[])
              .fold<double>(0, (sum, item) => sum + item.totalValuationAmount);
      return total / 1000000;
    }).toList(),
  );

  final assetAverages = assetSeries.map((series) {
    final average = series.values.isEmpty
        ? 0.0
        : series.values.reduce((a, b) => a + b) / series.values.length;
    return _AssetAverage(label: series.label, averageValue: average * 1000000);
  }).toList()..sort((a, b) => b.averageValue.compareTo(a.averageValue));

  final monthRows = trendSnapshots.map((snapshot) {
    final date = DateTime.parse(snapshot.snapshotDate);
    final total =
        (snapshotIdToItems[snapshot.id] ?? const <DailyPortfolioSnapshotItem>[])
            .fold<double>(0, (sum, item) => sum + item.totalValuationAmount);
    return _MonthNavigationRow(
      label: '$year년 ${date.month}월',
      value: total,
      snapshot: snapshot,
      items:
          (snapshotIdToItems[snapshot.id] ??
                  const <DailyPortfolioSnapshotItem>[])
              .toList(),
    );
  }).toList();

  final startTotalValue = totalSeries.values.isEmpty
      ? 0.0
      : totalSeries.values.first * 1000000;
  final endTotalValue = totalSeries.values.isEmpty
      ? 0.0
      : totalSeries.values.last * 1000000;
  final hasAnnualComparison = totalSeries.values.length >= 2;
  final annualGrowthAmount = hasAnnualComparison
      ? endTotalValue - startTotalValue
      : 0.0;
  final annualGrowthRate = !hasAnnualComparison || startTotalValue == 0
      ? 0.0
      : (annualGrowthAmount / startTotalValue) * 100;

  return _YearBundle(
    year: year,
    monthLabels: monthLabels,
    totalSeries: totalSeries,
    assetSeries: assetSeries,
    assetAverages: assetAverages,
    monthRows: monthRows,
    hasAnnualComparison: hasAnnualComparison,
    startTotalValue: startTotalValue,
    endTotalValue: endTotalValue,
    annualGrowthAmount: annualGrowthAmount,
    annualGrowthRate: annualGrowthRate,
  );
}

String _annualAssetKey(DailyPortfolioSnapshotItem item) {
  return 'id:${item.assetId}';
}

bool _isFutureSnapshotDate(String snapshotDate) {
  final parsed = DateTime.tryParse(snapshotDate);
  if (parsed == null) return false;
  final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return dateOnly.isAfter(today);
}

class _SelectedValueRow extends StatelessWidget {
  const _SelectedValueRow({required this.month, required this.values});

  final String month;
  final List<_SelectedSeriesValue> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MoneyfyPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final item in values)
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MoneyfyPalette.secondaryText,
                    ),
                    children: [
                      TextSpan(
                        text: '${item.label} ',
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: item.value,
                        style: const TextStyle(
                          color: MoneyfyPalette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedSeriesValue {
  const _SelectedSeriesValue({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final String value;
}

class _LegendTextItem extends StatelessWidget {
  const _LegendTextItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '●',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: MoneyfyPalette.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
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
              color: MoneyfyPalette.tertiaryText,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: moneyfyValueColor(value),
          ),
        ),
      ],
    );
  }
}

class _MonthlyTrendPainter extends CustomPainter {
  _MonthlyTrendPainter({required this.series, required this.selectedIndex});

  final List<_MonthlyAssetSeries> series;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 12.0;
    const rightPadding = 12.0;
    const topPadding = 12.0;
    const bottomPadding = 28.0;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      size.width - leftPadding - rightPadding,
      size.height - topPadding - bottomPadding,
    );

    final allValues = series.expand((item) => item.values).toList();
    final minValue = allValues.isEmpty ? 0.0 : allValues.reduce(math.min);
    final maxValue = allValues.isEmpty ? 0.0 : allValues.reduce(math.max);
    final range = math.max(maxValue - minValue, 1.0);

    final gridPaint = Paint()
      ..color = MoneyfyPalette.border
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    if (selectedIndex != null &&
        series.isNotEmpty &&
        series.first.values.length > 1) {
      final selectedDx =
          chartRect.left +
          (chartRect.width / (series.first.values.length - 1)) * selectedIndex!;
      final indicatorPaint = Paint()
        ..color = MoneyfyPalette.tertiaryText.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(selectedDx, chartRect.top),
        Offset(selectedDx, chartRect.bottom),
        indicatorPaint,
      );
    }

    for (final item in series) {
      final path = Path();
      final dotPaint = Paint()..color = item.color;
      final linePaint = Paint()
        ..color = item.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (var i = 0; i < item.values.length; i++) {
        final dx = item.values.length == 1
            ? chartRect.center.dx
            : chartRect.left + (chartRect.width / (item.values.length - 1)) * i;
        final normalized = (item.values[i] - minValue) / range;
        final dy = chartRect.bottom - (chartRect.height * normalized);
        final point = Offset(dx, dy);

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }

        canvas.drawCircle(point, selectedIndex == i ? 5.5 : 3.5, dotPaint);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _MonthlyAssetSeries {
  const _MonthlyAssetSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double> values;
}

class _YearBundle {
  const _YearBundle({
    required this.year,
    required this.monthLabels,
    required this.totalSeries,
    required this.assetSeries,
    required this.assetAverages,
    required this.monthRows,
    required this.hasAnnualComparison,
    required this.startTotalValue,
    required this.endTotalValue,
    required this.annualGrowthAmount,
    required this.annualGrowthRate,
  });

  final int year;
  final List<String> monthLabels;
  final _MonthlyAssetSeries totalSeries;
  final List<_MonthlyAssetSeries> assetSeries;
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
    required this.items,
  });

  final String label;
  final double value;
  final DailyPortfolioSnapshot snapshot;
  final List<DailyPortfolioSnapshotItem> items;
}

List<String> _buildYAxisLabels(List<_MonthlyAssetSeries> series) {
  final allValues = series.expand((item) => item.values).toList();
  if (allValues.isEmpty) return const ['0M', '0M', '0M', '0M'];

  final minValue = allValues.reduce(math.min);
  final maxValue = allValues.reduce(math.max);
  final range = math.max(maxValue - minValue, 1.0);

  return List.generate(4, (index) {
    final value = maxValue - ((range / 3) * index);
    return '${value.toStringAsFixed(1)}M';
  });
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

Color _valueColor(double value) {
  if (value > 0) return MoneyfyPalette.positive;
  if (value < 0) return MoneyfyPalette.negative;
  return MoneyfyPalette.secondaryText;
}
