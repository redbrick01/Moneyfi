# Daily Investment Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL at execution time: use `superpowers:subagent-driven-development` for task-by-task execution, or `superpowers:executing-plans` if the user chooses inline execution.

**Goal:** Convert only the `Today` investment review tab into a saved daily review composer. Keep weekly and monthly review behavior read-only and unchanged.

**Design Source:** `docs/superpowers/specs/2026-06-01-daily-investment-review-design.md`

**Tech Stack:** Flutter, Dart, Drift SQLite, `flutter_test`.

**Core Decisions:**

- The automatic `InvestmentReviewReport` remains the draft context.
- User-written daily review fields are stored locally in SQLite.
- `draft` is a computed UI state when no saved row exists.
- Persisted statuses are only `inProgress` and `completed`.
- Trading day mode is chosen when today's activity has any buy or sell count.
- No-trade day mode is chosen when buy and sell counts are both zero.
- AI, market news, benchmark comparison, and weekly/monthly writing are out of scope.

## File Structure

- Modify `lib/db/app_database_tables.dart`
  - Add `DailyInvestmentReviews` Drift table.
- Modify `lib/db/app_database.dart`
  - Add the table to `@DriftDatabase`.
  - Increment `schemaVersion`.
  - Ensure the new table in create/upgrade flows.
  - Add small DB helper methods for loading and upserting daily reviews, unless a repository method can fully use generated Drift APIs.
- Generated `lib/db/app_database.g.dart`
  - Regenerate with `dart run build_runner build --delete-conflicting-outputs`.
- Create `lib/services/investment_review/daily_investment_review_models.dart`
  - Define user-review status, mode, form model, and combined view state.
- Create `lib/services/investment_review/daily_investment_review_repository.dart`
  - Load one review by date.
  - Upsert in-progress review.
  - Mark review complete.
- Create `lib/services/investment_review/daily_investment_review_presenter.dart`
  - Combine `InvestmentReviewReport` plus saved review into composer state.
  - Decide trading/no-trade mode.
- Modify `lib/pages/investment_review_page.dart`
  - Render composer only for `InvestmentReviewPeriodType.today`.
  - Keep existing report view for weekly/monthly.
  - Add testing injection for daily review repository or loader/saver.
- Modify `lib/components/cards/investment_review_home_card.dart`
  - Add review status input and state-specific CTA labels.
- Modify `lib/pages/portfolio_dashboard_page.dart`
  - Load today's saved daily review status for the home card.
- Create `test/daily_investment_review_repository_test.dart`
  - DB persistence and upsert coverage.
- Create `test/daily_investment_review_presenter_test.dart`
  - Mode/status mapping coverage.
- Modify `test/widget_test.dart`
  - Today composer, no-trade mode, trading mode, saving/completion, weekly/monthly unchanged, home card states.

## Task 1: Persist Daily Review Rows

**Files:**

- Modify: `lib/db/app_database_tables.dart`
- Modify: `lib/db/app_database.dart`
- Generated: `lib/db/app_database.g.dart`
- Create: `test/daily_investment_review_repository_test.dart`

- [ ] **Step 1: Add failing DB tests**

Create `test/daily_investment_review_repository_test.dart` with tests that describe the persistence contract before implementing the table and repository.

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/services/investment_review/daily_investment_review_models.dart';
import 'package:moneyfy/services/investment_review/daily_investment_review_repository.dart';

