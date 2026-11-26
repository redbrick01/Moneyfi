import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart' show AsyncCache;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'package:moneyfy/components/formatters/number_format.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/models/holding_price_history.dart';
import 'package:moneyfy/features/portfolio/models/market_snapshot.dart';

class MarketRefreshResult {
  const MarketRefreshResult({
    required this.total,
    required this.updated,
    required this.unresolvedExchanges,
    required this.fxUpdated,
  });

  final int total;
  final int updated;
  final int unresolvedExchanges;
  final bool fxUpdated;

  String get message {
    final failed = total - updated - unresolvedExchanges;
    return [
      if (total > 0) '서버 시세 $updated/$total건 확인' else '갱신할 종목이 없어요',
      if (unresolvedExchanges > 0) '거래소 미확인 $unresolvedExchanges건',
      if (failed > 0) '서버 시세 미확인 $failed건',
      if (!fxUpdated) '환율 갱신 실패',
    ].join(' · ');
  }
}

enum QuoteRead { normal, cachedOnly, refresh }

class MarketDataService {
  MarketDataService._({
    HttpClientAdapter? adapter,
    _MarketApiConfig? config,
    bool persistKisTokenStorage = true,
    bool useServerPrices = true,
  }) : _client = Dio(
         BaseOptions(
           connectTimeout: _quoteTimeout,
           sendTimeout: _quoteTimeout,
           receiveTimeout: _quoteTimeout,
           responseType: ResponseType.plain,
           validateStatus: (status) => status != null,
         ),
       ),
       _config = config ?? _MarketApiConfig(),
       _persistKisTokenStorage = persistKisTokenStorage,
       _useServerPrices = useServerPrices {
    if (adapter != null) _client.httpClientAdapter = adapter;
  }

  @visibleForTesting
  factory MarketDataService.test({
    required HttpClientAdapter adapter,
    String kisBaseUrl = 'https://openapi.koreainvestment.com:9443',
    String kisAppKey = '',
    String kisAppSecret = '',
    String kisStockQuotePath =
        '/uapi/domestic-stock/v1/quotations/inquire-price',
    String kisStockQuoteTrId = 'FHKST01010100',
    String kisOverseasStockQuotePath =
        '/uapi/overseas-price/v1/quotations/price-detail',
    String kisOverseasStockQuoteTrId = 'HHDFS76200200',
    String kisFundQuotePath = '/uapi/etfetn/v1/quotations/inquire-price',
    String kisFundQuoteTrId = 'FHPST02400000',
    String kisFundComponentsPath =
        '/uapi/etfetn/v1/quotations/inquire-component-stock-price',
    String kisFundComponentsTrId = 'FHKST121600C0',
    String kisFundComponentsScrDivCode = '11216',
    String coinTickerUrlTemplate = '',
    String usdKrwRateUrl = '',
  }) {
    return MarketDataService._(
      adapter: adapter,
      persistKisTokenStorage: false,
      useServerPrices: false,
      config: _MarketApiConfig(
        kisBaseUrl: kisBaseUrl,
        kisAppKey: kisAppKey,
        kisAppSecret: kisAppSecret,
        kisStockQuotePath: kisStockQuotePath,
        kisStockQuoteTrId: kisStockQuoteTrId,
        kisOverseasStockQuotePath: kisOverseasStockQuotePath,
        kisOverseasStockQuoteTrId: kisOverseasStockQuoteTrId,
        kisFundQuotePath: kisFundQuotePath,
        kisFundQuoteTrId: kisFundQuoteTrId,
        kisFundComponentsPath: kisFundComponentsPath,
        kisFundComponentsTrId: kisFundComponentsTrId,
        kisFundComponentsScrDivCode: kisFundComponentsScrDivCode,
        coinTickerUrlTemplate: coinTickerUrlTemplate,
        usdKrwRateUrl: usdKrwRateUrl,
      ),
    );
  }

  static final MarketDataService instance = MarketDataService._();
  static const _secureStorage = FlutterSecureStorage();
  static const _kisAccessTokenStorageKey = 'kis_access_token';
  static const _kisAccessTokenExpiryStorageKey = 'kis_access_token_expires_at';
  static const _quoteTimeout = Duration(seconds: 15);

  final Dio _client;
  final _quotes = <Uri, Map<String, dynamic>>{};
  int _cacheGeneration = 0;
  final _pendingReads =
      <(Uri, String?, bool), AsyncCache<Map<String, dynamic>>>{};

  final _MarketApiConfig _config;
  final bool _persistKisTokenStorage;
  final bool _useServerPrices;

  String? _accessToken;
  DateTime? _accessTokenExpiresAt;
  Future<String>? _accessTokenFuture;
  Future<void>? _accessTokenRestoreFuture;
  DateTime? _kisTokenRetryAvailableAt;

  Future<MarketRefreshResult>? _marketRefresh;

  Future<MarketRefreshResult> refreshAllMarketData() {
    return _marketRefresh ??= _refreshAllMarketData().whenComplete(() {
      _marketRefresh = null;
    });
  }

  Future<MarketRefreshResult> _refreshAllMarketData() async {
    var fxUpdated = false;
    try {
      fxUpdated = await refreshUsdKrwRate() != null;
    } catch (error, stackTrace) {
      _log('FX refresh failed: $error');
      _logStack(stackTrace);
    }

    final positions = await AppDatabase.instance
        .fetchHoldingsForMarketRefresh();
    final holdings = positions
        .where((holding) => !_isCashLikeHolding(holding))
        .toList();
    var updated = 0;
    final userId = AuthService.currentUser?.id;
    if (holdings.isNotEmpty && userId != null) {
      try {
        updated = await _readStoredPrices(userId);
      } catch (error) {
        _log('Server price refresh failed: ${error.runtimeType}');
      }
    }
    return MarketRefreshResult(
      total: holdings.length,
      updated: updated,
      unresolvedExchanges: 0,
      fxUpdated: fxUpdated,
    );
  }

  Future<void> refreshHoldingPrice(HoldingItem holding) async {
    final userId = AuthService.currentUser?.id;
    final clientId = holding.clientId;
    if (userId == null || clientId == null || clientId.isEmpty) return;
    await _readStoredPrices(userId, clientId: clientId);
  }

  Future<int> _readStoredPrices(String userId, {String? clientId}) async {
    final response = await AuthService.client.functions.invoke(
      'update-holding-prices',
      body: {'mode': 'read', if (clientId != null) 'client_id': clientId},
    );
    final payload = response.data;
    if (response.status != 200 ||
        payload is! Map ||
        payload['ok'] != true ||
        payload['prices'] is! List) {
      throw StateError('Server holding prices are unavailable');
    }
    return AppDatabase.instance.applyServerHoldingPrices(
      (payload['prices'] as List).whereType<Map<String, dynamic>>().toList(),
      ownerId: userId,
      clientId: clientId,
      canApply: () => AuthService.currentUser?.id == userId,
    );
  }

  Future<void> clearLocalCache() async {
    _pendingReads.clear();
    _quotes.clear();
    _cacheGeneration++;
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _accessTokenFuture = null;
    _accessTokenRestoreFuture = null;
    _kisTokenRetryAvailableAt = null;
    await _clearPersistedKisAccessToken();
  }

