import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import 'auth_service.dart';

class CompanyNewsSummaryService {
  CompanyNewsSummaryService._();

  static final CompanyNewsSummaryService instance =
      CompanyNewsSummaryService._();

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
      if (cached.isNotEmpty) {
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
      return fetchCachedUserSummaries();
    }

    try {
      final response = await AuthService.client.functions.invoke(
        'get-user-company-news-summaries',
      );

      debugPrint(
        '[company-news-summary] response status=${response.status} data=${response.data}',
      );

      if (response.status != 200 || response.data is! Map) {
        return const [];
      }

      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true || payload['items'] is! List) {
        return const [];
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
      return fetchCachedUserSummaries();
    }
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
}

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
    this.summary,
  });

  factory CompanyNewsSummaryItem.fromJson(Map<String, dynamic> json) {
    return CompanyNewsSummaryItem(
      symbol: '${json['symbol'] ?? ''}',
      found: json['found'] == true,
      assetType: json['asset_type']?.toString(),
      summaryDate: json['summary_date']?.toString(),
      model: json['model']?.toString(),
      newsCount: json['news_count'] is num
          ? (json['news_count'] as num).toInt()
          : int.tryParse('${json['news_count'] ?? ''}'),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      summary: json['summary'] is Map
          ? Map<String, dynamic>.from(
              (json['summary'] as Map).map(
                (key, value) => MapEntry('$key', value),
              ),
            )
          : null,
    );
  }

  final String symbol;
  final bool found;
  final String? assetType;
  final String? summaryDate;
  final String? model;
  final int? newsCount;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? summary;

  bool get hasKnownAssetType => assetType == '주식' || assetType == '코인';

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'found': found,
      'asset_type': assetType,
      'summary_date': summaryDate,
      'model': model,
      'news_count': newsCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'summary': summary,
    };
  }
}
