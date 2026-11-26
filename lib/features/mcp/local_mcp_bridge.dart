import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';

import 'local_mcp_queries.dart';

/// Local-only adapter: all money changes go through the application's ledger.
class LocalMcpBridge {
  LocalMcpBridge({
    required this.db,
    required this.userId,
    required this.sync,
    this.runtimeStatus,
    this.confirmChange,
  }) : _queries = LocalMcpQueries(db);

  final AppDatabase db;
  final String? Function() userId;
  final Future<bool> Function(String user) sync;
  final ({bool loggedIn, bool loading, bool syncing}) Function()? runtimeStatus;
  final Future<bool> Function(Map<String, dynamic> preview)? confirmChange;
  final LocalMcpQueries _queries;

  static const _transactionWrites = {
    'create_transaction',
    'transfer_cash',
    'exchange_cash',
    'update_transaction',
    'delete_transaction',
  };
  HttpServer? _server;
  Future<void> _writeQueue = Future.value();

  Future<void> start({required String token, int port = 47831}) async {
    if (token.length < 32) {
      throw ArgumentError('MCP token must have at least 32 characters');
    }
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    unawaited(_serve(token));
  }

  Future<void> close() async => _server?.close(force: true);

  Future<void> _serve(String token) async {
    await for (final request in _server!) {
      unawaited(_handle(request, token));
    }
  }