  Future<double?> refreshUsdKrwRate() async {
    if (_config.usdKrwRateUrl.isEmpty) {
      _log('USD/KRW rate refresh skipped: url missing');
      return null;
    }

    final uri = Uri.parse(_config.usdKrwRateUrl);
    _log('FX request GET $uri');
    final response = await _request(uri);
    _log('FX response status=${response.statusCode}');

    if (response.statusCode! < 200 || response.statusCode! >= 300) {
      _log('FX request failed body=${_truncate(response.data ?? '')}');
      return null;
    }

    final json = jsonDecode(response.data ?? '') as Map<String, dynamic>;
    final rate = _extractUsdKrwRate(json);
    if (rate == null) {
      _log('FX response parse failed body=${_truncate(response.data ?? '')}');
      return null;
    }

    await AppDatabase.instance.saveExchangeRate(
      currencyPair: 'USD/KRW',
      rate: rate,
      source: 'api',
    );
    _log('FX persisted USD/KRW rate=$rate');
    return rate;
  }

  bool supportsPriceHistory(HoldingItem holding) {
    if (holding.symbol.trim().isEmpty || _isCashLikeHolding(holding)) {
      return false;
    }
    return switch ((
      holding.assetType ?? holding.assetTitle,
      holding.currencyCode.toUpperCase(),
    )) {
      ('주식' || '펀드' || '코인', 'KRW') => true,
      ('주식', 'USD') => holding.exchangeCode.trim().isNotEmpty,
      _ => false,
    };
  }

  DateTime latestDailyCloseDate(HoldingItem holding, {DateTime? now}) {
    final utc = (now ?? DateTime.now()).toUtc();
    if ((holding.assetType ?? holding.assetTitle) == '코인') {
      return DateTime.utc(utc.year, utc.month, utc.day - 1);
    }
    final overseas = holding.currencyCode.toUpperCase() == 'USD';
    // During the session, show the prior completed close.
    final marketDay = overseas
        ? utc.subtract(Duration(hours: _usSummerTime(utc) ? 20 : 21))
        : utc.subtract(const Duration(hours: 6, minutes: 30));
    return DateTime.utc(marketDay.year, marketDay.month, marketDay.day);
  }

