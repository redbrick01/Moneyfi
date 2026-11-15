import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';

/// Local-only adapter: all money changes go through the application's ledger.
class LocalMcpBridge {
  LocalMcpBridge({required this.db, required this.userId, required this.sync});
  final AppDatabase db;
  final String? Function() userId;
  final Future<bool> Function() sync;
  HttpServer? _server;

  Future<void> start({required String token, int port = 47831}) async {
    if (token.length < 32) {
      throw ArgumentError('MCP token must have 32 characters');
    }
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    // Requests are serialized, including retries and cloud synchronization.
    _serve(token);
  }

  Future<void> close() async => _server?.close(force: true);

  Future<void> _serve(String token) async {
    await for (final request in _server!) {
      try {
        if (request.method != 'POST' ||
            request.uri.path != '/mcp' ||
            request.headers.value('authorization') != 'Bearer $token' ||
            request.headers.value('origin') != null) {
          request.response.statusCode = 403;
          continue;
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
        await request.response.close();
      }
    }
  }

  Future<Map<String, dynamic>> execute(
    String operation,
    Map<String, dynamic> args,
  ) async {
    final user = userId();
    if (user == null) throw StateError('MONEYFY 앱에서 로그인하고 데이터 로딩을 완료하세요.');
    if (operation == 'list_assets') {
      return {
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
    }
    if (operation == 'list_recent_transactions') {
      final limit = args['limit'] ?? 20;
      if (limit is! int || limit < 1 || limit > 100) {
        throw ArgumentError('limit: 1..100');
      }
      final items = await _transactions();
      items.sort((a, b) => b.date.compareTo(a.date));
      return {
        'transactions': [for (final t in items.take(limit)) _json(t)],
      };
    }
    if (!{
      'create_transaction',
      'transfer_cash',
      'exchange_cash',
      'update_transaction',
      'delete_transaction',
      'retry_sync',
    }.contains(operation)) {
      throw ArgumentError('Unknown operation');
    }
    final requestId = _text(args, 'request_id');
    if (!RegExp(r'^[a-zA-Z0-9_-]{8,128}$').hasMatch(requestId)) {
      throw ArgumentError('request_id: 8..128 letters, digits, _ or -');
    }
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS mcp_write_receipts (user_id TEXT NOT NULL, request_id TEXT NOT NULL, command TEXT NOT NULL, result TEXT NOT NULL, PRIMARY KEY(user_id, request_id))',
    );
    final keys = args.keys.toList()..sort();
    final command = jsonEncode({
      'operation': operation,
      'arguments': {for (final key in keys) key: args[key]},
    });
    final result = await db.transaction(() async {
      final rows = await db
          .customSelect(
            'SELECT command, result FROM mcp_write_receipts WHERE user_id = ? AND request_id = ?',
            variables: [
              Variable.withString(user),
              Variable.withString(requestId),
            ],
          )
          .get();
      if (rows.isNotEmpty) {
        if (operation != 'retry_sync' &&
            rows.first.read<String>('command') != command) {
          throw StateError('같은 request_id에 다른 변경을 사용할 수 없습니다.');
        }
        return Map<String, dynamic>.from(
          jsonDecode(rows.first.read<String>('result')) as Map,
        );
      }
      if (operation == 'retry_sync') throw StateError('존재하지 않는 request_id입니다.');
      if (userId() != user) throw StateError('계정이 변경되었습니다.');
      final changed = await _write(operation, args);
      // Reject edits/deletions that would leave an impossible current balance.
      for (final a in await db.fetchAssets()) {
        for (final h in a.holdings) {
          if (h.quantity < -0.00000001) {
            throw StateError('수량 또는 현금 잔액이 부족합니다: ${h.name}');
          }
        }
      }
      final result = <String, dynamic>{
        'request_id': requestId,
        'local_saved': true,
        'supabase_synced': false,
        ...changed,
      };
      await db.customStatement(
        'INSERT INTO mcp_write_receipts VALUES (?, ?, ?, ?)',
        [user, requestId, command, jsonEncode(result)],
      );
      return result;
    });
    if (result['supabase_synced'] != true) {
      try {
        result['supabase_synced'] = userId() == user && await sync();
      } catch (_) {
        result['supabase_synced'] = false;
      }
      await db.customStatement(
        'UPDATE mcp_write_receipts SET result = ? WHERE user_id = ? AND request_id = ?',
        [jsonEncode(result), user, requestId],
      );
    }
    result['message'] = result['supabase_synced'] == true
        ? '앱 저장 및 Supabase 반영이 완료되었습니다.'
        : '앱에는 저장됐지만 Supabase 반영은 확인되지 않았습니다. 같은 request_id로 retry_sync를 호출하세요. 새 거래를 만들지 마세요.';
    return result;
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
        await db.deleteLedgerTransactionItem(t);
        return {'deleted_event_id': id};
      }
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
      await db.updateTransactionItem(
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
      return {'replaced_event_id': id, 'refresh_transactions': true};
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
    if (operation == 'transfer_cash') {
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
      final quantity = holdingId > 0 && {'매수', '매도'}.contains(type)
          ? _positive(args, 'quantity').toString()
          : '0';
      id = await db.createTransaction(
        assetId: holding.assetId!,
        holdingId: holdingId,
        date: date,
        type: type,
        name: name,
        amount: amount,
        quantity: quantity,
        tradeFxRate: args.containsKey('fx_rate')
            ? _positive(args, 'fx_rate')
            : null,
      );
    }
    return {'event_id': id.abs()};
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

  double _positive(Map<String, dynamic> args, String key) {
    final value = args[key];
    if (value is! num || !value.isFinite || value <= 0) {
      throw ArgumentError('$key: 0보다 큰 숫자가 필요합니다.');
    }
    return value.toDouble();
  }

  String _date(Map<String, dynamic> args) {
    final value = _text(args, 'date');
    final parsed = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        parsed == null ||
        parsed.toIso8601String().substring(0, 10) != value) {
      throw ArgumentError('date: YYYY-MM-DD 날짜가 필요합니다.');
    }
    return value;
  }
}
