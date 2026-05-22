import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import 'auth_service.dart';

class MarketNewsSummaryService {
  MarketNewsSummaryService._();

  static final MarketNewsSummaryService instance = MarketNewsSummaryService._();

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
      if (cached != null) {
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
      return summaryDate == null
          ? fetchCachedSummary(category: category)
          : null;
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
        return null;
      }

      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true) {
        return null;
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
      return summaryDate == null
          ? fetchCachedSummary(category: category)
          : null;
    }
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
}
