import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';

part 'company_news_summary_service.g.dart';

class CompanyNewsSummaryService {
  CompanyNewsSummaryService._();

  static final CompanyNewsSummaryService instance =
      CompanyNewsSummaryService._();
  static const Duration _cacheFreshnessWindow = Duration(hours: 6);

  Future<List<CompanyNewsSummaryItem>>? _inFlightFetch;

  Future<CompanyNewsSummaryItem?> fetchSummaryForSymbol(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final normalizedSymbol = symbol.trim().toUpperCase();
    if (normalizedSymbol.isEmpty) {
      return null;
    }

    final items = await fetchUserSummaries(forceRefresh: forceRefresh);
    for (final item in items) {
      if (item.symbol.trim().toUpperCase() == normalizedSymbol) {
        return item;
      }
    }
    return null;
  }

  Future<List<CompanyNewsSummaryItem>> fetchUserSummaries({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _inFlightFetch != null) {
      return _inFlightFetch!;
    }

    if (!forceRefresh) {
      final cached = await fetchCachedUserSummaries();
      if (cached.isNotEmpty &&
          _areFreshCachedSummaries(cached, DateTime.now())) {
        return cached;
      }
    }

    final future = _fetchUserSummariesFromRemote(forceRefresh: forceRefresh);
    if (!forceRefresh) {
      _inFlightFetch = future;
    }

    try {
      return await future;
    } finally {
      if (identical(_inFlightFetch, future)) {
        _inFlightFetch = null;
      }
    }
  }

