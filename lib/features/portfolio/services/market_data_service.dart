import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/models/market_snapshot.dart';

class MarketDataService {
  MarketDataService._({
    http.Client? client,
    _MarketApiConfig? config,
    bool persistKisTokenStorage = true,
  }) : _client = client ?? http.Client(),
       _config = config ?? _MarketApiConfig(),
       _persistKisTokenStorage = persistKisTokenStorage;

  @visibleForTesting
  factory MarketDataService.test({
    required http.Client client,
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
    String kisFundComponentsScrDivCode = '16616',
    String coinTickerUrlTemplate = '',
    String usdKrwRateUrl = '',
  }) {
    return MarketDataService._(
      client: client,
      persistKisTokenStorage: false,
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

  final http.Client _client;
  final _MarketApiConfig _config;
  final bool _persistKisTokenStorage;

  String? _accessToken;
  DateTime? _accessTokenExpiresAt;
  Future<String>? _accessTokenFuture;
  Future<void>? _accessTokenRestoreFuture;
  DateTime? _kisTokenRetryAvailableAt;

  Future<void> refreshAllMarketData() async {
    try {
      await refreshUsdKrwRate();
    } catch (error, stackTrace) {
      _log('FX refresh failed: $error');
      _logStack(stackTrace);
    }

    final assets = await AppDatabase.instance.fetchAssets();
    final holdings = assets
        .expand((asset) => asset.holdings)
        .where(_supportsMarketRefresh)
        .toList(growable: false);
    await _runWithConcurrency(
      holdings,
      concurrency: 4,
      worker: (holding) async {
        await fetchSnapshot(holding);
      },
    );
  }

  Future<void> clearLocalCache() async {
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _accessTokenFuture = null;
    _accessTokenRestoreFuture = null;
    _kisTokenRetryAvailableAt = null;
    await _clearPersistedKisAccessToken();
  }

  Future<void> _runWithConcurrency<T>(
    List<T> items, {
    required int concurrency,
    required Future<void> Function(T item) worker,
  }) async {
    if (items.isEmpty) return;

    final runnerCount = concurrency < 1
        ? 1
        : (concurrency > items.length ? items.length : concurrency);
    var index = 0;

    Future<void> runner() async {
      while (true) {
        if (index >= items.length) return;
        final item = items[index++];
        await worker(item);
      }
    }

    await Future.wait(
      List.generate(runnerCount, (_) => runner(), growable: false),
    );
  }

  Future<double?> refreshUsdKrwRate() async {
    if (_config.usdKrwRateUrl.isEmpty) {
      _log('USD/KRW rate refresh skipped: url missing');
      return null;
    }

    final uri = Uri.parse(_config.usdKrwRateUrl);
    _log('FX request GET $uri');
    final response = await _client.get(uri);
    _log('FX response status=${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('FX request failed body=${_truncate(response.body)}');
      return null;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rate = _extractUsdKrwRate(json);
    if (rate == null) {
      _log('FX response parse failed body=${_truncate(response.body)}');
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

  Future<HoldingMarketSnapshot> fetchSnapshot(
    HoldingItem holding, {
    bool includeFundComponents = true,
  }) async {
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
          return await _fetchStockSnapshot(holding);
        case '펀드':
          return await _fetchFundSnapshot(
            holding,
            includeComponents: includeFundComponents,
          );
        case '코인':
          return await _fetchCoinSnapshot(holding);
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

  bool _supportsMarketRefresh(HoldingItem holding) {
    if (_isCashLikeHolding(holding)) return false;

    switch (holding.assetType ?? holding.assetTitle) {
      case '주식':
      case '펀드':
      case '코인':
        return true;
      default:
        return false;
    }
  }

  bool _isCashLikeHolding(HoldingItem holding) {
    final symbol = holding.symbol.trim().toUpperCase();
    final currencyCode = holding.currencyCode.trim().toUpperCase();
    if (symbol.isEmpty || currencyCode.isEmpty) return false;
    return symbol == currencyCode;
  }

  Future<HoldingMarketSnapshot> _fetchStockSnapshot(HoldingItem holding) async {
    if (holding.currencyCode.toUpperCase() == 'USD') {
      return _fetchOverseasStockSnapshot(holding);
    }

    if (!_config.hasKisStockConfig) {
      _log('fetchSnapshot fallback: KIS stock config missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    if (holding.symbol.isEmpty) {
      _log('fetchSnapshot fallback: stock symbol missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final json = await _kisGet(
      path: _config.kisStockQuotePath,
      trId: _config.kisStockQuoteTrId,
      query: {'FID_COND_MRKT_DIV_CODE': 'J', 'FID_INPUT_ISCD': holding.symbol},
    );
    final output =
        (json['output'] as Map?)?.cast<String, dynamic>() ?? const {};

    final currentPrice = _parseNumber(output['stck_prpr'])?.toDouble();
    final snapshot = HoldingMarketSnapshot(
      marketName: holding.assetTitle ?? '-',
      sectorName: _stringOrDash(output['bstp_kor_isnm']),
      currentPrice: _formatKrw(output['stck_prpr']),
      currentPriceValue: currentPrice,
      dayChange: _formatSignedKrw(
        output['prdy_vrss'],
        sign: output['prdy_vrss_sign'],
      ),
      dayChangeRate: _formatSignedPercent(
        output['prdy_ctrt'],
        sign: output['prdy_vrss_sign'],
      ),
      previousClose: _formatKrw(output['stck_prdy_clpr']),
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
      etfComponentCount: '-',
      etfComponentMarketCap: '-',
      etfNetAssetsTotal: '-',
      etfCuUnitCount: '-',
      etfNavOpen: '-',
      etfNavHigh: '-',
      etfNavLow: '-',
      etfTopComponents: const [],
    );
    await _persistCurrentPrice(holding, output['stck_prpr']);
    return snapshot;
  }

  Future<HoldingMarketSnapshot> _fetchOverseasStockSnapshot(
    HoldingItem holding,
  ) async {
    if (!_config.hasKisOverseasStockConfig) {
      _log('fetchSnapshot fallback: KIS overseas config missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    if (holding.symbol.isEmpty) {
      _log('fetchSnapshot fallback: overseas symbol missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    if (holding.exchangeCode.isEmpty) {
      _log('fetchSnapshot fallback: overseas exchangeCode missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final json = await _kisGet(
      path: _config.kisOverseasStockQuotePath,
      trId: _config.kisOverseasStockQuoteTrId,
      query: {'AUTH': '', 'EXCD': holding.exchangeCode, 'SYMB': holding.symbol},
    );
    final output =
        (json['output'] as Map?)?.cast<String, dynamic>() ?? const {};
    final currentPrice = _parseNumber(output['last'])?.toDouble();
    final previousClose = _parseNumber(output['base']);
    final dayChange = currentPrice != null && previousClose != null
        ? currentPrice - previousClose
        : null;
    final dayChangeRate =
        dayChange != null && previousClose != null && previousClose != 0
        ? (dayChange / previousClose) * 100
        : null;

    final snapshot = HoldingMarketSnapshot(
      marketName: _marketNameForExchange(holding.exchangeCode),
      sectorName: '-',
      currentPrice: _formatMoney(output['last'], currencyCode: 'USD'),
      currentPriceValue: currentPrice,
      dayChange: _formatSignedMoney(dayChange, currencyCode: 'USD'),
      dayChangeRate: _formatSignedPercent(dayChangeRate),
      previousClose: _formatMoney(output['base'], currencyCode: 'USD'),
      openPrice: _formatMoney(output['open'], currencyCode: 'USD'),
      highPrice: _formatMoney(output['high'], currencyCode: 'USD'),
      lowPrice: _formatMoney(output['low'], currencyCode: 'USD'),
      volume: _formatNumber(output['pvol']),
      turnover: _formatMoney(output['pamt'], currencyCode: 'USD'),
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
      etfComponentCount: '-',
      etfComponentMarketCap: '-',
      etfNetAssetsTotal: '-',
      etfCuUnitCount: '-',
      etfNavOpen: '-',
      etfNavHigh: '-',
      etfNavLow: '-',
      etfTopComponents: const [],
    );
    await _persistCurrentPrice(holding, output['last']);
    return snapshot;
  }

  Future<HoldingMarketSnapshot> _fetchFundSnapshot(
    HoldingItem holding, {
    required bool includeComponents,
  }) async {
    if (!_config.hasKisFundConfig) {
      _log('fetchSnapshot fallback: KIS fund config missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    if (holding.symbol.isEmpty) {
      _log('fetchSnapshot fallback: fund symbol missing');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final summaryJson = await _kisGet(
      path: _config.kisFundQuotePath,
      trId: _config.kisFundQuoteTrId,
      query: {'FID_COND_MRKT_DIV_CODE': 'J', 'FID_INPUT_ISCD': holding.symbol},
    );
    final summary =
        (summaryJson['output'] as Map?)?.cast<String, dynamic>() ?? const {};

    List<FundComponentItem> components = const [];
    Map<String, dynamic> componentSummary = const {};
    if (includeComponents &&
        _config.kisFundComponentsPath.isNotEmpty &&
        _config.kisFundComponentsTrId.isNotEmpty) {
      final componentJson = await _kisGet(
        path: _config.kisFundComponentsPath,
        trId: _config.kisFundComponentsTrId,
        query: {
          'FID_COND_MRKT_DIV_CODE': 'J',
          'FID_INPUT_ISCD': holding.symbol,
          'FID_COND_SCR_DIV_CODE': _config.kisFundComponentsScrDivCode,
        },
      );
      componentSummary =
          (componentJson['output1'] as Map?)?.cast<String, dynamic>() ??
          const {};
      final output2 = (componentJson['output2'] as List?) ?? const [];

      components = output2
          .cast<Map>()
          .take(10)
          .map(
            (row) => FundComponentItem(
              code: _stringOrDash(row['stck_shrn_iscd']),
              name: _stringOrDash(row['hts_kor_isnm']),
              price: _formatKrw(row['stck_prpr']),
              changeRate: _formatSignedPercent(
                row['prdy_ctrt'],
                sign: row['prdy_vrss_sign'],
              ),
              weight: _formatPercent(row['etf_cnfg_issu_rlim']),
              valuationAmount: _formatKrw(row['etf_vltn_amt']),
            ),
          )
          .toList();
    }

    final currentPrice = _parseNumber(summary['stck_prpr'])?.toDouble();
    final snapshot = HoldingMarketSnapshot(
      marketName: holding.assetTitle ?? '-',
      sectorName: _stringOrDash(summary['bstp_kor_isnm']),
      currentPrice: _formatKrw(summary['stck_prpr']),
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
      turnover: '-',
      per: '-',
      pbr: '-',
      eps: '-',
      bps: '-',
      week52High: _formatKrw(summary['stck_dryy_hgpr']),
      week52Low: _formatKrw(summary['stck_dryy_lwpr']),
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
      etfComponentCount: _formatNumber(componentSummary['etf_cnfg_issu_cnt']),
      etfComponentMarketCap: _formatKrw(componentSummary['etf_cnfg_issu_avls']),
      etfNetAssetsTotal: _formatKrw(componentSummary['etf_ntas_ttam']),
      etfCuUnitCount: _formatNumber(componentSummary['etf_cu_unit_scrt_cnt']),
      etfNavOpen: _formatKrw(componentSummary['oprc_nav']),
      etfNavHigh: _formatKrw(componentSummary['hprc_nav']),
      etfNavLow: _formatKrw(componentSummary['lprc_nav']),
      etfTopComponents: components,
    );
    await _persistCurrentPrice(holding, summary['stck_prpr']);
    return snapshot;
  }

  Future<HoldingMarketSnapshot> _fetchCoinSnapshot(HoldingItem holding) async {
    if (holding.symbol.isEmpty) {
      return HoldingMarketSnapshot.fallback(holding);
    }

    final symbol = holding.symbol.toUpperCase();
    final quoteCurrency = holding.currencyCode.toUpperCase();
    final url = _config.coinTickerUrlTemplate.isNotEmpty
        ? _config.coinTickerUrlTemplate
              .replaceAll('{symbol}', symbol)
              .replaceAll('{quote}', quoteCurrency)
        : 'https://api.coinone.co.kr/public/v2/ticker_utc_new/'
              '$quoteCurrency/$symbol?additional_data=true';
    _log('Coin request GET $url');
    final response = await _client.get(Uri.parse(url));
    _log('Coin response status=${response.statusCode} symbol=$symbol');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('Coin request failed body=${_truncate(response.body)}');
      return HoldingMarketSnapshot.fallback(holding);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tickers = (json['tickers'] as List?) ?? const [];
    if (tickers.isEmpty) {
      _log(
        'Coin response has no tickers symbol=$symbol body=${_truncate(response.body)}',
      );
      return HoldingMarketSnapshot.fallback(holding);
    }

    final ticker = tickers.first as Map;
    final bestAsks = (ticker['best_asks'] as List?) ?? const [];
    final bestBids = (ticker['best_bids'] as List?) ?? const [];
    final bestAsk = bestAsks.isEmpty ? const {} : bestAsks.first as Map;
    final bestBid = bestBids.isEmpty ? const {} : bestBids.first as Map;

    final currentPrice = _parseNumber(ticker['last'])?.toDouble();
    final snapshot = HoldingMarketSnapshot(
      marketName: holding.assetTitle ?? '-',
      sectorName: '-',
      currentPrice: _formatKrw(ticker['last']),
      currentPriceValue: currentPrice,
      dayChange: '-',
      dayChangeRate: '-',
      previousClose: _formatKrw(ticker['yesterday_last']),
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
      etfComponentCount: '-',
      etfComponentMarketCap: '-',
      etfNetAssetsTotal: '-',
      etfCuUnitCount: '-',
      etfNavOpen: '-',
      etfNavHigh: '-',
      etfNavLow: '-',
      etfTopComponents: const [],
    );
    await _persistCurrentPrice(holding, ticker['last']);
    return snapshot;
  }

  Future<Map<String, dynamic>> _kisGet({
    required String path,
    required String trId,
    required Map<String, String> query,
  }) async {
    final uri = Uri.parse(
      '${_config.kisBaseUrl}$path',
    ).replace(queryParameters: query);
    Future<http.Response> requestWithToken(String accessToken) {
      return _client.get(
        uri,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'authorization': 'Bearer $accessToken',
          'appkey': _config.kisAppKey,
          'appsecret': _config.kisAppSecret,
          'tr_id': trId,
          'custtype': 'P',
        },
      );
    }

    var token = await _issueKisAccessToken();
    _log('KIS request GET $uri tr_id=$trId');
    var response = await requestWithToken(token);
    _log('KIS response status=${response.statusCode} tr_id=$trId path=$path');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        _log('KIS auth appears stale. Clearing token cache and retrying once.');
        await _clearPersistedKisAccessToken();
        token = await _issueKisAccessToken();
        response = await requestWithToken(token);
        _log(
          'KIS retry response status=${response.statusCode} '
          'tr_id=$trId path=$path',
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('KIS request failed body=${_truncate(response.body)}');
      throw Exception('KIS request failed: ${response.statusCode}');
    }

    var json = jsonDecode(response.body) as Map<String, dynamic>;
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
          'tr_id=$trId path=$path',
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          _log('KIS retry failed body=${_truncate(response.body)}');
          throw Exception('KIS request failed: ${response.statusCode}');
        }
        json = jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (!_isKisSuccess(json)) {
        throw Exception(
          'KIS business failed: rt_cd=${json['rt_cd']} msg_cd=${json['msg_cd']}',
        );
      }
    }

    _log('KIS response body=${_truncate(response.body)}');
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

    final response = await _client.post(
      Uri.parse('${_config.kisBaseUrl}/oauth2/tokenP'),
      headers: const {'content-type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'grant_type': 'client_credentials',
        'appkey': _config.kisAppKey,
        'appsecret': _config.kisAppSecret,
      }),
    );
    _log('KIS token response status=${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('KIS token request failed body=${_truncate(response.body)}');
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['error_code']?.toString() == 'EGW00133') {
          _kisTokenRetryAvailableAt = DateTime.now().add(
            const Duration(minutes: 1),
          );
        }
      } catch (_) {}
      throw Exception('KIS auth failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _kisTokenRetryAvailableAt = null;
    _accessToken = json['access_token'] as String?;
    if (_accessToken == null || _accessToken!.isEmpty) {
      _log('KIS token missing body=${_truncate(response.body)}');
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
    Object? rawPrice,
  ) async {
    final holdingId = holding.id;
    final parsedPrice = _parseNumber(rawPrice);
    if (holdingId == null || parsedPrice == null) return;
    _log(
      'Persist current price holdingId=$holdingId '
      'symbol=${holding.symbol} price=${parsedPrice.toDouble()}',
    );
    await AppDatabase.instance.updateHoldingCurrentPrice(
      holdingId,
      parsedPrice.toDouble(),
    );
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
    this.kisAppKey = const String.fromEnvironment('KIS_APP_KEY'),
    this.kisAppSecret = const String.fromEnvironment('KIS_APP_SECRET'),
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
      defaultValue: '16616',
    ),
    this.coinTickerUrlTemplate = const String.fromEnvironment(
      'COIN_TICKER_URL_TEMPLATE',
    ),
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
  final fixed = number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final isNegative = whole.startsWith('-');
  final digits = isNegative ? whole.substring(1) : whole;
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  final formattedWhole = '${isNegative ? '-' : ''}$buffer';
  if (parts.length == 1 || parts[1] == '00') {
    return formattedWhole;
  }
  return '$formattedWhole.${parts[1]}';
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
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  final prefix = rounded < 0 ? '-₩' : '₩';
  return '$prefix$buffer';
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
