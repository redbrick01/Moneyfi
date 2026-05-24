import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/section_card.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../models/asset_item.dart';
import '../theme/moneyfy_theme.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';

class PortfolioAnalysisMvpPage extends StatelessWidget {
  const PortfolioAnalysisMvpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PortfolioAnalysisMvpData>(
      future: _loadPortfolioAnalysisMvpData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return MoneyfyPage(
          title: '포트폴리오 진단',
          subtitle: '위험 신호와 조정 후보를 먼저 확인해요',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting &&
                data == null)
              const _LoadingCard()
            else if (snapshot.hasError)
              const _MessageCard(
                icon: Icons.error_outline_rounded,
                title: '분석 데이터를 불러오지 못했어요',
                body: '잠시 후 다시 시도해 주세요.',
              )
            else if (data == null || data.assets.isEmpty)
              const _MessageCard(
                icon: Icons.add_chart_rounded,
                title: '분석할 자산이 없어요',
                body: '자산과 보유 종목을 추가하면 MVP 분석 구성을 확인할 수 있어요.',
              )
            else ...[
              _OverviewCard(data: data),
              SizedBox(height: context.spacing.sectionGap),
              _AttentionItemsCard(data: data),
              SizedBox(height: context.spacing.sectionGap),
              _RebalancePreviewCard(data: data),
              SizedBox(height: context.spacing.sectionGap),
              _PerformanceContributionCard(data: data),
              SizedBox(height: context.spacing.sectionGap),
              _AssetChangeCauseCard(data: data),
              SizedBox(height: context.spacing.sectionGap),
              _DrawdownCard(data: data),
              SizedBox(height: context.spacing.sectionGap),
              _ConcentrationCard(data: data),
            ],
          ],
        );
      },
    );
  }
}

Future<_PortfolioAnalysisMvpData> _loadPortfolioAnalysisMvpData() async {
  final db = AppDatabase.instance;
  final results = await Future.wait<Object>([
    db.fetchAssets(),
    db.fetchAssetAllocationTargets(),
    db.fetchRecentPortfolioSnapshots(maxDates: 60),
  ]);
  final assets = (results[0] as List<AssetItem>)
      .where((asset) => !asset.isHidden && asset.totalValuationAmount > 0)
      .toList(growable: false);
  final targetRatios = results[1] as Map<int, double>;
  final snapshots = results[2] as List<DailyPortfolioSnapshot>;
  final snapshotDates = snapshots
      .map((snapshot) => snapshot.snapshotDate)
      .toList(growable: false);
  final snapshotItems = await db.fetchDisplayPortfolioSnapshotItemsByDates(
    snapshotDates,
  );
  final visibleValuationBySnapshotId = <int, double>{};
  for (final item in snapshotItems) {
    visibleValuationBySnapshotId.update(
      item.snapshotId,
      (value) => value + item.totalValuationAmount,
      ifAbsent: () => item.totalValuationAmount,
    );
  }
  final riskSnapshots = snapshots
      .map(
        (snapshot) => snapshot.copyWith(
          totalValuationAmount:
              visibleValuationBySnapshotId[snapshot.id] ??
              snapshot.totalValuationAmount,
        ),
      )
      .toList(growable: false);
  return _PortfolioAnalysisMvpData(
    assets: assets,
    targetRatios: targetRatios,
    snapshots: snapshots,
    riskSnapshots: riskSnapshots,
  );
}

class _PortfolioAnalysisMvpData {
  const _PortfolioAnalysisMvpData({
    required this.assets,
    required this.targetRatios,
    required this.snapshots,
    required this.riskSnapshots,
  });

  final List<AssetItem> assets;
  final Map<int, double> targetRatios;
  final List<DailyPortfolioSnapshot> snapshots;
  final List<DailyPortfolioSnapshot> riskSnapshots;

  double get totalValue =>
      assets.fold<double>(0, (sum, asset) => sum + asset.totalValuationAmount);

  double get totalPurchase =>
      assets.fold<double>(0, (sum, asset) => sum + asset.totalPurchaseAmount);

  double get totalProfit => totalValue - totalPurchase;

  double get totalProfitRate {
    if (totalPurchase <= 0) return 0;
    return (totalProfit / totalPurchase) * 100;
  }

