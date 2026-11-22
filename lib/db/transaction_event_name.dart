const transactionEventNameContextSql = '''
  SELECT e.id, e.client_id, e.kind, e.title, e.memo, e.last_modified_at,
    MAX(h.name) AS holding_name,
    MAX(c.name) AS cash_name,
    MAX(CASE WHEN l.action = 'transfer_out' THEN
      TRIM(COALESCE(NULLIF(a.alias, ''), a.title, '') || ' ' || c.name)
    END) AS transfer_from,
    MAX(CASE WHEN l.action = 'transfer_in' THEN
      TRIM(COALESCE(NULLIF(a.alias, ''), a.title, '') || ' ' || c.name)
    END) AS transfer_to,
    MAX(CASE WHEN l.action = 'fx_out' THEN l.currency_code END) AS fx_from,
    MAX(CASE WHEN l.action = 'fx_in' THEN l.currency_code END) AS fx_to
  FROM transaction_events e
  LEFT JOIN transaction_lines l ON l.event_id = e.id AND l.deleted_at IS NULL
  LEFT JOIN holdings h ON h.id = l.holding_id
  LEFT JOIN cash_accounts c ON c.id = l.cash_account_id
  LEFT JOIN assets a ON a.id = c.asset_id
''';

final _typePrefix = RegExp(
  r'^(?:manual buy|manual sell|매수|매도|입금|출금|이체|환전|배당|이자|초기)(?:\s*·\s*|\s+|$)',
  caseSensitive: false,
);
final _typeSuffix = RegExp(
  r'(?:\s*·\s*|\s+|^)(?:매수|매도|입금|출금|이체|환전|배당|이자|초기 보유)$',
);

String mergeTransactionMemos(String original, String detail) {
  if (detail.isEmpty || original.split('\n').contains(detail)) return original;
  return original.isEmpty ? detail : '$original\n$detail';
}

({String title, String memo}) normalizeTransactionEventName(
  Map<String, Object?> row,
) {
  String read(String key) => (row[key] as String? ?? '').trim();

  final original = read('title');
  final memo = row['memo'] as String;
  final kind = read('kind');
  final holding = read('holding_name');
  final cashName = read('cash_name');
  final isCashPair = kind == 'cash_transfer' || kind == 'fx_exchange';
  if (original.isNotEmpty &&
      (original == holding || (!isCashPair && original == cashName))) {
    return (title: original, memo: memo);
  }

  final stripped = original
      .replaceFirst(_typePrefix, '')
      .replaceFirst(_typeSuffix, '')
      .trim();
  if (holding.isNotEmpty) {
    final generated =
        original != stripped ||
        original.isEmpty ||
        const {'기초 잔고', '보유 정보 조정', '분배금', '결산분배금'}.contains(original);
    if (generated) {
      final detail = switch (original) {
        '기초 잔고' || '보유 정보 조정' => '',
        _ => stripped == holding ? '' : stripped,
      };
      return (title: holding, memo: mergeTransactionMemos(memo, detail));
    }
  }

  if (isCashPair) {
    final isFx = kind == 'fx_exchange';
    final from = read(isFx ? 'fx_from' : 'transfer_from');
    final to = read(isFx ? 'fx_to' : 'transfer_to');
    if (from.isNotEmpty && to.isNotEmpty) {
      final route = '$from → $to';
      final detail = stripped == route || stripped == from || stripped == to
          ? ''
          : stripped;
      return (title: route, memo: mergeTransactionMemos(memo, detail));
    }
    if (isFx) {
      return (title: stripped.isEmpty ? '통화' : stripped, memo: memo);
    }
    // Older transfers can have only one active line.
    final partialRoute = stripped.replaceFirst(RegExp(r'\s+이체\s*·\s*'), ' → ');
    return (title: partialRoute.isEmpty ? '현금' : partialRoute, memo: memo);
  }

  final title = switch (stripped) {
    '추가 입금' || '추가' => '추가 자금',
    '타사' || '타사 이체' => '타 금융기관',
    '이체 수수료' || '출금 수수료' => '수수료',
    '' => cashName.isEmpty ? '현금' : cashName,
    _ => stripped,
  };
  return (title: title, memo: memo);
}
