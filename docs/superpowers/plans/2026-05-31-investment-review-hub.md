# Investment Review Hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-first Investment Review Hub that adds a home daily review card, an Analysis tab entry point, and a dedicated Today/Weekly/Monthly review screen.

**Architecture:** Add focused report domain files under `lib/services/investment_review/` for period resolution, snapshot models, local aggregation, deterministic Korean narrative, and opt-in AI state. UI consumes the report model through a dedicated page and reusable cards; routing exposes the page at `/analysis/investment-review` without changing the current Analysis page's top-level role.

**Tech Stack:** Flutter, Dart, Drift SQLite via existing `AppDatabase`, go_router, MONEYFY design system components, `flutter_test`.

---

## File Structure

- Create `lib/services/investment_review/investment_review_models.dart`
  - Defines period enum, report model, metrics, signals, narrative, AI state, and compact AI payload.
- Create `lib/services/investment_review/investment_review_periods.dart`
  - Resolves today, weekly, and monthly date ranges in one predictable place.
- Create `lib/services/investment_review/investment_review_snapshot_builder.dart`
  - Builds `InvestmentReviewReport` from existing local DB APIs.
- Create `lib/services/investment_review/investment_review_narrative_builder.dart`
  - Converts calculated signals into deterministic Korean copy.
- Create `lib/services/investment_review/investment_review_ai_coach.dart`
  - Provides AI off/on state and safe compact payload construction. First implementation does not call a remote endpoint.
- Create `lib/pages/investment_review_page.dart`
  - Dedicated review hub screen with Today/Weekly/Monthly segmented navigation.
- Create `lib/components/cards/investment_review_home_card.dart`
  - Compact home dashboard entry card.
- Modify `lib/navigation/moneyfy_routes.dart`
  - Add route name/path for `/analysis/investment-review`.
- Modify `lib/navigation/moneyfy_navigation.dart`
  - Add `openInvestmentReview()`.
- Modify `lib/navigation/moneyfy_router.dart`
  - Register the dedicated route.
- Modify `lib/pages/analysis_page.dart`
  - Add a top-level `투자 회고` entry card without replacing existing entries.
- Modify `lib/pages/portfolio_dashboard_page.dart`
  - Add the compact daily review card near the dashboard summary area.
- Create `test/investment_review_periods_test.dart`
  - Tests date range boundaries.
- Create `test/investment_review_narrative_test.dart`
  - Tests deterministic copy and low-data copy.
- Create `test/investment_review_snapshot_builder_test.dart`
  - Tests local report aggregation.
- Create `test/investment_review_ai_coach_test.dart`
  - Tests AI off default and compact payload safety.
- Modify `test/router_smoke_test.dart`
  - Tests direct route opening.
- Modify `test/widget_test.dart`
  - Adds widget tests for home card and review page states.

## Task 1: Period Model And Date Ranges

**Files:**
- Create: `lib/services/investment_review/investment_review_models.dart`
- Create: `lib/services/investment_review/investment_review_periods.dart`
- Create: `test/investment_review_periods_test.dart`

- [ ] **Step 1: Write the failing period tests**

Add this file:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';

void main() {
  group('InvestmentReviewPeriodResolver', () {
    test('resolves today as a single calendar day', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.today,
        now: DateTime(2026, 5, 31, 22, 15),
      );

      expect(range.type, InvestmentReviewPeriodType.today);
      expect(range.from, DateTime(2026, 5, 31));
      expect(range.to, DateTime(2026, 5, 31));
      expect(range.label, '오늘');
    });

    test('resolves weekly range from Monday through Sunday', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.weekly,
        now: DateTime(2026, 5, 31, 22, 15),
      );

      expect(range.type, InvestmentReviewPeriodType.weekly);
      expect(range.from, DateTime(2026, 5, 25));
      expect(range.to, DateTime(2026, 5, 31));
      expect(range.label, '이번 주');
    });

    test('resolves monthly range from first through last day', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.monthly,
        now: DateTime(2026, 5, 31, 22, 15),
      );

      expect(range.type, InvestmentReviewPeriodType.monthly);
      expect(range.from, DateTime(2026, 5, 1));
      expect(range.to, DateTime(2026, 5, 31));
      expect(range.label, '이번 달');
    });
  });
}
```

- [ ] **Step 2: Run the failing period tests**

Run:

```bash
flutter test test/investment_review_periods_test.dart
```

Expected: FAIL because `InvestmentReviewPeriodType` and `InvestmentReviewPeriodResolver` do not exist.

- [ ] **Step 3: Add report model primitives**

Create `lib/services/investment_review/investment_review_models.dart`:

```dart
enum InvestmentReviewPeriodType { today, weekly, monthly }

class InvestmentReviewPeriodRange {
  const InvestmentReviewPeriodRange({
    required this.type,
    required this.from,
    required this.to,
    required this.label,
  });

  final InvestmentReviewPeriodType type;
  final DateTime from;
  final DateTime to;
  final String label;
}

class InvestmentReviewMetric {
  const InvestmentReviewMetric({
    required this.label,
    required this.value,
    this.detail,
    this.isPositive,
  });

  final String label;
  final String value;
  final String? detail;
  final bool? isPositive;
}

class InvestmentReviewSignal {
  const InvestmentReviewSignal({
    required this.title,
    required this.description,
    this.severity = InvestmentReviewSignalSeverity.info,
  });

  final String title;
  final String description;
  final InvestmentReviewSignalSeverity severity;
}

enum InvestmentReviewSignalSeverity { info, warning, positive }

class InvestmentReviewNarrative {
  const InvestmentReviewNarrative({
    required this.headline,
    required this.summary,
    required this.nextActions,
  });