  List<_AssetMetric> get assetMetrics {
    if (totalValue <= 0) return const [];
    return assets
        .map(
          (asset) => _AssetMetric(
            asset: asset,
            ratio: (asset.totalValuationAmount / totalValue) * 100,
            targetRatio: asset.id == null ? null : targetRatios[asset.id!],
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<_HoldingConcentrationMetric> get holdingConcentrationMetrics {
    return assets
        .map(_HoldingConcentrationMetric.fromAsset)
        .where((metric) => metric != null)
        .cast<_HoldingConcentrationMetric>()
        .toList(growable: false)
      ..sort((a, b) => b.hhiScore.compareTo(a.hhiScore));
  }
}

class _AssetMetric {
  const _AssetMetric({
    required this.asset,
    required this.ratio,
    required this.targetRatio,
  });

  final AssetItem asset;
  final double ratio;
  final double? targetRatio;

  String get label => asset.displayName;
  double get value => asset.totalValuationAmount;
  double get profit => asset.totalProfitAmount;
  double get profitRate => asset.totalProfitRate;
  double get targetGap => targetRatio == null ? 0 : ratio - targetRatio!;
}

class _HoldingConcentrationMetric {
  const _HoldingConcentrationMetric({
    required this.assetLabel,
    required this.holdingCount,
    required this.topHoldingLabel,
    required this.topHoldingRatio,
    required this.hhiScore,
  });

  final String assetLabel;
  final int holdingCount;
  final String topHoldingLabel;
  final double topHoldingRatio;
  final int hhiScore;

  _HhiLevel get level => _HhiLevel.fromScore(hhiScore);

  static _HoldingConcentrationMetric? fromAsset(AssetItem asset) {
    final holdings = asset.visibleHoldings
        .where((holding) => holding.valuationAmount > 0)
        .toList(growable: false);
    if (holdings.isEmpty) return null;

    final total = holdings.fold<double>(
      0,
      (sum, holding) => sum + holding.valuationAmount,
    );
    if (total <= 0) return null;

    final ratios =
        holdings
            .map(
              (holding) => (
                label: holding.name.isEmpty ? holding.symbol : holding.name,
                ratio: (holding.valuationAmount / total) * 100,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.ratio.compareTo(a.ratio));

    final hhi = ratios.fold<double>(
      0,
      (sum, holding) => sum + math.pow(holding.ratio / 100, 2).toDouble(),
    );

    return _HoldingConcentrationMetric(
      assetLabel: asset.displayName,
      holdingCount: holdings.length,
      topHoldingLabel: ratios.first.label,
      topHoldingRatio: ratios.first.ratio,
      hhiScore: (hhi * 10000).round(),
    );
  }
}

class _AnalysisSectionCard extends StatelessWidget {
  const _AnalysisSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: context.typography.meta.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.data});

  final _PortfolioAnalysisMvpData data;

  @override
  Widget build(BuildContext context) {
    final diagnosis = _PortfolioDiagnosis.fromData(data);
    final drawdown = _calculateMaxDrawdown(data.riskSnapshots);
    final maxTargetGap = _maxTargetGap(data.assetMetrics);

    return _AnalysisSectionCard(
      title: '진단 요약',
      subtitle: '최근 자산과 스냅샷 기준',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosisHero(diagnosis: diagnosis),
          SizedBox(height: context.spacing.md),
          _SectionExplanation(text: diagnosis.reason),
          _MetricGrid(
            metrics: [
              _MetricTileData(
                label: '총자산',
                value: _formatAmount(data.totalValue),
                accent: MoneyfyPalette.info,
              ),
              _MetricTileData(
                label: '수익률',
                value: _formatSignedPercent(data.totalProfitRate),
                accent: _valueColor(data.totalProfit),
              ),
              _MetricTileData(
                label: '목표 이탈',
                value: maxTargetGap == null
                    ? '미설정'
                    : '${maxTargetGap.abs().toStringAsFixed(1)}%p',
                accent: maxTargetGap == null
                    ? MoneyfyPalette.tertiaryText
                    : maxTargetGap.abs() >= 5
                    ? MoneyfyPalette.warningStrong
                    : MoneyfyPalette.positive,
              ),
              _MetricTileData(
                label: '최대 낙폭',
                value: drawdown == null
                    ? '데이터 부족'
                    : '${drawdown.percent.toStringAsFixed(1)}%',
                accent: drawdown == null
                    ? MoneyfyPalette.tertiaryText
                    : MoneyfyPalette.negative,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionItemsCard extends StatelessWidget {
  const _AttentionItemsCard({required this.data});

  final _PortfolioAnalysisMvpData data;

  @override
  Widget build(BuildContext context) {
    final items = _buildAttentionItems(data);

    return _AnalysisSectionCard(
      title: '주의가 필요한 항목',
      subtitle: '먼저 확인할 위험 신호',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionExplanation(
            text: '상태가 나쁜 지표만 따로 찾지 않아도 되도록 집중도, 낙폭, 목표 이탈, 손익 영향을 한곳에 모았어요.',
          ),
          ...items.map((item) => _AttentionRow(item: item)),
        ],
      ),
    );
  }
}

class _RebalancePreviewCard extends StatelessWidget {
  const _RebalancePreviewCard({required this.data});

  final _PortfolioAnalysisMvpData data;

  @override
  Widget build(BuildContext context) {
    final entries =
        data.assetMetrics
            .where((item) => item.targetRatio != null)
            .toList(growable: false)
          ..sort((a, b) => b.targetGap.abs().compareTo(a.targetGap.abs()));

    return _AnalysisSectionCard(
      title: '조정 제안',
      subtitle: '목표 비중과 비교한 점검 후보',
      child: entries.isEmpty
          ? const _InlineNotice(
              icon: Icons.flag_outlined,
              title: '목표 비중이 아직 없어요',
              body: '포트폴리오 탭에서 목표 비중을 설정하면 축소/확대 후보를 볼 수 있어요.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  entries
                      .map<Widget>((item) {
                        final row = _RebalanceRow(
                          item: item,
                          totalValue: data.totalValue,
                        );
                        return row;
                      })
                      .take(5)
                      .toList()
                    ..insert(
                      0,
                      const _SectionExplanation(
                        text:
                            '목표보다 많이 보유한 자산은 축소 후보, 적게 보유한 자산은 확대 후보로 표시합니다. 실제 거래 판단 전 점검 정보로 봐주세요.',
                      ),
                    ),
            ),
    );
  }
}

class _PerformanceContributionCard extends StatelessWidget {
  const _PerformanceContributionCard({required this.data});

  final _PortfolioAnalysisMvpData data;

  @override
  Widget build(BuildContext context) {
    final entries = [...data.assetMetrics]
      ..sort((a, b) => b.profit.abs().compareTo(a.profit.abs()));
    final totalAbsProfit = entries.fold<double>(
      0,
      (sum, item) => sum + item.profit.abs(),
    );

    return _AnalysisSectionCard(
      title: '성과 기여도',
      subtitle: '손익 금액 기준으로 포트폴리오에 미친 영향',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionExplanation(
            text: '손익 금액이 큰 순서로 정렬해서 어떤 자산이 전체 성과를 가장 많이 움직였는지 보여줍니다.',
          ),
          ...entries
              .take(5)
              .indexed
              .map(
                (entry) => _ContributionRow(
                  rank: entry.$1 + 1,
                  label: entry.$2.label,
                  value: entry.$2.profit,
                  ratio: entry.$2.profitRate,
                  contributionRatio: totalAbsProfit == 0
                      ? 0
                      : (entry.$2.profit.abs() / totalAbsProfit) * 100,
                ),
              ),
        ],
      ),
    );
  }
}

class _AssetChangeCauseCard extends StatelessWidget {
  const _AssetChangeCauseCard({required this.data});

  final _PortfolioAnalysisMvpData data;

  @override
  Widget build(BuildContext context) {
    if (data.snapshots.length < 2) {
      return const _AnalysisSectionCard(
        title: '자산 변화 원인',
        subtitle: '스냅샷 기반 테스트 분석',
        child: _InlineNotice(
          icon: Icons.calendar_month_outlined,
          title: '스냅샷이 2개 이상 필요해요',
          body: '스냅샷이 쌓이면 총자산 변화와 평가손익 변화를 분해해서 보여줄 수 있어요.',
        ),
      );
    }

    final first = data.snapshots.first;
    final last = data.snapshots.last;
    final totalChange = last.totalValuationAmount - first.totalValuationAmount;
    final profitChange = last.profitAmount - first.profitAmount;
    final estimatedCashOrCostChange = totalChange - profitChange;
    return _AnalysisSectionCard(
      title: '자산 변화 원인',
      subtitle: '${first.snapshotDate} ~ ${last.snapshotDate}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionExplanation(
            text: '스냅샷의 총자산 변화에서 평가손익 변화를 뺀 값으로 입출금 또는 원금 변화 영향을 추정합니다.',
          ),
          _CauseRow(
            label: '총자산 변화',
            value: totalChange,
            note: '기간 시작 대비 현재 총자산 차이',
          ),
          _CauseRow(
            label: '평가손익 변화',
            value: profitChange,
            note: '보유 자산 평가손익의 순변화',
          ),
          _CauseRow(
            label: '입출금/원금 변화 추정',
            value: estimatedCashOrCostChange,
            note: '총자산 변화에서 평가손익 변화를 제외한 값',
          ),
        ],
      ),
    );
  }
}

class _DrawdownCard extends StatelessWidget {
  const _DrawdownCard({required this.data});