void main() {
  late AppDatabase db;
  late DailyInvestmentReviewRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DailyInvestmentReviewRepository(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('load returns null when no review exists for date', () async {
    final review = await repository.loadByDate(DateTime(2026, 6, 1));
    expect(review, isNull);
  });

  test('saveDraft upserts one in-progress row per date', () async {
    final date = DateTime(2026, 6, 1);

    await repository.saveDraft(
      DailyInvestmentReviewDraft(
        reviewDate: date,
        mode: DailyInvestmentReviewMode.noTradeDay,
        performanceNote: '성과 변동은 작았다.',
        tradeReviewNote: '원칙에 맞는 기회가 없었다.',
        selectedDecisionTags: const [],
        selectedNoTradeReasons: const ['원칙에 맞는 기회가 없었음'],
        selectedEmotions: const ['차분함'],
        principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
        riskNote: '충동 매매 없음.',
        insightGood: '기다린 점이 좋았다.',
        insightWeak: '관심 종목 조건을 더 구체화해야 한다.',
        insightRepeatOrAvoid: '목표 가격 전에는 진입하지 않기.',
        nextPlan: '내일은 현금 비중과 관심 종목 가격만 확인한다.',
      ),
    );
    await repository.saveDraft(
      DailyInvestmentReviewDraft(
        reviewDate: date,
        mode: DailyInvestmentReviewMode.noTradeDay,
        performanceNote: '수정된 성과 메모',
        tradeReviewNote: '수정된 관망 메모',
        selectedDecisionTags: const [],
        selectedNoTradeReasons: const ['변동성이 커서 관망'],
        selectedEmotions: const ['불안함'],
        principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
        riskNote: '진입을 참았다.',
        insightGood: '기다림.',
        insightWeak: '분석 부족.',
        insightRepeatOrAvoid: '뉴스만 보고 사지 않기.',
        nextPlan: '조건 재확인.',
      ),
    );

    final review = await repository.loadByDate(date);
    expect(review, isNotNull);
    expect(review!.status, DailyInvestmentReviewStatus.inProgress);
    expect(review.performanceNote, '수정된 성과 메모');

    final rows = await db.customSelect(
      'SELECT COUNT(*) AS count FROM daily_investment_reviews WHERE review_date = ?',
      variables: [Variable.withString('2026-06-01')],
    ).get();
    expect(rows.single.read<int>('count'), 1);
  });

  test('markCompleted stores completed status and completed timestamp', () async {
    final date = DateTime(2026, 6, 1);
    await repository.saveDraft(
      DailyInvestmentReviewDraft.empty(
        reviewDate: date,
        mode: DailyInvestmentReviewMode.tradingDay,
      ).copyWith(
        performanceNote: '실현손익 확인',
        tradeReviewNote: '계획 매도',
      ),
    );

    await repository.markCompleted(date);

    final review = await repository.loadByDate(date);
    expect(review, isNotNull);
    expect(review!.status, DailyInvestmentReviewStatus.completed);
    expect(review.completedAt, isNotNull);
  });
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
flutter test test/daily_investment_review_repository_test.dart
```

Expected: FAIL because the model and repository files do not exist.

- [ ] **Step 3: Add the Drift table**

In `lib/db/app_database_tables.dart`, add the table near other daily/portfolio tables:

```dart
class DailyInvestmentReviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get reviewDate => text().unique()();
  TextColumn get status => text()();
  TextColumn get mode => text()();
  TextColumn get performanceNote => text().withDefault(const Constant(''))();
  TextColumn get tradeReviewNote => text().withDefault(const Constant(''))();
  TextColumn get selectedDecisionTags =>
      text().withDefault(const Constant('[]'))();
  TextColumn get selectedNoTradeReasons =>
      text().withDefault(const Constant('[]'))();
  TextColumn get selectedEmotions => text().withDefault(const Constant('[]'))();
  TextColumn get principleCheck =>
      text().withDefault(const Constant('notApplicable'))();
  TextColumn get riskNote => text().withDefault(const Constant(''))();
  TextColumn get insightGood => text().withDefault(const Constant(''))();
  TextColumn get insightWeak => text().withDefault(const Constant(''))();
  TextColumn get insightRepeatOrAvoid =>
      text().withDefault(const Constant(''))();
  TextColumn get nextPlan => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get completedAt => text().nullable()();
}
```

- [ ] **Step 4: Register and ensure the table**

In `lib/db/app_database.dart`, add `DailyInvestmentReviews` to the `@DriftDatabase` table list immediately after `BenchmarkPrices`.

Increment:

```dart
int get schemaVersion => 37;
```

In both `onCreate` and the start of `onUpgrade`, call:

```dart
await _ensureDailyInvestmentReviewsTable();
```

Add this helper near `_ensureBenchmarkPricesTable()`:

```dart
Future<void> _ensureDailyInvestmentReviewsTable() async {
  await customStatement('''
    CREATE TABLE IF NOT EXISTS daily_investment_reviews (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      review_date TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL,
      mode TEXT NOT NULL,
      performance_note TEXT NOT NULL DEFAULT '',
      trade_review_note TEXT NOT NULL DEFAULT '',
      selected_decision_tags TEXT NOT NULL DEFAULT '[]',
      selected_no_trade_reasons TEXT NOT NULL DEFAULT '[]',
      selected_emotions TEXT NOT NULL DEFAULT '[]',
      principle_check TEXT NOT NULL DEFAULT 'notApplicable',
      risk_note TEXT NOT NULL DEFAULT '',
      insight_good TEXT NOT NULL DEFAULT '',
      insight_weak TEXT NOT NULL DEFAULT '',
      insight_repeat_or_avoid TEXT NOT NULL DEFAULT '',
      next_plan TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      completed_at TEXT
    )
  ''');
  await customStatement(
    'CREATE INDEX IF NOT EXISTS daily_investment_reviews_date_idx '
    'ON daily_investment_reviews(review_date)',
  );
}
```

- [ ] **Step 5: Create domain models and repository**

Create `lib/services/investment_review/daily_investment_review_models.dart`:

```dart
enum DailyInvestmentReviewStatus { inProgress, completed }

enum DailyInvestmentReviewMode { tradingDay, noTradeDay }

enum DailyInvestmentReviewPrincipleCheck {
  followedRules,
  brokeRules,
  notApplicable,
}

class DailyInvestmentReviewDraft {
  const DailyInvestmentReviewDraft({
    required this.reviewDate,
    required this.mode,
    required this.performanceNote,
    required this.tradeReviewNote,
    required this.selectedDecisionTags,
    required this.selectedNoTradeReasons,
    required this.selectedEmotions,
    required this.principleCheck,
    required this.riskNote,
    required this.insightGood,
    required this.insightWeak,
    required this.insightRepeatOrAvoid,
    required this.nextPlan,
  });

  factory DailyInvestmentReviewDraft.empty({
    required DateTime reviewDate,
    required DailyInvestmentReviewMode mode,
  }) {
    return DailyInvestmentReviewDraft(
      reviewDate: reviewDate,
      mode: mode,
      performanceNote: '',
      tradeReviewNote: '',
      selectedDecisionTags: const [],
      selectedNoTradeReasons: const [],
      selectedEmotions: const [],
      principleCheck: DailyInvestmentReviewPrincipleCheck.notApplicable,
      riskNote: '',
      insightGood: '',
      insightWeak: '',
      insightRepeatOrAvoid: '',
      nextPlan: '',
    );
  }

  final DateTime reviewDate;
  final DailyInvestmentReviewMode mode;
  final String performanceNote;
  final String tradeReviewNote;
  final List<String> selectedDecisionTags;
  final List<String> selectedNoTradeReasons;
  final List<String> selectedEmotions;
  final DailyInvestmentReviewPrincipleCheck principleCheck;
  final String riskNote;
  final String insightGood;
  final String insightWeak;
  final String insightRepeatOrAvoid;
  final String nextPlan;

  DailyInvestmentReviewDraft copyWith({
    String? performanceNote,
    String? tradeReviewNote,
  }) {
    return DailyInvestmentReviewDraft(
      reviewDate: reviewDate,
      mode: mode,
      performanceNote: performanceNote ?? this.performanceNote,
      tradeReviewNote: tradeReviewNote ?? this.tradeReviewNote,
      selectedDecisionTags: selectedDecisionTags,
      selectedNoTradeReasons: selectedNoTradeReasons,
      selectedEmotions: selectedEmotions,
      principleCheck: principleCheck,
      riskNote: riskNote,
      insightGood: insightGood,
      insightWeak: insightWeak,
      insightRepeatOrAvoid: insightRepeatOrAvoid,
      nextPlan: nextPlan,
    );
  }
}

class DailyInvestmentReviewEntry {
  const DailyInvestmentReviewEntry({
    required this.id,
    required this.reviewDate,
    required this.status,
    required this.mode,
    required this.performanceNote,
    required this.tradeReviewNote,
    required this.selectedDecisionTags,
    required this.selectedNoTradeReasons,
    required this.selectedEmotions,
    required this.principleCheck,
    required this.riskNote,
    required this.insightGood,
    required this.insightWeak,
    required this.insightRepeatOrAvoid,
    required this.nextPlan,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final int id;
  final DateTime reviewDate;
  final DailyInvestmentReviewStatus status;
  final DailyInvestmentReviewMode mode;
  final String performanceNote;
  final String tradeReviewNote;
  final List<String> selectedDecisionTags;
  final List<String> selectedNoTradeReasons;
  final List<String> selectedEmotions;
  final DailyInvestmentReviewPrincipleCheck principleCheck;
  final String riskNote;
  final String insightGood;
  final String insightWeak;
  final String insightRepeatOrAvoid;
  final String nextPlan;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
}
```

Create `lib/services/investment_review/daily_investment_review_repository.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../db/app_database.dart';
import 'daily_investment_review_models.dart';

class DailyInvestmentReviewRepository {
  const DailyInvestmentReviewRepository({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<DailyInvestmentReviewEntry?> loadByDate(DateTime date) async {
    final row = await (_database.select(_database.dailyInvestmentReviews)
          ..where((table) => table.reviewDate.equals(_dateKey(date))))
        .getSingleOrNull();
    if (row == null) return null;
    return _entryFromRow(row);
  }

  Future<void> saveDraft(DailyInvestmentReviewDraft draft) async {
    final now = DateTime.now().toIso8601String();
    final existing = await loadByDate(draft.reviewDate);
    final companion = DailyInvestmentReviewsCompanion(
      id: existing == null ? const Value.absent() : Value(existing.id),
      reviewDate: Value(_dateKey(draft.reviewDate)),
      status: Value(DailyInvestmentReviewStatus.inProgress.name),
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
      completedAt: existing?.completedAt == null
          ? const Value.absent()
          : Value(existing!.completedAt!.toIso8601String()),
    );

    await _database
        .into(_database.dailyInvestmentReviews)
        .insertOnConflictUpdate(companion);
  }

  Future<void> markCompleted(DateTime date) async {
    final now = DateTime.now().toIso8601String();
    await (_database.update(_database.dailyInvestmentReviews)
          ..where((table) => table.reviewDate.equals(_dateKey(date))))
        .write(
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
      completedAt: row.completedAt == null ? null : DateTime.parse(row.completedAt!),
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
```

- [ ] **Step 6: Regenerate Drift code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generated `lib/db/app_database.g.dart` includes `DailyInvestmentReviews`.

- [ ] **Step 7: Run persistence tests**

Run:

```bash
flutter test test/daily_investment_review_repository_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/db/app_database.dart lib/db/app_database_tables.dart lib/db/app_database.g.dart lib/services/investment_review/daily_investment_review_models.dart lib/services/investment_review/daily_investment_review_repository.dart test/daily_investment_review_repository_test.dart
git commit -m "feat: persist daily investment reviews"
```

## Task 2: Build Daily Review Presenter State

**Files:**

- Modify: `lib/services/investment_review/daily_investment_review_models.dart`
- Create: `lib/services/investment_review/daily_investment_review_presenter.dart`
- Create: `test/daily_investment_review_presenter_test.dart`

- [ ] **Step 1: Add failing presenter tests**

Create `test/daily_investment_review_presenter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_review/daily_investment_review_models.dart';
import 'package:moneyfy/services/investment_review/daily_investment_review_presenter.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';

void main() {
  InvestmentReviewReport report({
    int buyCount = 0,
    int sellCount = 0,
  }) {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.today,
      now: DateTime(2026, 6, 1, 12),
    );
    return InvestmentReviewReport(
      period: period,
      metrics: const [],
      signals: const [],
      narrative: const InvestmentReviewNarrative(
        headline: '오늘 회고 초안',
        summary: '자동 초안입니다.',
        nextActions: ['내일 조건을 정리하세요.'],
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: buyCount + sellCount > 0,
      activity: InvestmentReviewActivitySummary(
        buyCount: buyCount,
        sellCount: sellCount,
      ),
      generatedAt: DateTime(2026, 6, 1, 12),
    );
  }

  test('uses draft status and no-trade mode without a saved row', () {
    final state = DailyInvestmentReviewPresenter.buildState(
      report: report(),
      savedReview: null,
    );

    expect(state.status, DailyInvestmentReviewComposerStatus.draft);
    expect(state.mode, DailyInvestmentReviewMode.noTradeDay);
    expect(state.isCompleted, isFalse);
    expect(state.draft.tradeReviewNote, isEmpty);
  });

  test('uses trading mode when buy or sell activity exists', () {
    final state = DailyInvestmentReviewPresenter.buildState(
      report: report(buyCount: 1),
      savedReview: null,
    );

    expect(state.mode, DailyInvestmentReviewMode.tradingDay);
  });

  test('preserves saved fields even when report mode changes', () {
    final saved = DailyInvestmentReviewEntry(
      id: 1,
      reviewDate: DateTime(2026, 6, 1),
      status: DailyInvestmentReviewStatus.inProgress,
      mode: DailyInvestmentReviewMode.noTradeDay,
      performanceNote: '기존 메모',
      tradeReviewNote: '관망 이유',
      selectedDecisionTags: const [],
      selectedNoTradeReasons: const ['기다림'],
      selectedEmotions: const ['차분함'],
      principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
      riskNote: '',
      insightGood: '',
      insightWeak: '',
      insightRepeatOrAvoid: '',
      nextPlan: '',
      createdAt: DateTime(2026, 6, 1, 10),
      updatedAt: DateTime(2026, 6, 1, 11),
    );

    final state = DailyInvestmentReviewPresenter.buildState(
      report: report(sellCount: 1),
      savedReview: saved,
    );

    expect(state.status, DailyInvestmentReviewComposerStatus.inProgress);
    expect(state.mode, DailyInvestmentReviewMode.tradingDay);
    expect(state.draft.performanceNote, '기존 메모');
    expect(state.draft.tradeReviewNote, '관망 이유');
  });
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
flutter test test/daily_investment_review_presenter_test.dart
```

Expected: FAIL because presenter state does not exist.

- [ ] **Step 3: Add composer state model**

Append to `daily_investment_review_models.dart`:

```dart
enum DailyInvestmentReviewComposerStatus { draft, inProgress, completed }

class DailyInvestmentReviewComposerState {
  const DailyInvestmentReviewComposerState({
    required this.status,
    required this.mode,
    required this.draft,
    this.savedReview,
  });

  final DailyInvestmentReviewComposerStatus status;
  final DailyInvestmentReviewMode mode;
  final DailyInvestmentReviewDraft draft;
  final DailyInvestmentReviewEntry? savedReview;

  bool get isCompleted => status == DailyInvestmentReviewComposerStatus.completed;
}
```

- [ ] **Step 4: Create presenter**

Create `lib/services/investment_review/daily_investment_review_presenter.dart`:

```dart
import 'daily_investment_review_models.dart';
import 'investment_review_models.dart';

abstract final class DailyInvestmentReviewPresenter {
  static DailyInvestmentReviewComposerState buildState({
    required InvestmentReviewReport report,
    required DailyInvestmentReviewEntry? savedReview,
  }) {
    final mode = _modeFrom(report);
    if (savedReview == null) {
      return DailyInvestmentReviewComposerState(
        status: DailyInvestmentReviewComposerStatus.draft,
        mode: mode,
        draft: DailyInvestmentReviewDraft.empty(
          reviewDate: report.period.from,
          mode: mode,
        ),
      );
    }

    final status = switch (savedReview.status) {
      DailyInvestmentReviewStatus.inProgress =>
        DailyInvestmentReviewComposerStatus.inProgress,
      DailyInvestmentReviewStatus.completed =>
        DailyInvestmentReviewComposerStatus.completed,
    };

    return DailyInvestmentReviewComposerState(
      status: status,
      mode: mode,
      savedReview: savedReview,
      draft: DailyInvestmentReviewDraft(
        reviewDate: savedReview.reviewDate,
        mode: mode,
        performanceNote: savedReview.performanceNote,
        tradeReviewNote: savedReview.tradeReviewNote,
        selectedDecisionTags: savedReview.selectedDecisionTags,
        selectedNoTradeReasons: savedReview.selectedNoTradeReasons,
        selectedEmotions: savedReview.selectedEmotions,
        principleCheck: savedReview.principleCheck,
        riskNote: savedReview.riskNote,
        insightGood: savedReview.insightGood,
        insightWeak: savedReview.insightWeak,
        insightRepeatOrAvoid: savedReview.insightRepeatOrAvoid,
        nextPlan: savedReview.nextPlan,
      ),
    );
  }

  static DailyInvestmentReviewMode _modeFrom(InvestmentReviewReport report) {
    return report.activity.tradeCount > 0
        ? DailyInvestmentReviewMode.tradingDay
        : DailyInvestmentReviewMode.noTradeDay;
  }
}
```

- [ ] **Step 5: Run presenter tests**

Run:

```bash
flutter test test/daily_investment_review_presenter_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/services/investment_review/daily_investment_review_models.dart lib/services/investment_review/daily_investment_review_presenter.dart test/daily_investment_review_presenter_test.dart
git commit -m "feat: prepare daily review composer state"
```

## Task 3: Convert Today Tab Into Composer

**Files:**

- Modify: `lib/pages/investment_review_page.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add failing widget tests**

In `test/widget_test.dart`, add tests near existing investment review page tests:

```dart
testWidgets('today investment review shows no-trade composer prompts', (
  tester,
) async {
  final period = InvestmentReviewPeriodResolver.resolve(
    InvestmentReviewPeriodType.today,
    now: DateTime(2026, 6, 1),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: InvestmentReviewPage(
        reportBuilderForTesting: (_) async => InvestmentReviewReport(
          period: period,
          metrics: const [],
          signals: const [],
          narrative: const InvestmentReviewNarrative(
            headline: '오늘 회고 초안',
            summary: '오늘은 거래가 없었어요.',
            nextActions: ['내일 조건을 정리하세요.'],
          ),
          aiState: const InvestmentReviewAiState.off(),
          hasEnoughData: false,
          activity: const InvestmentReviewActivitySummary(),
        ),
        dailyReviewLoaderForTesting: (_) async => null,
        dailyReviewSaverForTesting: (_) async {},
        dailyReviewCompleterForTesting: (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('초안 생성됨'), findsOneWidget);
  expect(find.text('관망 회고'), findsOneWidget);
  expect(find.text('원칙에 맞는 기회가 없었음'), findsOneWidget);
  expect(find.text('성과 분석'), findsOneWidget);
  expect(find.text('리스크/멘탈 점검'), findsOneWidget);
  expect(find.text('핵심 인사이트'), findsOneWidget);
  expect(find.text('다음 투자 계획'), findsOneWidget);
});

testWidgets('today investment review shows trading composer prompts', (
  tester,
) async {
  final period = InvestmentReviewPeriodResolver.resolve(
    InvestmentReviewPeriodType.today,
    now: DateTime(2026, 6, 1),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: InvestmentReviewPage(
        reportBuilderForTesting: (_) async => InvestmentReviewReport(
          period: period,
          metrics: const [],
          signals: const [],
          narrative: const InvestmentReviewNarrative(
            headline: '오늘 회고 초안',
            summary: '매수 1건이 있었어요.',
            nextActions: const ['매수 이유를 복기하세요.'],
          ),
          aiState: const InvestmentReviewAiState.off(),
          hasEnoughData: true,
          activity: const InvestmentReviewActivitySummary(buyCount: 1),
        ),
        dailyReviewLoaderForTesting: (_) async => null,
        dailyReviewSaverForTesting: (_) async {},
        dailyReviewCompleterForTesting: (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('매매 복기'), findsOneWidget);
  expect(find.text('계획 매매'), findsOneWidget);
  expect(find.text('FOMO'), findsOneWidget);
});
```

- [ ] **Step 2: Run failing widget tests**

Run:

```bash
flutter test test/widget_test.dart --plain-name "today investment review"
```

Expected: FAIL because the composer UI and testing hooks do not exist.

- [ ] **Step 3: Add testing hooks and combined load**

In `lib/pages/investment_review_page.dart`, add imports:

```dart
import '../services/investment_review/daily_investment_review_models.dart';
import '../services/investment_review/daily_investment_review_presenter.dart';
import '../services/investment_review/daily_investment_review_repository.dart';
```

Add typedefs:

```dart
typedef DailyInvestmentReviewLoader =
    Future<DailyInvestmentReviewEntry?> Function(DateTime date);
typedef DailyInvestmentReviewSaver =
    Future<void> Function(DailyInvestmentReviewDraft draft);
typedef DailyInvestmentReviewCompleter = Future<void> Function(DateTime date);
```

Extend constructor:

```dart
const InvestmentReviewPage({
  super.key,
  this.reportBuilderForTesting,
  this.dailyReviewLoaderForTesting,
  this.dailyReviewSaverForTesting,
  this.dailyReviewCompleterForTesting,
});

final DailyInvestmentReviewLoader? dailyReviewLoaderForTesting;
final DailyInvestmentReviewSaver? dailyReviewSaverForTesting;
final DailyInvestmentReviewCompleter? dailyReviewCompleterForTesting;
```

Add a private view model:

```dart
class _TodayReviewLoadResult {
  const _TodayReviewLoadResult({required this.report, required this.state});

  final InvestmentReviewReport report;
  final DailyInvestmentReviewComposerState state;
}
```

In `_InvestmentReviewPageState`, add:

```dart
Future<_TodayReviewLoadResult> _loadTodayReview() async {
  final report = await _loadReportFor(InvestmentReviewPeriodType.today);
  final loader = widget.dailyReviewLoaderForTesting;
  final repository = DailyInvestmentReviewRepository(database: AppDatabase.instance);
  final saved = loader == null
      ? await repository.loadByDate(report.period.from)
      : await loader(report.period.from);
  return _TodayReviewLoadResult(
    report: report,
    state: DailyInvestmentReviewPresenter.buildState(
      report: report,
      savedReview: saved,
    ),
  );
}
```

Refactor current `_loadReport()` into `_loadReportFor(type)` so weekly/monthly still use the old `FutureBuilder<InvestmentReviewReport>`.

- [ ] **Step 4: Render composer only for Today**

Change the build method so Today uses `FutureBuilder<_TodayReviewLoadResult>` and weekly/monthly use the existing `FutureBuilder<InvestmentReviewReport>`.

Add `_TodayInvestmentReviewComposer` below existing report widgets. Start with a pragmatic single-file implementation; split later only if the page becomes hard to navigate.

The composer must show:

```dart
_TodayReviewStatusHeader(state: state),
_AutomaticDraftContext(report: report),
_PerformanceComposer(initialText: state.draft.performanceNote),
if (state.mode == DailyInvestmentReviewMode.tradingDay)
  _TradingReviewComposer(initialText: state.draft.tradeReviewNote)
else
  _NoTradeReviewComposer(initialText: state.draft.tradeReviewNote),
_RiskMentalComposer(state: state),
_InsightComposer(state: state),
_NextPlanComposer(initialText: state.draft.nextPlan),
_TodayReviewActions(
  report: report,
  draftBuilder: _draftFromControllers,
  saver: saver,
  completer: completer,
  onReloadRequested: onReloadRequested,
)
```

Use these visible Korean labels:

- `초안 생성됨`
- `작성 중`
- `완료`
- `자동 초안`
- `성과 분석`
- `매매 복기`
- `관망 회고`
- `리스크/멘탈 점검`
- `핵심 인사이트`
- `다음 투자 계획`
- `임시 저장`
- `회고 완료`
- `수정하기`

Use these trading chips:

- `계획 매매`
- `리밸런싱`
- `손절/익절 원칙`
- `FOMO`
- `소문/추천`
- `충동 매매`

Use these no-trade chips:

- `원칙에 맞는 기회가 없었음`
- `목표 가격 대기`
- `현금 비중 유지`
- `추가 분석 필요`
- `변동성이 커서 관망`
- `충동 매매를 참음`
- `특별히 기록할 변화 없음`

Use these emotion chips:

- `차분함`
- `불안함`
- `조급함`
- `아쉬움`
- `확신`

Use these principle chips:

- `원칙 지킴`
- `원칙 어김`
- `해당 없음`

- [ ] **Step 5: Add save and complete behavior**

Inside `_TodayInvestmentReviewComposerState`, keep `TextEditingController`s and selected chip sets.

On `임시 저장`, call:

```dart
await saver(
  DailyInvestmentReviewDraft(
    reviewDate: widget.report.period.from,
    mode: widget.state.mode,
    performanceNote: _performanceController.text,
    tradeReviewNote: _tradeReviewController.text,
    selectedDecisionTags: _selectedDecisionTags.toList(growable: false),
    selectedNoTradeReasons: _selectedNoTradeReasons.toList(growable: false),
    selectedEmotions: _selectedEmotions.toList(growable: false),
    principleCheck: _principleCheck,
    riskNote: _riskController.text,
    insightGood: _insightGoodController.text,
    insightWeak: _insightWeakController.text,
    insightRepeatOrAvoid: _repeatAvoidController.text,
    nextPlan: _nextPlanController.text,
  ),
);
```

On success, show:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('오늘 회고를 저장했어요.')),
);
```

On `회고 완료`, save the current draft first, then call the completer for `report.period.from`, then reload the Today future.

On save failure, keep controller contents and show:

```dart
const SnackBar(content: Text('회고를 저장하지 못했어요. 다시 시도해 주세요.'))
```

- [ ] **Step 6: Add discard confirmation**

Wrap the composer with `PopScope`. If controllers/chips differ from initial state, show a dialog:

```dart
AlertDialog(
  title: const Text('저장하지 않은 회고가 있어요'),
  content: const Text('저장하지 않고 나가면 작성 중인 내용이 사라집니다.'),
  actions: [
    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('계속 작성')),
    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('나가기')),
  ],
)
```

- [ ] **Step 7: Run widget tests**

Run:

```bash
flutter test test/widget_test.dart --plain-name "today investment review"
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/investment_review_page.dart test/widget_test.dart
git commit -m "feat: add daily investment review composer"
```

## Task 4: Save, Resume, Complete Widget Coverage

**Files:**

- Modify: `test/widget_test.dart`
- Modify: `lib/pages/investment_review_page.dart`

- [ ] **Step 1: Add failing tests for save and completion**

Add tests:

```dart
testWidgets('today investment review saves draft from form fields', (
  tester,
) async {
  final period = InvestmentReviewPeriodResolver.resolve(
    InvestmentReviewPeriodType.today,
    now: DateTime(2026, 6, 1),
  );
  DailyInvestmentReviewDraft? savedDraft;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: InvestmentReviewPage(
        reportBuilderForTesting: (_) async => InvestmentReviewReport(
          period: period,
          metrics: const [],
          signals: const [],
          narrative: const InvestmentReviewNarrative(
            headline: '오늘 회고 초안',
            summary: '자동 초안입니다.',
            nextActions: const [],
          ),
          aiState: const InvestmentReviewAiState.off(),
          hasEnoughData: false,
          activity: const InvestmentReviewActivitySummary(),
        ),
        dailyReviewLoaderForTesting: (_) async => null,
        dailyReviewSaverForTesting: (draft) async {
          savedDraft = draft;
        },
        dailyReviewCompleterForTesting: (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextField, '오늘 성과의 원인을 적어보세요.'),
    '거래 없이 비중을 유지했다.',
  );
  await tester.tap(find.text('차분함'));
  await tester.tap(find.text('원칙 지킴'));
  await tester.tap(find.text('임시 저장'));
  await tester.pump();

  expect(savedDraft, isNotNull);
  expect(savedDraft!.performanceNote, '거래 없이 비중을 유지했다.');
  expect(savedDraft!.selectedEmotions, contains('차분함'));
  expect(savedDraft!.principleCheck, DailyInvestmentReviewPrincipleCheck.followedRules);
});

testWidgets('today investment review can mark completed', (tester) async {
  final period = InvestmentReviewPeriodResolver.resolve(
    InvestmentReviewPeriodType.today,
    now: DateTime(2026, 6, 1),
  );
  var completed = false;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: InvestmentReviewPage(
        reportBuilderForTesting: (_) async => InvestmentReviewReport(
          period: period,
          metrics: const [],
          signals: const [],
          narrative: const InvestmentReviewNarrative(
            headline: '오늘 회고 초안',
            summary: '자동 초안입니다.',
            nextActions: const [],
          ),
          aiState: const InvestmentReviewAiState.off(),
          hasEnoughData: false,
          activity: const InvestmentReviewActivitySummary(),
        ),
        dailyReviewLoaderForTesting: (_) async => null,
        dailyReviewSaverForTesting: (_) async {},
        dailyReviewCompleterForTesting: (_) async {
          completed = true;
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('회고 완료'));
  await tester.pump();

  expect(completed, isTrue);
});
```

- [ ] **Step 2: Run failing tests**

Run:

```bash
flutter test test/widget_test.dart --plain-name "today investment review saves"
flutter test test/widget_test.dart --plain-name "today investment review can mark completed"
```

Expected: FAIL until controls and actions are fully wired.

- [ ] **Step 3: Complete form wiring**

Ensure every section has stable labels and `TextField` hints:

- Performance: `오늘 성과의 원인을 적어보세요.`
- Trade/no-trade: `오늘의 판단 과정을 적어보세요.`
- Risk: `리스크나 감정 변화를 적어보세요.`
- Good insight: `오늘 잘한 점`
- Weak insight: `아쉬운 점`
- Repeat/avoid: `반복하거나 피할 점`
- Next plan: `다음 투자 전에 확인할 계획`

Use `FilterChip` for chip selections and keep selected values in `Set<String>`.

Map principle chips:

```dart
DailyInvestmentReviewPrincipleCheck _principleFromLabel(String label) {
  return switch (label) {
    '원칙 지킴' => DailyInvestmentReviewPrincipleCheck.followedRules,
    '원칙 어김' => DailyInvestmentReviewPrincipleCheck.brokeRules,
    _ => DailyInvestmentReviewPrincipleCheck.notApplicable,
  };
}
```

- [ ] **Step 4: Run save/complete tests**

Run:

```bash
flutter test test/widget_test.dart --plain-name "today investment review"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/investment_review_page.dart test/widget_test.dart
git commit -m "test: cover daily review save and completion"
```

## Task 5: Update Home Card Status

**Files:**

- Modify: `lib/components/cards/investment_review_home_card.dart`
- Modify: `lib/pages/portfolio_dashboard_page.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add failing home card tests**

Replace or extend the current home card test with:

```dart
testWidgets('investment review home card shows draft status CTA', (tester) async {
  final period = InvestmentReviewPeriodResolver.resolve(
    InvestmentReviewPeriodType.today,
    now: DateTime(2026, 6, 1),
  );
  var tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: InvestmentReviewHomeCard(
          report: InvestmentReviewReport(
            period: period,
            metrics: const [],
            signals: const [],
            narrative: const InvestmentReviewNarrative(
              headline: '오늘 회고 초안',
              summary: '자동 초안입니다.',
              nextActions: ['내일 조건을 정리하세요.'],
            ),
            aiState: const InvestmentReviewAiState.off(),
            hasEnoughData: false,
            activity: const InvestmentReviewActivitySummary(),
          ),
          reviewStatus: DailyInvestmentReviewComposerStatus.draft,
          onOpen: () {
            tapped = true;
          },
        ),
      ),
    ),
  );

  expect(find.text('오늘 회고 초안이 준비됐어요'), findsOneWidget);
  await tester.tap(find.text('작성하기'));
  expect(tapped, isTrue);
});

testWidgets('investment review home card shows completed status CTA', (
  tester,
) async {
  final period = InvestmentReviewPeriodResolver.resolve(
    InvestmentReviewPeriodType.today,
    now: DateTime(2026, 6, 1),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: InvestmentReviewHomeCard(
          report: InvestmentReviewReport(
            period: period,
            metrics: const [],
            signals: const [],
            narrative: const InvestmentReviewNarrative(
              headline: '오늘 회고 초안',
              summary: '자동 초안입니다.',
              nextActions: const [],
            ),
            aiState: const InvestmentReviewAiState.off(),
            hasEnoughData: false,
            activity: const InvestmentReviewActivitySummary(),
          ),
          reviewStatus: DailyInvestmentReviewComposerStatus.completed,
          onOpen: () {},
        ),
      ),
    ),
  );

  expect(find.text('오늘 회고 완료'), findsOneWidget);
  expect(find.text('보기'), findsOneWidget);
});
```

- [ ] **Step 2: Run failing home card tests**

Run:

```bash
flutter test test/widget_test.dart --plain-name "investment review home card"
```

Expected: FAIL because the card does not accept `reviewStatus`.

- [ ] **Step 3: Update `InvestmentReviewHomeCard` API**

In `lib/components/cards/investment_review_home_card.dart`, import the daily model and update constructor:

```dart
final DailyInvestmentReviewComposerStatus reviewStatus;
```

Add status text:

```dart
String get _headline => switch (reviewStatus) {
  DailyInvestmentReviewComposerStatus.draft => '오늘 회고 초안이 준비됐어요',
  DailyInvestmentReviewComposerStatus.inProgress => '작성 중인 회고가 있어요',
  DailyInvestmentReviewComposerStatus.completed => '오늘 회고 완료',
};

String get _buttonLabel => switch (reviewStatus) {
  DailyInvestmentReviewComposerStatus.draft => '작성하기',
  DailyInvestmentReviewComposerStatus.inProgress => '이어쓰기',
  DailyInvestmentReviewComposerStatus.completed => '보기',
};
```

Render `_headline` as the main card title text and keep up to two automatic next actions under it.

- [ ] **Step 4: Load status in dashboard**

In `lib/pages/portfolio_dashboard_page.dart`, add a testable daily review status loader or load the repository next to the existing today report loader.

The dashboard should:

1. Load today's `InvestmentReviewReport`.
2. Load today's saved daily review row.
3. Convert saved row to `DailyInvestmentReviewComposerStatus`.
4. Pass the status to `InvestmentReviewHomeCard`.

Mapping:

```dart
DailyInvestmentReviewComposerStatus statusFromSaved(
  DailyInvestmentReviewEntry? saved,
) {
  if (saved == null) return DailyInvestmentReviewComposerStatus.draft;
  return switch (saved.status) {
    DailyInvestmentReviewStatus.inProgress =>
      DailyInvestmentReviewComposerStatus.inProgress,
    DailyInvestmentReviewStatus.completed =>
      DailyInvestmentReviewComposerStatus.completed,
  };
}
```

- [ ] **Step 5: Run home/dashboard tests**

Run:

```bash
flutter test test/widget_test.dart --plain-name "investment review home card"
flutter test test/widget_test.dart --plain-name "portfolio dashboard hides stale investment review"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/components/cards/investment_review_home_card.dart lib/pages/portfolio_dashboard_page.dart test/widget_test.dart
git commit -m "feat: show daily review status on home"
```

## Task 6: Verify Existing Weekly And Monthly Behavior

**Files:**

- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add regression tests**

Add a widget test ensuring weekly/monthly still render the old read-only report sections after switching tabs:

```dart
testWidgets('weekly and monthly investment reviews remain read-only reports', (
  tester,
) async {
  InvestmentReviewReport reportFor(InvestmentReviewPeriodType type) {
    final period = InvestmentReviewPeriodResolver.resolve(
      type,
      now: DateTime(2026, 6, 1),
    );
    return InvestmentReviewReport(
      period: period,
      metrics: const [
        InvestmentReviewMetric(label: '순 투자성과', value: '+10,000원'),
      ],
      signals: const [
        InvestmentReviewSignal(title: '성과 개선', description: '성과가 개선됐어요.'),
      ],
      narrative: InvestmentReviewNarrative(
        headline: '${period.label} 회고',
        summary: '읽기형 리포트입니다.',
        nextActions: const ['비중을 확인하세요.'],
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: true,
      activity: const InvestmentReviewActivitySummary(buyCount: 1),
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: InvestmentReviewPage(
        reportBuilderForTesting: (type) async => reportFor(type),
        dailyReviewLoaderForTesting: (_) async => null,
        dailyReviewSaverForTesting: (_) async {},
        dailyReviewCompleterForTesting: (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('주간'));
  await tester.pumpAndSettle();

  expect(find.text('주간 회고'), findsOneWidget);
  expect(find.text('주요 지표'), findsOneWidget);
  expect(find.text('리뷰 신호'), findsOneWidget);
  expect(find.text('성과 분석'), findsNothing);

  await tester.tap(find.text('월간'));
  await tester.pumpAndSettle();

  expect(find.text('월간 회고'), findsOneWidget);
  expect(find.text('주요 지표'), findsOneWidget);
  expect(find.text('리뷰 신호'), findsOneWidget);
  expect(find.text('성과 분석'), findsNothing);
});
```

- [ ] **Step 2: Run regression test**

Run:

```bash
flutter test test/widget_test.dart --plain-name "weekly and monthly investment reviews remain read-only reports"
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: preserve weekly monthly review reports"
```

## Task 7: Full Verification And Cleanup

**Files:**

- Modify only files touched by earlier tasks if verification finds issues.

- [ ] **Step 1: Format changed Dart files**

Run:

```bash
dart format lib/db/app_database.dart lib/db/app_database_tables.dart lib/services/investment_review/daily_investment_review_models.dart lib/services/investment_review/daily_investment_review_repository.dart lib/services/investment_review/daily_investment_review_presenter.dart lib/pages/investment_review_page.dart lib/components/cards/investment_review_home_card.dart lib/pages/portfolio_dashboard_page.dart test/daily_investment_review_repository_test.dart test/daily_investment_review_presenter_test.dart test/widget_test.dart
```

- [ ] **Step 2: Analyze**

Run:

```bash
flutter analyze
```

Expected: no new analyzer errors.

- [ ] **Step 3: Run targeted tests**

Run:

```bash
flutter test test/daily_investment_review_repository_test.dart test/daily_investment_review_presenter_test.dart test/investment_review_snapshot_builder_test.dart test/investment_review_periods_test.dart test/investment_review_narrative_test.dart test/widget_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Run broader test suite**

Run:

```bash
flutter test
```

Expected: all tests pass. If the full suite cannot be completed in the current execution window, stop it cleanly and record the targeted test results plus the elapsed time before stopping.

- [ ] **Step 5: Inspect git diff**

Run:

```bash
git diff --stat
git diff --check
git status --short
```

Expected:

- No whitespace errors.
- Only planned files changed.
- Generated Drift file changed because of the new table.

- [ ] **Step 6: Final commit**

If any cleanup changes were needed:

```bash
git add .
git commit -m "chore: verify daily investment review workflow"
```

If no cleanup changes were needed, do not create an empty commit.
