import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/buttons/app_buttons.dart';
import '../components/chips/delta_chip.dart';
import '../components/rows/transaction_row.dart';
import '../components/transaction_history_list.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../db/app_database.dart';
import '../models/asset_item.dart';
import '../services/sync_service.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';
import 'forms/cash_account_form_page.dart';
import 'forms/cash_transaction_form_page.dart';

class CashAccountDetailPage extends StatefulWidget {
  const CashAccountDetailPage({
    super.key,
    required this.holdingId,
    this.holdingClientId,
  });

  final int holdingId;
  final String? holdingClientId;

  @override
  State<CashAccountDetailPage> createState() => _CashAccountDetailPageState();
}

class _CashAccountDetailPageState extends State<CashAccountDetailPage> {
  static const String _kSlidableGroupTag = 'cash_account_detail_slidable_group';
  bool _isHeroDetailExpanded = false;
  late Future<HoldingItem?> _holdingFuture;
  Future<_CashComparisonMetrics>? _comparisonMetricsFuture;
  String? _comparisonMetricsCacheKey;

  @override
  void initState() {
    super.initState();
    _holdingFuture = _loadHoldingWithRetry();
  }

  Future<HoldingItem?> _loadHoldingWithRetry() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final holdingById = await AppDatabase.instance.fetchHoldingById(
        widget.holdingId,
      );
      if (holdingById != null) return holdingById;