  final String headline;
  final String summary;
  final List<String> nextActions;
}

class InvestmentReviewAiState {
  const InvestmentReviewAiState.off()
      : enabled = false,
        commentary = null,
        errorMessage = null;

  const InvestmentReviewAiState.ready(this.commentary)
      : enabled = true,
        errorMessage = null;

  const InvestmentReviewAiState.failed(this.errorMessage)
      : enabled = true,
        commentary = null;

  final bool enabled;
  final String? commentary;
  final String? errorMessage;
}

class InvestmentReviewReport {
  const InvestmentReviewReport({
    required this.period,
    required this.metrics,
    required this.signals,
    required this.narrative,
    required this.aiState,
    required this.hasEnoughData,
    this.generatedAt,
  });

  final InvestmentReviewPeriodRange period;
  final List<InvestmentReviewMetric> metrics;
  final List<InvestmentReviewSignal> signals;
  final InvestmentReviewNarrative narrative;
  final InvestmentReviewAiState aiState;
  final bool hasEnoughData;
  final DateTime? generatedAt;
}

class InvestmentReviewAiPayload {
  const InvestmentReviewAiPayload({
    required this.periodLabel,
    required this.metrics,
    required this.signals,
    required this.nextActions,
  });

  final String periodLabel;
  final Map<String, String> metrics;
  final List<String> signals;
  final List<String> nextActions;

  Map<String, Object> toJson() {
    return {
      'periodLabel': periodLabel,
      'metrics': metrics,
      'signals': signals,
      'nextActions': nextActions,
    };
  }
}
```

- [ ] **Step 4: Add period resolver**

Create `lib/services/investment_review/investment_review_periods.dart`:

```dart
import 'investment_review_models.dart';

