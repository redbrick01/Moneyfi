import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class RedditPostSummaryService {
  RedditPostSummaryService._();

  static final RedditPostSummaryService instance = RedditPostSummaryService._();

  Future<List<RedditPostSummaryItem>> fetchSummaries({
    int limit = 30,
    DateTime? postedDate,
  }) async {
    if (!await AuthService.ensureInitialized()) {
      debugPrint('[reddit-post-summaries] skipped: auth not initialized');
      return const [];
    }

    try {
      var query = AuthService.client
          .from('reddit_post_summaries')
          .select(_selectColumns);

      if (postedDate != null) {
        final start = DateTime(
          postedDate.year,
          postedDate.month,
          postedDate.day,
        );
        final end = start.add(const Duration(days: 1));
        final startIso = start.toUtc().toIso8601String();
        final endIso = end.toUtc().toIso8601String();
        query = query.or(
          'and(posted_at.gte.$startIso,posted_at.lt.$endIso),'
          'and(posted_at.is.null,synced_at.gte.$startIso,synced_at.lt.$endIso)',
        );
      }

      final response = await query
          .order('synced_at', ascending: false)
          .order('posted_at', ascending: false)
          .limit(limit);

      return response
          .whereType<Map>()
          .map(
            (row) => RedditPostSummaryItem.fromJson(
              row.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('[reddit-post-summaries] failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<DateTime>> fetchSummaryDates({int limit = 1000}) async {
    if (!await AuthService.ensureInitialized()) {
      debugPrint('[reddit-post-summary-dates] skipped: auth not initialized');
      return const [];
    }

    try {
      final response = await AuthService.client
          .from('reddit_post_summaries')
          .select('posted_at,synced_at')
          .order('synced_at', ascending: false)
          .order('posted_at', ascending: false)
          .limit(limit);

      final seen = <String>{};
      final dates = <DateTime>[];
      for (final row in response.whereType<Map>()) {
        final dateTime =
            _readDateTime(row['posted_at']) ?? _readDateTime(row['synced_at']);
        if (dateTime == null) continue;
        final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
        final key = _dateKey(date);
        if (seen.add(key)) {
          dates.add(date);
        }
      }
      return dates;
    } catch (error, stackTrace) {
      debugPrint('[reddit-post-summary-dates] failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static final _selectColumns = [
    'post_reddit_id',
    'subreddit',
    'title',
    'url',
    'score',
    'comment_count',
    'posted_at',
    'model',
    'is_valuable',
    'quality_label',
    'confidence',
    'tickers_json',
    'title_ko',
    'post_summary_ko',
    'comments_summary_ko',
    'analysis_reasons_ko',
    'analyzed_at',
    'importance_model',
    'importance_label',
    'importance_score',
    'category_label',
    'importance_reasons_ko',
    'judged_at',
    'insight_model',
    'insight_ko',
    'insight_generated_at',
    'synced_at',
  ].join(',');
}

class RedditPostSummaryItem {
  const RedditPostSummaryItem({
    required this.postRedditId,
    required this.subreddit,
    required this.title,
    required this.url,
    required this.score,
    required this.commentCount,
    required this.postedAt,
    required this.model,
    required this.isValuable,
    required this.qualityLabel,
    required this.confidence,
    required this.tickers,
    required this.titleKo,
    required this.postSummaryKo,
    required this.commentsSummaryKo,
    required this.analysisReasonsKo,
    required this.analyzedAt,
    required this.importanceModel,
    required this.importanceLabel,
    required this.importanceScore,
    required this.categoryLabel,
    required this.importanceReasonsKo,
    required this.judgedAt,
    required this.insightModel,
    required this.insightKo,
    required this.insightGeneratedAt,
    required this.syncedAt,
  });

  factory RedditPostSummaryItem.fromJson(Map<String, dynamic> json) {
    return RedditPostSummaryItem(
      postRedditId: _readString(json['post_reddit_id']),
      subreddit: _readString(json['subreddit']),
      title: _readString(json['title']),
      url: _readString(json['url']),
      score: _readInt(json['score']),
      commentCount: _readInt(json['comment_count']),
      postedAt: _readDateTime(json['posted_at']),
      model: _readString(json['model']),
      isValuable: _readInt(json['is_valuable']) > 0,
      qualityLabel: _readString(json['quality_label']),
      confidence: _readDouble(json['confidence']),
      tickers: _readTickers(json['tickers_json']),
      titleKo: _readString(json['title_ko']),
      postSummaryKo: _readString(json['post_summary_ko']),
      commentsSummaryKo: _readString(json['comments_summary_ko']),
      analysisReasonsKo: _readString(json['analysis_reasons_ko']),
      analyzedAt: _readDateTime(json['analyzed_at']),
      importanceModel: _readString(json['importance_model']),
      importanceLabel: _readString(json['importance_label']),
      importanceScore: _readInt(json['importance_score']),
      categoryLabel: _readString(json['category_label']),
      importanceReasonsKo: _readString(json['importance_reasons_ko']),
      judgedAt: _readDateTime(json['judged_at']),
      insightModel: _readString(json['insight_model']),
      insightKo: _readString(json['insight_ko']),
      insightGeneratedAt: _readDateTime(json['insight_generated_at']),
      syncedAt: _readDateTime(json['synced_at']),
    );
  }

  final String postRedditId;
  final String subreddit;
  final String title;
  final String url;
  final int score;
  final int commentCount;
  final DateTime? postedAt;
  final String model;
  final bool isValuable;
  final String qualityLabel;
  final double? confidence;
  final List<String> tickers;
  final String titleKo;
  final String postSummaryKo;
  final String commentsSummaryKo;
  final String analysisReasonsKo;
  final DateTime? analyzedAt;
  final String importanceModel;
  final String importanceLabel;
  final int importanceScore;
  final String categoryLabel;
  final String importanceReasonsKo;
  final DateTime? judgedAt;
  final String insightModel;
  final String insightKo;
  final DateTime? insightGeneratedAt;
  final DateTime? syncedAt;

  String get displayTitle => titleKo.isNotEmpty ? titleKo : title;
  bool get hasInsight => insightKo.trim().isNotEmpty;
  bool get hasPostSummary => postSummaryKo.trim().isNotEmpty;
  bool get hasCommentsSummary => commentsSummaryKo.trim().isNotEmpty;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final haystack = [
      subreddit,
      title,
      titleKo,
      postSummaryKo,
      commentsSummaryKo,
      analysisReasonsKo,
      importanceReasonsKo,
      insightKo,
      categoryLabel,
      ...tickers,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

String _readString(Object? value) {
  return value == null ? '' : '$value'.trim();
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_readString(value)) ?? 0;
}

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(_readString(value));
}

DateTime? _readDateTime(Object? value) {
  final raw = _readString(value);
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

List<String> _readTickers(Object? value) {
  final rawItems = value is List ? value : const [];
  return rawItems
      .map((item) => _readString(item).toUpperCase())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

String _dateKey(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}.${two(value.month)}.${two(value.day)}';
}
