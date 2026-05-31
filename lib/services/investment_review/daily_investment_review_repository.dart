import 'dart:convert';

import 'package:drift/drift.dart';

import '../../db/app_database.dart';
import 'daily_investment_review_models.dart';

class DailyInvestmentReviewRepository {
  const DailyInvestmentReviewRepository({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<DailyInvestmentReviewEntry?> loadByDate(DateTime date) async {
    final row =
        await (_database.select(_database.dailyInvestmentReviews)
              ..where((table) => table.reviewDate.equals(_dateKey(date))))
            .getSingleOrNull();
    if (row == null) return null;
    return _entryFromRow(row);
  }

  Future<void> saveDraft(DailyInvestmentReviewDraft draft) async {
    final now = DateTime.now().toIso8601String();
    final existing = await loadByDate(draft.reviewDate);
    final existingCompleted =
        existing?.status == DailyInvestmentReviewStatus.completed;
    final companion = DailyInvestmentReviewsCompanion(
      id: existing == null ? const Value.absent() : Value(existing.id),
      reviewDate: Value(_dateKey(draft.reviewDate)),
      status: Value(
        existingCompleted
            ? DailyInvestmentReviewStatus.completed.name
            : DailyInvestmentReviewStatus.inProgress.name,
      ),
      mode: Value(draft.mode.name),
      performanceNote: Value(draft.performanceNote),
      tradeReviewNote: Value(draft.tradeReviewNote),
      selectedDecisionTags: Value(jsonEncode(draft.selectedDecisionTags)),
      selectedNoTradeReasons: Value(jsonEncode(draft.selectedNoTradeReasons)),
      selectedEmotions: Value(jsonEncode(draft.selectedEmotions)),
      principleCheck: Value(draft.principleCheck.name),
      riskNote: Value(draft.riskNote),
      insightGood: Value(draft.insightGood),
      insightWeak: Value(draft.insightWeak),
      insightRepeatOrAvoid: Value(draft.insightRepeatOrAvoid),
      nextPlan: Value(draft.nextPlan),
      createdAt: Value(existing?.createdAt.toIso8601String() ?? now),
      updatedAt: Value(now),
      completedAt: existingCompleted && existing?.completedAt != null
          ? Value(existing!.completedAt!.toIso8601String())
          : const Value(null),
    );

    await _database
        .into(_database.dailyInvestmentReviews)
        .insertOnConflictUpdate(companion);
  }

  Future<void> markCompleted(DateTime date) async {
    final now = DateTime.now().toIso8601String();
    await (_database.update(
      _database.dailyInvestmentReviews,
    )..where((table) => table.reviewDate.equals(_dateKey(date)))).write(
      DailyInvestmentReviewsCompanion(
        status: Value(DailyInvestmentReviewStatus.completed.name),
        updatedAt: Value(now),
        completedAt: Value(now),
      ),
    );
  }

  DailyInvestmentReviewEntry _entryFromRow(DailyInvestmentReview row) {
    return DailyInvestmentReviewEntry(
      id: row.id,
      reviewDate: DateTime.parse(row.reviewDate),
      status: DailyInvestmentReviewStatus.values.byName(row.status),
      mode: DailyInvestmentReviewMode.values.byName(row.mode),
      performanceNote: row.performanceNote,
      tradeReviewNote: row.tradeReviewNote,
      selectedDecisionTags: _decodeStringList(row.selectedDecisionTags),
      selectedNoTradeReasons: _decodeStringList(row.selectedNoTradeReasons),
      selectedEmotions: _decodeStringList(row.selectedEmotions),
      principleCheck: DailyInvestmentReviewPrincipleCheck.values.byName(
        row.principleCheck,
      ),
      riskNote: row.riskNote,
      insightGood: row.insightGood,
      insightWeak: row.insightWeak,
      insightRepeatOrAvoid: row.insightRepeatOrAvoid,
      nextPlan: row.nextPlan,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
      completedAt: row.completedAt == null
          ? null
          : DateTime.parse(row.completedAt!),
    );
  }

  List<String> _decodeStringList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList(growable: false);
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