abstract final class InvestmentReviewPeriodResolver {
  static InvestmentReviewPeriodRange resolve(
    InvestmentReviewPeriodType type, {
    DateTime? now,
  }) {
    final base = _dateOnly(now ?? DateTime.now());
    return switch (type) {
      InvestmentReviewPeriodType.today => InvestmentReviewPeriodRange(
          type: type,
          from: base,
          to: base,
          label: '오늘',
        ),
      InvestmentReviewPeriodType.weekly => InvestmentReviewPeriodRange(
          type: type,
          from: base.subtract(Duration(days: base.weekday - 1)),
          to: base.add(Duration(days: DateTime.sunday - base.weekday)),
          label: '이번 주',
        ),
      InvestmentReviewPeriodType.monthly => InvestmentReviewPeriodRange(
          type: type,
          from: DateTime(base.year, base.month),
          to: DateTime(base.year, base.month + 1, 0),
          label: '이번 달',
        ),
    };
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
flutter test test/investment_review_periods_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/services/investment_review/investment_review_models.dart lib/services/investment_review/investment_review_periods.dart test/investment_review_periods_test.dart
git commit -m "feat: add investment review period model"
```

## Task 2: Deterministic Narrative Builder

**Files:**
- Create: `lib/services/investment_review/investment_review_narrative_builder.dart`
- Modify: `lib/services/investment_review/investment_review_models.dart`
- Create: `test/investment_review_narrative_test.dart`

- [ ] **Step 1: Write failing narrative tests**

Add this file:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_narrative_builder.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';

void main() {
  test('builds low-data copy without forcing interpretation', () {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.weekly,
      now: DateTime(2026, 5, 31),
    );

    final narrative = InvestmentReviewNarrativeBuilder.build(
      period: period,
      metrics: const [],
      signals: const [],
      hasEnoughData: false,
    );

    expect(narrative.headline, '이번 주 회고를 만들 기록이 더 필요해요.');
    expect(narrative.summary, contains('거래나 스냅샷 기록'));
    expect(narrative.nextActions, contains('거래와 스냅샷 기록을 먼저 쌓아보세요.'));
  });

  test('builds factual copy from positive and warning signals', () {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.monthly,
      now: DateTime(2026, 5, 31),
    );

    final narrative = InvestmentReviewNarrativeBuilder.build(
      period: period,
      metrics: const [
        InvestmentReviewMetric(
          label: '순 투자성과',
          value: '+120,000원',
          isPositive: true,
        ),
      ],
      signals: const [
        InvestmentReviewSignal(
          title: '성과 개선',
          description: '순 투자성과가 플러스입니다.',
          severity: InvestmentReviewSignalSeverity.positive,
        ),
        InvestmentReviewSignal(
          title: '비중 점검',
          description: '한 자산군 비중이 목표보다 높습니다.',
          severity: InvestmentReviewSignalSeverity.warning,
        ),
      ],
      hasEnoughData: true,
    );

    expect(narrative.headline, '이번 달에는 성과 개선이 가장 먼저 보여요.');
    expect(narrative.summary, contains('순 투자성과 +120,000원'));
    expect(narrative.summary, contains('비중 점검'));
    expect(narrative.nextActions.first, '비중 점검 항목을 확인해 보세요.');
  });
}
```

- [ ] **Step 2: Run the failing narrative tests**

Run:

```bash
flutter test test/investment_review_narrative_test.dart
```

Expected: FAIL because `InvestmentReviewNarrativeBuilder` does not exist.

- [ ] **Step 3: Add narrative builder**

Create `lib/services/investment_review/investment_review_narrative_builder.dart`:

```dart
import 'investment_review_models.dart';

abstract final class InvestmentReviewNarrativeBuilder {
  static InvestmentReviewNarrative build({
    required InvestmentReviewPeriodRange period,
    required List<InvestmentReviewMetric> metrics,
    required List<InvestmentReviewSignal> signals,
    required bool hasEnoughData,
  }) {
    if (!hasEnoughData) {
      return InvestmentReviewNarrative(
        headline: '${period.label} 회고를 만들 기록이 더 필요해요.',
        summary: '거래나 스냅샷 기록이 쌓이면 성과, 현금흐름, 판단 포인트를 함께 보여드릴게요.',
        nextActions: const ['거래와 스냅샷 기록을 먼저 쌓아보세요.'],
      );
    }

    final primarySignal = _primarySignal(signals);
    final primaryMetric = metrics.isEmpty ? null : metrics.first;
    final headline = primarySignal == null
        ? '${period.label} 회고에서 두드러진 변화는 아직 없어요.'
        : '${period.label}에는 ${primarySignal.title}이 가장 먼저 보여요.';

    final metricText = primaryMetric == null
        ? '대표 지표는 아직 계산되지 않았습니다.'
        : '${primaryMetric.label} ${primaryMetric.value}';
    final signalText = signals.isEmpty
        ? '추가 점검 신호는 없습니다.'
        : signals.map((signal) => signal.title).join(', ');

    return InvestmentReviewNarrative(
      headline: headline,
      summary: '$metricText 기준으로 확인했습니다. 주요 포인트는 $signalText입니다.',
      nextActions: _nextActions(signals),
    );
  }

  static InvestmentReviewSignal? _primarySignal(
    List<InvestmentReviewSignal> signals,
  ) {
    if (signals.isEmpty) return null;
    final positive = signals.where(
      (signal) => signal.severity == InvestmentReviewSignalSeverity.positive,
    );
    if (positive.isNotEmpty) return positive.first;
    return signals.first;
  }

  static List<String> _nextActions(List<InvestmentReviewSignal> signals) {
    final warning = signals.where(
      (signal) => signal.severity == InvestmentReviewSignalSeverity.warning,
    );
    if (warning.isNotEmpty) {
      return ['${warning.first.title} 항목을 확인해 보세요.'];
    }
    if (signals.isNotEmpty) {
      return ['${signals.first.title} 내용을 기준으로 다음 거래 전 한 번 더 점검해 보세요.'];
    }
    return const ['다음 거래 전 목표 비중과 현금흐름을 함께 확인해 보세요.'];
  }
}
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
flutter test test/investment_review_narrative_test.dart test/investment_review_periods_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/services/investment_review/investment_review_narrative_builder.dart test/investment_review_narrative_test.dart
git commit -m "feat: add investment review narrative builder"
```

## Task 3: Local Snapshot Builder

**Files:**
- Create: `lib/services/investment_review/investment_review_snapshot_builder.dart`
- Modify: `lib/services/investment_review/investment_review_models.dart`
- Modify: `lib/db/app_database.dart`
- Modify: `lib/db/app_database_records.dart`
- Create: `test/investment_review_snapshot_builder_test.dart`

- [ ] **Step 1: Write failing builder tests**

Add this file:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_snapshot_builder.dart';

void main() {
  group('InvestmentReviewSnapshotBuilder', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns low-data report when portfolio has no activity', () async {
      final builder = InvestmentReviewSnapshotBuilder(database: db);

      final report = await builder.build(
        InvestmentReviewPeriodType.today,
        now: DateTime(2026, 5, 31),
      );

      expect(report.hasEnoughData, isFalse);
      expect(report.period.label, '오늘');
      expect(report.metrics, isEmpty);
      expect(report.narrative.headline, '오늘 회고를 만들 기록이 더 필요해요.');
      expect(report.aiState.enabled, isFalse);
    });

    test('summarizes local ledger performance and activity', () async {
      final assetId = await db.createAsset(
        assetType: '주식',
        title: '국내주식',
        alias: '국내주식',
        hidden: false,
        currencyCode: 'KRW',
        value: '0',
        change: '+0.0%',
        icon: Icons.account_balance_wallet_rounded,
        quantityLabel: '항목',
        quantityValue: '0개',
        averageLabel: '수익률',
        averageValue: '+0.0%',
        note: '',
      );
      final holdingId = await db.createHolding(
        assetId: assetId,
        currencyCode: 'KRW',
        exchangeCode: 'KRX',
        name: '테스트전자',
        symbol: 'TEST',
        quantity: 0,
        averagePrice: 0,
        currentPrice: 120,
        note: '',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.26',
        type: '매수',
        name: '테스트전자 매수',
        amount: '1000',
        quantity: '10',
      );
      await db.createTransaction(
        assetId: assetId,
        holdingId: holdingId,
        date: '2026.05.29',
        type: '매도',
        name: '테스트전자 매도',
        amount: '600',
        quantity: '5',
        manualRealizedProfitAmount: 100,
      );

      final builder = InvestmentReviewSnapshotBuilder(database: db);
      final report = await builder.build(
        InvestmentReviewPeriodType.weekly,
        now: DateTime(2026, 5, 31),
      );

      expect(report.hasEnoughData, isTrue);
      expect(report.period.label, '이번 주');
      expect(report.metrics.map((metric) => metric.label), contains('순 투자성과'));
      expect(report.metrics.map((metric) => metric.label), contains('거래 활동'));
      expect(
        report.signals.map((signal) => signal.title),
        contains('거래 판단 복기'),
      );
      expect(report.narrative.headline, contains('이번 주'));
    });
  });
}
```

- [ ] **Step 2: Run failing builder tests**

Run:

```bash
flutter test test/investment_review_snapshot_builder_test.dart
```

Expected: FAIL because `InvestmentReviewSnapshotBuilder` does not exist.

- [ ] **Step 3: Add compact activity fields to models**

Append this class to `lib/services/investment_review/investment_review_models.dart` before `InvestmentReviewReport`:

```dart
class InvestmentReviewActivitySummary {
  const InvestmentReviewActivitySummary({
    required this.buyCount,
    required this.sellCount,
    required this.incomeCount,
    required this.cashFlowCount,
  });

