import 'dart:convert';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/utils/risk_adjusted_performance_calculator.dart';

class LocalMcpQueries {
  LocalMcpQueries(this.db);

  final AppDatabase db;

  static const _transactionTypes = {
    'buy': '매수',
    'sell': '매도',
    'deposit': '입금',
    'withdrawal': '출금',
    'dividend': '배당',
    'interest': '이자',
    'transfer_out': '이체',
    'transfer_in': '이체',
    'fx_out': '환전',
    'fx_in': '환전',
    'fee': '수수료',
    'tax': '세금',
    'opening_cash': '초기',
    'opening_quantity': '초기',
    'adjustment': '조정',
  };

  Future<Map<String, dynamic>> searchTransactions({
    String? from,
    String? to,
    int? assetId,
    int? holdingId,
    String? symbol,
    String? type,
    required int limit,
    required int offset,
  }) async {
    final actions = [
      for (final entry in _transactionTypes.entries)
        if (entry.value == type) entry.key,
    ];
    if (type != null && actions.isEmpty) {
      throw ArgumentError('지원하지 않는 거래 유형입니다.');
    }

    final events = await _transactionEvents(
      from: from,
      to: to,
      assetId: assetId,
      holdingId: holdingId,
      symbol: symbol,
      actions: actions,
      limit: limit + 1,
      offset: offset,
    );
    return {
      'transactions': events.take(limit).toList(),
      'next_offset': events.length > limit ? offset + limit : null,
    };
  }

  Future<Map<String, dynamic>> transaction(int eventId) async {
    final events = await _transactionEvents(eventId: eventId);
    return {
      'found': events.isNotEmpty,
      'event_id': eventId,
      'transaction': events.firstOrNull,
    };
  }

