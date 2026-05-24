import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import 'auth_service.dart';

class MarketNewsSummaryService {
  MarketNewsSummaryService._();

  static final MarketNewsSummaryService instance = MarketNewsSummaryService._();
  static const Duration _cacheFreshnessWindow = Duration(hours: 6);

  Future<MarketNewsSummaryResponse?>? _inFlightFetch;

  Future<MarketNewsSummaryResponse?> fetchSummary({
    String category = 'general',
    String? summaryDate,
    bool forceRefresh = false,
  }) async {
    final canShareRequest =
        !forceRefresh && summaryDate == null && category == 'general';
    if (canShareRequest && _inFlightFetch != null) {
      return _inFlightFetch!;
    }

    if (!forceRefresh && summaryDate == null) {
      final cached = await fetchCachedSummary(category: category);
      if (cached != null && _isFreshCachedSummary(cached, DateTime.now())) {
        return cached;
      }
    }

    final future = _fetchSummaryFromRemote(
      category: category,
      summaryDate: summaryDate,
      forceRefresh: forceRefresh,
    );
    if (canShareRequest) {
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

  Future<MarketNewsSummaryResponse?> _fetchSummaryFromRemote({
    required String category,
    required String? summaryDate,
    required bool forceRefresh,
  }) async {
    if (!await AuthService.ensureInitialized()) {
      debugPrint('[market-news-summary] skipped: auth not initialized');
      return _fetchCachedOrFallbackSummary(
        category: category,
        summaryDate: summaryDate,
      );
    }

    try {
      final response = await AuthService.client.functions.invoke(
        'get-market-news-summary',
        body: <String, Object?>{
          'category': category,
          'summary_date': ?summaryDate,
        },
      );

      debugPrint(
        '[market-news-summary] response status=${response.status} data=${response.data}',
      );

      if (response.status != 200 || response.data is! Map) {
        return _fetchCachedOrFallbackSummary(
          category: category,
          summaryDate: summaryDate,
        );
      }

      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true) {
        return _fetchCachedOrFallbackSummary(
          category: category,
          summaryDate: summaryDate,
        );
      }

      final result = MarketNewsSummaryResponse.fromJson(payload);
      if (summaryDate == null) {
        await AppDatabase.instance.saveMarketNewsCache(
          category: result.category,
          found: result.found,
          summaryDate: result.summaryDate,
          model: result.model,
          newsCount: result.newsCount,
          summary: result.summary,
          createdAt: result.createdAt,
          updatedAt: result.updatedAt,
        );
      }
      return result;
    } catch (error, stackTrace) {
      debugPrint('[market-news-summary] failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      return _fetchCachedOrFallbackSummary(
        category: category,
        summaryDate: summaryDate,
      );
    }
  }

  Future<MarketNewsSummaryResponse?> _fetchCachedOrFallbackSummary({
    required String category,
    required String? summaryDate,
  }) async {
    if (summaryDate != null) {
      return null;
    }

    final cached = await fetchCachedSummary(category: category);
    return cached ?? _buildLocalFallbackSummary(category: category);
  }

  Future<MarketNewsSummaryResponse?> fetchCachedSummary({
    String category = 'general',
  }) async {
    final payload = await AppDatabase.instance.fetchMarketNewsCache(
      category: category,
    );
    if (payload == null) return null;
    return MarketNewsSummaryResponse.fromJson(payload);
  }

  @visibleForTesting
  static MarketNewsSummaryResponse buildFallbackSummaryForTesting({
    String category = 'general',
  }) {
    return _buildLocalFallbackSummary(category: category);
  }

  @visibleForTesting
  static bool isFreshCachedSummaryForTesting(
    MarketNewsSummaryResponse summary,
    DateTime now,
  ) {
    return _isFreshCachedSummary(summary, now);
  }
}

bool _isFreshCachedSummary(MarketNewsSummaryResponse summary, DateTime now) {
  final cachedAt = _parseIsoDateTime(summary.cachedAt);
  if (cachedAt == null) {
    return false;
  }

  final age = now.difference(cachedAt);
  return !age.isNegative &&
      age <= MarketNewsSummaryService._cacheFreshnessWindow;
}

DateTime? _parseIsoDateTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

MarketNewsSummaryResponse _buildLocalFallbackSummary({
  required String category,
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return MarketNewsSummaryResponse(
    category: category,
    found: true,
    model: 'fallback-local',
    newsCount: 0,
    summaryDate: now.split('T').first,
    createdAt: now,
    updatedAt: now,
    summary: const {
      'market_summary':
          '외부 시장 뉴스 요약 API가 일시적으로 응답하지 않아 저장된 데이터와 기본 점검 안내를 표시합니다.',
      'issues': [
        {
          'title': '실시간 뉴스 요약 지연',
          'summary':
              'KIS, Finnhub, OpenAI 등 외부 API 응답을 받을 수 없어 최신 뉴스 기반 판단은 보류해야 합니다.',
          'importance': '2',
          'market_impact': {
            'stocks': '개별 종목 뉴스와 지수 흐름을 앱 밖에서도 함께 확인하세요.',
            'bonds_rates': '금리와 환율 변동이 큰 날에는 보수적으로 해석하세요.',
            'fx': 'USD/KRW 환율 캐시가 최신이 아닐 수 있습니다.',
            'crypto': '코인 시세는 최근 체결가와 거래소 공지를 함께 확인하세요.',
          },
        },
      ],
      'overall_assessment': {
        'key_risk': '외부 데이터 지연으로 최신 리스크 반영이 제한됩니다.',
        'risk_assets': '변동성이 큰 주식, 코인',
        'safe_assets': '현금성 자산, 분산된 장기 보유 자산',
      },
    },
  );
}

class MarketNewsSummaryResponse {
  const MarketNewsSummaryResponse({
    required this.category,
    required this.found,
    required this.summary,
    this.model,
    this.newsCount,
    this.summaryDate,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
  });

  factory MarketNewsSummaryResponse.fromJson(Map<String, dynamic> json) {
    return MarketNewsSummaryResponse(
      category: '${json['category'] ?? 'general'}',
      found: json['found'] == true,
      summary: json['summary'] is Map
          ? Map<String, dynamic>.from(
              (json['summary'] as Map).map(
                (key, value) => MapEntry('$key', value),
              ),
            )
          : null,
      model: json['model']?.toString(),
      newsCount: json['news_count'] is num
          ? (json['news_count'] as num).toInt()
          : int.tryParse('${json['news_count'] ?? ''}'),
      summaryDate: json['summary_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      cachedAt: json['cached_at']?.toString(),
    );
  }

  final String category;
  final bool found;
  final Map<String, dynamic>? summary;
  final String? model;
  final int? newsCount;
  final String? summaryDate;
  final String? createdAt;
  final String? updatedAt;
  final String? cachedAt;
}