  final int buyCount;
  final int sellCount;
  final int incomeCount;
  final int cashFlowCount;

  int get totalCount => buyCount + sellCount + incomeCount + cashFlowCount;
}
```

Then add this field to `InvestmentReviewReport`:

```dart
final InvestmentReviewActivitySummary activity;
```

Update the constructor with:

```dart
required this.activity,
```

- [ ] **Step 4: Add ledger activity counts to the existing performance record**

In `lib/db/app_database_records.dart`, update `LedgerPortfolioPerformanceRecord` constructor:

```dart
const LedgerPortfolioPerformanceRecord({
  this.currencyCode,
  required this.realizedPnl,
  required this.incomeAmount,
  required this.feeAmount,
  required this.taxAmount,
  required this.externalCashFlowAmount,
  this.externalDepositAmount = 0,
  this.externalWithdrawalAmount = 0,
  required this.tradeSettlementCashFlowAmount,
  required this.internalCashMovementAmount,
  required this.buyAmount,
  required this.sellAmount,
  this.buyCount = 0,
  this.sellCount = 0,
  this.incomeCount = 0,
  this.cashFlowCount = 0,
});
```

Add fields after `sellAmount`:

```dart
final int buyCount;
final int sellCount;
final int incomeCount;
final int cashFlowCount;
```

In `lib/db/app_database.dart`, add these selected columns to `fetchLedgerPortfolioPerformance()`:

```sql
          COALESCE(SUM(CASE WHEN action = 'buy' THEN 1 ELSE 0 END), 0) AS buy_count,
          COALESCE(SUM(CASE WHEN action = 'sell' THEN 1 ELSE 0 END), 0) AS sell_count,
          COALESCE(SUM(CASE WHEN action IN ('dividend', 'interest') THEN 1 ELSE 0 END), 0) AS income_count,
          COALESCE(SUM(CASE WHEN action IN ('deposit', 'withdrawal', 'opening_cash', 'transfer_out', 'transfer_in', 'fx_out', 'fx_in') THEN 1 ELSE 0 END), 0) AS cash_flow_count
```

Place them immediately after:

```sql
          COALESCE(SUM(CASE WHEN action = 'sell' THEN gross_amount ELSE 0 END), 0) AS sell_amount
```

Add a comma after `sell_amount` before appending the count columns.

Pass the fields into the returned record:

```dart
buyCount: row.read<int>('buy_count'),
sellCount: row.read<int>('sell_count'),
incomeCount: row.read<int>('income_count'),
cashFlowCount: row.read<int>('cash_flow_count'),
```

In `fetchLedgerPortfolioPerformanceByCurrency()`, add the same selected count columns and pass the same four constructor arguments. These default to zero for older constructor callers, but both portfolio performance query paths should expose consistent activity data.

- [ ] **Step 5: Add snapshot builder**

Create `lib/services/investment_review/investment_review_snapshot_builder.dart`:

```dart
import '../../db/app_database.dart';
import '../../utils/display_currency.dart';
import 'investment_review_models.dart';
import 'investment_review_narrative_builder.dart';
import 'investment_review_periods.dart';

class InvestmentReviewSnapshotBuilder {
  const InvestmentReviewSnapshotBuilder({required AppDatabase database})
      : _database = database;

  final AppDatabase _database;

  Future<InvestmentReviewReport> build(
    InvestmentReviewPeriodType type, {
    DateTime? now,
  }) async {
    final period = InvestmentReviewPeriodResolver.resolve(type, now: now);
    final performance = await _database.fetchLedgerPortfolioPerformance(
      from: period.from,
      to: period.to,
    );
    final activity = InvestmentReviewActivitySummary(
      buyCount: performance.buyCount,
      sellCount: performance.sellCount,
      incomeCount: performance.incomeCount,
      cashFlowCount: performance.cashFlowCount,
    );
    final hasEnoughData =
        activity.totalCount > 0 || performance.pureRealizedPerformance != 0;
    final metrics = hasEnoughData
        ? _metrics(performance: performance, activity: activity)
        : const <InvestmentReviewMetric>[];
    final signals = hasEnoughData
        ? _signals(performance: performance, activity: activity)
        : const <InvestmentReviewSignal>[];
    final narrative = InvestmentReviewNarrativeBuilder.build(
      period: period,
      metrics: metrics,
      signals: signals,
      hasEnoughData: hasEnoughData,
    );

    return InvestmentReviewReport(
      period: period,
      metrics: metrics,
      signals: signals,
      narrative: narrative,
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: hasEnoughData,
      activity: activity,
      generatedAt: now ?? DateTime.now(),
    );
  }

  List<InvestmentReviewMetric> _metrics({
    required LedgerPortfolioPerformanceRecord performance,
    required InvestmentReviewActivitySummary activity,
  }) {
    return [
      InvestmentReviewMetric(
        label: '순 투자성과',
        value: MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(
          performance.pureRealizedPerformance,
        ),
        isPositive: performance.pureRealizedPerformance >= 0,
      ),
      InvestmentReviewMetric(
        label: '실현손익',
        value: MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(
          performance.realizedPnl,
        ),
        isPositive: performance.realizedPnl >= 0,
      ),
      InvestmentReviewMetric(
        label: '배당/이자',
        value: MoneyfyDisplayCurrencySettings.formatSignedAmountFromKrw(
          performance.incomeAmount,
        ),
        isPositive: performance.incomeAmount >= 0,
      ),
      InvestmentReviewMetric(
        label: '거래 활동',
        value: '${activity.totalCount}건',
        detail: '매수 ${activity.buyCount} · 매도 ${activity.sellCount}',
      ),
    ];
  }