  Future<List<CompanyNewsSummaryItem>> _fetchUserSummariesFromRemote({
    required bool forceRefresh,
  }) async {
    if (!await AuthService.ensureInitialized()) {
      debugPrint('[company-news-summary] skipped: auth not initialized');
      return _fetchCachedOrFallbackUserSummaries();
    }

    try {
      final response = await AuthService.client.functions.invoke(
        'get-user-company-news-summaries',
      );

      debugPrint(
        '[company-news-summary] response status=${response.status} data=${response.data}',
      );

      if (response.status != 200 || response.data is! Map) {
        return await _fetchCachedOrFallbackUserSummaries();
      }

      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true || payload['items'] is! List) {
        return await _fetchCachedOrFallbackUserSummaries();
      }

      final items = (payload['items'] as List)
          .whereType<Map>()
          .map(
            (row) => CompanyNewsSummaryItem.fromJson(
              row.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .where((item) => item.found && item.summary != null)
          .where((item) => item.hasKnownAssetType)
          .toList(growable: false);
      await AppDatabase.instance.replaceCompanyNewsCaches(
        items.map((item) => item.toJson()).toList(growable: false),
      );
      return items;
    } catch (error, stackTrace) {
      debugPrint('[company-news-summary] failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      return _fetchCachedOrFallbackUserSummaries();
    }
  }

  Future<List<CompanyNewsSummaryItem>>
  _fetchCachedOrFallbackUserSummaries() async {
    final cached = await fetchCachedUserSummaries();
    if (cached.isNotEmpty) {
      return cached;
    }

    final symbolAssetTypeMap = await AppDatabase.instance
        .fetchVisibleHoldingSymbolAssetTypes();
    return _buildLocalFallbackSummaries(symbolAssetTypeMap);
  }

  Future<List<CompanyNewsSummaryItem>> fetchCachedUserSummaries() async {
    final rows = await AppDatabase.instance.fetchCompanyNewsCaches();
    if (rows.isEmpty) return const [];

    final symbolAssetTypeMap = await AppDatabase.instance
        .fetchVisibleHoldingSymbolAssetTypes();

    return rows
        .map((row) {
          final mutable = Map<String, dynamic>.from(row);
          final symbol = '${mutable['symbol'] ?? ''}'.trim().toUpperCase();
          mutable['asset_type'] = symbolAssetTypeMap[symbol];
          return CompanyNewsSummaryItem.fromJson(mutable);
        })
        .where((item) => item.found && item.summary != null)
        .where((item) => item.hasKnownAssetType)
        .toList(growable: false);
  }

  @visibleForTesting
  static List<CompanyNewsSummaryItem> buildFallbackSummariesForTesting(
    Map<String, String> symbolAssetTypeMap,
  ) {
    return _buildLocalFallbackSummaries(symbolAssetTypeMap);
  }

  @visibleForTesting
  static bool areFreshCachedSummariesForTesting(
    List<CompanyNewsSummaryItem> items,
    DateTime now,
  ) {
    return _areFreshCachedSummaries(items, now);
  }
}

bool _areFreshCachedSummaries(
  List<CompanyNewsSummaryItem> items,
  DateTime now,
) {
  if (items.isEmpty) {
    return false;
  }

  return items.every((item) {
    final cachedAt = _parseIsoDateTime(item.cachedAt);
    if (cachedAt == null) {
      return false;
    }

    final age = now.difference(cachedAt);
    return !age.isNegative &&
        age <= CompanyNewsSummaryService._cacheFreshnessWindow;
  });
}

DateTime? _parseIsoDateTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

List<CompanyNewsSummaryItem> _buildLocalFallbackSummaries(
  Map<String, String> symbolAssetTypeMap,
) {
  if (symbolAssetTypeMap.isEmpty) {
    return const [];
  }

  final now = DateTime.now().toUtc().toIso8601String();
  final summaryDate = now.split('T').first;
  final symbols = symbolAssetTypeMap.keys.toList(growable: false)..sort();
  return symbols
      .where((symbol) {
        final assetType = symbolAssetTypeMap[symbol];
        return assetType == '주식' || assetType == '코인';
      })
      .take(5)
      .map((symbol) {
        final assetType = symbolAssetTypeMap[symbol]!;
        final targetLabel = assetType == '코인' ? '거래소 공지와 시세' : '공시와 뉴스';
        return CompanyNewsSummaryItem(
          symbol: symbol,
          found: true,
          assetType: assetType,
          summaryDate: summaryDate,
          model: 'fallback-local',
          newsCount: 0,
          createdAt: now,
          updatedAt: now,
          summary: {
            'company_summary':
                '외부 종목 뉴스 API가 일시적으로 응답하지 않아 $symbol의 최신 요약 대신 기본 점검 안내를 표시합니다.',
            'issues': [
              {
                'title': '뉴스 요약 지연',
                'summary':
                    'Finnhub 또는 OpenAI 응답을 받을 수 없어 $targetLabel를 별도로 확인한 뒤 판단하세요.',
                'importance': '2',
              },
            ],
            'outlook': {
              'business_impact': '외부 뉴스 수집이 회복되기 전까지 단기 이슈 반영이 제한됩니다.',
              'market_view': '가격 변동, 거래량, 공식 공지의 동시 확인이 필요합니다.',
              'watchpoint': '$symbol 관련 최신 공시, 거래소 공지, 급격한 가격 변동',
            },
          },
        );
      })
      .toList(growable: false);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CompanyNewsSummaryItem {
  const CompanyNewsSummaryItem({
    required this.symbol,
    required this.found,
    this.assetType,
    this.summaryDate,
    this.model,
    this.newsCount,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
    this.summary,
  });

  factory CompanyNewsSummaryItem.fromJson(Map<String, dynamic> json) =>
      _$CompanyNewsSummaryItemFromJson(json);

  @JsonKey(fromJson: _symbol)
  final String symbol;
  @JsonKey(fromJson: _found)
  final bool found;
  @JsonKey(fromJson: _text)
  final String? assetType;
  @JsonKey(fromJson: _text)
  final String? summaryDate;
  @JsonKey(fromJson: _text)
  final String? model;
  @JsonKey(fromJson: _count)
  final int? newsCount;
  @JsonKey(fromJson: _text)
  final String? createdAt;
  @JsonKey(fromJson: _text)
  final String? updatedAt;
  @JsonKey(fromJson: _text)
  final String? cachedAt;
  @JsonKey(fromJson: _summary)
  final Map<String, dynamic>? summary;

  bool get hasKnownAssetType => assetType == '주식' || assetType == '코인';

  Map<String, dynamic> toJson() => _$CompanyNewsSummaryItemToJson(this);

  static String _symbol(Object? value) => value?.toString() ?? '';
  static bool _found(Object? value) => value == true;
  static String? _text(Object? value) => value?.toString();
  static int? _count(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value');
  static Map<String, dynamic>? _summary(Object? value) =>
      value is Map ? value.map((key, item) => MapEntry('$key', item)) : null;
}
