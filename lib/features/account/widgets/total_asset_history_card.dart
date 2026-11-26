import 'package:flutter/material.dart';
import 'package:moneyfy/components/charts/value_history_card.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/chart_palette.dart';

class TotalAssetHistoryCard extends StatelessWidget {
  const TotalAssetHistoryCard({
    super.key,
    required this.snapshots,
    this.initialPeriod = HistoryPeriod.quarter,
    required this.loadItems,
  });

  final HistoryPeriod initialPeriod;

  /// Snapshots ordered from oldest to newest.
  final List<DailyPortfolioSnapshot> snapshots;
  final Future<List<DailyPortfolioSnapshotItem>> Function(List<String>)
  loadItems;

  @override
  Widget build(BuildContext context) {
    final latest = snapshots.lastOrNull;
    final now = DateTime.now();
    return ValueHistoryCard(
      title: '총자산 변화',
      initialPeriod: initialPeriod,
      valueLabel: '총자산',
      chartLabel: '날짜별 총자산 차트',
      periodAverageLabel: '기간 평균 자산',
      through: latest == null
          ? DateTime.utc(now.year, now.month, now.day)
          : _snapshotDate(latest.snapshotDate),
      sourceKey: (snapshots, loadItems),
      loadPoints: _loadPoints,
    );
  }

  DateTime _snapshotDate(String key) => DateTime.parse('${key}T00:00:00Z');

  Future<List<HistoryPoint>> _loadPoints(
    DateTime from,
    DateTime through,
    bool Function() isCancelled,
  ) async {
    final firstDate = from.toIso8601String().split('T').first;
    final lastDate = through.toIso8601String().split('T').first;
    final datesById = {
      for (final snapshot in snapshots)
        if (snapshot.snapshotDate.compareTo(firstDate) >= 0 &&
            snapshot.snapshotDate.compareTo(lastDate) <= 0)
          snapshot.id: snapshot.snapshotDate,
    };
    if (datesById.isEmpty) return const [];
    final items = await loadItems(datesById.values.toList());
    if (isCancelled()) return const [];

    final breakdowns = <int, Map<Object, HistoryBreakdown>>{};
    for (final item in items) {
      final amount = item.totalValuationAmount;
      if (!amount.isFinite) continue;
      final breakdown = breakdowns.putIfAbsent(item.snapshotId, () => {});
      final label = item.assetTitle;
      breakdown[item.assetId] = (
        label: label,
        color: MoneyfyChartPalette.colorForAsset(label, assetId: item.assetId),
        value: amount + (breakdown[item.assetId]?.value ?? 0),
      );
    }
    final points = <HistoryPoint>[];
    for (final entry in datesById.entries) {
      final breakdown = breakdowns[entry.key];
      if (breakdown == null) continue;
      final total = breakdown.values.fold(0.0, (sum, item) => sum + item.value);
      if (!total.isFinite) continue;
      points.add(
        HistoryPoint(
          date: _snapshotDate(entry.value),
          value: total,
          breakdown: breakdown,
        ),
      );
    }
    return points;
  }
}
