import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:moneyfy/db/app_database.dart';

class BenchmarkPriceService {
  BenchmarkPriceService._({
    http.Client? client,
    AppDatabase? database,
    _BenchmarkApiConfig? config,
  }) : _client = client ?? http.Client(),
       _database = database ?? AppDatabase.instance,
       _config = config ?? _BenchmarkApiConfig();

  @visibleForTesting
  factory BenchmarkPriceService.test({
    required http.Client client,
    required AppDatabase database,
    String yahooChartBaseUrl = 'https://query2.finance.yahoo.com',
  }) {
    return BenchmarkPriceService._(
      client: client,
      database: database,
      config: _BenchmarkApiConfig(yahooChartBaseUrl: yahooChartBaseUrl),
    );
  }

  static final BenchmarkPriceService instance = BenchmarkPriceService._();
  static const String usTBill13WeekCode = 'US_13W_TBILL';

  final http.Client _client;
  final AppDatabase _database;
  final _BenchmarkApiConfig _config;

  Future<int> ensureBenchmarkPrices({
    required String benchmarkCode,
    required String from,
    required String to,
  }) async {
    final normalizedFrom = _normalizeDateKey(from);
    final normalizedTo = _normalizeDateKey(to);
    if (normalizedFrom == null || normalizedTo == null) return 0;
    if (normalizedFrom.compareTo(normalizedTo) > 0) return 0;

    final cached = await _database.fetchBenchmarkPrices(
      benchmarkCode: benchmarkCode,
      from: normalizedFrom,
      to: normalizedTo,
    );
    if (_hasBoundaryPrices(cached)) return 0;

    final provider = _providerFor(benchmarkCode);
    if (provider == null) return 0;

    final fetchFrom = _dateKey(
      DateTime.parse(normalizedFrom).subtract(const Duration(days: 10)),
    );
    final prices = await _fetchYahooChartPrices(
      provider: provider,
      from: fetchFrom,
      to: normalizedTo,
    );
    var saved = 0;
    for (final price in prices) {
      await _database.saveBenchmarkPrice(
        benchmarkCode: benchmarkCode,
        priceDate: price.priceDate,
        closePrice: price.closePrice,
        currencyCode: provider.currencyCode,
        source: provider.source,
      );
      saved += 1;
    }
    return saved;
  }

  Future<int> ensureRiskFreeRates({
    required String from,
    required String to,
  }) async {
    final normalizedFrom = _normalizeDateKey(from);
    final normalizedTo = _normalizeDateKey(to);
    if (normalizedFrom == null || normalizedTo == null) return 0;
    if (normalizedFrom.compareTo(normalizedTo) > 0) return 0;

    final cached = await _database.fetchBenchmarkPrices(
      benchmarkCode: usTBill13WeekCode,
      from: normalizedFrom,
      to: normalizedTo,
    );
    if (_hasRecentRiskFreePrice(cached, normalizedTo)) return 0;

    return ensureBenchmarkPrices(
      benchmarkCode: usTBill13WeekCode,
      from: normalizedFrom,
      to: normalizedTo,
    );
  }

  Future<BenchmarkRiskFreeRate?> fetchLatestRiskFreeRate({
    required String to,
  }) async {
    final normalizedTo = _normalizeDateKey(to);
    if (normalizedTo == null) return null;

    final prices = await _database.fetchBenchmarkPrices(
      benchmarkCode: usTBill13WeekCode,
      to: normalizedTo,
    );
    final usable = prices
        .where((price) => price.closePrice > 0)
        .toList(growable: false);
    if (usable.isEmpty) return null;
    usable.sort((a, b) => a.priceDate.compareTo(b.priceDate));
    final latest = usable.last;
    return BenchmarkRiskFreeRate(
      annualRate: latest.closePrice / 100,
      source: latest.source ?? 'yahoo:^IRX',
      priceDate: latest.priceDate,
    );
  }