  List<InvestmentReviewSignal> _signals({
    required LedgerPortfolioPerformanceRecord performance,
    required InvestmentReviewActivitySummary activity,
  }) {
    final signals = <InvestmentReviewSignal>[];
    if (performance.pureRealizedPerformance > 0) {
      signals.add(
        const InvestmentReviewSignal(
          title: '성과 개선',
          description: '기간 중 순 투자성과가 플러스입니다.',
          severity: InvestmentReviewSignalSeverity.positive,
        ),
      );
    } else if (performance.pureRealizedPerformance < 0) {
      signals.add(
        const InvestmentReviewSignal(
          title: '성과 압박',
          description: '기간 중 순 투자성과가 마이너스입니다.',
          severity: InvestmentReviewSignalSeverity.warning,
        ),
      );
    }
    if (activity.buyCount + activity.sellCount > 0) {
      signals.add(
        InvestmentReviewSignal(
          title: '거래 판단 복기',
          description:
              '매수 ${activity.buyCount}건, 매도 ${activity.sellCount}건이 포트폴리오에 반영됐습니다.',
        ),
      );
    }
    if (activity.incomeCount > 0) {
      signals.add(
        InvestmentReviewSignal(
          title: '수입 흐름',
          description: '배당/이자 기록 ${activity.incomeCount}건이 있습니다.',
          severity: InvestmentReviewSignalSeverity.positive,
        ),
      );
    }
    return signals;
  }
}
```

- [ ] **Step 6: Run builder tests and commit**

Run:

```bash
flutter test test/investment_review_snapshot_builder_test.dart test/investment_review_narrative_test.dart test/investment_review_periods_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/services/investment_review/investment_review_models.dart lib/services/investment_review/investment_review_snapshot_builder.dart lib/db/app_database.dart lib/db/app_database_records.dart test/investment_review_snapshot_builder_test.dart
git commit -m "feat: build local investment review reports"
```

## Task 4: Safe AI Coach State And Payload

**Files:**
- Create: `lib/services/investment_review/investment_review_ai_coach.dart`
- Create: `test/investment_review_ai_coach_test.dart`

- [ ] **Step 1: Write failing AI payload tests**

Add this file:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_review/investment_review_ai_coach.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';

void main() {
  test('AI coach is disabled by default', () {
    const coach = InvestmentReviewAiCoach();

    expect(coach.isEnabled, isFalse);
  });

  test('builds compact payload without raw ledger or account identifiers', () {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.monthly,
      now: DateTime(2026, 5, 31),
    );
    final report = InvestmentReviewReport(
      period: period,
      metrics: const [
        InvestmentReviewMetric(label: '순 투자성과', value: '+120,000원'),
      ],
      signals: const [
        InvestmentReviewSignal(
          title: '거래 판단 복기',
          description: '매수 1건, 매도 1건이 반영됐습니다.',
        ),
      ],
      narrative: const InvestmentReviewNarrative(
        headline: '이번 달에는 성과 개선이 보입니다.',
        summary: '순 투자성과 +120,000원 기준으로 확인했습니다.',
        nextActions: ['비중 점검 항목을 확인해 보세요.'],
      ),
      aiState: const InvestmentReviewAiState.off(),
      hasEnoughData: true,
      activity: const InvestmentReviewActivitySummary(
        buyCount: 1,
        sellCount: 1,
        incomeCount: 0,
        cashFlowCount: 0,
      ),
    );

    final payload = InvestmentReviewAiCoach.buildPayload(report);
    final json = payload.toJson();

    expect(json.keys, isNot(contains('transactions')));
    expect(json.keys, isNot(contains('userId')));
    expect(json.keys, isNot(contains('email')));
    expect(json.keys, isNot(contains('accountId')));
    expect(json['periodLabel'], '이번 달');
    expect((json['metrics'] as Map<String, String>)['순 투자성과'], '+120,000원');
  });
}
```

- [ ] **Step 2: Run failing AI tests**

Run:

```bash
flutter test test/investment_review_ai_coach_test.dart
```

Expected: FAIL because `InvestmentReviewAiCoach` does not exist.

- [ ] **Step 3: Add AI coach service stub**

Create `lib/services/investment_review/investment_review_ai_coach.dart`:

```dart
import 'investment_review_models.dart';

class InvestmentReviewAiCoach {
  const InvestmentReviewAiCoach({this.isEnabled = false});

  final bool isEnabled;

  static InvestmentReviewAiPayload buildPayload(InvestmentReviewReport report) {
    return InvestmentReviewAiPayload(
      periodLabel: report.period.label,
      metrics: {
        for (final metric in report.metrics) metric.label: metric.value,
      },
      signals: report.signals.map((signal) => signal.title).toList(),
      nextActions: report.narrative.nextActions,
    );
  }

  Future<InvestmentReviewAiState> explain(InvestmentReviewReport report) async {
    if (!isEnabled) {
      return const InvestmentReviewAiState.off();
    }
    final payload = buildPayload(report);
    final metricCount = payload.metrics.length;
    return InvestmentReviewAiState.ready(
      'AI 코치가 켜져 있습니다. 현재는 ${report.period.label} 요약 지표 $metricCount개를 기준으로 보강할 준비가 되어 있어요.',
    );
  }
}
```