  Future<List<Map<String, dynamic>>> _transactionEvents({
    int? eventId,
    String? from,
    String? to,
    int? assetId,
    int? holdingId,
    String? symbol,
    List<String> actions = const [],
    int limit = 1,
    int offset = 0,
  }) async {
    const date = "REPLACE(SUBSTR(e.occurred_at, 1, 10), '.', '-')";
    final filters = [
      'e.deleted_at IS NULL',
      "e.source != 'snapshot_restore'",
      'EXISTS (SELECT 1 FROM transaction_lines l WHERE l.event_id = e.id AND l.deleted_at IS NULL)',
      if (eventId != null) 'e.id = ?',
      if (from != null) '$date >= ?',
      if (to != null) '$date <= ?',
      if (assetId != null)
        _lineMatches('COALESCE(l.asset_id, h.asset_id, c.asset_id) = ?'),
      if (holdingId != null)
        _lineMatches(
          holdingId > 0 ? 'l.holding_id = ?' : 'l.cash_account_id = ?',
        ),
      if (symbol != null) _lineMatches('h.symbol = ? COLLATE NOCASE'),
      if (actions.isNotEmpty)
        _lineMatches(
          'l.action IN (${List.filled(actions.length, '?').join(', ')})',
        ),
    ];
    final rows = await db
        .customSelect(
          '''
      WITH matching_events AS (
        SELECT e.id, e.title, e.memo, e.kind, $date AS event_date
        FROM transaction_events e
        WHERE ${filters.join(' AND ')}
        ORDER BY event_date DESC, e.id DESC
        LIMIT ? OFFSET ?
      )
      SELECT e.*, l.id AS line_id, l.action, l.currency_code,
        COALESCE(l.asset_id, h.asset_id, c.asset_id) AS asset_id,
        COALESCE(NULLIF(a.alias, ''), a.title) AS asset_name,
        COALESCE(l.holding_id, -l.cash_account_id) AS holding_id,
        COALESCE(h.name, c.name) AS holding_name, h.symbol,
        l.cash_delta, l.quantity_delta, l.unit_price, l.gross_amount, l.fx_rate
      FROM matching_events e
      JOIN transaction_lines l ON l.event_id = e.id AND l.deleted_at IS NULL
      LEFT JOIN holdings h ON h.id = l.holding_id
      LEFT JOIN cash_accounts c ON c.id = l.cash_account_id
      LEFT JOIN assets a ON a.id = COALESCE(l.asset_id, h.asset_id, c.asset_id)
      ORDER BY e.event_date DESC, e.id DESC,
        CASE l.action
          WHEN 'settlement' THEN 2 WHEN 'transfer_in' THEN 1 WHEN 'fx_in' THEN 1
          ELSE 0
        END, l.sort_order, l.id
      ''',
          variables: [
            if (eventId != null) Variable.withInt(eventId),
            if (from != null) Variable.withString(from),
            if (to != null) Variable.withString(to),
            if (assetId != null) Variable.withInt(assetId),
            if (holdingId != null) Variable.withInt(holdingId.abs()),
            if (symbol != null) Variable.withString(symbol),
            for (final action in actions) Variable.withString(action),
            Variable.withInt(limit),
            Variable.withInt(offset),
          ],
        )
        .get();
    final events = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = row.read<int>('id');
      final event = events.putIfAbsent(
        id,
        () => {
          'event_id': id,
          'date': row.read<String>('event_date'),
          'name': row.read<String>('title'),
          'memo': row.read<String>('memo'),
          'type':
              _transactionTypes[row.read<String>('action')] ??
              row.read<String>('kind'),
          'lines': <Map<String, dynamic>>[],
        },
      );
      (event['lines'] as List<Map<String, dynamic>>).add(_transactionLine(row));
    }
    return events.values.toList();
  }

  static String _lineMatches(String condition) =>
      '''
    EXISTS (
      SELECT 1 FROM transaction_lines l
      LEFT JOIN holdings h ON h.id = l.holding_id
      LEFT JOIN cash_accounts c ON c.id = l.cash_account_id
      WHERE l.event_id = e.id AND l.deleted_at IS NULL AND $condition
    )
  ''';

  static Map<String, dynamic> _transactionLine(QueryRow row) => {
    'line_id': row.read<int>('line_id'),
    'action': row.read<String>('action'),
    'asset_id': row.readNullable<int>('asset_id'),
    'asset_name': row.readNullable<String>('asset_name'),
    'holding_id': row.readNullable<int>('holding_id'),
    'holding_name': row.readNullable<String>('holding_name'),
    'symbol': row.readNullable<String>('symbol'),
    'currency': row.read<String>('currency_code'),
    'cash_delta': row.read<double>('cash_delta'),
    'quantity_delta': row.read<double>('quantity_delta'),
    'unit_price': row.read<double>('unit_price'),
    'gross_amount': row.read<double>('gross_amount'),
    'fx_rate': row.readNullable<double>('fx_rate'),
  };

  Future<Map<String, dynamic>> dataIssues({
    String? from,
    String? to,
    required int staleAfterDays,
    required int limit,
  }) async {
    const date = "REPLACE(SUBSTR(e.occurred_at, 1, 10), '.', '-')";
    final dateFilter = [
      if (from != null) 'AND $date >= ?',
      if (to != null) 'AND $date <= ?',
    ].join(' ');
    final dateVariables = [
      if (from != null) Variable.withString(from),
      if (to != null) Variable.withString(to),
    ];
    final duplicateRows = await db
        .customSelect(
          '''
      WITH signatures AS (
        SELECT e.id, $date AS date, e.kind,
          (SELECT json_group_array(json(leg)) FROM (
             SELECT json_array(l.action, l.asset_id, l.holding_id, l.cash_account_id,
               l.currency_code, l.cash_delta, l.quantity_delta, l.unit_price,
               l.gross_amount, l.fee_amount, l.tax_amount, l.fx_rate) AS leg
             FROM transaction_lines l
             WHERE l.event_id = e.id AND l.deleted_at IS NULL
             ORDER BY leg
          )) AS legs
        FROM transaction_events e
        WHERE e.deleted_at IS NULL
          AND e.source != 'snapshot_restore'
          AND e.kind != 'opening_balance'
          AND EXISTS (SELECT 1 FROM transaction_lines l WHERE l.event_id = e.id
            AND l.deleted_at IS NULL AND l.action NOT LIKE 'opening_%')
          $dateFilter
      )
      SELECT date, kind, JSON_GROUP_ARRAY(id) AS event_ids
      FROM signatures
      GROUP BY date, kind, legs
      HAVING COUNT(*) > 1
      ORDER BY date DESC, MIN(id) DESC
      LIMIT ?
      ''',
          variables: [...dateVariables, Variable.withInt(limit)],
        )
        .get();
    final pendingRows = await db
        .customSelect(
          '''
      SELECT e.id, $date AS date, e.title, e.kind, e.deleted_at
      FROM transaction_events e
      WHERE (e.dirty = 1 OR EXISTS (
        SELECT 1 FROM transaction_lines l WHERE l.event_id = e.id AND l.dirty = 1
      )) $dateFilter
      ORDER BY date DESC, e.id DESC
      LIMIT ?
      ''',
          variables: [...dateVariables, Variable.withInt(limit)],
        )
        .get();
    final quoteRows = await db.customSelect('''
      SELECT h.id, h.name, h.symbol, h.currency_code, h.market_updated_at
      FROM holdings h JOIN assets a ON a.id = h.asset_id
      WHERE h.deleted_at IS NULL AND a.deleted_at IS NULL
        AND h.quantity != 0 AND TRIM(h.symbol) != ''
      ORDER BY h.market_updated_at, h.id
      ''').get();
    final usd = await db.customSelect('''
      SELECT 1 FROM holdings h JOIN assets a ON a.id = h.asset_id
      WHERE h.deleted_at IS NULL AND a.deleted_at IS NULL
        AND h.quantity != 0 AND UPPER(h.currency_code) = 'USD'
      UNION ALL
      SELECT 1 FROM cash_accounts c JOIN assets a ON a.id = c.asset_id
      WHERE c.deleted_at IS NULL AND a.deleted_at IS NULL
        AND c.balance != 0 AND UPPER(c.currency_code) = 'USD'
      LIMIT 1
      ''').getSingleOrNull();
    final fx = usd == null
        ? null
        : await db.customSelect('''
      SELECT rate, recorded_at FROM exchange_rates
      WHERE currency_pair = 'USD/KRW'
      ORDER BY recorded_at DESC, id DESC LIMIT 1
      ''').getSingleOrNull();

    final cutoff = DateTime.now().subtract(Duration(days: staleAfterDays));
    String? freshness(String? timestamp) {
      final recorded = timestamp == null ? null : DateTime.tryParse(timestamp);
      if (recorded == null) return 'missing';
      return recorded.isBefore(cutoff) ? 'stale' : null;
    }

    final staleQuotes = <Map<String, dynamic>>[];
    for (final quote in quoteRows) {
      final timestamp = quote.readNullable<String>('market_updated_at');
      final status = freshness(timestamp);
      if (status != null) {
        staleQuotes.add({
          'holding_id': quote.read<int>('id'),
          'name': quote.read<String>('name'),
          'symbol': quote.read<String>('symbol'),
          'currency': quote.read<String>('currency_code'),
          'status': status,
          'updated_at': timestamp,
        });
        if (staleQuotes.length == limit) break;
      }
    }
    final fxTimestamp = fx?.read<String>('recorded_at');
    return {
      'stale_after_days': staleAfterDays,
      'duplicate_candidates': [
        for (final row in duplicateRows)
          {
            'date': row.read<String>('date'),
            'kind': row.read<String>('kind'),
            'event_ids': jsonDecode(row.read<String>('event_ids')),
          },
      ],
      'pending_transactions': [
        for (final row in pendingRows)
          {
            'event_id': row.read<int>('id'),
            'date': row.read<String>('date'),
            'name': row.read<String>('title'),
            'kind': row.read<String>('kind'),
            'deleted': row.readNullable<String>('deleted_at') != null,
          },
      ],
      'stale_quotes': staleQuotes,
      'fx_issue': usd != null && freshness(fxTimestamp) != null
          ? {
              'pair': 'USD/KRW',
              'rate': fx?.read<double>('rate'),
              'recorded_at': fxTimestamp,
              'status': freshness(fxTimestamp),
            }
          : null,
    };
  }

  Future<Map<String, dynamic>> portfolioSummary({
    String? asOf,
    String? from,
  }) async {
    final latest = (await db.fetchRecentPortfolioSnapshots(
      maxDates: 1,
    )).firstOrNull;
    final snapshot = asOf == null || asOf == latest?.snapshotDate
        ? latest
        : await db.fetchPortfolioSnapshotByDate(asOf);
    if (snapshot == null) {
      return {
        'found': false,
        'as_of': asOf,
        'latest_available_date': latest?.snapshotDate,
      };
    }
    final date = snapshot.snapshotDate;
    final end = DateTime.parse(date);
    final start = from == null
        ? DateTime.utc(end.year, end.month, end.day - 29)
        : DateTime.parse(from);
    final fromDate = start.toIso8601String().substring(0, 10);
    if (fromDate.compareTo(date) > 0) {
      throw ArgumentError('from_date는 as_of보다 늦을 수 없습니다.');
    }

    final accounts = await db.fetchPortfolioSnapshotCashAccountsByDates([date]);
    final holdings = await db.fetchPortfolioSnapshotHoldingItemsByDates([date]);
    final groups = await db.fetchPortfolioSnapshotItemsByDates([date]);
    final total = snapshot.totalValuationAmount;
    double? weight(double value) => total == 0 ? null : value / total;
    double cashKrw(SnapshotCashAccountRecord account) =>
        account.balance *
        (account.currencyCode.toUpperCase() == 'USD'
            ? snapshot.exchangeRate
            : 1);
    final currencyTotals = <String, double>{};
    for (final holding in holdings) {
      currencyTotals.update(
        holding.currencyCode,
        (value) => value + holding.totalValuationAmount,
        ifAbsent: () => holding.totalValuationAmount,
      );
    }
    for (final account in accounts) {
      currencyTotals.update(
        account.currencyCode,
        (value) => value + cashKrw(account),
        ifAbsent: () => cashKrw(account),
      );
    }
    final rows = await db.calculatePortfolioDailyReturns(
      from: fromDate,
      to: date,
    );
    final usable = rows
        .where((row) => row.dailyReturn?.isFinite ?? false)
        .toList();
    final expectedDays =
        DateTime.utc(
          end.year,
          end.month,
          end.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
    final fallbackFxDays = usable
        .where((row) => row.dataQuality == 'missing_fx')
        .length;
    final periodReturn = calculateCumulativeReturn(
      usable.map((row) => row.dailyReturn!),
    );
    return {
      'found': true,
      'as_of': date,
      'snapshot_created_at': snapshot.createdAt,
      'valuation_currency': 'KRW',
      'total_valuation_krw': total,
      'usd_krw_rate': snapshot.exchangeRate,
      'asset_groups': [
        for (final group in groups)
          {
            'asset_id': group.assetId > 0 ? group.assetId : null,
            'name': group.assetTitle,
            'valuation_krw': group.totalValuationAmount,
            'allocation_ratio': weight(group.totalValuationAmount),
          },
      ],
      'cash_accounts': [
        for (final account in accounts)
          {
            'asset_id': account.assetId,
            'asset_name': account.assetTitle,
            'holding_id': account.cashAccountId == null
                ? null
                : -account.cashAccountId!,
            'name': account.cashAccountName,
            'currency': account.currencyCode,
            'balance': account.balance,
            'valuation_krw': cashKrw(account),
          },
      ],
      'holdings': [
        for (final holding in holdings)
          {
            'asset_id': holding.assetId,
            'holding_id': holding.holdingId,
            'name': holding.holdingName,
            'symbol': holding.holdingSymbol,
            'currency': holding.currencyCode,
            'quantity': holding.quantity,
            'valuation_krw': holding.totalValuationAmount,
            'allocation_ratio': weight(holding.totalValuationAmount),
          },
      ],
      'currency_allocation': [
        for (final entry in currencyTotals.entries)
          {
            'currency': entry.key,
            'valuation_krw': entry.value,
            'allocation_ratio': weight(entry.value),
          },
      ],
      'unallocated_valuation_krw':
          total - currencyTotals.values.fold(0.0, (sum, value) => sum + value),
      'period_return': {
        'from_date': fromDate,
        'to_date': date,
        'return_ratio': periodReturn?.isFinite == true ? periodReturn : null,
        'calculated_days': usable.length,
        'missing_days': expectedDays - usable.length,
        'fallback_fx_days': fallbackFxDays,
        'complete': usable.length == expectedDays && fallbackFxDays == 0,
      },
    };
  }
}
