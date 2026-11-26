import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moneyfy/data/asset_data.dart';
import '../models/asset_item.dart';
import 'market_data_service.dart';

final _whitespace = RegExp(r'\s+');
String _searchTerm(String value) =>
    value.toUpperCase().replaceAll(_whitespace, '');

class _SearchEntry {
  _SearchEntry(this.result)
    : symbol = _searchTerm(result.symbol),
      names = [result.name, ...result.aliases].map(_searchTerm).toList();

  final MarketSearchResult result;
  final String symbol;
  final List<String> names;

  int rank(String query) {
    if (symbol == query) return 0;
    if (names.contains(query)) return 1;
    if (symbol.startsWith(query) ||
        names.any((name) => name.startsWith(query))) {
      return 2;
    }
    if (symbol.contains(query) || names.any((name) => name.contains(query))) {
      return 3;
    }
    return -1;
  }
}

final _catalog = _loadCatalog();

Future<List<_SearchEntry>> _loadCatalog() async {
  final data = await rootBundle.load('assets/market_catalog.json');
  return compute(
    _parseCatalog,
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

List<_SearchEntry> _parseCatalog(Uint8List bytes) {
  final rows = jsonDecode(utf8.decode(bytes)) as List;
  return [
    for (final row in rows.cast<List>())
      _SearchEntry(MarketSearchResult.fromCatalog(row.cast<String>())),
  ];
}

Future<List<MarketSearchResult>> searchMarketLocally(
  List<AssetItem> assets,
  Set<String> assetTypes,
  String query,
) async {
  final term = _searchTerm(query);
  if (term.isEmpty) return const [];
  final ranked = List.generate(4, (_) => <MarketSearchResult>[]);
  void consider(_SearchEntry entry) {
    if (!assetTypes.contains(entry.result.assetType)) return;
    final rank = entry.rank(term);
    if (rank >= 0) ranked[rank].add(entry.result);
  }

  for (final instrument in _knownInstruments) {
    consider(_SearchEntry(instrument));
  }
  for (final asset in [...assets, ...assetItems]) {
    if (!assetTypes.contains(asset.assetType)) continue;
    for (final holding in asset.holdings) {
      if (holding.isCashLike || holding.symbol.trim().isEmpty) continue;
      consider(
        _SearchEntry(MarketSearchResult.fromHolding(holding, asset.assetType)),
      );
    }
  }
  if (assetTypes.contains('주식') || assetTypes.contains('펀드')) {
    for (final entry in await _catalog) {
      consider(entry);
    }
  }

  final seen = <String>{};
  return ranked
      .expand((bucket) => bucket)
      .where((result) => seen.add(result.key))
      .take(8)
      .toList();
}

List<MarketSearchResult> mergeMarketResults(
  MarketSearchResult apiResult,
  List<MarketSearchResult> localResults,
) {
  return [
    apiResult,
    ...localResults.where((result) => result.key != apiResult.key),
  ].take(8).toList(growable: false);
}

Future<MarketSearchResult?> verifyMarketSymbol({
  required String primaryAssetType,
  required Set<String> searchableAssetTypes,
  required String query,
  required List<MarketSearchResult> localResults,
}) async {
  for (final candidate in _marketLookupCandidates(
    primaryAssetType,
    searchableAssetTypes,
    localResults,
    query,
  )) {
    final lookupHolding = HoldingItem(
      assetTitle: query,
      assetType: candidate.assetType,
      currencyCode: candidate.currencyCode,
      exchangeCode: candidate.exchangeCode,
      name: query,
      symbol: candidate.symbol,
      quantity: 0,
      averagePrice: 0,
      currentPrice: -1,
      note: '',
      transactions: const [],
    );

    final snapshot = await MarketDataService.instance.fetchSnapshot(
      lookupHolding,
      includeFundComponents: false,
    );
    final currentPrice = snapshot.currentPriceValue;
    if (snapshot.isFallback || currentPrice == null || currentPrice <= 0) {
      continue;
    }

    MarketSearchResult? matchedLocal;
    for (final result in localResults) {
      if (result.assetType == candidate.assetType &&
          result.symbol == candidate.symbol &&
          result.currencyCode == candidate.currencyCode &&
          (candidate.currencyCode != 'USD' ||
              result.exchangeCode == candidate.exchangeCode)) {
        matchedLocal = result;
        break;
      }
    }
    return MarketSearchResult(
      name: matchedLocal?.name ?? query,
      symbol: candidate.symbol,
      assetType: candidate.assetType,
      currencyCode: candidate.currencyCode,
      exchangeCode: candidate.exchangeCode,
      currentPrice: currentPrice,
      sourceLabel: 'API',
      aliases: matchedLocal?.aliases ?? const [],
      listingMarket: matchedLocal?.listingMarket,
    );
  }
  return null;
}

List<_MarketLookupCandidate> _marketLookupCandidates(
  String primaryAssetType,
  Set<String> searchableAssetTypes,
  List<MarketSearchResult> localResults,
  String query,
) {
  final normalized = query.trim().toUpperCase();
  final candidates = <_MarketLookupCandidate>[];
  final seen = <String>{};

  void add(
    String assetType,
    String symbol,
    String currencyCode,
    String exchangeCode,
  ) {
    final key = '$assetType:$currencyCode:$exchangeCode:$symbol';
    if (seen.add(key)) {
      candidates.add(
        _MarketLookupCandidate(
          assetType: assetType,
          symbol: symbol,
          currencyCode: currencyCode,
          exchangeCode: exchangeCode,
        ),
      );
    }
  }

  for (final instrument in localResults) {
    final exact = [
      instrument.name,
      instrument.symbol,
      ...instrument.aliases,
    ].any((value) => _searchTerm(value) == _searchTerm(normalized));
    if (!exact) continue;
    add(
      instrument.assetType,
      instrument.symbol,
      instrument.currencyCode,
      instrument.exchangeCode,
    );
  }

  if (!RegExp(r'^[A-Z0-9][A-Z0-9.-]*$').hasMatch(normalized)) {
    return candidates;
  }
  if (searchableAssetTypes.contains('주식')) {
    add('주식', normalized, 'KRW', '');
    add('주식', normalized, 'USD', 'NAS');
  }
  if (primaryAssetType != '주식' && primaryAssetType != '코인') {
    add(primaryAssetType, normalized, 'KRW', '');
    add(primaryAssetType, normalized, 'USD', 'NAS');
  }
  if (searchableAssetTypes.contains('코인')) add('코인', normalized, 'KRW', '');
  return candidates;
}

class MarketSearchResult {
  const MarketSearchResult({
    required this.name,
    required this.symbol,
    required this.assetType,
    required this.currencyCode,
    required this.exchangeCode,
    required this.currentPrice,
    required this.sourceLabel,
    this.aliases = const [],
    this.listingMarket,
  });

  factory MarketSearchResult.fromCatalog(List<String> row) {
    final [market, symbol, name, english, assetType] = row;
    final domestic = market == 'KOSPI' || market == 'KOSDAQ';
    return MarketSearchResult(
      name: name,
      symbol: symbol,
      assetType: assetType,
      currencyCode: domestic ? 'KRW' : 'USD',
      exchangeCode: domestic ? '' : market,
      listingMarket: market,
      currentPrice: 0,
      sourceLabel: '종목 목록',
      aliases: [
        if (english.isNotEmpty && english != name) english,
        if (!domestic && symbol.contains('/')) symbol.replaceAll('/', '.'),
      ],
    );
  }

  factory MarketSearchResult.fromHolding(
    HoldingItem holding,
    String assetType,
  ) {
    return MarketSearchResult(
      name: holding.name,
      symbol: holding.symbol,
      assetType: assetType,
      currencyCode: holding.currencyCode,
      exchangeCode: holding.exchangeCode,
      currentPrice: holding.currentPrice,
      sourceLabel: '목록',
    );
  }

  final String name;
  final String symbol;
  final String assetType;
  final String currencyCode;
  final String exchangeCode;
  final double currentPrice;
  final String sourceLabel;
  final List<String> aliases;
  final String? listingMarket;

  HoldingItem asMarketQuote() => HoldingItem(
    assetType: assetType,
    assetTitle: name,
    name: name,
    symbol: symbol,
    currencyCode: currencyCode,
    exchangeCode: exchangeCode,
    currentPrice: sourceLabel == 'API' ? currentPrice : 0,
    quantity: 0,
    averagePrice: 0,
    note: '',
    transactions: const [],
  );

  String get key => [
    assetType,
    currencyCode,
    currencyCode == 'USD' ? exchangeCode : '',
    symbol.trim().toUpperCase(),
  ].join(':');

  String get marketLabel {
    final market =
        listingMarket ??
        switch ((assetType, currencyCode)) {
          ('코인', _) => currencyCode,
          (_, 'KRW') => 'KRX',
          _ => exchangeCode.isEmpty ? currencyCode : exchangeCode,
        };
    return '$symbol · $market · $assetType';
  }

  String get subtitle {
    final exchange = exchangeCode.isEmpty ? currencyCode : exchangeCode;
    return '$symbol · $exchange · $sourceLabel';
  }

  String get priceLabel {
    if (currentPrice <= 0) return '시세 미제공';
    final rounded = currentPrice % 1 == 0
        ? currentPrice.toStringAsFixed(0)
        : currentPrice.toStringAsFixed(2);
    return currencyCode == 'USD' ? '\$$rounded' : '₩$rounded';
  }
}

class _MarketLookupCandidate {
  const _MarketLookupCandidate({
    required this.assetType,
    required this.symbol,
    required this.currencyCode,
    required this.exchangeCode,
  });

  final String assetType;
  final String symbol;
  final String currencyCode;
  final String exchangeCode;
}

const _knownInstruments = <MarketSearchResult>[
  MarketSearchResult(
    name: '삼성전자',
    symbol: '005930',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['SAMSUNG'],
  ),
  MarketSearchResult(
    name: 'SK하이닉스',
    symbol: '000660',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['HYNIX'],
  ),
  MarketSearchResult(
    name: 'NAVER',
    symbol: '035420',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['네이버'],
  ),
  MarketSearchResult(
    name: '카카오',
    symbol: '035720',
    assetType: '주식',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['KAKAO'],
  ),
  MarketSearchResult(
    name: 'Apple',
    symbol: 'AAPL',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['애플'],
  ),
  MarketSearchResult(
    name: 'Microsoft',
    symbol: 'MSFT',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['마이크로소프트'],
  ),
  MarketSearchResult(
    name: 'NVIDIA',
    symbol: 'NVDA',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['엔비디아'],
  ),
  MarketSearchResult(
    name: 'Tesla',
    symbol: 'TSLA',
    assetType: '주식',
    currencyCode: 'USD',
    exchangeCode: 'NAS',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['테슬라'],
  ),
  MarketSearchResult(
    name: 'Bitcoin',
    symbol: 'BTC',
    assetType: '코인',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['비트코인'],
  ),
  MarketSearchResult(
    name: 'Ethereum',
    symbol: 'ETH',
    assetType: '코인',
    currencyCode: 'KRW',
    exchangeCode: '',
    currentPrice: 0,
    sourceLabel: '추천',
    aliases: ['이더리움'],
  ),
];