- [ ] **Step 4: Run tests and commit**

Run:

```bash
flutter test test/investment_review_ai_coach_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/services/investment_review/investment_review_ai_coach.dart test/investment_review_ai_coach_test.dart
git commit -m "feat: add safe investment review ai coach payload"
```

## Task 5: Dedicated Investment Review Page

**Files:**
- Create: `lib/pages/investment_review_page.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing page widget tests**

Append these tests to `test/widget_test.dart`:

```dart
  testWidgets('investment review page shows period segments and low-data state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InvestmentReviewPage(
          reportBuilderForTesting: (type) async {
            final period = InvestmentReviewPeriodResolver.resolve(
              type,
              now: DateTime(2026, 5, 31),
            );
            return InvestmentReviewReport(
              period: period,
              metrics: const [],
              signals: const [],
              narrative: InvestmentReviewNarrative(
                headline: '${period.label} 회고를 만들 기록이 더 필요해요.',
                summary: '거래나 스냅샷 기록이 쌓이면 보여드릴게요.',
                nextActions: const ['거래와 스냅샷 기록을 먼저 쌓아보세요.'],
              ),
              aiState: const InvestmentReviewAiState.off(),
              hasEnoughData: false,
              activity: const InvestmentReviewActivitySummary(
                buyCount: 0,
                sellCount: 0,
                incomeCount: 0,
                cashFlowCount: 0,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('투자 회고'), findsOneWidget);
    expect(find.text('오늘'), findsWidgets);
    expect(find.text('주간'), findsWidgets);
    expect(find.text('월간'), findsWidgets);
    expect(find.text('오늘 회고를 만들 기록이 더 필요해요.'), findsOneWidget);
  });
```

Also add these imports at the top of `test/widget_test.dart`:

```dart
import 'package:moneyfy/pages/investment_review_page.dart';
import 'package:moneyfy/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/services/investment_review/investment_review_periods.dart';
```

- [ ] **Step 2: Run failing page test**

Run:

```bash
flutter test test/widget_test.dart --plain-name "investment review page shows period segments and low-data state"
```

Expected: FAIL because `InvestmentReviewPage` does not exist.

- [ ] **Step 3: Add dedicated page**

Create `lib/pages/investment_review_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../components/section_card.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../services/investment_review/investment_review_models.dart';
import '../services/investment_review/investment_review_snapshot_builder.dart';
import '../widgets/moneyfy_ui.dart';

typedef InvestmentReviewReportLoader = Future<InvestmentReviewReport> Function(
  InvestmentReviewPeriodType type,
);

class InvestmentReviewPage extends StatefulWidget {
  const InvestmentReviewPage({super.key, this.reportBuilderForTesting});

  final InvestmentReviewReportLoader? reportBuilderForTesting;

  @override
  State<InvestmentReviewPage> createState() => _InvestmentReviewPageState();
}

class _InvestmentReviewPageState extends State<InvestmentReviewPage> {
  var _selected = InvestmentReviewPeriodType.today;

  Future<InvestmentReviewReport> _loadReport() {
    final loader = widget.reportBuilderForTesting;
    if (loader != null) {
      return loader(_selected);
    }
    return InvestmentReviewSnapshotBuilder(database: AppDatabase.instance)
        .build(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return MoneyfyPage(
      title: '투자 회고',
      children: [
        SegmentedButton<InvestmentReviewPeriodType>(
          segments: const [
            ButtonSegment(
              value: InvestmentReviewPeriodType.today,
              label: Text('오늘'),
            ),
            ButtonSegment(
              value: InvestmentReviewPeriodType.weekly,
              label: Text('주간'),
            ),
            ButtonSegment(
              value: InvestmentReviewPeriodType.monthly,
              label: Text('월간'),
            ),
          ],
          selected: {_selected},
          onSelectionChanged: (selection) {
            setState(() {
              _selected = selection.single;
            });
          },
        ),
        SizedBox(height: context.spacing.sectionGap),
        FutureBuilder<InvestmentReviewReport>(
          future: _loadReport(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _InvestmentReviewReportView(report: snapshot.data!);
          },
        ),
      ],
    );
  }
}

class _InvestmentReviewReportView extends StatelessWidget {
  const _InvestmentReviewReportView({required this.report});

  final InvestmentReviewReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.narrative.headline, style: context.typography.cardTitle),
              SizedBox(height: context.spacing.xs),
              Text(report.narrative.summary),
            ],
          ),
        ),
        SizedBox(height: context.spacing.sm),
        if (report.metrics.isNotEmpty)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('핵심 지표', style: context.typography.cardTitle),
                SizedBox(height: context.spacing.xs),
                for (final metric in report.metrics)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.spacing.xs),
                    child: Text('${metric.label}: ${metric.value}'),
                  ),
              ],
            ),
          ),
        if (report.signals.isNotEmpty) SizedBox(height: context.spacing.sm),
        if (report.signals.isNotEmpty)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('판단 피드백', style: context.typography.cardTitle),
                SizedBox(height: context.spacing.xs),
                for (final signal in report.signals)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.spacing.xs),
                    child: Text('${signal.title}: ${signal.description}'),
                  ),
              ],
            ),
          ),
        SizedBox(height: context.spacing.sm),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('다음 액션', style: context.typography.cardTitle),
              SizedBox(height: context.spacing.xs),
              for (final action in report.narrative.nextActions) Text(action),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run page test and commit**

Run:

```bash
flutter test test/widget_test.dart --plain-name "investment review page shows period segments and low-data state"
```

Expected: PASS.

Commit:

```bash
git add lib/pages/investment_review_page.dart test/widget_test.dart
git commit -m "feat: add investment review page"
```