  Future<List<_FetchedBenchmarkPrice>> _fetchYahooChartPrices({
    required _BenchmarkProvider provider,
    required String from,
    required String to,
  }) async {
    try {
      final period1 = _unixSeconds(DateTime.parse(from));
      final period2 = _unixSeconds(
        DateTime.parse(to).add(const Duration(days: 1)),
      );
      final base = Uri.parse(_config.yahooChartBaseUrl);
      final uri = base.replace(
        pathSegments: ['v8', 'finance', 'chart', provider.providerSymbol],
        queryParameters: {
          'period1': period1.toString(),
          'period2': period2.toString(),
          'interval': '1d',
          'events': 'history',
        },
      );
      final response = await _client.get(
        uri,
        headers: const {'user-agent': 'Mozilla/5.0'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      return _parseYahooChartJson(response.body);
    } catch (error) {
      debugPrint('[BenchmarkPriceService] fetch failed: $error');
      return const [];
    }
  }

  List<_FetchedBenchmarkPrice> _parseYahooChartJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final chart = decoded['chart'];
    if (chart is! Map<String, dynamic>) return const [];
    final result = chart['result'];
    if (result is! List || result.isEmpty || result.first is! Map) {
      return const [];
    }
    final firstResult = result.first as Map;
    final timestamps = firstResult['timestamp'];
    final indicators = firstResult['indicators'];
    if (timestamps is! List || indicators is! Map) return const [];
    final quote = indicators['quote'];
    if (quote is! List || quote.isEmpty || quote.first is! Map) {
      return const [];
    }
    final closes = (quote.first as Map)['close'];
    if (closes is! List) return const [];

    final prices = <_FetchedBenchmarkPrice>[];
    final count = timestamps.length < closes.length
        ? timestamps.length
        : closes.length;
    for (var index = 0; index < count; index += 1) {
      final timestamp = timestamps[index];
      final close = closes[index];
      if (timestamp is! num || close is! num || close <= 0) continue;
      final date = _dateKey(
        DateTime.fromMillisecondsSinceEpoch(
          timestamp.toInt() * 1000,
          isUtc: true,
        ),
      );
      prices.add(
        _FetchedBenchmarkPrice(priceDate: date, closePrice: close.toDouble()),
      );
    }
    return prices;
  }

  bool _hasBoundaryPrices(List<BenchmarkPrice> prices) {
    final usable = prices
        .where((price) => price.closePrice > 0)
        .toList(growable: false);
    if (usable.length < 2) return false;
    usable.sort((a, b) => a.priceDate.compareTo(b.priceDate));
    return usable.first.priceDate != usable.last.priceDate;
  }

  bool _hasRecentRiskFreePrice(List<BenchmarkPrice> prices, String to) {
    final normalizedTo = DateTime.parse(to);
    final minimumDate = _dateKey(
      normalizedTo.subtract(const Duration(days: 10)),
    );
    return prices.any(
      (price) =>
          price.closePrice > 0 && price.priceDate.compareTo(minimumDate) >= 0,
    );
  }

  _BenchmarkProvider? _providerFor(String benchmarkCode) {
    switch (benchmarkCode.trim().toUpperCase()) {
      case 'SP500':
        return const _BenchmarkProvider(
          providerSymbol: '^GSPC',
          currencyCode: 'POINTS',
          source: 'yahoo',
        );
      case BenchmarkPriceService.usTBill13WeekCode:
        return const _BenchmarkProvider(
          providerSymbol: '^IRX',
          currencyCode: 'PERCENT',
          source: 'yahoo:^IRX',
        );
      default:
        return null;
    }
  }
}

class BenchmarkRiskFreeRate {
  const BenchmarkRiskFreeRate({
    required this.annualRate,
    required this.source,
    required this.priceDate,
  });

  final double annualRate;
  final String source;
  final String priceDate;
}

class _BenchmarkApiConfig {
  const _BenchmarkApiConfig({
    this.yahooChartBaseUrl = const String.fromEnvironment(
      'YAHOO_CHART_BASE_URL',
      defaultValue: 'https://query2.finance.yahoo.com',
    ),
  });

  final String yahooChartBaseUrl;
}

class _BenchmarkProvider {
  const _BenchmarkProvider({
    required this.providerSymbol,
    required this.currencyCode,
    required this.source,
  });

  final String providerSymbol;
  final String currencyCode;
  final String source;
}

class _FetchedBenchmarkPrice {
  const _FetchedBenchmarkPrice({
    required this.priceDate,
    required this.closePrice,
  });

  final String priceDate;
  final double closePrice;
}

String? _normalizeDateKey(String value) {
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) return null;
  return _dateKey(parsed);
}

String _dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

int _unixSeconds(DateTime date) {
  final utc = DateTime.utc(date.year, date.month, date.day);
  return utc.millisecondsSinceEpoch ~/ 1000;
}