  Future<void> _handle(HttpRequest request, String token) async {
    try {
      if (request.method != 'POST' ||
          request.uri.path != '/mcp' ||
          request.headers.value('authorization') != 'Bearer $token' ||
          request.headers.value('origin') != null) {
        request.response.statusCode = 403;
        return;
      }
      final bytes = <int>[];
      await for (final chunk in request) {
        bytes.addAll(chunk);
        if (bytes.length > 65536) throw ArgumentError('Request too large');
      }
      final input = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(bytes)) as Map,
      );
      final result = await execute(
        input['operation'] as String,
        Map<String, dynamic>.from(input['arguments'] as Map),
      );
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(result));
    } catch (e) {
      request.response.statusCode = 400;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
    } finally {
      try {
        await request.response.close();
      } on IOException {
        // The client may close its connection while the request is pending.
      }
    }
  }

  Future<Map<String, dynamic>> execute(
    String operation,
    Map<String, dynamic> args,
  ) async {
    if (operation == 'get_status') return _status();
    final user = userId();
    if (user == null) throw StateError('MONEYFY 앱에서 로그인하고 데이터 로딩을 완료하세요.');
    if (const {
      'list_assets',
      'list_recent_transactions',
      'get_request_status',
      'search_transactions',
      'get_transaction',
      'get_portfolio_summary',
      'preview_transaction',
      'get_data_issues',
    }.contains(operation)) {
      return db.transaction(() async {
        await _checkAccount(user);
        final result = await _read(user, operation, args);
        await _checkAccount(user);
        return result;
      });
    }
    // Keep writes and sync retries serialized while reads can run during app approval.
    final result = _writeQueue.then(
      (_) => _executeWrite(user, operation, args),
    );
    _writeQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<Map<String, dynamic>> _status() => db.transaction(() async {
    final user = userId();
    final ownerMatches = user != null && await db.localDataOwner() == user;
    final pending = ownerMatches ? await db.hasPendingSyncChanges() : null;
    final ready = ownerMatches && userId() == user;
    final status = runtimeStatus?.call();
    return {
      'bridge_connected': true,
      'app_running': true,
      'logged_in': status?.loggedIn ?? userId() != null,
      'data_loading': status?.loading ?? false,
      'data_ready': ready,
      'sync_in_progress': ready ? status?.syncing : null,
      'pending_local_changes': ready ? pending : null,
    };
  });

  Future<Map<String, dynamic>> _read(
    String user,
    String operation,
    Map<String, dynamic> args,
  ) async {
    switch (operation) {
      case 'list_assets':
        return _listAssets();
      case 'list_recent_transactions':
        return _listRecentTransactions(args);
      case 'get_request_status':
        return _requestStatus(user, _requestId(args));
      case 'get_transaction':
        return _queries.transaction(_positiveInteger(args, 'event_id'));
      case 'get_portfolio_summary':
        final asOf = _optionalDate(args, 'as_of');
        final from = _optionalDate(args, 'from_date');
        _checkDateRange(from, asOf);
        return _queries.portfolioSummary(asOf: asOf, from: from);
      case 'preview_transaction':
        final action = _text(args, 'operation');
        final fields = args['arguments'];
        if (fields is! Map<String, dynamic>) {
          throw ArgumentError('arguments: 거래 입력 객체가 필요합니다.');
        }
        if (!_transactionWrites.contains(action)) {
          throw ArgumentError('미리보기를 지원하지 않는 거래 작업입니다.');
        }
        return (await _preview(user, action, fields))
          ..remove('_original_evidence');
      case 'get_data_issues':
        final from = _optionalDate(args, 'from_date');
        final to = _optionalDate(args, 'to_date');
        _checkDateRange(from, to);
        final days = args['stale_after_days'] ?? 7;
        if (days is! int || days < 1 || days > 365) {
          throw ArgumentError('stale_after_days: 1..365');
        }
        return _queries.dataIssues(
          from: from,
          to: to,
          staleAfterDays: days,
          limit: _limit(args),
        );
      case 'search_transactions':
        final from = _optionalDate(args, 'from_date');
        final to = _optionalDate(args, 'to_date');
        _checkDateRange(from, to);
        final offset = args['offset'] ?? 0;
        if (offset is! int || offset < 0) throw ArgumentError('offset: 0 이상');
        return _queries.searchTransactions(
          from: from,
          to: to,
          assetId: args.containsKey('asset_id')
              ? _positiveInteger(args, 'asset_id')
              : null,
          holdingId: args.containsKey('holding_id')
              ? _integer(args, 'holding_id')
              : null,
          symbol: args.containsKey('symbol') ? _text(args, 'symbol') : null,
          type: args.containsKey('transaction_type')
              ? _text(args, 'transaction_type')
              : null,
          limit: _limit(args),
          offset: offset,
        );
      default:
        throw ArgumentError('Unknown operation');
    }
  }

  Future<Map<String, dynamic>> _requestStatus(String user, String id) async {
    final receipt = await _existingReceipt(user, id);
    if (receipt == null) return {'request_id': id, 'status': 'not_found'};
    final result = receipt.result;
    if (result['invalidated'] == true) {
      return {'request_id': id, 'status': 'invalidated'};
    }
    final hasEvidence = result['ledger_evidence'] != null;
    final synced =
        result['supabase_synced'] == true ||
        (hasEvidence && await _ledgerAcknowledged(result));
    return {
      'request_id': id,
      'status': synced ? 'synced' : (hasEvidence ? 'pending' : 'unverified'),
      'local_saved': result['local_saved'] == true,
      'supabase_synced': synced ? true : (hasEvidence ? false : null),
    };
  }

  Future<({String command, Map<String, dynamic> result})?> _existingReceipt(
    String user,
    String id,
  ) async {
    final table = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'mcp_write_receipts'",
        )
        .getSingleOrNull();
    return table == null ? null : _receipt(user, id);
  }

  Future<void> _checkAccount(String user) async {
    if (await db.localDataOwner() != user || userId() != user) {
      throw StateError('MONEYFY 앱에서 계정 확인과 데이터 로딩을 완료하세요.');
    }
  }

  Future<Map<String, dynamic>> _listAssets() async => {
    'assets': [
      for (final a in await db.fetchAssets())
        {
          'asset_id': a.id,
          'name': a.title,
          'currency': a.currencyCode,
          'holdings': [
            for (final h in a.holdings)
              {
                'holding_id': h.id,
                'name': h.name,
                'symbol': h.symbol,
                'currency': h.currencyCode,
                'quantity_or_balance': h.quantity,
                'average_price_krw': h.averagePrice,
                'current_price': h.currentPrice,
              },
          ],
        },
    ],
  };

  Future<Map<String, dynamic>> _listRecentTransactions(
    Map<String, dynamic> args,
  ) async {
    final limit = _limit(args);
    final items = await _transactions();
    items.sort((a, b) => b.date.compareTo(a.date));
    return {
      'transactions': [for (final t in items.take(limit)) _json(t)],
    };
  }

  Future<Map<String, dynamic>> _executeWrite(
    String user,
    String operation,
    Map<String, dynamic> args,
  ) async {
    if (!_transactionWrites.contains(operation) &&
        !const {
          'retry_sync',
          'create_holding',
          'create_cash_account',
        }.contains(operation)) {
      throw ArgumentError('Unknown operation');
    }
    final requestId = _requestId(args);
    final keys = args.keys.toList()..sort();
    final command = jsonEncode({
      'operation': operation,
      'arguments': {for (final key in keys) key: args[key]},
    });
    Map<String, dynamic>? approvedPreview;
    if (operation == 'update_transaction' ||
        operation == 'delete_transaction') {
      approvedPreview = await db.transaction(() async {
        await _checkAccount(user);
        return await _existingReceipt(user, requestId) == null
            ? _preview(user, operation, args)
            : null;
      });
      if (approvedPreview != null &&
          await confirmChange?.call(approvedPreview) != true) {
        throw StateError('MONEYFY 앱에서 거래 변경을 승인하지 않았습니다.');
      }
    }
    final result = await db.transaction(() async {
      await _checkAccount(user);
      await db.customStatement(
        'CREATE TABLE IF NOT EXISTS mcp_write_receipts (user_id TEXT NOT NULL, request_id TEXT NOT NULL, command TEXT NOT NULL, result TEXT NOT NULL, PRIMARY KEY(user_id, request_id))',
      );
      final receipt = await _receipt(user, requestId);
      if (receipt != null) {
        _checkReceipt(receipt.result);
        if (operation != 'retry_sync' && receipt.command != command) {
          throw StateError('같은 request_id에 다른 변경을 사용할 수 없습니다.');
        }
        return receipt.result;
      }
      if (operation == 'retry_sync') throw StateError('존재하지 않는 request_id입니다.');
      if (operation == 'update_transaction' ||
          operation == 'delete_transaction') {
        if (approvedPreview == null) throw StateError('거래 변경 승인이 필요합니다.');
        final current = await _preview(user, operation, args);
        if (jsonEncode(current) != jsonEncode(approvedPreview)) {
          throw StateError('승인 후 거래 또는 잔액이 바뀌었습니다. 내용을 다시 확인하세요.');
        }
      }
      final changed =
          operation == 'create_holding' || operation == 'create_cash_account'
          ? await _createHolding(operation, args)
          : await _write(operation, args);
      await _holdings(validateBalances: true);
      final result = <String, dynamic>{
        'request_id': requestId,
        'local_saved': true,
        'supabase_synced': false,
        ...changed,
        if (changed['holding_id'] case final int id)
          'holding_evidence': await _holdingEvidence(id),
        'ledger_evidence': [
          for (final key in [
            'event_id',
            'replaced_event_id',
            'deleted_event_id',
          ])
            if (changed[key] case final int id) await _ledgerEvidence(id),
        ],
      };
      await _checkAccount(user);
      await db.customStatement(
        'INSERT INTO mcp_write_receipts VALUES (?, ?, ?, ?)',
        [user, requestId, command, jsonEncode(result)],
      );
      return result;
    });
    if (result['supabase_synced'] != true) {
      var synced = false;
      try {
        await _checkAccount(user);
        synced = await sync(user);
      } catch (_) {
        // The receipt is available for a retry after a failed sync.
      }
      await db.transaction(() async {
        await _checkAccount(user);
        final current = (await _receipt(user, requestId))!.result;
        _checkReceipt(current);
        if (current['supabase_synced'] == true ||
            (synced && await _ledgerAcknowledged(current))) {
          result['supabase_synced'] = true;
          await db.customStatement(
            'UPDATE mcp_write_receipts SET result = ? WHERE user_id = ? AND request_id = ?',
            [jsonEncode(result), user, requestId],
          );
        }
      });
    }
    await _checkAccount(user);
    result.remove('ledger_evidence');
    result.remove('holding_evidence');
    result['message'] = result['supabase_synced'] == true
        ? '앱 저장 및 Supabase 반영이 완료되었습니다.'
        : '앱에는 저장됐지만 Supabase 반영은 확인되지 않았습니다. 같은 request_id로 retry_sync를 호출하세요. 같은 변경을 새 요청으로 만들지 마세요.';
    return result;
  }

  Future<({String command, Map<String, dynamic> result})?> _receipt(
    String user,
    String requestId,
  ) async {
    final row = await db
        .customSelect(
          'SELECT command, result FROM mcp_write_receipts WHERE user_id = ? AND request_id = ?',
          variables: [
            Variable.withString(user),
            Variable.withString(requestId),
          ],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      command: row.read<String>('command'),
      result: Map<String, dynamic>.from(
        jsonDecode(row.read<String>('result')) as Map,
      ),
    );
  }

  void _checkReceipt(Map<String, dynamic> result) {
    if (result['invalidated'] == true) {
      throw StateError('로컬 데이터 초기화로 요청 기록이 무효화되었습니다. 거래 내역을 먼저 확인하세요.');
    }
    if (result['supabase_synced'] != true &&
        result['ledger_evidence'] == null) {
      throw StateError('이전 버전의 요청은 동기화 여부를 확인할 수 없습니다. 거래 내역을 먼저 확인하세요.');
    }
  }

  Future<Map<String, dynamic>> _ledgerEvidence(int eventId) async {
    final event = await db
        .customSelect(
          'SELECT client_id, last_modified_at FROM transaction_events WHERE id = ?',
          variables: [Variable.withInt(eventId)],
        )
        .getSingle();
    final lines = await db
        .customSelect(
          'SELECT client_id, last_modified_at FROM transaction_lines WHERE event_id = ? ORDER BY id',
          variables: [Variable.withInt(eventId)],
        )
        .get();
    return {
      'event': event.read<String>('client_id'),
      'revision': event.readNullable<String>('last_modified_at'),
      'lines': {
        for (final line in lines)
          line.read<String>('client_id'): line.readNullable<String>(
            'last_modified_at',
          ),
      },
    };
  }

  Future<bool> _ledgerAcknowledged(Map<String, dynamic> result) async {
    if (result['holding_evidence'] case final Map<String, dynamic> evidence) {
      final table = evidence['cash'] == true ? 'cash_accounts' : 'holdings';
      final row = await db
          .customSelect(
            'SELECT dirty, last_modified_at FROM $table WHERE client_id = ? AND deleted_at IS NULL',
            variables: [Variable.withString(evidence['client_id'] as String)],
          )
          .getSingleOrNull();
      return row != null &&
          !row.read<bool>('dirty') &&
          _sameRevision(
            row.readNullable<String>('last_modified_at'),
            evidence['revision'] as String?,
          );
    }

    for (final evidence in result['ledger_evidence'] as List) {
      final event = await db
          .customSelect(
            'SELECT id, dirty, last_modified_at FROM transaction_events WHERE client_id = ?',
            variables: [Variable.withString(evidence['event'] as String)],
          )
          .getSingleOrNull();
      if (event == null ||
          event.read<bool>('dirty') ||
          !_sameRevision(
            event.readNullable<String>('last_modified_at'),
            evidence['revision'] as String?,
          )) {
        return false;
      }
      final lines = await db
          .customSelect(
            'SELECT client_id, last_modified_at FROM transaction_lines WHERE event_id = ? AND dirty = 0',
            variables: [Variable.withInt(event.read<int>('id'))],
          )
          .get();
      final cleanRevisions = {
        for (final line in lines)
          line.read<String>('client_id'): line.readNullable<String>(
            'last_modified_at',
          ),
      };
      final expected = evidence['lines'] as Map<String, dynamic>;
      if (!expected.entries.every(
        (line) =>
            cleanRevisions.containsKey(line.key) &&
            _sameRevision(cleanRevisions[line.key], line.value as String?),
      )) {
        return false;
      }
    }
    return true;
  }

  bool _sameRevision(String? actual, String? expected) {
    if (actual == expected) return true;
    if (actual == null || expected == null) return false;
    final actualDate = DateTime.tryParse(actual);
    final expectedDate = DateTime.tryParse(expected);
    return actualDate != null &&
        expectedDate != null &&
        actualDate.isAtSameMomentAs(expectedDate);
  }

  Future<List<TransactionItem>> _transactions() async {
    final byLine = <String, TransactionItem>{};
    for (final a in await db.fetchAssets()) {
      for (final t in [
        ...a.transactions,
        ...a.holdings.expand((h) => h.transactions),
      ]) {
        if (t.ledgerEventId != null && t.ledgerAction != 'settlement') {
          byLine['${t.ledgerEventId}:${t.ledgerLineId}'] = t;
        }
      }
    }
    return byLine.values.toList();
  }

  Map<String, dynamic> _json(TransactionItem t) => {
    'event_id': t.ledgerEventId,
    'line_id': t.ledgerLineId,
    'holding_id': t.holdingId,
    'date': t.date,
    'type': t.type,
    'name': t.name,
    'amount': t.amount,
    'quantity': t.quantity,
    'fx_rate': t.fxRate,
  };

  Future<Map<int, HoldingItem>> _holdings({
    required bool validateBalances,
  }) async {
    final holdings = <int, HoldingItem>{};
    for (final asset in await db.fetchAssets()) {
      for (final holding in asset.holdings) {
        if (validateBalances && holding.quantity < -0.00000001) {
          throw StateError('수량 또는 현금 잔액이 부족합니다: ${holding.name}');
        }
        if (holding.id case final int id) holdings[id] = holding;
      }
    }
    return holdings;
  }

  Future<Map<String, dynamic>> _preview(
    String user,
    String operation,
    Map<String, dynamic> args,
  ) async {
    try {
      return await db.transaction(() async {
        await _checkAccount(user);
        final before = await _holdings(validateBalances: false);
        final originalId = args['event_id'];
        final original = originalId is int
            ? (await _queries.transaction(originalId))['transaction']
            : null;
        final evidence = originalId is int && original != null
            ? await _ledgerEvidence(originalId)
            : null;
        final changed = await _write(operation, args);
        final after = await _holdings(validateBalances: true);
        final draft = changed['event_id'] is int
            ? (await _queries.transaction(
                    changed['event_id'] as int,
                  ))['transaction']
                  as Map<String, dynamic>?
            : null;
        if (draft != null) {
          draft.remove('event_id');
          for (final line in draft['lines'] as List) {
            (line as Map).remove('line_id');
          }
        }
        await _checkAccount(user);
        // Drift rolls back the simulation, including related settlement legs.
        throw _PreviewRollback({
          'operation': operation,
          'approval_required':
              operation == 'update_transaction' ||
              operation == 'delete_transaction',
          'original': original,
          '_original_evidence': evidence,
          'proposed': draft,
          'balance_changes': [
            for (final id in {...before.keys, ...after.keys})
              if (before[id]?.quantity != after[id]?.quantity &&
                  ((before[id]?.quantity ?? 0) != 0 ||
                      (after[id]?.quantity ?? 0) != 0))
                {
                  'holding_id': before.containsKey(id) ? id : null,
                  'name': (after[id] ?? before[id])!.name,
                  'currency': (after[id] ?? before[id])!.currencyCode,
                  'is_cash': id < 0,
                  'before': before[id]?.quantity ?? 0,
                  'after': after[id]?.quantity ?? 0,
                },
          ],
        });
      });
    } on _PreviewRollback catch (preview) {
      return preview.result;
    }
  }

  Future<Map<String, dynamic>> _createHolding(
    String operation,
    Map<String, dynamic> args,
  ) async {
    final cash = operation == 'create_cash_account';
    _checkFields(args, {
      'request_id',
      'asset_id',
      'name',
      'currency',
      'note',
      if (!cash) ...['symbol', 'exchange_code'],
    });
    final assetId = _positiveInteger(args, 'asset_id');
    final asset = await db.fetchAssetById(assetId);
    if (asset == null) throw StateError('자산 그룹을 찾을 수 없습니다.');
    if (!cash && asset.assetType == '현금') {
      throw ArgumentError('현금 그룹은 create_cash_account를 사용하세요.');
    }
    final name = _text(args, 'name');
    final currency = _text(args, 'currency').toUpperCase();
    if (currency != 'KRW' && currency != 'USD') {
      throw ArgumentError('currency: KRW 또는 USD가 필요합니다.');
    }
    final symbol = args.containsKey('symbol')
        ? _text(args, 'symbol').toUpperCase()
        : '';
    final exchangeCode = args.containsKey('exchange_code')
        ? _text(args, 'exchange_code').toUpperCase()
        : '';
    if (exchangeCode.isNotEmpty &&
        (currency != 'USD' ||
            !const {'NAS', 'NYS', 'AMS'}.contains(exchangeCode))) {
      throw ArgumentError('USD 종목의 거래소 코드는 NAS, NYS, AMS 중 하나여야 합니다.');
    }
    final note = args['note'] ?? '';
    if (note is! String || note.length > 1000) {
      throw ArgumentError('note: 1000자 이하의 텍스트가 필요합니다.');
    }
    final duplicates = asset.holdings
        .where(
          (holding) =>
              ((holding.id ?? 0) < 0) == cash &&
              holding.currencyCode == currency &&
              (holding.name.trim().toLowerCase() == name.toLowerCase() ||
                  (!cash &&
                      symbol.isNotEmpty &&
                      holding.symbol.trim().toUpperCase() == symbol)),
        )
        .toList();
    if (duplicates.isNotEmpty) {
      final existing = duplicates
          .map(
            (h) =>
                '${h.name}${h.symbol.isEmpty ? '' : ' (${h.symbol})'} ${h.currencyCode} · ID ${h.id}',
          )
          .join(', ');
      throw StateError('같은 이름 또는 티커의 항목이 있습니다: $existing');
    }
    final id = cash
        ? await db.createCashAccount(
            assetId: assetId,
            currencyCode: currency,
            name: name,
            note: note.trim(),
          )
        : await db.createHolding(
            assetId: assetId,
            currencyCode: currency,
            exchangeCode: exchangeCode,
            name: name,
            symbol: symbol,
            quantity: 0,
            averagePrice: 0,
            currentPrice: 0,
            note: note.trim(),
          );
    return {'asset_id': assetId, 'holding_id': id};
  }

  Future<Map<String, dynamic>> _holdingEvidence(int id) async {
    final table = id < 0 ? 'cash_accounts' : 'holdings';
    final row = await db
        .customSelect(
          'SELECT client_id, last_modified_at FROM $table WHERE id = ?',
          variables: [Variable.withInt(id.abs())],
        )
        .getSingle();
    return {
      'cash': id < 0,
      'client_id': row.read<String>('client_id'),
      'revision': row.readNullable<String>('last_modified_at'),
    };
  }

  Future<Map<String, dynamic>> _write(
    String operation,
    Map<String, dynamic> args,
  ) async {
    if (operation == 'delete_transaction' ||
        operation == 'update_transaction') {
      final id = _integer(args, 'event_id');
      final matches = (await _transactions())
          .where((t) => t.ledgerEventId == id)
          .toList();
      if (matches.isEmpty) throw StateError('거래를 찾을 수 없습니다.');
      // For transfer/exchange use the outgoing leg, regardless of the displayed row.
      final t = matches.firstWhere(
        (t) => {'transfer_out', 'fx_out'}.contains(t.ledgerAction),
        orElse: () => matches.first,
      );
      if (operation == 'delete_transaction') {
        _checkFields(args, {'request_id', 'event_id'});
        await db.deleteLedgerTransactionItem(t);
        return {'deleted_event_id': id};
      }
      final allowed = {'request_id', 'event_id', 'date', 'name', 'amount'};
      if (t.ledgerAction == 'buy' ||
          t.ledgerAction == 'sell' ||
          t.ledgerAction == 'opening_quantity') {
        allowed.add('quantity');
      }
      if (t.ledgerAction == 'fx_out' ||
          (t.ledgerAction == 'buy' &&
              (await db.fetchHoldingById(t.holdingId!))?.currencyCode ==
                  'USD')) {
        allowed.add('fx_rate');
      }
      _checkFields(args, allowed);
      final amount = args.containsKey('amount')
          ? _positive(args, 'amount').toString()
          : t.amount;
      final quantity = t.type == '환전' && args.containsKey('fx_rate')
          ? _positive(args, 'fx_rate').toString()
          : args.containsKey('quantity')
          ? _positive(args, 'quantity').toString()
          : t.quantity;
      final date = args.containsKey('date') ? _date(args) : t.date;
      if (args.keys.every((k) => {'request_id', 'event_id'}.contains(k))) {
        throw ArgumentError('수정할 값이 필요합니다.');
      }
      final newEventId = await db.replaceLedgerTransactionItem(
        TransactionItem(
          id: t.id,
          clientId: t.clientId,
          assetId: t.assetId,
          holdingId: t.holdingId,
          date: date,
          type: t.type,
          name: args.containsKey('name') ? _text(args, 'name') : t.name,
          amount: amount,
          quantity: quantity,
          ledgerEventId: t.ledgerEventId,
          ledgerLineId: t.ledgerLineId,
          ledgerKind: t.ledgerKind,
          ledgerAction: t.ledgerAction,
          includeInCalculations: t.includeInCalculations,
          flowCategory: t.flowCategory,
          counterpartyHoldingId: t.counterpartyHoldingId,
          realizedProfitSource: t.realizedProfitSource,
          realizedProfitAmount: t.realizedProfitAmount,
          fxRate: args.containsKey('fx_rate')
              ? _positive(args, 'fx_rate')
              : t.fxRate,
        ),
      );
      if (newEventId == null) throw StateError('수정할 거래를 찾을 수 없습니다.');
      return {
        'event_id': newEventId,
        'replaced_event_id': id,
        'refresh_transactions': true,
      };
    }
    final holdingId = _integer(
      args,
      operation == 'create_transaction' ? 'holding_id' : 'source_holding_id',
    );
    final holding = await db.fetchHoldingById(holdingId);
    if (holding == null) throw StateError('보유 종목 또는 현금 계좌를 찾을 수 없습니다.');
    final date = _date(args);
    final name = _text(args, 'name');
    final amount = _positive(args, 'amount').toString();
    int id;
    const cashFields = {
      'request_id',
      'source_holding_id',
      'date',
      'name',
      'amount',
    };
    if (operation == 'transfer_cash') {
      _checkFields(args, {...cashFields, 'target_holding_id'});
      final targetId = _integer(args, 'target_holding_id');
      final target = await db.fetchHoldingById(targetId);
      if (holdingId >= 0 || targetId >= 0 || target == null) {
        throw ArgumentError('현금 계좌 ID가 필요합니다.');
      }
      if (target.currencyCode != holding.currencyCode) {
        throw ArgumentError('다른 통화는 exchange_cash를 사용하세요.');
      }
      id = await db.createCashTransfer(
        assetId: holding.assetId!,
        sourceHoldingId: holdingId,
        targetHoldingId: targetId,
        date: date,
        name: name,
        amount: amount,
      );
    } else if (operation == 'exchange_cash') {
      _checkFields(args, {...cashFields, 'fx_rate'});
      if (holdingId >= 0) throw ArgumentError('현금 계좌 ID가 필요합니다.');
      id = await db.createCashExchange(
        assetId: holding.assetId!,
        sourceHoldingId: holdingId,
        date: date,
        name: name,
        amount: amount,
        exchangeRate: _positive(args, 'fx_rate'),
      );
    } else {
      final type = _text(args, 'type');
      final allowed = holdingId < 0
          ? {'입금', '출금', '배당', '이자'}
          : {'매수', '매도', '배당', '이자'};
      if (!allowed.contains(type)) {
        throw ArgumentError('이 종목/계좌에서 지원하지 않는 거래 유형입니다.');
      }
      final isTrade = {'매수', '매도'}.contains(type);
      final isUsdBuy = type == '매수' && holding.currencyCode == 'USD';
      _checkFields(args, {
        'request_id',
        'holding_id',
        'date',
        'name',
        'amount',
        'type',
        if (isTrade) 'quantity',
        if (isUsdBuy) 'fx_rate',
      });
      final quantity = isTrade ? _positive(args, 'quantity').toString() : '0';
      id = await db.createTransaction(
        assetId: holding.assetId!,
        holdingId: holdingId,
        date: date,
        type: type,
        name: name,
        amount: amount,
        quantity: quantity,
        tradeFxRate: isUsdBuy ? _positive(args, 'fx_rate') : null,
      );
    }
    return {'event_id': id.abs()};
  }

  void _checkFields(Map<String, dynamic> args, Set<String> allowed) {
    final unsupported = args.keys.where((key) => !allowed.contains(key));
    if (unsupported.isNotEmpty) {
      throw ArgumentError('이 거래에 적용할 수 없는 항목: ${unsupported.join(', ')}');
    }
  }

  String _text(Map<String, dynamic> args, String key) {
    final value = args[key];
    if (value is! String || value.trim().isEmpty || value.length > 1000) {
      throw ArgumentError('$key 값이 필요합니다.');
    }
    return value.trim();
  }

  int _integer(Map<String, dynamic> args, String key) {
    final value = args[key];
    if (value is! int || value == 0) throw ArgumentError('$key: 정수 ID가 필요합니다.');
    return value;
  }

  int _positiveInteger(Map<String, dynamic> args, String key) {
    final value = _integer(args, key);
    if (value < 1) throw ArgumentError('$key: 양의 정수 ID가 필요합니다.');
    return value;
  }

  int _limit(Map<String, dynamic> args) {
    final limit = args['limit'] ?? 20;
    if (limit is! int || limit < 1 || limit > 100) {
      throw ArgumentError('limit: 1..100');
    }
    return limit;
  }

  String _requestId(Map<String, dynamic> args) {
    final id = _text(args, 'request_id');
    if (!RegExp(r'^[a-zA-Z0-9_-]{8,128}$').hasMatch(id)) {
      throw ArgumentError('request_id: 8..128 letters, digits, _ or -');
    }
    return id;
  }

  double _positive(Map<String, dynamic> args, String key) {
    final value = args[key];
    if (value is! num || !value.isFinite || value <= 0) {
      throw ArgumentError('$key: 0보다 큰 숫자가 필요합니다.');
    }
    return value.toDouble();
  }

  String? _optionalDate(Map<String, dynamic> args, String key) =>
      args.containsKey(key) ? _date(args, key) : null;

  void _checkDateRange(String? from, String? to) {
    if (from != null && to != null && from.compareTo(to) > 0) {
      throw ArgumentError('시작일은 종료일보다 늦을 수 없습니다.');
    }
  }

  String _date(Map<String, dynamic> args, [String key = 'date']) {
    final value = _text(args, key);
    final parsed = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        parsed == null ||
        parsed.toIso8601String().substring(0, 10) != value) {
      throw ArgumentError('$key: YYYY-MM-DD 날짜가 필요합니다.');
    }
    return value;
  }
}

class _PreviewRollback implements Exception {
  const _PreviewRollback(this.result);

  final Map<String, dynamic> result;
}