## Task 6: Routing And Analysis Entry

**Files:**
- Modify: `lib/navigation/moneyfy_routes.dart`
- Modify: `lib/navigation/moneyfy_navigation.dart`
- Modify: `lib/navigation/moneyfy_router.dart`
- Modify: `lib/pages/analysis_page.dart`
- Modify: `test/router_smoke_test.dart`

- [ ] **Step 1: Write failing router and Analysis entry tests**

In `test/router_smoke_test.dart`, add this import:

```dart
import 'package:moneyfy/pages/investment_review_page.dart';
```

Add this test after `opens analysis detail route`:

```dart
  testWidgets('opens investment review route', (tester) async {
    await pumpRouter(
      tester,
      initialLocation: MoneyfyRoutePaths.investmentReview,
    );

    expect(find.byType(InvestmentReviewPage), findsOneWidget);
    expect(find.text('투자 회고'), findsOneWidget);
  });
```

Add this assertion to the existing `opens shell route /analysis` case by changing the route case to expect the page text `투자 회고`:

```dart
_ShellRouteCase(MoneyfyRoutePaths.analysis, '분석', '투자 회고'),
```

- [ ] **Step 2: Run failing router tests**

Run:

```bash
flutter test test/router_smoke_test.dart --plain-name "opens investment review route"
```

Expected: FAIL because `MoneyfyRoutePaths.investmentReview` does not exist.

- [ ] **Step 3: Add route constants and navigation extension**

In `lib/navigation/moneyfy_routes.dart`, add:

```dart
static const investmentReview = 'investmentReview';
```

near other analysis detail route names, and add:

```dart
static const investmentReview = '/analysis/investment-review';
```

near other analysis detail route paths.

In `lib/navigation/moneyfy_navigation.dart`, import `InvestmentReviewPage`:

```dart
import '../pages/investment_review_page.dart';
```

Add this method before `openPortfolioDiagnosis()`:

```dart
Future<void> openInvestmentReview() {
  if (!_hasRouter) {
    return Navigator.of(this).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: MoneyfyRoutePaths.investmentReview,
        ),
        builder: (_) => const InvestmentReviewPage(),
      ),
    );
  }
  return push<void>(MoneyfyRoutePaths.investmentReview);
}
```

- [ ] **Step 4: Register router route**

In `lib/navigation/moneyfy_router.dart`, import:

```dart
import '../pages/investment_review_page.dart';
```

Add this `GoRoute` before the portfolio diagnosis route:

```dart
GoRoute(
  path: MoneyfyRoutePaths.investmentReview,
  name: MoneyfyRouteNames.investmentReview,
  builder: (context, state) => const InvestmentReviewPage(),
),
```

- [ ] **Step 5: Add Analysis page entry**

In `lib/pages/analysis_page.dart`, add this entry before `포트폴리오 진단`:

```dart
_AnalysisEntryCard(
  icon: Icons.rate_review_rounded,
  title: '투자 회고',
  onTap: context.openInvestmentReview,
),
SizedBox(height: context.spacing.sm),
```

- [ ] **Step 6: Run routing tests and commit**

Run:

```bash
flutter test test/router_smoke_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/navigation/moneyfy_routes.dart lib/navigation/moneyfy_navigation.dart lib/navigation/moneyfy_router.dart lib/pages/analysis_page.dart test/router_smoke_test.dart
git commit -m "feat: route investment review hub"
```

## Task 7: Home Dashboard Review Card

**Files:**
- Create: `lib/components/cards/investment_review_home_card.dart`
- Modify: `lib/pages/portfolio_dashboard_page.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing home card widget test**

Add this import to `test/widget_test.dart`:

```dart
import 'package:moneyfy/components/cards/investment_review_home_card.dart';
```

Append this test:

```dart
  testWidgets('investment review home card shows headline and action', (
    tester,
  ) async {
    final period = InvestmentReviewPeriodResolver.resolve(
      InvestmentReviewPeriodType.today,
      now: DateTime(2026, 5, 31),
    );
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: InvestmentReviewHomeCard(
            report: InvestmentReviewReport(
              period: period,
              metrics: const [
                InvestmentReviewMetric(label: '순 투자성과', value: '+10,000원'),
              ],
              signals: const [],
              narrative: const InvestmentReviewNarrative(
                headline: '오늘은 성과 개선이 보여요.',
                summary: '순 투자성과 +10,000원 기준으로 확인했습니다.',
                nextActions: ['비중을 확인해 보세요.'],
              ),
              aiState: const InvestmentReviewAiState.off(),
              hasEnoughData: true,
              activity: const InvestmentReviewActivitySummary(
                buyCount: 0,
                sellCount: 0,
                incomeCount: 0,
                cashFlowCount: 0,
              ),
            ),
            onOpen: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('오늘의 투자 회고'), findsOneWidget);
    expect(find.text('오늘은 성과 개선이 보여요.'), findsOneWidget);
    await tester.tap(find.text('자세히 보기'));
    expect(tapped, isTrue);
  });
```

- [ ] **Step 2: Run failing home card test**

Run:

```bash
flutter test test/widget_test.dart --plain-name "investment review home card shows headline and action"
```

Expected: FAIL because `InvestmentReviewHomeCard` does not exist.

- [ ] **Step 3: Add home card component**

Create `lib/components/cards/investment_review_home_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../design_system/context_extensions.dart';
import '../../services/investment_review/investment_review_models.dart';
import '../section_card.dart';

class InvestmentReviewHomeCard extends StatelessWidget {
  const InvestmentReviewHomeCard({
    super.key,
    required this.report,
    required this.onOpen,
  });