  final _PortfolioAnalysisMvpData data;

  @override
  Widget build(BuildContext context) {
    final drawdown = _calculateMaxDrawdown(data.riskSnapshots);
    final drawdownLevel = drawdown == null
        ? null
        : _MddLevel.fromPercent(drawdown.percent);
    return _AnalysisSectionCard(
      title: '최대 낙폭 MDD',
      subtitle: '스냅샷 고점 대비 가장 크게 하락한 구간',
      child: drawdown == null
          ? const _InlineNotice(
              icon: Icons.show_chart_rounded,
              title: '스냅샷 데이터가 부족해요',
              body: '2개 이상의 스냅샷이 있어야 고점 대비 하락률을 계산할 수 있어요.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionExplanation(
                  text:
                      '선택된 스냅샷 기간에서 고점 이후 가장 크게 내려간 구간을 계산합니다. 앱에서는 5%, 15%, 30%를 기준으로 체감 위험 구간을 나눕니다.',
                ),
                _MddGauge(percent: drawdown.percent, level: drawdownLevel!),
                const SizedBox(height: 14),
                _MddDetailGrid(drawdown: drawdown),
              ],
            ),
    );
  }
}

class _ConcentrationCard extends StatefulWidget {
  const _ConcentrationCard({required this.data});

  final _PortfolioAnalysisMvpData data;

  @override
  State<_ConcentrationCard> createState() => _ConcentrationCardState();
}

class _ConcentrationCardState extends State<_ConcentrationCard> {
  bool _isHoldingDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final entries = data.assetMetrics;
    final topOne = entries.isEmpty ? 0.0 : entries.first.ratio;
    final topThree = entries
        .take(3)
        .fold<double>(0, (sum, item) => sum + item.ratio);
    final hhi = entries.fold<double>(
      0,
      (sum, item) => sum + math.pow(item.ratio / 100, 2).toDouble(),
    );
    final hhiScore = (hhi * 10000).round();
    final hhiLevel = _HhiLevel.fromScore(hhiScore);
    final holdingMetrics = data.holdingConcentrationMetrics;