      final clientId = widget.holdingClientId;
      if (clientId != null && clientId.trim().isNotEmpty) {
        final holdingByClientId = await AppDatabase.instance
            .fetchHoldingByClientId(clientId);
        if (holdingByClientId != null) return holdingByClientId;
      }
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
    return null;
  }

  void _reloadHolding() {
    if (!mounted) return;
    setState(() {
      _holdingFuture = _loadHoldingWithRetry();
      _comparisonMetricsFuture = null;
      _comparisonMetricsCacheKey = null;
    });
  }

  Future<_CashComparisonMetrics> _comparisonMetricsFor(HoldingItem holding) {
    final cacheKey =
        '${holding.id}|${holding.valuationAmount}|${holding.purchaseAmount}|${holding.quantity}|${holding.currentPrice}';
    if (_comparisonMetricsFuture == null ||
        _comparisonMetricsCacheKey != cacheKey) {
      _comparisonMetricsCacheKey = cacheKey;
      _comparisonMetricsFuture = _loadCashComparisonMetrics(holding);
    }
    return _comparisonMetricsFuture!;
  }

  Future<void> _editHolding(HoldingItem holding) async {
    final assetId = holding.assetId;
    if (assetId == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CashAccountFormPage(assetId: assetId, item: holding),
      ),
    );

    if (changed == true && mounted) {
      _reloadHolding();
    }
  }

  Future<void> _deleteHolding(HoldingItem holding) async {
    final currentHolding = await _resolveCurrentHolding(holding);
    final holdingId = currentHolding?.id;
    if (holdingId == null) return;
    final confirmed = await _confirmDelete(
      title: '현금 계좌 삭제',
      message: '${holding.name} 계좌를 삭제하시겠습니까?',
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteHoldingItem(holdingId);
    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'delete_cash_account');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<HoldingItem?> _resolveCurrentHolding(HoldingItem holding) async {
    final id = holding.id;
    if (id != null) {
      final byId = await AppDatabase.instance.fetchHoldingById(id);
      if (byId != null) return byId;
    }

    final clientId = holding.clientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      return AppDatabase.instance.fetchHoldingByClientId(clientId);
    }
    return null;
  }

  Future<void> _openTransactionForm(
    HoldingItem holding, {
    TransactionItem? item,
  }) async {
    final assetId = holding.assetId;
    final holdingId = holding.id;
    if (assetId == null || holdingId == null) return;
    if (item != null &&
        item.isLedgerBacked &&
        !item.canOpenCashFormFromLedger) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 원장 라인은 원본 투자 거래에서 관리됩니다.')),
      );
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CashTransactionFormPage(
          assetId: assetId,
          holdingId: holdingId,
          holdingClientId: holding.clientId,
          item: item,
          defaultName: holding.name,
        ),
      ),
    );

    if (changed == true && mounted) {
      _reloadHolding();
    }
  }

  Future<void> _deleteTransaction(TransactionItem item) async {
    if (item.id == null && item.ledgerEventId == null) return;
    final confirmed = await _confirmDelete(
      title: '거래 내역 삭제',
      message: '${item.date} ${item.type} 내역을 삭제하시겠습니까?',
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteLedgerTransactionItem(item);
    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'delete_cash_transaction');
    }
    if (!mounted) return;
    _reloadHolding();
  }

  Future<bool?> _confirmDelete({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppGhostButton(
            expand: false,
            onPressed: () => Navigator.of(context).pop(false),
            label: '취소',
          ),
          AppDestructiveButton(
            expand: false,
            onPressed: () => Navigator.of(context).pop(true),
            label: '삭제',
            icon: Icons.delete_outline_rounded,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBackground,
      body: FutureBuilder<HoldingItem?>(
        future: _holdingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final holding = snapshot.data;
          if (holding == null) {
            return const Center(child: Text('현금 계좌 정보를 찾을 수 없습니다.'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.contentHorizontalPadding,
                context.spacing.md,
                context.contentHorizontalPadding,
                context.spacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CashTopActionButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icons.arrow_back_rounded,
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.xs + context.spacing.xs / 4),
                  MoneyfySurfaceCard(
                    variant: MoneyfySurfaceCardVariant.raised,
                    padding: EdgeInsets.all(context.cardPadding()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.colors.neutralSurfaceRaised,
                                borderRadius: BorderRadius.circular(
                                  VisualSpec.surface.radiusCard,
                                ),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                size: VisualSpec.icon.sizeSmall,
                              ),
                            ),
                            SizedBox(width: context.spacing.sm),
                            Expanded(
                              child: Text(
                                holding.name,
                                style: context.typography.cardTitle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _CashTopActionButton(
                              onPressed: () => _editHolding(holding),
                              icon: Icons.edit_outlined,
                            ),
                            SizedBox(
                              width:
                                  context.spacing.xs + context.spacing.xs / 4,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.7),
                            ),
                            SizedBox(
                              width:
                                  context.spacing.xs + context.spacing.xs / 4,
                            ),
                            _CashTopActionButton(
                              onPressed: () => _deleteHolding(holding),
                              icon: Icons.delete_outline_rounded,
                            ),
                          ],
                        ),
                        SizedBox(height: context.spacing.lg),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            holding.value,
                            style: context.typography.heroNumber.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(height: context.spacing.md),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity > 120 && !_isHeroDetailExpanded) {
                              setState(() {
                                _isHeroDetailExpanded = true;
                              });
                            } else if (velocity < -120 &&
                                _isHeroDetailExpanded) {
                              setState(() {
                                _isHeroDetailExpanded = false;
                              });
                            }
                          },
                          child: FutureBuilder<_CashComparisonMetrics>(
                            future: _comparisonMetricsFor(holding),
                            initialData: _CashComparisonMetrics.fromHolding(
                              holding,
                            ),
                            builder: (context, comparisonSnapshot) {
                              final metrics =
                                  comparisonSnapshot.data ??
                                  _CashComparisonMetrics.fromHolding(holding);
                              return AnimatedSize(
                                duration: context.motion.fast,
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(
                                    context.cardPadding(),
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.surfaces.surfaceBase,
                                    borderRadius: BorderRadius.circular(
                                      VisualSpec.surface.radiusCard,
                                    ),
                                    boxShadow: context.shadows.level2,
                                  ),
                                  child: Column(
                                    children: [
                                      _CashHeroDeltaMetricRow(
                                        label: '전월 대비 수익',
                                        value: metrics.hasMonthlyComparison
                                            ? _formatSignedCurrency(
                                                metrics.monthlyProfit,
                                              )
                                            : '-',
                                        rawValue: metrics.monthlyProfit,
                                        percentValue: metrics.monthlyProfitRate,
                                        showDeltaChip:
                                            metrics.hasMonthlyComparison,
                                      ),
                                      AnimatedSwitcher(
                                        duration: context.motion.fast,
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SizeTransition(
                                              sizeFactor: animation,
                                              axisAlignment: -1,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: _isHeroDetailExpanded
                                            ? Column(
                                                key: const ValueKey(
                                                  'cash-hero-expanded',
                                                ),
                                                children: [
                                                  SizedBox(
                                                    height: context.spacing.md,
                                                  ),
                                                  _CashHeroDeltaMetricRow(
                                                    label: '전일 대비 수익',
                                                    value:
                                                        metrics
                                                            .hasDailyComparison
                                                        ? _formatSignedCurrency(
                                                            metrics.dailyProfit,
                                                          )
                                                        : '-',
                                                    rawValue:
                                                        metrics.dailyProfit,
                                                    percentValue:
                                                        metrics.dailyProfitRate,
                                                    showDeltaChip: metrics
                                                        .hasDailyComparison,
                                                  ),
                                                ],
                                              )
                                            : const SizedBox(
                                                key: ValueKey(
                                                  'cash-hero-collapsed',
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.spacing.sectionGap),
                  _CashCardSection(
                    title: '거래 내역',
                    trailing: IconButton(
                      onPressed: () => _openTransactionForm(holding),
                      icon: const Icon(Icons.add_rounded),
                      color: context.colors.neutralTextMuted,
                    ),
                    child: SlidableAutoCloseBehavior(
                      child: TransactionHistoryList(
                        itemCount: holding.transactions.length,
                        itemBuilder: (context, index) => Slidable(
                          key: ValueKey(
                            'cash-tx-${holding.transactions[index].id ?? holding.transactions[index].hashCode}',
                          ),
                          groupTag:
                              _CashAccountDetailPageState._kSlidableGroupTag,
                          endActionPane: moneyfySingleSlideActionPane(
                            onPressed: () =>
                                _deleteTransaction(holding.transactions[index]),
                            icon: Icons.delete_outline_rounded,
                            iconColor: Theme.of(context).colorScheme.error,
                          ),
                          child: TransactionRow(
                            typeLabel: holding.transactions[index].type,
                            title: holding.transactions[index].name,
                            subtitle: holding.transactions[index].date,
                            amountText:
                                MoneyfyDisplayCurrencySettings.formatAmountFromSource(
                                  double.tryParse(
                                        holding.transactions[index].amount
                                            .replaceAll(',', '')
                                            .trim(),
                                      ) ??
                                      0,
                                  sourceCurrency: holding.currencyCode,
                                  exchangeRate: holding.exchangeRate,
                                ),
                            amountColor: _cashTransactionAmountColor(
                              context,
                              holding.transactions[index],
                            ),
                            metaText: _ledgerLineMeta(
                              holding.transactions[index],
                            ),
                            onTap: () => _openTransactionForm(
                              holding,
                              item: holding.transactions[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.spacing.sectionGap),
                  _CashCardSection(
                    title: '메모',
                    trailing: IconButton(
                      onPressed: () => _editHolding(holding),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: VisualSpec.icon.sizeSmall,
                      ),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: Text(
                      holding.note,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _ledgerLineMeta(TransactionItem item) {
  final action = item.ledgerAction;
  if (action == null || action.trim().isEmpty) return '';
  return switch (action) {
    'settlement' => '매매 정산 라인',
    'transfer_out' => '이체 출금 라인',
    'transfer_in' => '이체 입금 라인',
    'fx_out' => '환전 출금 라인',
    'fx_in' => '환전 입금 라인',
    'deposit' => '외부 입금 라인',
    'withdrawal' => '외부 출금 라인',
    'dividend' => '배당 수입 라인',
    'interest' => '이자 수입 라인',
    'fee' => '비용 라인',
    'tax' => '세금 라인',
    'opening_cash' => '초기 잔고 라인',
    _ => '조정 라인',
  };
}

class _CashTopActionButton extends StatelessWidget {
  const _CashTopActionButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        splashRadius: 20,
        icon: Icon(icon),
      ),
    );
  }
}

class _CashCardSection extends StatelessWidget {
  const _CashCardSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.7);
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
                  child: Text(title, style: context.typography.sectionTitle),
                ),
                if (trailing != null) ...[
                  SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
                  Container(width: 1, height: 24, color: dividerColor),
                  SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: context.spacing.sm + context.spacing.xs / 4),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaces.surfaceBase,
                  borderRadius: BorderRadius.circular(
                    VisualSpec.surface.radiusCard,
                  ),
                  boxShadow: context.shadows.level2,
                ),
                child: Padding(
                  padding: EdgeInsets.all(context.cardPadding()),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _cashTransactionAmountColor(
  BuildContext context,
  TransactionItem transaction,
) {
  return switch (TransactionFlowCategory.normalize(transaction.flowCategory)) {
    TransactionFlowCategory.externalDeposit => context.colors.positiveOn,
    TransactionFlowCategory.externalWithdrawal => context.colors.negativeOn,
    _ => context.colors.neutralText,
  };
}

class _CashHeroDeltaMetricRow extends StatelessWidget {
  const _CashHeroDeltaMetricRow({
    required this.label,
    required this.value,
    required this.rawValue,
    required this.percentValue,
    this.showDeltaChip = true,
  });

  final String label;
  final String value;
  final double rawValue;
  final double percentValue;
  final bool showDeltaChip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.typography.meta.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.neutralText,
            ),
          ),
        ),
        Text(
          value,
          style: context.typography.meta.copyWith(
            fontWeight: FontWeight.w600,
            color: _cashValueStringColor(context, value),
          ),
        ),
        SizedBox(width: context.spacing.xs + context.spacing.xs / 4),
        if (showDeltaChip)
          DeltaChip(
            value: rawValue,
            percent: percentValue,
            mode: DeltaChipMode.percent,
            vivid: true,
          )
        else
          const _CashHeroDashChip(),
      ],
    );
  }
}

class _CashHeroDashChip extends StatelessWidget {
  const _CashHeroDashChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: context.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.neutralSurfaceBase,
        border: Border.all(color: context.colors.neutralOutline),
        borderRadius: BorderRadius.circular(context.radius.rPill),
      ),
      child: Text(
        '-',
        style: context.typography.meta.copyWith(
          color: context.colors.neutralText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CashComparisonMetrics {
  const _CashComparisonMetrics({
    required this.valuationProfit,
    required this.valuationProfitRate,
    required this.monthlyProfit,
    required this.monthlyProfitRate,
    required this.dailyProfit,
    required this.dailyProfitRate,
    required this.hasMonthlyComparison,
    required this.hasDailyComparison,
  });

  factory _CashComparisonMetrics.fromHolding(HoldingItem holding) {
    return _CashComparisonMetrics(
      valuationProfit: holding.profitAmount,
      valuationProfitRate: holding.profitRate,
      monthlyProfit: 0,
      monthlyProfitRate: 0,
      dailyProfit: 0,
      dailyProfitRate: 0,
      hasMonthlyComparison: false,
      hasDailyComparison: false,
    );
  }

  final double valuationProfit;
  final double valuationProfitRate;
  final double monthlyProfit;
  final double monthlyProfitRate;
  final double dailyProfit;
  final double dailyProfitRate;
  final bool hasMonthlyComparison;
  final bool hasDailyComparison;
}

Color _cashValueStringColor(BuildContext context, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return context.colors.neutralText;
  }
  if (normalized.startsWith('-') || normalized.startsWith('−')) {
    return context.colors.negativeOn;
  }
  if (normalized.startsWith('+')) return context.colors.positiveOn;
  if (normalized.startsWith('(') && normalized.endsWith(')')) {
    return context.colors.negativeOn;
  }
  if (normalized.contains('-') || normalized.contains('−')) {
    return context.colors.negativeOn;
  }
  if (normalized.contains('+')) return context.colors.positiveOn;
  return context.colors.neutralText;
}

String _cashPreviousMonthComparisonDate(DateTime date) {
  final previousMonth = date.month == 1
      ? DateTime(date.year - 1, 12, 20)
      : DateTime(date.year, date.month - 1, 20);
  final month = previousMonth.month.toString().padLeft(2, '0');
  final day = previousMonth.day.toString().padLeft(2, '0');
  return '${previousMonth.year}-$month-$day';
}

String _cashSnapshotDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _formatSignedCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(amount);
}

Future<_CashComparisonMetrics> _loadCashComparisonMetrics(
  HoldingItem holding,
) async {
  final currentValue = holding.valuationAmount;
  final valuationProfit = holding.profitAmount;
  final valuationProfitRate = holding.profitRate;

  final monthlyPrevious = await _resolveCashComparisonValue(
    holding: holding,
    dateCandidates: [_cashPreviousMonthComparisonDate(DateTime.now())],
    includeRecentFallback: true,
  );
  final dailyPrevious = await _resolveCashComparisonValue(
    holding: holding,
    dateCandidates: [
      _cashSnapshotDate(DateTime.now().subtract(const Duration(days: 1))),
      _cashSnapshotDate(DateTime.now().subtract(const Duration(days: 2))),
    ],
    includeRecentFallback: false,
  );

  final hasMonthly = monthlyPrevious != null;
  final hasDaily = dailyPrevious != null;
  final monthlyProfit = hasMonthly ? currentValue - monthlyPrevious : 0.0;
  final monthlyRate = !hasMonthly || monthlyPrevious == 0
      ? 0.0
      : (monthlyProfit / monthlyPrevious) * 100;
  final dailyProfit = hasDaily ? currentValue - dailyPrevious : 0.0;
  final dailyRate = !hasDaily || dailyPrevious == 0
      ? 0.0
      : (dailyProfit / dailyPrevious) * 100;

  return _CashComparisonMetrics(
    valuationProfit: valuationProfit,
    valuationProfitRate: valuationProfitRate,
    monthlyProfit: monthlyProfit,
    monthlyProfitRate: monthlyRate,
    dailyProfit: dailyProfit,
    dailyProfitRate: dailyRate,
    hasMonthlyComparison: hasMonthly,
    hasDailyComparison: hasDaily,
  );
}

Future<double?> _resolveCashComparisonValue({
  required HoldingItem holding,
  required List<String> dateCandidates,
  required bool includeRecentFallback,
}) async {
  for (final snapshotDate in dateCandidates) {
    final rows = await AppDatabase.instance
        .fetchPortfolioSnapshotHoldingItemsByDates([snapshotDate]);
    final value = _findCashSnapshotValue(rows: rows, holding: holding);
    if (value != null) {
      return value;
    }
  }

  if (!includeRecentFallback) return null;
  final snapshots = await AppDatabase.instance.fetchRecentPortfolioSnapshots(
    maxDates: 2,
  );
  if (snapshots.length < 2) return null;
  final fallbackDate = snapshots[snapshots.length - 2].snapshotDate;
  final fallbackRows = await AppDatabase.instance
      .fetchPortfolioSnapshotHoldingItemsByDates([fallbackDate]);
  return _findCashSnapshotValue(rows: fallbackRows, holding: holding);
}

double? _findCashSnapshotValue({
  required List<DailyPortfolioSnapshotHoldingItem> rows,
  required HoldingItem holding,
}) {
  final holdingId = holding.id;
  if (holdingId != null) {
    for (final row in rows) {
      if (row.holdingId == holdingId) {
        return row.totalValuationAmount;
      }
    }
  }

  final targetAssetId = holding.assetId;
  final targetCurrency = holding.currencyCode.trim().toLowerCase();
  final targetName = holding.name.trim().toLowerCase();
  final targetSymbol = holding.symbol.trim().toLowerCase();

  // Prefer matching inside the same asset first to avoid cross-asset symbol collisions.
  for (final row in rows) {
    if (targetAssetId != null && row.assetId != targetAssetId) {
      continue;
    }
    if (targetCurrency.isNotEmpty &&
        row.currencyCode.trim().toLowerCase() != targetCurrency) {
      continue;
    }
    final rowName = row.holdingName.trim().toLowerCase();
    final rowSymbol = row.holdingSymbol.trim().toLowerCase();
    if (rowName == targetName &&
        (targetSymbol.isEmpty || rowSymbol == targetSymbol)) {
      return row.totalValuationAmount;
    }
  }

  // Legacy fallback: if snapshot row has no asset id, allow name/symbol/currency match.
  if (targetAssetId != null) {
    for (final row in rows) {
      if (row.assetId != null) continue;
      if (targetCurrency.isNotEmpty &&
          row.currencyCode.trim().toLowerCase() != targetCurrency) {
        continue;
      }
      final rowName = row.holdingName.trim().toLowerCase();
      final rowSymbol = row.holdingSymbol.trim().toLowerCase();
      if (rowName == targetName &&
          (targetSymbol.isEmpty || rowSymbol == targetSymbol)) {
        return row.totalValuationAmount;
      }
    }
  }
  return null;
}