  final InvestmentReviewReport report;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘의 투자 회고', style: context.typography.cardTitle),
          SizedBox(height: context.spacing.xs),
          Text(report.narrative.headline),
          SizedBox(height: context.spacing.sm),
          for (final action in report.narrative.nextActions.take(3))
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing.xs / 2),
              child: Text(action),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('자세히 보기'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add card to dashboard**

In `lib/pages/portfolio_dashboard_page.dart`, import:

```dart
import '../components/cards/investment_review_home_card.dart';
import '../services/investment_review/investment_review_models.dart';
import '../services/investment_review/investment_review_snapshot_builder.dart';
```

Add a private method to the dashboard state class:

```dart
Future<InvestmentReviewReport> _loadTodayReview() {
  return InvestmentReviewSnapshotBuilder(database: AppDatabase.instance)
      .build(InvestmentReviewPeriodType.today);
}
```

Place this FutureBuilder near the existing summary section, before dense lists of assets:

```dart
FutureBuilder<InvestmentReviewReport>(
  future: _loadTodayReview(),
  builder: (context, snapshot) {
    final report = snapshot.data;
    if (report == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sectionGap),
      child: InvestmentReviewHomeCard(
        report: report,
        onOpen: context.openInvestmentReview,
      ),
    );
  },
),
```

If `portfolio_dashboard_page.dart` already has a single loaded dashboard future, fold `_loadTodayReview()` into that future instead of creating a repeated FutureBuilder rebuild loop. The acceptance condition is that the card is loaded once per page refresh, not on every widget rebuild.

- [ ] **Step 5: Run home card tests and commit**

Run:

```bash
flutter test test/widget_test.dart --plain-name "investment review home card shows headline and action"
flutter analyze lib/components/cards/investment_review_home_card.dart lib/pages/portfolio_dashboard_page.dart
```

Expected: PASS for widget test and no analyzer issues.

Commit:

```bash
git add lib/components/cards/investment_review_home_card.dart lib/pages/portfolio_dashboard_page.dart test/widget_test.dart
git commit -m "feat: add daily investment review home card"
```

## Task 8: Final Verification And Documentation

**Files:**
- Modify: `docs/superpowers/specs/2026-05-31-investment-review-hub-design.md` if implementation decisions differ from the spec.
- Create: `docs/features/new_feature_development/investment_review_hub/implementation_report_20260531.md`

- [ ] **Step 1: Run targeted tests**

Run:

```bash
flutter test test/investment_review_periods_test.dart test/investment_review_narrative_test.dart test/investment_review_snapshot_builder_test.dart test/investment_review_ai_coach_test.dart test/router_smoke_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run broader smoke tests**

Run:

```bash
flutter test test/widget_test.dart test/page_walkthrough_test.dart test/transaction_flow_test.dart
```

Expected: PASS. If an existing unrelated failure appears, capture the exact failing test name and stack trace in the implementation report.

- [ ] **Step 3: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: No issues. If existing unrelated analyzer issues appear, capture them in the implementation report and verify the new files with narrower analyzer commands.

- [ ] **Step 4: Write implementation report**

Create `docs/features/new_feature_development/investment_review_hub/implementation_report_20260531.md`:

```markdown
# Investment Review Hub Implementation Report

Date: 2026-05-31

## Summary

Implemented the local-first Investment Review Hub with a home daily review card, Analysis tab entry point, dedicated Today/Weekly/Monthly review page, deterministic narrative builder, and safe AI Coach payload stub.

## Implemented Scope

- Added investment review period model and date range resolver.
- Added local report snapshot builder using existing Drift ledger performance APIs.
- Added deterministic Korean narrative generation.
- Added AI Coach off-by-default payload builder without remote calls.
- Added dedicated `/analysis/investment-review` route.
- Added `투자 회고` entry in the Analysis page.
- Added home `오늘의 투자 회고` card.

## Verification

| Command | Result |
| --- | --- |
| `flutter test test/investment_review_periods_test.dart test/investment_review_narrative_test.dart test/investment_review_snapshot_builder_test.dart test/investment_review_ai_coach_test.dart test/router_smoke_test.dart` | PASS |
| `flutter test test/widget_test.dart test/page_walkthrough_test.dart test/transaction_flow_test.dart` | PASS |
| `flutter analyze` | PASS |

## Notes

- AI Coach does not call a remote endpoint in this implementation.
- The Analysis page remains a top-level entry hub; Investment Review Hub is a separate feature route.
- Report caching was not added because the first implementation computes from local data on demand.
```

- [ ] **Step 5: Commit verification docs**

Run:

```bash
git add docs/features/new_feature_development/investment_review_hub/implementation_report_20260531.md docs/superpowers/specs/2026-05-31-investment-review-hub-design.md
git commit -m "docs: report investment review hub implementation"
```

Expected: commit succeeds.

## Self-Review

- Spec coverage: The plan covers home entry, Analysis entry, dedicated hub, Today/Weekly/Monthly reports, local-first deterministic reports, AI off-by-default payload safety, low-data states, routing, tests, and implementation reporting.
- Scope check: The plan does not implement remote AI calls, manual journaling, dashboard redesign, or replacement of the existing Analysis page.
- Type consistency: The same `InvestmentReviewPeriodType`, `InvestmentReviewReport`, `InvestmentReviewActivitySummary`, `InvestmentReviewNarrativeBuilder`, and `InvestmentReviewSnapshotBuilder` names are used across tasks.
- Placeholder scan: This plan intentionally excludes vague future work from implementation steps and gives exact test names, files, snippets, commands, and expected results.