    return _AnalysisSectionCard(
      title: '집중도 위험',
      subtitle: 'DOJ/FTC HHI 기준을 포트폴리오에 적용',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionExplanation(
            text:
                '미국 DOJ/FTC 시장집중도 기준을 차용해 포트폴리오 쏠림을 해석합니다. 1,000 이하는 낮음, 1,000~1,800은 중간, 1,800 초과는 높은 집중도로 봅니다.',
          ),
          _HhiGauge(score: hhiScore, level: hhiLevel),
          const SizedBox(height: 18),
          _MetricGrid(
            metrics: [
              _MetricTileData(
                label: 'HHI 구간',
                value: hhiLevel.label,
                accent: hhiLevel.color,
              ),
              _MetricTileData(
                label: 'HHI',
                value: '$hhiScore',
                accent: hhiLevel.color,
              ),
              _MetricTileData(
                label: '1위 자산',
                value: '${topOne.toStringAsFixed(1)}%',
                accent: topOne >= 50
                    ? MoneyfyPalette.warningStrong
                    : MoneyfyPalette.info,
              ),
              _MetricTileData(
                label: '상위 3개',
                value: '${topThree.toStringAsFixed(1)}%',
                accent: topThree >= 70
                    ? MoneyfyPalette.warningStrong
                    : MoneyfyPalette.info,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (holdingMetrics.isNotEmpty) ...[
            _ExpandableSubsectionHeader(
              title: '자산 내부 홀딩 집중도',
              subtitle: '각 자산 안에서 특정 종목/계좌에 얼마나 몰려 있는지 확인합니다.',
              count: holdingMetrics.length,
              isExpanded: _isHoldingDetailsExpanded,
              onTap: () {
                setState(() {
                  _isHoldingDetailsExpanded = !_isHoldingDetailsExpanded;
                });
              },
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: holdingMetrics
                      .take(6)
                      .map((metric) => _HoldingConcentrationRow(metric: metric))
                      .toList(),
                ),
              ),
              crossFadeState: _isHoldingDetailsExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 18,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(context.radius.rSm),
            ),
          ),
          SizedBox(height: context.spacing.md),
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(context.radius.rMd),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisHero extends StatelessWidget {
  const _DiagnosisHero({required this.diagnosis});

  final _PortfolioDiagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: diagnosis.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: diagnosis.color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MoneyfyPalette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: diagnosis.color.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(diagnosis.icon, color: diagnosis.color),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MoneyfyPalette.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: diagnosis.color.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  diagnosis.label,
                  style: context.typography.meta.copyWith(
                    color: diagnosis.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            diagnosis.message,
            style: context.typography.sectionTitle.copyWith(
              color: MoneyfyPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionItem {
  const _AttentionItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final String value;
  final Color color;
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final _AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MoneyfyPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoneyfyPalette.borderNeutral),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MoneyfyPalette.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: item.color.withValues(alpha: 0.20)),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: context.typography.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: context.typography.meta.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 108),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  item.value,
                  textAlign: TextAlign.right,
                  style: context.typography.cardTitle.copyWith(
                    color: item.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: _InlineNotice(icon: icon, title: title, body: body),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MoneyfyPalette.infoBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: MoneyfyPalette.info),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.typography.cardTitle),
              const SizedBox(height: 6),
              Text(
                body,
                style: context.typography.body.copyWith(
                  color: MoneyfyPalette.tertiaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionExplanation extends StatelessWidget {
  const _SectionExplanation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: context.typography.body.copyWith(
          color: MoneyfyPalette.tertiaryText,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ExpandableSubsectionHeader extends StatelessWidget {
  const _ExpandableSubsectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MoneyfyPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoneyfyPalette.borderNeutral),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: context.typography.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: MoneyfyPalette.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: MoneyfyPalette.borderNeutral,
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: context.typography.meta.copyWith(
                            color: MoneyfyPalette.tertiaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: context.typography.meta.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricTileData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final columns = ((constraints.maxWidth + gap) / (140 + gap))
            .floor()
            .clamp(1, 3);
        final tileWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: tileWidth,
                  child: _MetricTile(data: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _HhiGauge extends StatelessWidget {
  const _HhiGauge({required this.score, required this.level});

  final int score;
  final _HhiLevel level;

  @override
  Widget build(BuildContext context) {
    final markerPosition = (score / 10000).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MoneyfyPalette.borderNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 HHI',
                      style: context.typography.meta.copyWith(
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score',
                      style: context.typography.pageTitle.copyWith(
                        color: level.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: level.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: level.color.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  level.label,
                  style: context.typography.meta.copyWith(
                    color: level.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const markerSize = 16.0;
              const markerRadius = markerSize / 2;
              final trackLeft = markerRadius;
              final trackWidth = math.max(
                0.0,
                constraints.maxWidth - markerSize,
              );
              double gaugeX(double ratio) => trackLeft + (trackWidth * ratio);
              final markerCenter = gaugeX(markerPosition);
              return SizedBox(
                height: 76,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: trackLeft,
                      width: trackWidth,
                      top: 17,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: ColoredBox(
                                color: MoneyfyPalette.successBg,
                                child: SizedBox(height: 10),
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: ColoredBox(
                                color: Color(0xFFFFF4D8),
                                child: SizedBox(height: 10),
                              ),
                            ),
                            Expanded(
                              flex: 82,
                              child: ColoredBox(
                                color: MoneyfyPalette.errorBg,
                                child: SizedBox(height: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: gaugeX(0.10) - 1,
                      top: 10,
                      height: 34,
                      child: const _GaugeThresholdLine(),
                    ),
                    Positioned(
                      left: gaugeX(0.18) - 1,
                      top: 10,
                      height: 34,
                      child: const _GaugeThresholdLine(),
                    ),
                    Positioned(
                      left: markerCenter - markerRadius,
                      top: 6,
                      child: Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: level.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MoneyfyPalette.surface,
                                width: 3,
                              ),
                            ),
                          ),
                          Container(width: 2, height: 22, color: level.color),
                        ],
                      ),
                    ),
                    _GaugeThresholdLabel(
                      left: gaugeX(0.10),
                      top: 46,
                      width: constraints.maxWidth,
                      label: '1,000',
                    ),
                    _GaugeThresholdLabel(
                      left: gaugeX(0.18),
                      top: 58,
                      width: constraints.maxWidth,
                      label: '1,800',
                    ),
                  ],
                ),
              );
            },
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: Text(
                  '낮음',
                  style: context.typography.meta.copyWith(
                    color: MoneyfyPalette.positive,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 8,
                child: Text(
                  '중간',
                  textAlign: TextAlign.center,
                  style: context.typography.meta.copyWith(
                    color: MoneyfyPalette.warningStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 82,
                child: Text(
                  '높음',
                  textAlign: TextAlign.right,
                  style: context.typography.meta.copyWith(
                    color: MoneyfyPalette.negative,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _MddGauge extends StatelessWidget {
  const _MddGauge({required this.percent, required this.level});

  final double percent;
  final _MddLevel level;

  @override
  Widget build(BuildContext context) {
    final drawdown = percent.abs();
    final markerPosition = (drawdown / 50).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MoneyfyPalette.borderNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 MDD',
                      style: context.typography.meta.copyWith(
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: context.typography.pageTitle.copyWith(
                        color: level.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: level.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: level.color.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  level.label,
                  style: context.typography.meta.copyWith(
                    color: level.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const segments = [
                _GaugeSegment(
                  start: 0,
                  end: 0.10,
                  label: '낮음',
                  color: MoneyfyPalette.successBg,
                  textColor: MoneyfyPalette.positive,
                ),
                _GaugeSegment(
                  start: 0.10,
                  end: 0.30,
                  label: '주의',
                  color: Color(0xFFFFF4D8),
                  textColor: MoneyfyPalette.warningStrong,
                ),
                _GaugeSegment(
                  start: 0.30,
                  end: 0.60,
                  label: '높음',
                  color: Color(0xFFFFE7D6),
                  textColor: MoneyfyPalette.errorSoft,
                ),
                _GaugeSegment(
                  start: 0.60,
                  end: 1,
                  label: '심각',
                  color: MoneyfyPalette.errorBg,
                  textColor: MoneyfyPalette.negative,
                ),
              ];
              const markerSize = 16.0;
              const markerRadius = markerSize / 2;
              final trackLeft = markerRadius;
              final trackWidth = math.max(
                0.0,
                constraints.maxWidth - markerSize,
              );
              double gaugeX(double ratio) => trackLeft + (trackWidth * ratio);
              final markerCenter = gaugeX(markerPosition);

              Widget labelFor(_GaugeSegment segment) {
                final width = trackWidth * (segment.end - segment.start);
                return Positioned(
                  left: gaugeX(segment.start),
                  width: width,
                  top: 0,
                  child: Text(
                    segment.label,
                    textAlign: segment.start == 0
                        ? TextAlign.left
                        : segment.end == 1
                        ? TextAlign.right
                        : TextAlign.center,
                    style: context.typography.meta.copyWith(
                      color: segment.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: trackLeft,
                          width: trackWidth,
                          top: 17,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              height: 10,
                              child: Stack(
                                children: [
                                  for (final segment in segments)
                                    Positioned(
                                      left: trackWidth * segment.start,
                                      width:
                                          trackWidth *
                                          (segment.end - segment.start),
                                      top: 0,
                                      bottom: 0,
                                      child: ColoredBox(color: segment.color),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: gaugeX(0.10) - 1,
                          top: 10,
                          height: 34,
                          child: const _GaugeThresholdLine(),
                        ),
                        Positioned(
                          left: gaugeX(0.30) - 1,
                          top: 10,
                          height: 34,
                          child: const _GaugeThresholdLine(),
                        ),
                        Positioned(
                          left: gaugeX(0.60) - 1,
                          top: 10,
                          height: 34,
                          child: const _GaugeThresholdLine(),
                        ),
                        Positioned(
                          left: markerCenter - markerRadius,
                          top: 6,
                          child: Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: level.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: MoneyfyPalette.surface,
                                    width: 3,
                                  ),
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 22,
                                color: level.color,
                              ),
                            ],
                          ),
                        ),
                        _GaugeThresholdLabel(
                          left: gaugeX(0.10),
                          top: 46,
                          width: constraints.maxWidth,
                          label: '5%',
                        ),
                        _GaugeThresholdLabel(
                          left: gaugeX(0.30),
                          top: 46,
                          width: constraints.maxWidth,
                          label: '15%',
                        ),
                        _GaugeThresholdLabel(
                          left: gaugeX(0.60),
                          top: 46,
                          width: constraints.maxWidth,
                          label: '30%',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    child: Stack(
                      children: [for (final s in segments) labelFor(s)],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MddDetailGrid extends StatelessWidget {
  const _MddDetailGrid({required this.drawdown});

  final _DrawdownResult drawdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MoneyfyPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MoneyfyPalette.borderNeutral),
          ),
          child: Row(
            children: [
              Expanded(
                child: _DateMetricText(label: '고점', value: drawdown.peakDate),
              ),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: MoneyfyPalette.borderNeutral,
              ),
              Expanded(
                child: _DateMetricText(label: '저점', value: drawdown.troughDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompactMetricBlock(
          label: '하락 금액',
          value: _formatSignedAmount(drawdown.amount),
          color: MoneyfyPalette.negative,
        ),
      ],
    );
  }
}

class _GaugeSegment {
  const _GaugeSegment({
    required this.start,
    required this.end,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final double start;
  final double end;
  final String label;
  final Color color;
  final Color textColor;
}

class _DateMetricText extends StatelessWidget {
  const _DateMetricText({required this.label, required this.value});

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
            color: MoneyfyPalette.tertiaryText,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.typography.body.copyWith(
              color: MoneyfyPalette.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _GaugeThresholdLine extends StatelessWidget {
  const _GaugeThresholdLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      decoration: BoxDecoration(
        color: MoneyfyPalette.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _GaugeThresholdLabel extends StatelessWidget {
  const _GaugeThresholdLabel({
    required this.left,
    required this.top,
    required this.width,
    required this.label,
  });

  final double left;
  final double top;
  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    const labelWidth = 52.0;
    final resolvedLeft = (left - (labelWidth / 2)).clamp(
      0.0,
      math.max(0.0, width - labelWidth),
    ).toDouble();

    return Positioned(
      left: resolvedLeft,
      top: top,
      width: labelWidth,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.typography.meta.copyWith(
          color: MoneyfyPalette.tertiaryText,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HhiLevel {
  const _HhiLevel({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  static _HhiLevel fromScore(int score) {
    if (score <= 1000) {
      return const _HhiLevel(
        label: '낮은 집중',
        color: MoneyfyPalette.positive,
        background: MoneyfyPalette.successBg,
      );
    }
    if (score <= 1800) {
      return const _HhiLevel(
        label: '중간 집중',
        color: MoneyfyPalette.warningStrong,
        background: Color(0xFFFFF4D8),
      );
    }
    return const _HhiLevel(
      label: '높은 집중',
      color: MoneyfyPalette.negative,
      background: MoneyfyPalette.errorBg,
    );
  }
}

class _MddLevel {
  const _MddLevel({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  static _MddLevel fromPercent(double percent) {
    final drawdown = percent.abs();
    if (drawdown <= 5) {
      return const _MddLevel(
        label: '낮은 낙폭',
        color: MoneyfyPalette.positive,
        background: MoneyfyPalette.successBg,
      );
    }
    if (drawdown <= 15) {
      return const _MddLevel(
        label: '주의 구간',
        color: MoneyfyPalette.warningStrong,
        background: Color(0xFFFFF4D8),
      );
    }
    if (drawdown <= 30) {
      return const _MddLevel(
        label: '높은 낙폭',
        color: MoneyfyPalette.errorSoft,
        background: Color(0xFFFFE7D6),
      );
    }
    return const _MddLevel(
      label: '심각한 낙폭',
      color: MoneyfyPalette.negative,
      background: MoneyfyPalette.errorBg,
    );
  }
}

class _MetricTileData {
  const _MetricTileData({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MoneyfyPalette.borderNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.label,
            style: context.typography.meta.copyWith(
              color: MoneyfyPalette.tertiaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: context.typography.cardTitle.copyWith(color: data.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _RebalanceRow extends StatelessWidget {
  const _RebalanceRow({required this.item, required this.totalValue});

  final _AssetMetric item;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    final gapAmount = totalValue * (item.targetGap / 100);
    final action = item.targetGap.abs() <= 3
        ? '정상 범위'
        : item.targetGap > 0
        ? '축소 후보'
        : '확대 후보';
    final color = item.targetGap.abs() < 1
        ? MoneyfyPalette.tertiaryText
        : item.targetGap > 0
        ? MoneyfyPalette.warningStrong
        : MoneyfyPalette.info;
    return _AnalysisRowShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoPairRow(
            label: item.label,
            value: action,
            valueColor: color,
            dense: true,
          ),
          const SizedBox(height: 8),
          _ProgressLine(gapPercent: item.targetGap, color: color),
          const SizedBox(height: 8),
          Text(
            '현재 ${item.ratio.toStringAsFixed(1)}% · 목표 ${item.targetRatio!.toStringAsFixed(1)}% · 차이 ${item.targetGap >= 0 ? '+' : ''}${item.targetGap.toStringAsFixed(1)}%p (${_formatSignedAmount(gapAmount)})',
            style: context.typography.meta.copyWith(
              color: MoneyfyPalette.tertiaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({
    required this.rank,
    required this.label,
    required this.value,
    required this.ratio,
    required this.contributionRatio,
  });

  final int rank;
  final String label;
  final double value;
  final double ratio;
  final double contributionRatio;

  @override
  Widget build(BuildContext context) {
    final color = _valueColor(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MoneyfyPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoneyfyPalette.borderNeutral),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MoneyfyPalette.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: MoneyfyPalette.borderNeutral),
                  ),
                  child: Text(
                    '$rank',
                    style: context.typography.meta.copyWith(
                      color: MoneyfyPalette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: context.typography.body.copyWith(
                      color: MoneyfyPalette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatSignedAmount(value),
                  style: context.typography.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CompactMetricBlock(
                    label: '수익률',
                    value: _formatSignedPercent(ratio),
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactMetricBlock(
                    label: '기여율',
                    value: '${contributionRatio.toStringAsFixed(1)}%',
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value >= 0 ? '전체 손익을 끌어올린 자산입니다.' : '전체 손익을 낮춘 자산입니다.',
              style: context.typography.meta.copyWith(
                color: MoneyfyPalette.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CauseRow extends StatelessWidget {
  const _CauseRow({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final double value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final color = _valueColor(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MoneyfyPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoneyfyPalette.borderNeutral),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.typography.body.copyWith(
                color: MoneyfyPalette.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatSignedAmount(value),
              style: context.typography.cardTitle.copyWith(color: color),
            ),
            const SizedBox(height: 6),
            Text(
              note,
              style: context.typography.meta.copyWith(
                color: MoneyfyPalette.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingConcentrationRow extends StatelessWidget {
  const _HoldingConcentrationRow({required this.metric});

  final _HoldingConcentrationMetric metric;

  @override
  Widget build(BuildContext context) {
    final level = metric.level;
    final topHoldingColor = metric.topHoldingRatio >= 50
        ? MoneyfyPalette.warningStrong
        : MoneyfyPalette.info;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MoneyfyPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MoneyfyPalette.borderNeutral),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    metric.assetLabel,
                    style: context.typography.body.copyWith(
                      color: MoneyfyPalette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: level.background,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: level.color.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    level.label,
                    style: context.typography.meta.copyWith(
                      color: level.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CompactMetricBlock(
                    label: '내부 HHI',
                    value: '${metric.hhiScore}',
                    color: level.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompactMetricBlock(
                    label: '1위 비중',
                    value: '${metric.topHoldingRatio.toStringAsFixed(1)}%',
                    color: topHoldingColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MoneyfyPalette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MoneyfyPalette.borderNeutral),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1위 홀딩',
                    style: context.typography.meta.copyWith(
                      color: MoneyfyPalette.tertiaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.topHoldingLabel,
                    style: context.typography.body.copyWith(
                      color: MoneyfyPalette.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '홀딩 ${metric.holdingCount}개 기준으로 계산',
              style: context.typography.meta.copyWith(
                color: MoneyfyPalette.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetricBlock extends StatelessWidget {
  const _CompactMetricBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MoneyfyPalette.borderNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.typography.meta.copyWith(
              color: MoneyfyPalette.tertiaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: context.typography.cardTitle.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisRowShell extends StatelessWidget {
  const _AnalysisRowShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(padding: const EdgeInsets.only(bottom: 14), child: child),
    );
  }
}

class _InfoPairRow extends StatelessWidget {
  const _InfoPairRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.dense = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.typography.body.copyWith(
      color: MoneyfyPalette.secondaryText,
    );
    final valueStyle = context.typography.body.copyWith(
      color: valueColor ?? MoneyfyPalette.ink,
      fontWeight: FontWeight.w700,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(value, style: valueStyle, maxLines: 2),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: valueStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.gapPercent, required this.color});

  final double gapPercent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = constraints.maxWidth / 2;
          final fillWidth = center * (gapPercent.abs() / 20).clamp(0.0, 1.0);
          final fillLeft = gapPercent >= 0 ? center : center - fillWidth;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const ColoredBox(
                    color: MoneyfyPalette.borderNeutral,
                    child: SizedBox(height: 8),
                  ),
                ),
              ),
              Positioned(
                left: fillLeft,
                top: 3,
                width: fillWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: ColoredBox(
                    color: color,
                    child: const SizedBox(height: 8),
                  ),
                ),
              ),
              Positioned(
                left: center - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: MoneyfyPalette.secondaryText.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PortfolioDiagnosis {
  const _PortfolioDiagnosis({
    required this.label,
    required this.message,
    required this.reason,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String message;
  final String reason;
  final IconData icon;
  final Color color;
  final Color background;

  static _PortfolioDiagnosis fromData(_PortfolioAnalysisMvpData data) {
    final topThreeRatio = _topThreeRatio(data.assetMetrics);
    final hhiScore = _hhiScore(data.assetMetrics);
    final drawdown = _calculateMaxDrawdown(data.riskSnapshots);
    final maxTargetGap = _maxTargetGap(data.assetMetrics)?.abs();
    final drawdownAbs = drawdown?.percent.abs() ?? 0;

    if (topThreeRatio >= 80 || hhiScore > 2500 || drawdownAbs >= 30) {
      return const _PortfolioDiagnosis(
        label: '위험',
        message: '포트폴리오 쏠림이나 낙폭을 먼저 점검해야 해요.',
        reason: '상위 자산 비중, 집중도, 최근 낙폭 중 하나 이상이 높은 구간에 있어요.',
        icon: Icons.warning_amber_rounded,
        color: MoneyfyPalette.negative,
        background: MoneyfyPalette.errorBg,
      );
    }

    if (topThreeRatio >= 70 || hhiScore > 1800 || drawdownAbs >= 15) {
      return const _PortfolioDiagnosis(
        label: '주의',
        message: '상위 자산 비중이 높아 변동성에 취약할 수 있어요.',
        reason: '집중도와 낙폭 지표를 함께 보고, 목표 비중과 크게 벗어난 자산이 있는지 확인해 보세요.',
        icon: Icons.report_problem_outlined,
        color: MoneyfyPalette.warningStrong,
        background: Color(0xFFFFF4D8),
      );
    }

    if (maxTargetGap != null && maxTargetGap >= 5) {
      return const _PortfolioDiagnosis(
        label: '주의',
        message: '목표 비중과 크게 벗어난 자산이 있어요.',
        reason: '전체 위험은 높지 않지만, 목표 대비 초과 또는 부족한 자산을 조정 후보로 점검할 수 있어요.',
        icon: Icons.tune_rounded,
        color: MoneyfyPalette.warningStrong,
        background: Color(0xFFFFF4D8),
      );
    }

    if (data.totalProfit < 0) {
      return const _PortfolioDiagnosis(
        label: '점검',
        message: '손실 자산이 전체 성과를 낮추고 있어요.',
        reason: '집중도 위험은 제한적이지만, 성과 기여도에서 손실 영향이 큰 자산을 확인해 보세요.',
        icon: Icons.query_stats_rounded,
        color: MoneyfyPalette.info,
        background: MoneyfyPalette.infoBg,
      );
    }

    return const _PortfolioDiagnosis(
      label: '양호',
      message: '큰 위험 신호는 낮은 편이에요.',
      reason: '현재 기준으로 집중도와 낙폭이 과도하지 않습니다. 목표 비중을 설정해두면 조정 후보를 더 정확히 볼 수 있어요.',
      icon: Icons.check_circle_outline_rounded,
      color: MoneyfyPalette.positive,
      background: MoneyfyPalette.successBg,
    );
  }
}

class _DrawdownResult {
  const _DrawdownResult({
    required this.percent,
    required this.amount,
    required this.peakDate,
    required this.troughDate,
  });

  final double percent;
  final double amount;
  final String peakDate;
  final String troughDate;
}

_DrawdownResult? _calculateMaxDrawdown(List<DailyPortfolioSnapshot> snapshots) {
  if (snapshots.length < 2) return null;

  final sorted = [...snapshots]
    ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

  var peakValue = sorted.first.totalValuationAmount;
  var peakDate = sorted.first.snapshotDate;
  var worstPercent = 0.0;
  var worstAmount = 0.0;
  var worstPeakDate = peakDate;
  var worstTroughDate = sorted.first.snapshotDate;

  for (final snapshot in sorted.skip(1)) {
    final value = snapshot.totalValuationAmount;
    if (value > peakValue) {
      peakValue = value;
      peakDate = snapshot.snapshotDate;
      continue;
    }
    if (peakValue <= 0) continue;

    final amount = value - peakValue;
    final percent = (amount / peakValue) * 100;
    if (percent < worstPercent) {
      worstPercent = percent;
      worstAmount = amount;
      worstPeakDate = peakDate;
      worstTroughDate = snapshot.snapshotDate;
    }
  }

  return _DrawdownResult(
    percent: worstPercent,
    amount: worstAmount,
    peakDate: worstPeakDate,
    troughDate: worstTroughDate,
  );
}

List<_AttentionItem> _buildAttentionItems(_PortfolioAnalysisMvpData data) {
  final metrics = data.assetMetrics;
  final topOne = metrics.isEmpty ? 0.0 : metrics.first.ratio;
  final topThree = _topThreeRatio(metrics);
  final hhi = _hhiScore(metrics);
  final drawdown = _calculateMaxDrawdown(data.riskSnapshots);
  final maxGap = _maxTargetGap(metrics);
  final worstAsset = metrics.isEmpty
      ? null
      : ([...metrics]..sort((a, b) => a.profit.compareTo(b.profit))).first;

  final concentrationColor = topThree >= 70 || hhi > 1800
      ? MoneyfyPalette.warningStrong
      : MoneyfyPalette.positive;
  final drawdownColor = drawdown == null
      ? MoneyfyPalette.tertiaryText
      : drawdown.percent.abs() >= 15
      ? MoneyfyPalette.warningStrong
      : MoneyfyPalette.positive;
  final targetColor = maxGap == null
      ? MoneyfyPalette.tertiaryText
      : maxGap.abs() >= 5
      ? MoneyfyPalette.warningStrong
      : MoneyfyPalette.positive;
  final performanceColor = worstAsset == null
      ? MoneyfyPalette.tertiaryText
      : _valueColor(worstAsset.profit);

  return [
    _AttentionItem(
      icon: Icons.donut_large_rounded,
      title: '집중도',
      body: topThree >= 70
          ? '상위 자산이 전체 변동을 크게 좌우할 수 있어요.'
          : '상위 자산 쏠림은 과도하지 않은 편이에요.',
      value: '${topThree.toStringAsFixed(1)}%',
      color: concentrationColor,
    ),
    _AttentionItem(
      icon: Icons.show_chart_rounded,
      title: '최대 낙폭',
      body: drawdown == null
          ? '2개 이상의 스냅샷이 쌓이면 낙폭을 계산할 수 있어요.'
          : '최근 스냅샷 기준 고점 대비 하락폭이에요.',
      value: drawdown == null
          ? '부족'
          : '${drawdown.percent.toStringAsFixed(1)}%',
      color: drawdownColor,
    ),
    _AttentionItem(
      icon: Icons.flag_outlined,
      title: '목표 비중 이탈',
      body: maxGap == null
          ? '목표 비중을 설정하면 조정 후보를 볼 수 있어요.'
          : '현재 비중과 목표 비중의 가장 큰 차이예요.',
      value: maxGap == null ? '미설정' : '${maxGap.abs().toStringAsFixed(1)}%p',
      color: targetColor,
    ),
    _AttentionItem(
      icon: Icons.trending_down_rounded,
      title: '성과 영향',
      body: worstAsset == null || worstAsset.profit >= 0
          ? '전체 성과를 크게 낮추는 자산은 아직 뚜렷하지 않아요.'
          : '${worstAsset.label}의 손익 영향이 가장 큽니다.',
      value: worstAsset == null ? '-' : _formatSignedAmount(worstAsset.profit),
      color: performanceColor,
    ),
    _AttentionItem(
      icon: Icons.filter_3_rounded,
      title: '상위 1개 비중',
      body: topOne >= 50
          ? '단일 자산 비중이 높아 포트폴리오 체감 변동이 커질 수 있어요.'
          : '단일 자산 비중은 관리 가능한 수준이에요.',
      value: '${topOne.toStringAsFixed(1)}%',
      color: topOne >= 50 ? MoneyfyPalette.warningStrong : MoneyfyPalette.info,
    ),
  ];
}

double _topThreeRatio(List<_AssetMetric> metrics) {
  return metrics.take(3).fold<double>(0, (sum, item) => sum + item.ratio);
}

int _hhiScore(List<_AssetMetric> metrics) {
  final hhi = metrics.fold<double>(
    0,
    (sum, item) => sum + math.pow(item.ratio / 100, 2).toDouble(),
  );
  return (hhi * 10000).round();
}

double? _maxTargetGap(List<_AssetMetric> metrics) {
  final entries = metrics
      .where((item) => item.targetRatio != null)
      .toList(growable: false);
  if (entries.isEmpty) return null;
  entries.sort((a, b) => b.targetGap.abs().compareTo(a.targetGap.abs()));
  return entries.first.targetGap;
}

Color _valueColor(double value) {
  if (value > 0) return MoneyfyPalette.positive;
  if (value < 0) return MoneyfyPalette.negative;
  return MoneyfyPalette.tertiaryText;
}

String _formatAmount(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}

String _formatSignedAmount(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

String _formatSignedPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1)}%';
}