  Future<List<HoldingDailyClose>> fetchDailyCloses(
    HoldingItem holding, {
    required DateTime from,
    required DateTime through,
    bool Function()? isCancelled,
  }) async {
    if (!supportsPriceHistory(holding) || through.isBefore(from)) {
      return const [];
    }
    if ((holding.assetType ?? holding.assetTitle) == '코인') {
      if (isCancelled?.call() == true) return const [];
      final response = await _serverMarketRead('coin_daily_closes', {
        'symbol': holding.symbol.trim().toUpperCase(),
        'quote': holding.currencyCode.trim().toUpperCase(),
        'from': DateTime.utc(
          from.year,
          from.month,
          from.day,
        ).millisecondsSinceEpoch.toString(),
        'through': DateTime.utc(
          through.year,
          through.month,
          through.day,
        ).millisecondsSinceEpoch.toString(),
      });
      if (isCancelled?.call() == true) return const [];
      final rows = response['closes'];
      if (rows is! List)
        throw const FormatException('Invalid coin daily prices');
      return [
        for (final row in rows.whereType<Map>())
          if (row['timestamp'] is int && row['close'] is num)
            HoldingDailyClose(
              date: DateTime.fromMillisecondsSinceEpoch(
                row['timestamp'] as int,
                isUtc: true,
              ),
              price: (row['close'] as num).toDouble(),
            ),
      ];
    }
    if (!_useServerPrices && !_config.hasKisStockConfig) {
      throw StateError('KIS market data is not configured');
    }
    final overseas = holding.currencyCode.toUpperCase() == 'USD';
    final symbol = holding.symbol.trim().toUpperCase();
    final exchange = holding.exchangeCode.trim().toUpperCase();
    final byDate = <DateTime, HoldingDailyClose>{};
    var cursor = through;
    while (!cursor.isBefore(from) && isCancelled?.call() != true) {
      final json = _useServerPrices
          ? await _serverMarketRead('daily_closes', {
              'symbol': symbol,
              if (overseas) 'exchange': exchange,
              'from': _kisDateKey(from),
              'through': _kisDateKey(cursor),
            })
          : await _kisGet(
              path: overseas
                  ? '/uapi/overseas-price/v1/quotations/dailyprice'
                  : '/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice',
              trId: overseas ? 'HHDFS76240000' : 'FHKST03010100',
              query: overseas
                  ? {
                      'AUTH': '',
                      'EXCD': exchange,
                      'SYMB': symbol,
                      'GUBN': '0',
                      'BYMD': _kisDateKey(cursor),
                      'MODP': '0',
                    }
                  : {
                      'FID_COND_MRKT_DIV_CODE': 'J',
                      'FID_INPUT_ISCD': symbol,
                      'FID_INPUT_DATE_1': _kisDateKey(from),
                      'FID_INPUT_DATE_2': _kisDateKey(cursor),
                      'FID_PERIOD_DIV_CODE': 'D',
                      'FID_ORG_ADJ_PRC': '1',
                    },
              allowNoData: true,
            );
      if (isCancelled?.call() == true) return const [];
      final rows = json['output2'];
      if (rows is! List) {
        throw const FormatException('Invalid KIS daily prices');
      }

      DateTime? oldest;
      var hasTradingDates = false;
      for (final row in rows.whereType<Map>()) {
        final date = _parseKisDateKey(
          row[overseas ? 'xymd' : 'stck_bsop_date'],
        );
        if (date == null) continue;
        hasTradingDates = true;
        if (date.isAfter(cursor)) continue;
        if (oldest == null || date.isBefore(oldest)) oldest = date;
        final price = _parseNumber(
          row[overseas ? 'clos' : 'stck_clpr'],
        )?.toDouble();
        if (date.isBefore(from) ||
            price == null ||
            !price.isFinite ||
            price <= 0) {
          continue;
        }
        byDate[date] = HoldingDailyClose(date: date, price: price);
      }
      if (oldest == null) {
        if (hasTradingDates) {
          throw const FormatException('KIS daily prices did not advance');
        }
        break;
      }
      // The date-bounded domestic API returns at most 100 records.
      if (!overseas && rows.length < 100) break;
      // The overseas continuation header can repeat the same page. Move the
      // reference date to the previous day to request an older batch directly.
      cursor = oldest.subtract(const Duration(days: 1));
      if (!cursor.isBefore(from)) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    return byDate.values.toList()
      ..sort((first, second) => first.date.compareTo(second.date));
  }

  Future<HoldingMarketSnapshot> fetchSnapshot(
    HoldingItem holding, {
    bool includeFundComponents = false,
    QuoteRead policy = QuoteRead.normal,
  }) async {
    if (policy == QuoteRead.cachedOnly &&
        (!_useServerPrices || AuthService.currentUser == null)) {
      return HoldingMarketSnapshot.fallback(holding);
    }
    try {
      final assetType = holding.assetType ?? holding.assetTitle;
      _log(
        'fetchSnapshot start asset=${assetType ?? '-'} '
        'symbol=${holding.symbol} currency=${holding.currencyCode} '
        'exchange=${holding.exchangeCode}',
      );
      if (_isCashLikeHolding(holding)) {
        _log(
          'fetchSnapshot fallback cash-like holding '
          'symbol=${holding.symbol} currency=${holding.currencyCode}',
        );
        return HoldingMarketSnapshot.fallback(holding);
      }
      switch (assetType) {
        case '주식':
          return await _fetchStockSnapshot(holding, policy);
        case '펀드':
          return await _fetchFundSnapshot(
            holding,
            includeComponents: includeFundComponents,
            policy: policy,
          );
        case '코인':
          return await _fetchCoinSnapshot(holding, policy);
        default:
          _log('fetchSnapshot fallback unsupported asset=${assetType ?? '-'}');
          return HoldingMarketSnapshot.fallback(holding);
      }
    } catch (error, stackTrace) {
      _log('fetchSnapshot failed symbol=${holding.symbol} error=$error');
      _logStack(stackTrace);
      return HoldingMarketSnapshot.fallback(holding);
    }
  }

  bool _isCashLikeHolding(HoldingItem holding) {
    if (holding.isCashLike) return true;
    final symbol = holding.symbol.trim().toUpperCase();
    final currencyCode = holding.currencyCode.trim().toUpperCase();
    if (symbol.isEmpty || currencyCode.isEmpty) return false;
    return symbol == currencyCode;
  }

  Future<HoldingMarketSnapshot> _fetchStockSnapshot(
    HoldingItem holding,
    QuoteRead policy,
  ) async {
    if (holding.currencyCode.toUpperCase() == 'USD') {
      return _fetchOverseasStockSnapshot(holding, policy);
    }

    if (!_useServerPrices && !_config.hasKisStockConfig) {
      _log('fetchSnapshot fallback: KIS stock config missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    if (holding.symbol.isEmpty) {
      _log('fetchSnapshot fallback: stock symbol missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final json = _useServerPrices
        ? await _serverMarketRead('stock_details', {
            'symbol': holding.symbol.trim().toUpperCase(),
          }, policy)
        : await _kisGet(
            path: _config.kisStockQuotePath,
            trId: _config.kisStockQuoteTrId,
            query: {
              'FID_COND_MRKT_DIV_CODE': 'J',
              'FID_INPUT_ISCD': holding.symbol,
            },
          );
    final output =
        (json['output'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (output.isEmpty) return HoldingMarketSnapshot.fallback(holding);

    final latestPrice = _parseNumber(output['stck_prpr'])?.toDouble();
    final currentPrice = _useServerPrices && holding.id != null
        ? holding.currentPrice
        : latestPrice;
    final priceChange = _parseNumber(output['prdy_vrss']);
    final previousClose =
        _parseNumber(output['stck_prdy_clpr']) ??
        (latestPrice == null || priceChange == null
            ? null
            : latestPrice -
                  (_signedPrefix(output['prdy_vrss_sign'], priceChange) == '-'
                      ? -priceChange.abs()
                      : priceChange.abs()));
    final snapshot = HoldingMarketSnapshot(
      receivedAt: json['_receivedAt'] as DateTime?,
      marketName:
          (output['rprs_mrkt_kor_name']?.toString().trim() ?? '').isEmpty
          ? holding.assetTitle ?? '-'
          : _stringOrDash(output['rprs_mrkt_kor_name']),
      sectorName: _stringOrDash(output['bstp_kor_isnm']),
      currentPrice: _formatKrw(currentPrice),
      currentPriceValue: currentPrice,
      dayChange: _formatSignedKrw(
        output['prdy_vrss'],
        sign: output['prdy_vrss_sign'],
      ),
      dayChangeRate: _formatSignedPercent(
        output['prdy_ctrt'],
        sign: output['prdy_vrss_sign'],
      ),
      previousClose: _formatKrw(previousClose),
      openPrice: _formatKrw(output['stck_oprc']),
      highPrice: _formatKrw(output['stck_hgpr']),
      lowPrice: _formatKrw(output['stck_lwpr']),
      volume: _formatNumber(output['acml_vol']),
      turnover: _formatKrw(output['acml_tr_pbmn']),
      per: _formatRaw(output['per']),
      pbr: _formatRaw(output['pbr']),
      eps: _formatKrw(output['eps']),
      bps: _formatKrw(output['bps']),
      week52High: _formatKrw(output['w52_hgpr']),
      week52Low: _formatKrw(output['w52_lwpr']),
      nav: '-',
      navChangeRate: '-',
      trackingError: '-',
      disparityRate: '-',
      netAssets: '-',
      foreignHoldRate: _formatPercent(output['hts_frgn_ehrt']),
      dividendCycle: '-',
      etfCategory: '-',
      listingDate: '-',
      quoteCurrency: holding.currencyCode,
      targetCurrency: holding.symbol,
      quoteVolume24h: '-',
      targetVolume24h: '-',
      bestAskPrice: '-',
      bestBidPrice: '-',
      bestAskQty: '-',
      bestBidQty: '-',
    );
    if (!_useServerPrices) {
      await _persistCurrentPrice(holding, output['stck_prpr']);
    }
    return snapshot;
  }

  Future<HoldingMarketSnapshot> _fetchOverseasStockSnapshot(
    HoldingItem holding,
    QuoteRead policy,
  ) async {
    if (!_useServerPrices && !_config.hasKisOverseasStockConfig) {
      _log('fetchSnapshot fallback: KIS overseas config missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    if (holding.symbol.isEmpty) {
      _log('fetchSnapshot fallback: overseas symbol missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final configuredExchange = holding.exchangeCode.trim().toUpperCase();
    final symbol = holding.symbol.trim().toUpperCase();
    final needsExchange = configuredExchange.isEmpty;
    var exchange = configuredExchange;
    DateTime? receivedAt;
    Map<String, dynamic> output = const {};
    for (final candidate
        in needsExchange ? const ['NAS', 'NYS', 'AMS'] : [configuredExchange]) {
      final json = _useServerPrices
          ? await _serverMarketRead('stock_details', {
              'symbol': symbol,
              'exchange': candidate,
            }, policy)
          : await _kisGet(
              path: _config.kisOverseasStockQuotePath,
              trId: _config.kisOverseasStockQuoteTrId,
              query: {'AUTH': '', 'EXCD': candidate, 'SYMB': symbol},
            );
      final data =
          (json['output'] as Map?)?.cast<String, dynamic>() ?? const {};
      if (needsExchange && data['rsym'] != 'D$candidate$symbol') continue;
      final price = _parseNumber(data['last']);
      if (price == null || !price.isFinite || price <= 0) continue;
      receivedAt = json['_receivedAt'] as DateTime?;
      exchange = candidate;
      output = data;
      break;
    }
    if (output.isEmpty) {
      return HoldingMarketSnapshot.fallback(
        holding,
        exchangeNotFound: needsExchange,
      );
    }
    final latestPrice = _parseNumber(output['last'])?.toDouble();
    final currentPrice = _useServerPrices && holding.id != null
        ? holding.currentPrice
        : latestPrice;
    final previousClose = _parseNumber(output['base']);
    final dayChange = latestPrice != null && previousClose != null
        ? latestPrice - previousClose
        : null;
    final dayChangeRate =
        dayChange != null && previousClose != null && previousClose != 0
        ? (dayChange / previousClose) * 100
        : null;

    final snapshot = HoldingMarketSnapshot(
      receivedAt: receivedAt,
      marketName: _marketNameForExchange(exchange),
      sectorName: '-',
      currentPrice: _formatMoney(currentPrice, currencyCode: 'USD'),
      currentPriceValue: currentPrice,
      dayChange: _formatSignedMoney(dayChange, currencyCode: 'USD'),
      dayChangeRate: _formatSignedPercent(dayChangeRate),
      previousClose: _formatMoney(output['base'], currencyCode: 'USD'),
      openPrice: _formatMoney(output['open'], currencyCode: 'USD'),
      highPrice: _formatMoney(output['high'], currencyCode: 'USD'),
      lowPrice: _formatMoney(output['low'], currencyCode: 'USD'),
      volume: _formatNumber(output['tvol'] ?? output['pvol']),
      turnover: _formatMoney(
        output['tamt'] ?? output['pamt'],
        currencyCode: 'USD',
      ),
      per: _formatRaw(output['perx']),
      pbr: _formatRaw(output['pbrx']),
      eps: _formatMoney(output['epsx'], currencyCode: 'USD'),
      bps: _formatMoney(output['bpsx'], currencyCode: 'USD'),
      week52High: _formatMoney(output['h52p'], currencyCode: 'USD'),
      week52Low: _formatMoney(output['l52p'], currencyCode: 'USD'),
      nav: '-',
      navChangeRate: '-',
      trackingError: '-',
      disparityRate: '-',
      netAssets: '-',
      foreignHoldRate: '-',
      dividendCycle: '-',
      etfCategory: '-',
      listingDate: '-',
      quoteCurrency: holding.currencyCode,
      targetCurrency: holding.symbol,
      quoteVolume24h: '-',
      targetVolume24h: '-',
      bestAskPrice: '-',
      bestBidPrice: '-',
      bestAskQty: '-',
      bestBidQty: '-',
    );
    if (!_useServerPrices) {
      await _persistCurrentPrice(
        holding,
        output['last'],
        recoveredExchange: needsExchange ? exchange : null,
      );
    }
    return snapshot;
  }

  Future<HoldingMarketSnapshot> _fetchFundSnapshot(
    HoldingItem holding, {
    required bool includeComponents,
    required QuoteRead policy,
  }) async {
    if (!_useServerPrices && !_config.hasKisFundConfig) {
      _log('fetchSnapshot fallback: KIS fund config missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    if (holding.symbol.isEmpty) {
      _log('fetchSnapshot fallback: fund symbol missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final summaryJson = _useServerPrices
        ? await _serverMarketRead('fund_nav', {
            'symbol': holding.symbol.trim().toUpperCase(),
          }, policy)
        : await _kisGet(
            path: _config.kisFundQuotePath,
            trId: _config.kisFundQuoteTrId,
            query: {
              'FID_COND_MRKT_DIV_CODE': 'J',
              'FID_INPUT_ISCD': holding.symbol,
            },
          );
    final summary =
        (summaryJson['output'] as Map?)?.cast<String, dynamic>() ?? const {};

    if (summary.isEmpty) {
      _log('KIS fund quote returned no output symbol=${holding.symbol}');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final fundDetails = includeComponents
        ? await fetchFundMarketDetails(holding)
        : null;

    final currentPrice = _useServerPrices && holding.id != null
        ? holding.currentPrice
        : _parseNumber(summary['stck_prpr'])?.toDouble();
    final snapshot = HoldingMarketSnapshot(
      marketName: holding.assetTitle ?? '-',
      receivedAt: summaryJson['_receivedAt'] as DateTime?,
      sectorName: _stringOrDash(summary['bstp_kor_isnm']),
      currentPrice: _useServerPrices && holding.id != null
          ? holding.primaryMetricValue
          : _formatKrw(summary['stck_prpr']),
      currentPriceValue: currentPrice,
      dayChange: _formatSignedKrw(
        summary['prdy_vrss'],
        sign: summary['prdy_vrss_sign'],
      ),
      dayChangeRate: _formatSignedPercent(
        summary['prdy_ctrt'],
        sign: summary['prdy_vrss_sign'],
      ),
      previousClose: _formatKrw(summary['stck_prdy_clpr']),
      openPrice: _formatKrw(summary['stck_oprc']),
      highPrice: _formatKrw(summary['stck_hgpr']),
      lowPrice: _formatKrw(summary['stck_lwpr']),
      volume: _formatNumber(summary['acml_vol']),
      turnover: _formatKrw(summary['acml_tr_pbmn']),
      per: '-',
      pbr: '-',
      eps: '-',
      bps: '-',
      week52High: _formatKrw(summary['w52_hgpr']),
      week52Low: _formatKrw(summary['w52_lwpr']),
      nav: _formatKrw(summary['nav']),
      navChangeRate: _formatSignedPercent(
        summary['nav_prdy_ctrt'],
        sign: summary['nav_prdy_vrss_sign'],
      ),
      trackingError: _formatPercent(summary['trc_errt']),
      disparityRate: _formatPercent(summary['dprt']),
      netAssets: _formatKrw(summary['etf_ntas_ttam']),
      foreignHoldRate: _formatPercent(summary['frgn_hldn_qty_rate']),
      dividendCycle: _stringOrDash(summary['etf_dvdn_cycl']),
      etfCategory: _stringOrDash(summary['etf_div_name']),
      listingDate: _formatDate(summary['stck_lstn_date']),
      quoteCurrency: _stringOrDash(summary['crcd']),
      targetCurrency: holding.symbol,
      quoteVolume24h: '-',
      targetVolume24h: '-',
      bestAskPrice: '-',
      bestBidPrice: '-',
      bestAskQty: '-',
      bestBidQty: '-',
      fundDetails: fundDetails,
    );
    if (!_useServerPrices) {
      await _persistCurrentPrice(holding, summary['stck_prpr']);
    }
    return snapshot;
  }

  Future<FundMarketDetails?> fetchFundMarketDetails(HoldingItem holding) async {
    if (holding.symbol.trim().isEmpty ||
        (!_useServerPrices &&
            (!_config.hasKisStockConfig ||
                _config.kisFundComponentsPath.isEmpty ||
                _config.kisFundComponentsTrId.isEmpty))) {
      return null;
    }

    try {
      final json = _useServerPrices
          ? await _serverMarketRead('fund_details', {
              'symbol': holding.symbol.trim().toUpperCase(),
            })
          : await _kisGet(
              path: _config.kisFundComponentsPath,
              trId: _config.kisFundComponentsTrId,
              query: {
                'FID_COND_MRKT_DIV_CODE': 'J',
                'FID_INPUT_ISCD': holding.symbol,
                'FID_COND_SCR_DIV_CODE': _config.kisFundComponentsScrDivCode,
              },
            );
      final summary = (json['output1'] as Map?) ?? const {};
      final rows = (json['output2'] as List?) ?? const [];
      if (summary.isEmpty && rows.isEmpty) return null;

      return FundMarketDetails(
        componentCount: _formatNumber(summary['etf_cnfg_issu_cnt']),
        componentMarketCap: _formatKrw(summary['etf_cnfg_issu_avls']),
        netAssetsTotal: _formatKrw(summary['etf_ntas_ttam']),
        cuUnitCount: _formatNumber(summary['etf_cu_unit_scrt_cnt']),
        navOpen: _formatKrw(summary['oprc_nav']),
        navHigh: _formatKrw(summary['hprc_nav']),
        navLow: _formatKrw(summary['lprc_nav']),
        topComponents: rows.whereType<Map>().take(10).map((row) {
          return FundComponentItem(
            code: _stringOrDash(row['stck_shrn_iscd']),
            name: _stringOrDash(row['hts_kor_isnm']),
            price: _formatKrw(row['stck_prpr']),
            changeRate: _formatSignedPercent(
              row['prdy_ctrt'],
              sign: row['prdy_vrss_sign'],
            ),
            weight: _formatPercent(row['etf_cnfg_issu_rlim']),
            valuationAmount: _formatKrw(row['etf_vltn_amt']),
          );
        }).toList(),
      );
    } catch (error, stackTrace) {
      _log(
        'fetchSnapshot fund components failed symbol=${holding.symbol} error=$error',
      );
      _logStack(stackTrace);
      return null;
    }
  }

  Future<HoldingMarketSnapshot> _fetchCoinSnapshot(
    HoldingItem holding,
    QuoteRead policy,
  ) async {
    final symbol = holding.symbol.trim().toUpperCase();
    if (symbol.isEmpty) {
      return HoldingMarketSnapshot.fallback(holding);
    }

    final quoteCurrency = holding.currencyCode.trim().toUpperCase();
    final json = _useServerPrices
        ? await _serverMarketRead('coin_details', {
            'symbol': symbol,
            'quote': quoteCurrency,
          }, policy)
        : await _fetchCoinoneTestQuote(symbol, quoteCurrency);
    final tickers = (json['tickers'] as List?) ?? const [];
    if (tickers.isEmpty) {
      _log('Coin response has no tickers symbol=$symbol');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final ticker = tickers.first as Map;
    final bestAsks = (ticker['best_asks'] as List?) ?? const [];
    final bestBids = (ticker['best_bids'] as List?) ?? const [];
    final bestAsk = bestAsks.isEmpty ? const {} : bestAsks.first as Map;
    final bestBid = bestBids.isEmpty ? const {} : bestBids.first as Map;

    final last = _parseNumber(ticker['last'])?.toDouble();
    final previousClose = _parseNumber(ticker['yesterday_last']);
    final dayChange = last == null || previousClose == null
        ? null
        : last - previousClose;
    final dayChangeRate =
        dayChange == null || previousClose == null || previousClose <= 0
        ? null
        : (dayChange / previousClose) * 100;
    final currentPrice = _useServerPrices && holding.id != null
        ? holding.currentPrice
        : last;
    final snapshot = HoldingMarketSnapshot(
      marketName: holding.assetTitle ?? '-',
      receivedAt: json['_receivedAt'] as DateTime?,
      sectorName: '-',
      currentPrice: _formatKrw(currentPrice),
      currentPriceValue: currentPrice,
      dayChange: _formatSignedKrw(dayChange),
      dayChangeRate: _formatSignedPercent(dayChangeRate),
      previousClose: _formatKrw(previousClose),
      openPrice: _formatKrw(ticker['first']),
      highPrice: _formatKrw(ticker['high']),
      lowPrice: _formatKrw(ticker['low']),
      volume: _formatNumber(ticker['target_volume']),
      turnover: _formatKrw(ticker['quote_volume']),
      per: '-',
      pbr: '-',
      eps: '-',
      bps: '-',
      week52High: '-',
      week52Low: '-',
      nav: '-',
      navChangeRate: '-',
      trackingError: '-',
      disparityRate: '-',
      netAssets: '-',
      foreignHoldRate: '-',
      dividendCycle: '-',
      etfCategory: '-',
      listingDate: '-',
      quoteCurrency: _stringOrDash(ticker['quote_currency']),
      targetCurrency: _stringOrDash(ticker['target_currency']),
      quoteVolume24h: _formatKrw(ticker['quote_volume']),
      targetVolume24h: _formatNumber(ticker['target_volume']),
      bestAskPrice: _formatKrw(bestAsk['price']),
      bestBidPrice: _formatKrw(bestBid['price']),
      bestAskQty: _formatNumber(bestAsk['qty']),
      bestBidQty: _formatNumber(bestBid['qty']),
    );
    if (!_useServerPrices) await _persistCurrentPrice(holding, ticker['last']);
    return snapshot;
  }

  Future<Map<String, dynamic>> _fetchCoinoneTestQuote(
    String symbol,
    String quoteCurrency,
  ) {
    final url = _config.coinTickerUrlTemplate.isNotEmpty
        ? _config.coinTickerUrlTemplate
              .replaceAll('{symbol}', symbol)
              .replaceAll('{quote}', quoteCurrency)
        : 'https://api.coinone.co.kr/public/v2/ticker_utc_new/'
              '$quoteCurrency/$symbol?additional_data=true';
    final uri = Uri.parse(url);
    return _shareMarketRead(uri, () async {
      final response = await _request(uri);
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw StateError('Coin quote request failed: ${response.statusCode}');
      }
      return jsonDecode(response.data ?? '') as Map<String, dynamic>;
    });
  }

  Future<Response<String>> _request(Uri uri, {Options? options, Object? data}) {
    final cancel = CancelToken();
    return _client
        .requestUri<String>(
          uri,
          options: options,
          data: data,
          cancelToken: cancel,
        )
        .timeout(
          _quoteTimeout,
          onTimeout: () {
            cancel.cancel('Request deadline exceeded');
            throw TimeoutException(
              'Market request deadline exceeded',
              _quoteTimeout,
            );
          },
        );
  }

  // Share the API payload. Formatting, fallbacks and writes belong to each holding.
  Future<Map<String, dynamic>> _shareMarketRead(
    Uri uri,
    Future<Map<String, dynamic>> Function() load, {
    String? trId,
    bool allowNoData = false,
  }) {
    final key = (uri, trId, allowNoData);
    final cache = _pendingReads.putIfAbsent(key, AsyncCache.ephemeral);
    return cache.fetch(() async {
      try {
        return await load();
      } finally {
        if (identical(_pendingReads[key], cache)) _pendingReads.remove(key);
      }
    });
  }

  Future<Map<String, dynamic>> _serverMarketRead(
    String mode,
    Map<String, String> fields, [
    QuoteRead? policy,
  ]) {
    final userId = AuthService.currentUser?.id;
    if (userId == null) {
      return Future.error(StateError('Market data requires sign-in'));
    }
    final identity = Uri(
      scheme: 'moneyfy',
      host: 'market',
      pathSegments: [userId, mode],
      queryParameters: fields,
    );
    final cached = _quotes[identity];
    if (cached != null && policy != null && policy != QuoteRead.refresh) {
      final age = DateTime.now().difference(cached['_receivedAt'] as DateTime);
      if (age <
          (policy == QuoteRead.cachedOnly
              ? const Duration(hours: 24)
              : const Duration(seconds: 45))) {
        return Future.value(cached);
      }
    }
    if (policy == QuoteRead.cachedOnly) return Future.value({});
    final generation = _cacheGeneration;
    return _shareMarketRead(identity, () async {
      final response = await AuthService.client.functions.invoke(
        'update-holding-prices',
        body: {'mode': mode, ...fields},
      );
      final data = response.data;
      if (AuthService.currentUser?.id != userId ||
          response.status != 200 ||
          data is! Map<String, dynamic> ||
          data['ok'] != true) {
        throw StateError('Server market data is unavailable');
      }
      if (policy != null && generation == _cacheGeneration) {
        final output = data['output'];
        final tickers = data['tickers'];
        final rawPrice = output is Map
            ? output['stck_prpr'] ?? output['last']
            : tickers is List && tickers.isNotEmpty && tickers.first is Map
            ? tickers.first['last']
            : null;
        final price = _parseNumber(rawPrice);
        if (price != null && price.isFinite && price > 0) {
          final entry = {...data, '_receivedAt': DateTime.now()};
          _quotes.remove(identity);
          if (_quotes.length >= 128) _quotes.remove(_quotes.keys.first);
          return _quotes[identity] = entry;
        }
      }
      return data;
    });
  }

  Future<Map<String, dynamic>> _kisGet({
    required String path,
    required String trId,
    required Map<String, String> query,
    bool allowNoData = false,
  }) async {
    final uri = Uri.parse(
      '${_config.kisBaseUrl}$path',
    ).replace(queryParameters: query);
    return _shareMarketRead(
      uri,
      () => _loadKisData(uri, trId, allowNoData),
      trId: trId,
      allowNoData: allowNoData,
    );
  }

  Future<Map<String, dynamic>> _loadKisData(
    Uri uri,
    String trId,
    bool allowNoData,
  ) async {
    Future<Response<String>> requestWithToken(String accessToken) async {
      for (var attempt = 0; ; attempt++) {
        final response = await _request(
          uri,
          options: Options(
            headers: {
              'content-type': 'application/json; charset=utf-8',
              'authorization': 'Bearer $accessToken',
              'appkey': _config.kisAppKey,
              'appsecret': _config.kisAppSecret,
              'tr_id': trId,
              'custtype': 'P',
            },
          ),
        );
        if (response.statusCode != 429 &&
            !(response.data ?? '').contains('"EGW00201"')) {
          return response;
        }
        if (attempt == 2) {
          throw StateError('KIS quote rate limit exceeded');
        }
        _log('KIS quote rate limited. Retrying with the same token.');
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }

    var token = await _issueKisAccessToken();
    _log('KIS request GET $uri tr_id=$trId');
    var response = await requestWithToken(token);
    _log(
      'KIS response status=${response.statusCode} tr_id=$trId path=${uri.path}',
    );

    if (response.statusCode! < 200 || response.statusCode! >= 300) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        _log('KIS auth appears stale. Clearing token cache and retrying once.');
        await _clearPersistedKisAccessToken();
        token = await _issueKisAccessToken();
        response = await requestWithToken(token);
        _log(
          'KIS retry response status=${response.statusCode} '
          'tr_id=$trId path=${uri.path}',
        );
      }
    }

    if (response.statusCode! < 200 || response.statusCode! >= 300) {
      _log('KIS request failed body=${_truncate(response.data ?? '')}');
      throw Exception('KIS request failed: ${response.statusCode}');
    }

    var json = jsonDecode(response.data ?? '') as Map<String, dynamic>;
    if (!_isKisSuccess(json)) {
      _log(
        'KIS business error rt_cd=${json['rt_cd']} '
        'msg_cd=${json['msg_cd']} msg1=${json['msg1']}',
      );
      if (_isKisAuthError(json)) {
        _log(
          'KIS business auth error. Clearing token cache and retrying once.',
        );
        await _clearPersistedKisAccessToken();
        token = await _issueKisAccessToken();
        response = await requestWithToken(token);
        _log(
          'KIS business retry response status=${response.statusCode} '
          'tr_id=$trId path=${uri.path}',
        );
        if (response.statusCode! < 200 || response.statusCode! >= 300) {
          _log('KIS retry failed body=${_truncate(response.data ?? '')}');
          throw Exception('KIS request failed: ${response.statusCode}');
        }
        json = jsonDecode(response.data ?? '') as Map<String, dynamic>;
      }
      if (!_isKisSuccess(json)) {
        final message = json['msg1']?.toString() ?? '';
        if (allowNoData && _kisNoDailyPrices.hasMatch(message)) {
          return const {'output2': []};
        }
        throw Exception(
          'KIS business failed: rt_cd=${json['rt_cd']} msg_cd=${json['msg_cd']}',
        );
      }
    }

    _log('KIS response body=${_truncate(response.data ?? '')}');
    return json;
  }

  Future<String> _issueKisAccessToken() async {
    await _restoreKisAccessTokenIfNeeded();

    final now = DateTime.now();
    final accessToken = _accessToken;
    final expiresAt = _accessTokenExpiresAt;
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        expiresAt != null &&
        now.isBefore(expiresAt.subtract(const Duration(minutes: 1)))) {
      _log('KIS access token cache hit expiresAt=$expiresAt');
      return _accessToken!;
    }

    final retryAvailableAt = _kisTokenRetryAvailableAt;
    if (retryAvailableAt != null && now.isBefore(retryAvailableAt)) {
      _log('KIS token cooldown active until=$retryAvailableAt');
      throw Exception('KIS auth cooldown active');
    }

    final inFlight = _accessTokenFuture;
    if (inFlight != null) {
      _log('KIS token request join in-flight');
      return inFlight;
    }

    final future = _requestKisAccessToken();
    _accessTokenFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_accessTokenFuture, future)) {
        _accessTokenFuture = null;
      }
    }
  }

  Future<String> _requestKisAccessToken() async {
    _log('KIS token request POST ${_config.kisBaseUrl}/oauth2/tokenP');

    final response = await _request(
      Uri.parse('${_config.kisBaseUrl}/oauth2/tokenP'),
      options: Options(
        method: 'POST',
        contentType: 'application/json; charset=utf-8',
      ),
      data: {
        'grant_type': 'client_credentials',
        'appkey': _config.kisAppKey,
        'appsecret': _config.kisAppSecret,
      },
    );
    _log('KIS token response status=${response.statusCode}');

    if (response.statusCode! < 200 || response.statusCode! >= 300) {
      _log('KIS token request failed body=${_truncate(response.data ?? '')}');
      try {
        final json = jsonDecode(response.data ?? '') as Map<String, dynamic>;
        if (json['error_code']?.toString() == 'EGW00133') {
          _kisTokenRetryAvailableAt = DateTime.now().add(
            const Duration(minutes: 1),
          );
        }
      } catch (_) {}
      throw Exception('KIS auth failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.data ?? '') as Map<String, dynamic>;
    _kisTokenRetryAvailableAt = null;
    _accessToken = json['access_token'] as String?;
    if (_accessToken == null || _accessToken!.isEmpty) {
      _log('KIS token missing body=${_truncate(response.data ?? '')}');
      throw Exception('KIS access token missing');
    }
    _accessTokenExpiresAt = _resolveKisTokenExpiry(json);
    await _persistKisAccessToken(_accessToken!, _accessTokenExpiresAt);
    _log(
      'KIS token issued expires=${json['access_token_token_expired'] ?? '-'} '
      'parsed=$_accessTokenExpiresAt',
    );
    return _accessToken!;
  }

  Future<void> _restoreKisAccessTokenIfNeeded() async {
    if (_accessToken != null && _accessTokenExpiresAt != null) return;

    final inFlight = _accessTokenRestoreFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _restoreKisAccessToken();
    _accessTokenRestoreFuture = future;
    try {
      await future;
    } finally {
      if (identical(_accessTokenRestoreFuture, future)) {
        _accessTokenRestoreFuture = null;
      }
    }
  }

  Future<void> _restoreKisAccessToken() async {
    if (!_persistKisTokenStorage) return;

    final storedToken = await _readSecureStorageValue(
      _kisAccessTokenStorageKey,
    );
    final storedExpiry = await _readSecureStorageValue(
      _kisAccessTokenExpiryStorageKey,
    );
    final parsedExpiry = DateTime.tryParse(storedExpiry ?? '')?.toLocal();

    if (storedToken == null || storedToken.isEmpty || parsedExpiry == null) {
      await _clearPersistedKisAccessToken();
      return;
    }

    if (DateTime.now().isAfter(
      parsedExpiry.subtract(const Duration(minutes: 1)),
    )) {
      await _clearPersistedKisAccessToken();
      return;
    }

    _accessToken = storedToken;
    _accessTokenExpiresAt = parsedExpiry;
    _log('KIS access token restored expiresAt=$parsedExpiry');
  }

  Future<void> _persistKisAccessToken(String token, DateTime? expiresAt) async {
    if (!_persistKisTokenStorage) return;

    await _writeSecureStorageValue(_kisAccessTokenStorageKey, token);
    if (expiresAt == null) {
      await _deleteSecureStorageValue(_kisAccessTokenExpiryStorageKey);
      return;
    }
    await _writeSecureStorageValue(
      _kisAccessTokenExpiryStorageKey,
      expiresAt.toIso8601String(),
    );
  }

  Future<void> _clearPersistedKisAccessToken() async {
    _accessToken = null;
    _accessTokenExpiresAt = null;
    if (!_persistKisTokenStorage) return;

    await _deleteSecureStorageValue(_kisAccessTokenStorageKey);
    await _deleteSecureStorageValue(_kisAccessTokenExpiryStorageKey);
  }

  Future<String?> _readSecureStorageValue(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (error, stackTrace) {
      _log('Secure storage read failed key=$key error=$error');
      _logStack(stackTrace);
      return null;
    }
  }

  Future<void> _writeSecureStorageValue(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (error, stackTrace) {
      _log('Secure storage write failed key=$key error=$error');
      _logStack(stackTrace);
    }
  }

  Future<void> _deleteSecureStorageValue(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (error, stackTrace) {
      _log('Secure storage delete failed key=$key error=$error');
      _logStack(stackTrace);
    }
  }

  Future<void> _persistCurrentPrice(
    HoldingItem holding,
    Object? rawPrice, {
    String? recoveredExchange,
  }) async {
    final price = _parseNumber(rawPrice)?.toDouble();
    if (price == null || !price.isFinite || price <= 0) {
      throw const FormatException('Invalid market price');
    }
    final id = holding.id;
    if (id == null) return; // Lookup previews have no stored holding.
    final saved = await AppDatabase.instance.updateHoldingCurrentPrice(
      id,
      price,
      recoveredExchange: recoveredExchange,
      expectedSymbol: holding.symbol,
      expectedCurrency: holding.currencyCode,
      expectedClientId: holding.clientId,
      expectedExchange: holding.exchangeCode,
    );
    if (!saved) throw StateError('Holding changed before quote was saved');
  }

  void _log(String message) {
    debugPrint('[MarketDataService] $message');
  }

  void _logStack(StackTrace stackTrace) {
    final lines = stackTrace.toString().trim().split('\n').take(5);
    for (final line in lines) {
      _log(line);
    }
  }

  String _truncate(String text, {int maxLength = 400}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  bool _isKisSuccess(Map<String, dynamic> json) {
    final rtCd = json['rt_cd']?.toString().trim();
    if (rtCd == null || rtCd.isEmpty) return true;
    return rtCd == '0' || rtCd == '0000';
  }

  bool _isKisAuthError(Map<String, dynamic> json) {
    final msgCd = json['msg_cd']?.toString().toUpperCase() ?? '';
    final msg = json['msg1']?.toString().toLowerCase() ?? '';
    if (msgCd.startsWith('EGW')) return true;
    return msg.contains('token') ||
        msg.contains('auth') ||
        msg.contains('appkey') ||
        msg.contains('appsecret');
  }

  DateTime? _resolveKisTokenExpiry(Map<String, dynamic> json) {
    final explicitExpiry = _parseKisTokenExpiry(
      json['access_token_token_expired'],
    );
    if (explicitExpiry != null) return explicitExpiry;

    final expiresInSeconds = _parseNumber(json['expires_in'])?.toInt();
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      return DateTime.now().add(Duration(seconds: expiresInSeconds));
    }

    // Keep a conservative fallback so parse failures do not force re-issuance.
    return DateTime.now().add(const Duration(hours: 23, minutes: 55));
  }

  DateTime? _parseKisTokenExpiry(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;

    final isoParsed = DateTime.tryParse(text);
    if (isoParsed != null) return isoParsed.toLocal();

    final normalized = text.replaceFirst(' ', 'T');
    final normalizedParsed = DateTime.tryParse(normalized);
    if (normalizedParsed != null) return normalizedParsed.toLocal();

    final match = RegExp(
      r'^(\d{4})[-/](\d{2})[-/](\d{2})[ T](\d{2}):(\d{2}):(\d{2})$',
    ).firstMatch(text);
    if (match == null) return null;

    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }

  double? _extractUsdKrwRate(Map<String, dynamic> json) {
    final country = json['country'];
    if (country is List && country.length >= 2) {
      final krw = country[1];
      if (krw is Map && krw['value'] != null) {
        return _parseNumber(krw['value'])?.toDouble();
      }
    }

    final rates = json['rates'];
    if (rates is Map && rates['KRW'] != null) {
      return _parseNumber(rates['KRW'])?.toDouble();
    }

    final conversionRates = json['conversion_rates'];
    if (conversionRates is Map && conversionRates['KRW'] != null) {
      return _parseNumber(conversionRates['KRW'])?.toDouble();
    }

    final quotes = json['quotes'];
    if (quotes is Map && quotes['USDKRW'] != null) {
      return _parseNumber(quotes['USDKRW'])?.toDouble();
    }

    final result = json['result'];
    if (result is num) {
      return result.toDouble();
    }

    return null;
  }
}

class _MarketApiConfig {
  _MarketApiConfig({
    this.kisBaseUrl = const String.fromEnvironment(
      'KIS_BASE_URL',
      defaultValue: 'https://openapi.koreainvestment.com:9443',
    ),
    this.kisAppKey = '',
    this.kisAppSecret = '',
    this.kisStockQuotePath = const String.fromEnvironment(
      'KIS_STOCK_QUOTE_PATH',
      defaultValue: '/uapi/domestic-stock/v1/quotations/inquire-price',
    ),
    this.kisStockQuoteTrId = const String.fromEnvironment(
      'KIS_STOCK_QUOTE_TR_ID',
      defaultValue: 'FHKST01010100',
    ),
    this.kisOverseasStockQuotePath = const String.fromEnvironment(
      'KIS_OVERSEAS_STOCK_QUOTE_PATH',
      defaultValue: '/uapi/overseas-price/v1/quotations/price-detail',
    ),
    this.kisOverseasStockQuoteTrId = const String.fromEnvironment(
      'KIS_OVERSEAS_STOCK_QUOTE_TR_ID',
      defaultValue: 'HHDFS76200200',
    ),
    this.kisFundQuotePath = const String.fromEnvironment(
      'KIS_FUND_QUOTE_PATH',
      defaultValue: '/uapi/etfetn/v1/quotations/inquire-price',
    ),
    this.kisFundQuoteTrId = const String.fromEnvironment(
      'KIS_FUND_QUOTE_TR_ID',
      defaultValue: 'FHPST02400000',
    ),
    this.kisFundComponentsPath = const String.fromEnvironment(
      'KIS_FUND_COMPONENTS_PATH',
      defaultValue: '/uapi/etfetn/v1/quotations/inquire-component-stock-price',
    ),
    this.kisFundComponentsTrId = const String.fromEnvironment(
      'KIS_FUND_COMPONENTS_TR_ID',
      defaultValue: 'FHKST121600C0',
    ),
    this.kisFundComponentsScrDivCode = const String.fromEnvironment(
      'KIS_FUND_COMPONENTS_SCR_DIV_CODE',
      defaultValue: '11216',
    ),
    this.coinTickerUrlTemplate = '',
    this.usdKrwRateUrl = const String.fromEnvironment(
      'USD_KRW_RATE_URL',
      defaultValue:
          'https://m.search.naver.com/p/csearch/content/qapirender.nhn?key=calculator&pkid=141&q=%ED%99%98%EC%9C%A8&where=m&u1=keb&u6=standardUnit&u7=0&u3=USD&u4=KRW&u8=down&u2=1',
    ),
  }) {
    debugPrint(
      '[MarketDataService] KIS config '
      'appKeySet=${kisAppKey.isNotEmpty} '
      'appSecretSet=${kisAppSecret.isNotEmpty}',
    );
  }

  final String kisBaseUrl;
  final String kisAppKey;
  final String kisAppSecret;
  final String kisStockQuotePath;
  final String kisStockQuoteTrId;
  final String kisOverseasStockQuotePath;
  final String kisOverseasStockQuoteTrId;
  final String kisFundQuotePath;
  final String kisFundQuoteTrId;
  final String kisFundComponentsPath;
  final String kisFundComponentsTrId;
  final String kisFundComponentsScrDivCode;
  final String coinTickerUrlTemplate;
  final String usdKrwRateUrl;

  bool get hasKisStockConfig => kisAppKey.isNotEmpty && kisAppSecret.isNotEmpty;
  bool get hasKisOverseasStockConfig =>
      hasKisStockConfig &&
      kisOverseasStockQuotePath.isNotEmpty &&
      kisOverseasStockQuoteTrId.isNotEmpty;
  bool get hasKisFundConfig =>
      hasKisStockConfig &&
      kisFundQuotePath.isNotEmpty &&
      kisFundQuoteTrId.isNotEmpty;
}

String _stringOrDash(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? '-' : text;
}

String _formatRaw(Object? value) => _stringOrDash(value);

num? _parseNumber(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return num.tryParse(raw.replaceAll(',', ''));
}

final _kisNoDailyPrices = RegExp(r'(조회|해당).*(자료|데이터|내역).*(없|존재하지)');

String _kisDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}'
    '${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';

DateTime? _parseKisDateKey(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.length != 8) return null;
  final date = DateTime.tryParse('${raw}T00:00:00Z');
  return date != null && _kisDateKey(date) == raw ? date : null;
}

bool _usSummerTime(DateTime utc) {
  DateTime firstSunday(int month) {
    final first = DateTime.utc(utc.year, month);
    return first.add(Duration(days: (DateTime.sunday - first.weekday) % 7));
  }

  final start = firstSunday(3).add(const Duration(days: 7, hours: 7));
  final end = firstSunday(11).add(const Duration(hours: 6));
  return !utc.isBefore(start) && utc.isBefore(end);
}

String _marketNameForExchange(String exchangeCode) {
  switch (exchangeCode) {
    case 'NAS':
      return 'NASDAQ';
    case 'NYS':
      return 'NYSE';
    case 'AMS':
      return 'AMEX';
    default:
      return exchangeCode;
  }
}

String _formatNumber(Object? value) {
  final number = _parseNumber(value);
  if (number == null) return '-';
  final digits = number.abs().toStringAsFixed(2).endsWith('.00') ? 0 : 2;
  return "${number.isNegative ? '-' : ''}${formatCurrency(number.abs(), fractionDigits: digits)}";
}

String _formatPercent(Object? value) {
  final number = _parseNumber(value);
  if (number == null) return '-';
  return '${number.toStringAsFixed(2)}%';
}

String _formatSignedPercent(Object? value, {Object? sign}) {
  final number = _parseNumber(value);
  if (number == null) return '-';
  final prefix = _signedPrefix(sign, number);
  return '$prefix${number.abs().toStringAsFixed(2)}%';
}

String _formatMoney(Object? value, {required String currencyCode}) {
  final number = _parseNumber(value);
  if (number == null) return '-';
  final rounded = number % 1 == 0
      ? number.toInt().toString()
      : number.toStringAsFixed(2);
  return currencyCode == 'USD' ? '\$$rounded' : _formatKrw(number);
}

String _formatSignedMoney(
  Object? value, {
  required String currencyCode,
  Object? sign,
}) {
  final number = _parseNumber(value);
  if (number == null) return '-';
  final prefix = _signedPrefix(sign, number);
  return '$prefix${_formatMoney(number.abs(), currencyCode: currencyCode)}';
}

String _formatKrw(Object? value) {
  final number = _parseNumber(value);
  if (number == null) return '-';
  final rounded = number.round();
  final prefix = rounded < 0 ? '-₩' : '₩';
  return '$prefix${formatCurrency(rounded.abs())}';
}

String _formatSignedKrw(Object? value, {Object? sign}) {
  final number = _parseNumber(value);
  if (number == null) return '-';
  return '${_signedPrefix(sign, number)}${_formatKrw(number.abs())}';
}

String _signedPrefix(Object? sign, num number) {
  final signText = sign?.toString() ?? '';
  // KIS sign codes:
  // 1/2 = 상승(상한/상승), 3 = 보합, 4/5 = 하락(하한/하락)
  if (signText == '4' || signText == '5' || signText == '-') return '-';
  if (signText == '1' || signText == '2' || signText == '+') return '+';
  if (signText == '3' || signText == '0') return '';
  if (number < 0) return '-';
  if (number > 0) return '+';
  return '';
}

String _formatDate(Object? value) {
  final text = value?.toString() ?? '';
  if (text.length != 8) return _stringOrDash(value);
  return '${text.substring(0, 4)}-${text.substring(4, 6)}-${text.substring(6, 8)}';
}
