import 'package:flutter/material.dart';

import '../components/transaction_history_list.dart';
import '../db/app_database.dart';
import '../theme/moneyfy_theme.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';

class DividendInterestAnalysisPage extends StatelessWidget {
  const DividendInterestAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MoneyfyPage(
      title: '배당/이자 분석',
      children: [
        FutureBuilder<_IncomeAnalysisReport>(
          future: _loadIncomeAnalysisReport(),
          builder: (context, snapshot) {
            final report = snapshot.data ?? const _IncomeAnalysisReport.empty();
            return Column(
              children: [
                _IncomeSummaryCard(report: report),
                const SizedBox(height: MoneyfySpacing.sectionGap),
                _MonthlyIncomeTrendCard(months: report.months),
                const SizedBox(height: MoneyfySpacing.sectionGap),
                _YearlyIncomeTotalCard(years: report.years),
                const SizedBox(height: MoneyfySpacing.sectionGap),
                _IncomeSourceCard(sources: report.sources),
                const SizedBox(height: MoneyfySpacing.sectionGap),
                _IncomeTransactionCard(items: report.transactions),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _IncomeSummaryCard extends StatelessWidget {
  const _IncomeSummaryCard({required this.report});

  final _IncomeAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MoneyfySectionCard(
      title: '배당/이자 총합',
      subtitle: report.transactions.isEmpty
          ? '기록된 배당/이자 거래가 없습니다.'
          : '${report.firstMonth ?? '-'} ~ ${report.lastMonth ?? '-'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatCurrency(report.totalIncome),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: MoneyfyPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: '배당',
                  value: _formatCurrency(report.dividendIncome),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: '이자',
                  value: _formatCurrency(report.interestIncome),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: '월평균',
                  value: _formatCurrency(report.averageMonthlyIncome),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: '기록 수',
                  value: '${report.transactions.length}건',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyIncomeTrendCard extends StatelessWidget {
  const _MonthlyIncomeTrendCard({required this.months});

  final List<_IncomePeriodTotal> months;

  @override
  Widget build(BuildContext context) {
    final recentMonths = months.take(12).toList(growable: false);
    return MoneyfySectionCard(
      title: '월별 배당/이자',
      subtitle: '최근 12개월 기준',
      child: recentMonths.isEmpty
          ? const _EmptyIncomeText()
          : Column(
              children: [
                for (var index = 0; index < recentMonths.length; index++) ...[
                  _IncomeBarRow(
                    label: recentMonths[index].label,
                    total: recentMonths[index].total,
                    dividend: recentMonths[index].dividend,
                    interest: recentMonths[index].interest,
                    maxTotal: recentMonths
                        .map((item) => item.total)
                        .fold<double>(
                          0,
                          (max, value) => value > max ? value : max,
                        ),
                  ),
                  if (index != recentMonths.length - 1)
                    const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _YearlyIncomeTotalCard extends StatelessWidget {
  const _YearlyIncomeTotalCard({required this.years});

  final List<_IncomePeriodTotal> years;

  @override
  Widget build(BuildContext context) {
    return MoneyfySectionCard(
      title: '연 총합',
      subtitle: '연도별 배당/이자 합계',
      child: years.isEmpty
          ? const _EmptyIncomeText()
          : Column(
              children: [
                for (var index = 0; index < years.length; index++) ...[
                  _IncomePeriodRow(item: years[index]),
                  if (index != years.length - 1) const Divider(height: 24),
                ],
              ],
            ),
    );
  }
}

class _IncomeSourceCard extends StatelessWidget {
  const _IncomeSourceCard({required this.sources});

  final List<_IncomeSourceTotal> sources;

  @override
  Widget build(BuildContext context) {
    return MoneyfySectionCard(
      title: '종목별 배당/이자',
      subtitle: '수입이 큰 순서',
      child: sources.isEmpty
          ? const _EmptyIncomeText()
          : Column(
              children: [
                for (var index = 0; index < sources.length; index++) ...[
                  _IncomeSourceRow(item: sources[index]),
                  if (index != sources.length - 1) const Divider(height: 24),
                ],
              ],
            ),
    );
  }
}

class _IncomeTransactionCard extends StatelessWidget {
  const _IncomeTransactionCard({required this.items});

  final List<_IncomeTransaction> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(30).toList(growable: false);
    return MoneyfySectionCard(
      title: '최근 배당/이자 내역',
      child: visibleItems.isEmpty
          ? const _EmptyIncomeText()
          : TransactionHistoryList(
              itemCount: visibleItems.length,
              separator: const Divider(height: 24),
              itemBuilder: (context, index) =>
                  _IncomeTransactionRow(item: visibleItems[index]),
            ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MoneyfyPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoneyfyPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MoneyfyPalette.tertiaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: MoneyfyPalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeBarRow extends StatelessWidget {
  const _IncomeBarRow({
    required this.label,
    required this.total,
    required this.dividend,
    required this.interest,
    required this.maxTotal,
  });

  final String label;
  final double total;
  final double dividend;
  final double interest;
  final double maxTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = maxTotal <= 0 ? 0.0 : (total / maxTotal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            Text(
              _formatCurrency(total),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            color: MoneyfyPalette.accent,
            backgroundColor: MoneyfyPalette.surfaceMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '배당 ${_formatCurrency(dividend)} · 이자 ${_formatCurrency(interest)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: MoneyfyPalette.tertiaryText,
          ),
        ),
      ],
    );
  }
}

class _IncomePeriodRow extends StatelessWidget {
  const _IncomePeriodRow({required this.item});

  final _IncomePeriodTotal item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '배당 ${_formatCurrency(item.dividend)} · 이자 ${_formatCurrency(item.interest)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.tertiaryText,
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatCurrency(item.total),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _IncomeSourceRow extends StatelessWidget {
  const _IncomeSourceRow({required this.item});

  final _IncomeSourceTotal item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
                  '${item.count}건',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.tertiaryText,
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatCurrency(item.total),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _IncomeTransactionRow extends StatelessWidget {
  const _IncomeTransactionRow({required this.item});

  final _IncomeTransaction item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFFFD08A)),
          ),
          child: Text(
            item.type,
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFFB56A00),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${item.date} · ${item.assetName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MoneyfyPalette.tertiaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _formatCurrency(item.amountKrw),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyIncomeText extends StatelessWidget {
  const _EmptyIncomeText();

  @override
  Widget build(BuildContext context) {
    return Text(
      '배당/이자 거래를 추가하면 여기에 표시됩니다.',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: MoneyfyPalette.tertiaryText),
    );
  }
}

Future<_IncomeAnalysisReport> _loadIncomeAnalysisReport() async {
  final db = AppDatabase.instance;
  final usdKrwRate = await db.fetchLatestExchangeRate() ?? 1.0;
  final ledgerRows = await db.fetchLedgerIncomeTransactions();
  final transactions = ledgerRows
      .map((row) {
        final type = switch (row.action) {
          'dividend' => '배당',
          'interest' => '이자',
          _ => row.action,
        };
        final amountKrw = _toKrw(
          row.amount.abs(),
          row.currencyCode,
          row.currencyCode.toUpperCase() == 'USD' ? usdKrwRate : 1.0,
        );
        if (amountKrw <= 0) return null;
        return _IncomeTransaction(
          date: row.date,
          monthKey: _monthKey(row.date),
          yearKey: _yearKey(row.date),
          type: type,
          assetName: row.assetName,
          name: row.holdingName,
          symbol: row.symbol,
          amountKrw: amountKrw,
        );
      })
      .whereType<_IncomeTransaction>()
      .toList(growable: false);

  transactions.sort((a, b) {
    final dateCompare = _dateSortKey(b.date).compareTo(_dateSortKey(a.date));
    if (dateCompare != 0) return dateCompare;
    return b.amountKrw.compareTo(a.amountKrw);
  });

  final monthTotals = _buildPeriodTotals(
    transactions,
    keyOf: (item) => item.monthKey,
    labelOf: _formatMonthLabel,
  );
  final yearTotals = _buildPeriodTotals(
    transactions,
    keyOf: (item) => item.yearKey,
    labelOf: (key) => '$key년',
  );
  final sourceTotals = _buildSourceTotals(transactions);

  return _IncomeAnalysisReport(
    transactions: transactions,
    months: monthTotals,
    years: yearTotals,
    sources: sourceTotals,
  );
}

List<_IncomePeriodTotal> _buildPeriodTotals(
  List<_IncomeTransaction> transactions, {
  required String Function(_IncomeTransaction item) keyOf,
  required String Function(String key) labelOf,
}) {
  final totals = <String, _MutableIncomeTotal>{};
  for (final item in transactions) {
    final key = keyOf(item);
    final total = totals.putIfAbsent(key, _MutableIncomeTotal.new);
    total.add(item);
  }
  return totals.entries
      .map(
        (entry) => _IncomePeriodTotal(
          key: entry.key,
          label: labelOf(entry.key),
          dividend: entry.value.dividend,
          interest: entry.value.interest,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.key.compareTo(a.key));
}

List<_IncomeSourceTotal> _buildSourceTotals(
  List<_IncomeTransaction> transactions,
) {
  final totals = <String, _MutableSourceTotal>{};
  for (final item in transactions) {
    final key = '${item.assetName}|${item.name}|${item.symbol}';
    final total = totals.putIfAbsent(
      key,
      () => _MutableSourceTotal(
        assetName: item.assetName,
        name: item.name,
        symbol: item.symbol,
      ),
    );
    total.add(item);
  }
  return totals.values
      .map(
        (item) => _IncomeSourceTotal(
          assetName: item.assetName,
          name: item.name,
          symbol: item.symbol,
          total: item.total,
          count: item.count,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.total.compareTo(a.total));
}

class _IncomeAnalysisReport {
  const _IncomeAnalysisReport({
    required this.transactions,
    required this.months,
    required this.years,
    required this.sources,
  });

  const _IncomeAnalysisReport.empty()
    : transactions = const [],
      months = const [],
      years = const [],
      sources = const [];

  final List<_IncomeTransaction> transactions;
  final List<_IncomePeriodTotal> months;
  final List<_IncomePeriodTotal> years;
  final List<_IncomeSourceTotal> sources;

  double get totalIncome =>
      transactions.fold<double>(0, (sum, item) => sum + item.amountKrw);

  double get dividendIncome => transactions
      .where((item) => item.type == '배당')
      .fold<double>(0, (sum, item) => sum + item.amountKrw);

  double get interestIncome => transactions
      .where((item) => item.type == '이자')
      .fold<double>(0, (sum, item) => sum + item.amountKrw);

  double get averageMonthlyIncome {
    if (months.isEmpty) return 0;
    return totalIncome / months.length;
  }

  String? get firstMonth => months.isEmpty ? null : months.last.label;

  String? get lastMonth => months.isEmpty ? null : months.first.label;
}

class _IncomePeriodTotal {
  const _IncomePeriodTotal({
    required this.key,
    required this.label,
    required this.dividend,
    required this.interest,
  });

  final String key;
  final String label;
  final double dividend;
  final double interest;

  double get total => dividend + interest;
}

class _IncomeSourceTotal {
  const _IncomeSourceTotal({
    required this.assetName,
    required this.name,
    required this.symbol,
    required this.total,
    required this.count,
  });

  final String assetName;
  final String name;
  final String symbol;
  final double total;
  final int count;
}

class _IncomeTransaction {
  const _IncomeTransaction({
    required this.date,
    required this.monthKey,
    required this.yearKey,
    required this.type,
    required this.assetName,
    required this.name,
    required this.symbol,
    required this.amountKrw,
  });

  final String date;
  final String monthKey;
  final String yearKey;
  final String type;
  final String assetName;
  final String name;
  final String symbol;
  final double amountKrw;
}

class _MutableIncomeTotal {
  double dividend = 0;
  double interest = 0;

  void add(_IncomeTransaction item) {
    if (item.type == '배당') {
      dividend += item.amountKrw;
    } else if (item.type == '이자') {
      interest += item.amountKrw;
    }
  }
}

class _MutableSourceTotal {
  _MutableSourceTotal({
    required this.assetName,
    required this.name,
    required this.symbol,
  });

  final String assetName;
  final String name;
  final String symbol;
  double total = 0;
  int count = 0;

  void add(_IncomeTransaction item) {
    total += item.amountKrw;
    count++;
  }
}

String _dateSortKey(String value) {
  final digits = RegExp(
    r'\d+',
  ).allMatches(value).map((match) => match.group(0)!).toList();
  if (digits.length >= 3) {
    return '${digits[0].padLeft(4, '0')}${digits[1].padLeft(2, '0')}${digits[2].padLeft(2, '0')}';
  }
  return value;
}

String _monthKey(String value) {
  final sortKey = _dateSortKey(value);
  return sortKey.length >= 6 ? sortKey.substring(0, 6) : value;
}

String _yearKey(String value) {
  final sortKey = _dateSortKey(value);
  return sortKey.length >= 4 ? sortKey.substring(0, 4) : value;
}

String _formatMonthLabel(String key) {
  if (key.length < 6) return key;
  final year = key.substring(0, 4);
  final month = int.tryParse(key.substring(4, 6)) ?? 0;
  return '$year년 $month월';
}

double _toKrw(double amount, String currencyCode, double exchangeRate) {
  return currencyCode.toUpperCase() == 'USD' ? amount * exchangeRate : amount;
}

String _formatCurrency(double amount) {
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amount);
}
