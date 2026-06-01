# Investment Performance Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the investment performance page around a first-viewport scoreboard that lets users quickly judge whether the selected period's investment performance is good or bad.

**Architecture:** Keep the existing report loader and calculation pipeline in `InvestmentPerformancePage`. Extract a small pure judgment model for tested status mapping, then wire those display fields into a redesigned scoreboard header and evidence cards inside the existing page.

**Tech Stack:** Flutter, Dart, existing Moneyfy UI primitives, `flutter_test`.

---

## File Structure

- Create: `lib/services/investment_performance/performance_judgment.dart`
  - Pure display model for performance, benchmark, and risk judgment states.
  - No Flutter imports.
- Create: `test/investment_performance_judgment_test.dart`
  - Unit tests for judgment status mapping and unavailable reasons.
- Modify: `lib/pages/investment_performance_page.dart`
  - Import the pure judgment model.
  - Add judgment fields to `_InvestmentPerformanceViewModel`.
  - Replace the current top judgment header with a scoreboard header.
  - Reframe attribution, benchmark, risk, and data basis copy around evidence for the scoreboard.
- Modify: `test/page_walkthrough_test.dart` or `test/ui_component_smoke_test.dart`
  - Add a smoke assertion that `InvestmentPerformancePage` renders the scoreboard labels without throwing.

## Spec Component Mapping

- `PerformanceScoreboardHeader` maps to `_PerformanceScoreboardHeader` in `lib/pages/investment_performance_page.dart`.
- `BenchmarkComparisonCard` maps to `_BenchmarkSnapshotStrip` and the benchmark slots in `_PerformanceScoreboardHeader`.
- `PerformanceCompositionCard` maps to `_PerformanceAttributionCard`.
- `MonthlySignalCard` maps to `_MonthlyTrendCard`.
- `HoldingImpactCard` maps to `_HoldingContributionCard`.
- `RiskSignalCard` maps to `_RiskInterpretationCard`.
- `DataConfidenceCard` maps to `_DataBasisCard`.

## Task 1: Add Pure Judgment Model

**Files:**
- Create: `lib/services/investment_performance/performance_judgment.dart`
- Create: `test/investment_performance_judgment_test.dart`

- [ ] **Step 1: Write the failing judgment tests**

Add this file:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/investment_performance/performance_judgment.dart';

void main() {
  group('resolvePerformanceJudgment', () {
    test('marks positive return and positive benchmark delta as good', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 420000,
        periodReturn: 0.032,
        benchmarkDelta: 0.011,
        volatility: 0.12,
        maxDrawdown: -0.035,
        dailyReturnCount: 35,
      );

      expect(judgment.performanceStatus, PerformanceStatus.good);
      expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.outperforming);
      expect(judgment.riskStatus, RiskStatus.normal);
      expect(judgment.headlineReason, contains('벤치마크'));
    });

    test('marks positive return with negative benchmark delta as neutral', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 120000,
        periodReturn: 0.018,
        benchmarkDelta: -0.012,
        volatility: 0.10,
        maxDrawdown: -0.025,
        dailyReturnCount: 30,
      );

      expect(judgment.performanceStatus, PerformanceStatus.neutral);
      expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.lagging);
      expect(judgment.headlineReason, contains('시장 대비'));
    });

    test('marks negative return as caution', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: -80000,
        periodReturn: -0.015,
        benchmarkDelta: 0.004,
        volatility: 0.08,
        maxDrawdown: -0.02,
        dailyReturnCount: 28,
      );

      expect(judgment.performanceStatus, PerformanceStatus.caution);
      expect(judgment.headlineReason, contains('손실'));
    });

    test('keeps performance available when benchmark is missing', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: null,
        volatility: 0.09,
        maxDrawdown: -0.02,
        dailyReturnCount: 24,
      );

      expect(judgment.performanceStatus, PerformanceStatus.good);
      expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.unavailable);
      expect(judgment.unavailableReasons, contains('benchmark'));
    });

    test('marks risk unavailable when daily returns are insufficient', () {
      final judgment = resolvePerformanceJudgment(
        netPerformance: 90000,
        periodReturn: 0.012,
        benchmarkDelta: 0.001,
        volatility: null,
        maxDrawdown: null,
        dailyReturnCount: 3,
      );

      expect(judgment.riskStatus, RiskStatus.unavailable);
      expect(judgment.unavailableReasons, contains('risk'));
    });
  });
}
```

- [ ] **Step 2: Run the failing tests**

Run:

```bash
flutter test test/investment_performance_judgment_test.dart
```

Expected: fail because `performance_judgment.dart` does not exist.

- [ ] **Step 3: Implement the pure model**

Create `lib/services/investment_performance/performance_judgment.dart`:

```dart
enum PerformanceStatus { good, neutral, caution, unavailable }

enum BenchmarkDeltaStatus { outperforming, similar, lagging, unavailable }

enum RiskStatus { low, normal, elevated, unavailable }

class PerformanceJudgment {
  const PerformanceJudgment({
    required this.performanceStatus,
    required this.benchmarkDeltaStatus,
    required this.riskStatus,
    required this.headlineReason,
    required this.unavailableReasons,
  });

  final PerformanceStatus performanceStatus;
  final BenchmarkDeltaStatus benchmarkDeltaStatus;
  final RiskStatus riskStatus;
  final String headlineReason;
  final Set<String> unavailableReasons;
}

PerformanceJudgment resolvePerformanceJudgment({
  required double netPerformance,
  required double? periodReturn,
  required double? benchmarkDelta,
  required double? volatility,
  required double? maxDrawdown,
  required int dailyReturnCount,
}) {
  final unavailableReasons = <String>{};

  final performanceStatus = _resolvePerformanceStatus(
    netPerformance: netPerformance,
    periodReturn: periodReturn,
  );
  if (periodReturn == null) unavailableReasons.add('performance');

  final benchmarkDeltaStatus = _resolveBenchmarkStatus(benchmarkDelta);
  if (benchmarkDelta == null) unavailableReasons.add('benchmark');

  final riskStatus = _resolveRiskStatus(
    volatility: volatility,
    maxDrawdown: maxDrawdown,
    dailyReturnCount: dailyReturnCount,
  );
  if (riskStatus == RiskStatus.unavailable) unavailableReasons.add('risk');

  return PerformanceJudgment(
    performanceStatus: performanceStatus,
    benchmarkDeltaStatus: benchmarkDeltaStatus,
    riskStatus: riskStatus,
    headlineReason: _resolveHeadlineReason(
      performanceStatus: performanceStatus,
      benchmarkDeltaStatus: benchmarkDeltaStatus,
      riskStatus: riskStatus,
    ),
    unavailableReasons: unavailableReasons,
  );
}

PerformanceStatus _resolvePerformanceStatus({
  required double netPerformance,
  required double? periodReturn,
}) {
  if (periodReturn == null) return PerformanceStatus.unavailable;
  if (netPerformance < 0 || periodReturn < 0) return PerformanceStatus.caution;
  if (periodReturn >= 0.02) return PerformanceStatus.good;
  return PerformanceStatus.neutral;
}

BenchmarkDeltaStatus _resolveBenchmarkStatus(double? benchmarkDelta) {
  if (benchmarkDelta == null) return BenchmarkDeltaStatus.unavailable;
  if (benchmarkDelta >= 0.005) return BenchmarkDeltaStatus.outperforming;
  if (benchmarkDelta <= -0.005) return BenchmarkDeltaStatus.lagging;
  return BenchmarkDeltaStatus.similar;
}

RiskStatus _resolveRiskStatus({
  required double? volatility,
  required double? maxDrawdown,
  required int dailyReturnCount,
}) {
  if (dailyReturnCount < 5 || volatility == null || maxDrawdown == null) {
    return RiskStatus.unavailable;
  }
  if (volatility <= 0.08 && maxDrawdown >= -0.03) return RiskStatus.low;
  if (volatility >= 0.22 || maxDrawdown <= -0.12) return RiskStatus.elevated;
  return RiskStatus.normal;
}

String _resolveHeadlineReason({
  required PerformanceStatus performanceStatus,
  required BenchmarkDeltaStatus benchmarkDeltaStatus,
  required RiskStatus riskStatus,
}) {
  if (performanceStatus == PerformanceStatus.unavailable) {
    return '성과 판단에 필요한 데이터가 부족합니다.';
  }
  if (performanceStatus == PerformanceStatus.caution) {
    return '선택 기간에 손실이 발생했습니다.';
  }
  if (benchmarkDeltaStatus == BenchmarkDeltaStatus.lagging) {
    return '수익은 났지만 시장 대비 성과가 약합니다.';
  }
  if (benchmarkDeltaStatus == BenchmarkDeltaStatus.outperforming) {
    return '벤치마크보다 나은 성과를 냈습니다.';
  }
  if (riskStatus == RiskStatus.elevated) {
    return '성과는 양호하지만 변동성 확인이 필요합니다.';
  }
  return '선택 기간 성과가 안정적으로 유지되었습니다.';
}
```

- [ ] **Step 4: Run the tests**

Run:

```bash
flutter test test/investment_performance_judgment_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/investment_performance/performance_judgment.dart test/investment_performance_judgment_test.dart
git commit -m "feat: add performance judgment model"
```

## Task 2: Wire Judgment Into The View Model

**Files:**
- Modify: `lib/pages/investment_performance_page.dart`

- [ ] **Step 1: Add import and ViewModel fields**

Add the import near the other service imports:

```dart
import 'package:moneyfy/services/investment_performance/performance_judgment.dart';
```

Update `_InvestmentPerformanceViewModel`:

```dart
class _InvestmentPerformanceViewModel {
  const _InvestmentPerformanceViewModel({
    required this.report,
    required this.selectedRange,
    required this.periodReturn,
    required this.benchmarkReturn,
    required this.excessReturn,
    required this.reconciliation,
    required this.judgment,
  });

  final _InvestmentPerformanceReport report;
  final _PerformanceDateRange selectedRange;
  final _MetricValue periodReturn;
  final _MetricValue benchmarkReturn;
  final _MetricValue excessReturn;
  final _ReconciliationState reconciliation;
  final PerformanceJudgment judgment;
}
```

- [ ] **Step 2: Compute judgment in `fromReport`**

Inside `_InvestmentPerformanceViewModel.fromReport`, create a local judgment before returning:

```dart
final judgment = resolvePerformanceJudgment(
  netPerformance: report.pureInvestmentPerformance,
  periodReturn: advanced.periodReturn,
  benchmarkDelta: advanced.excessReturn,
  volatility: advanced.volatility,
  maxDrawdown: advanced.maxDrawdown,
  dailyReturnCount: advanced.dailyReturnCount,
);
```

Pass it into the constructor:

```dart
judgment: judgment,
```

- [ ] **Step 3: Add label helpers**

Add getters to `_InvestmentPerformanceViewModel`:

```dart
String get performanceStatusLabel => switch (judgment.performanceStatus) {
  PerformanceStatus.good => '양호',
  PerformanceStatus.neutral => '보통',
  PerformanceStatus.caution => '주의',
  PerformanceStatus.unavailable => '계산 불가',
};

String get benchmarkStatusLabel => switch (judgment.benchmarkDeltaStatus) {
  BenchmarkDeltaStatus.outperforming => '시장 대비 우위',
  BenchmarkDeltaStatus.similar => '시장과 유사',
  BenchmarkDeltaStatus.lagging => '시장 대비 열위',
  BenchmarkDeltaStatus.unavailable => '비교 불가',
};

String get riskStatusLabel => switch (judgment.riskStatus) {
  RiskStatus.low => '낮음',
  RiskStatus.normal => '보통',
  RiskStatus.elevated => '높음',
  RiskStatus.unavailable => '계산 불가',
};
```

- [ ] **Step 4: Analyze the modified file**

Run:

```bash
flutter analyze lib/pages/investment_performance_page.dart
```

Expected: no analyzer errors from constructor changes or missing fields.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/investment_performance_page.dart
git commit -m "feat: derive performance judgment summary"
```

## Task 3: Replace The Top Header With Scoreboard

**Files:**
- Modify: `lib/pages/investment_performance_page.dart`

- [ ] **Step 1: Rename the header component**

Rename `_PerformanceJudgmentHeader` to `_PerformanceScoreboardHeader` and keep the existing constructor inputs:

```dart
class _PerformanceScoreboardHeader extends StatelessWidget {
  const _PerformanceScoreboardHeader({
    required this.viewModel,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  final _InvestmentPerformanceViewModel viewModel;
  final _PerformanceDateRange selectedRange;
  final ValueChanged<_PerformanceDateRange> onRangeSelected;
}
```

Update the page build call:

```dart
_PerformanceScoreboardHeader(
  viewModel: viewModel,
  selectedRange: _selectedRange,
  onRangeSelected: _selectRange,
),
```

- [ ] **Step 2: Replace the header body with a scoreboard layout**

Use this structure inside `_PerformanceScoreboardHeader.build`:

```dart
return MoneyfySectionCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MoneyfyCardHeader(
        title: '성과 스코어보드',
        subtitle: viewModel.judgment.headlineReason,
        trailing: _StatusPill(label: viewModel.performanceStatusLabel),
      ),
      SizedBox(height: context.spacing.md),
      _DateRangeSelector(
        selectedRange: selectedRange,
        onSelected: onRangeSelected,
      ),
      SizedBox(height: context.spacing.md),
      LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          final tiles = [
            _JudgmentMetricBlock(
              label: '순 투자성과',
              value: _formatSignedCurrency(viewModel.report.pureInvestmentPerformance),
              caption: '입출금과 이체를 제외한 성과',
            ),
            _JudgmentMetricBlock(
              label: '수익률',
              value: viewModel.periodReturn.displayText,
              caption: viewModel.rangeLabel,
            ),
            _JudgmentMetricBlock(
              label: '벤치마크 대비',
              value: viewModel.excessReturn.displayText,
              caption: viewModel.benchmarkStatusLabel,
            ),
            _JudgmentMetricBlock(
              label: '리스크',
              value: viewModel.riskStatusLabel,
              caption: '변동성과 낙폭 기준',
            ),
          ];
          return GridView.count(
            crossAxisCount: isNarrow ? 2 : 4,
            childAspectRatio: isNarrow ? 1.45 : 1.25,
            crossAxisSpacing: context.spacing.sm,
            mainAxisSpacing: context.spacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: tiles,
          );
        },
      ),
      SizedBox(height: context.spacing.sm),
      _BenchmarkSnapshotStrip(viewModel: viewModel),
    ],
  ),
);
```

- [ ] **Step 3: Adjust `_JudgmentMetricBlock` for compact tiles**

Ensure `_JudgmentMetricBlock` has fixed internal spacing and uses wrapping text:

```dart
Text(
  value,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w800,
  ),
)
```

- [ ] **Step 4: Run analyzer**

Run:

```bash
flutter analyze lib/pages/investment_performance_page.dart
```

Expected: no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/investment_performance_page.dart
git commit -m "feat: add performance scoreboard header"
```

## Task 4: Reframe Evidence Cards

**Files:**
- Modify: `lib/pages/investment_performance_page.dart`

- [ ] **Step 1: Rename evidence card headings**

Update user-facing headings:

```dart
// _PerformanceAttributionCard
title: '성과 구성',
subtitle: '순성과를 만든 실현, 평가, 배당/이자, 비용 요인입니다.',

// _PerformanceReconciliationCard
title: '자산 변화 대조',
subtitle: '총자산 변화와 투자성과가 왜 다른지 분리해 봅니다.',

// _MonthlyTrendCard
title: '월별 성과 신호',
subtitle: '성과가 강했던 달과 약했던 달을 확인합니다.',

// _HoldingContributionCard
title: '종목별 성과 영향',
subtitle: '상위와 하위 기여 종목을 기준으로 판단 근거를 확인합니다.',

// _RiskInterpretationCard
title: '리스크 신호',
subtitle: '변동성, 낙폭, 위험 대비 성과를 판단합니다.',

// _DataBasisCard
title: '데이터 신뢰도',
subtitle: '계산 기준과 누락 가능성을 확인합니다.',
```

- [ ] **Step 2: Keep current section order aligned to the spec**

Ensure the build order is:

```dart
_PerformanceScoreboardHeader(...),
_BenchmarkSnapshotStrip(viewModel: viewModel),
_PerformanceAttributionCard(viewModel: viewModel),
_PerformanceReconciliationCard(viewModel: viewModel),
_MonthlyTrendCard(items: report.monthlyPerformance),
_HoldingContributionCard(...),
_RiskInterpretationCard(viewModel: viewModel),
_DataBasisCard(viewModel: viewModel),
```

If `_BenchmarkSnapshotStrip` remains inside the scoreboard header, do not also render it as a separate card.

- [ ] **Step 3: Make unavailable states explicit**

Where metric values use `_MetricValue`, render the reason text when unavailable:

```dart
final caption = metric.isAvailable
    ? availableCaption
    : metric.reasonText ?? '계산에 필요한 데이터가 부족합니다.';
```

Use that pattern for benchmark delta, benchmark return, and period return captions.

- [ ] **Step 4: Run analyzer**

Run:

```bash
flutter analyze lib/pages/investment_performance_page.dart
```

Expected: no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/investment_performance_page.dart
git commit -m "style: reframe performance evidence cards"
```

## Task 5: Add Widget Smoke Coverage

**Files:**
- Modify: `test/ui_component_smoke_test.dart` or `test/page_walkthrough_test.dart`

- [ ] **Step 1: Add a smoke test for scoreboard rendering**

If `InvestmentPerformancePage` can be pumped without external config in the existing smoke harness, add:

```dart
import 'package:moneyfy/pages/investment_performance_page.dart';

testWidgets('investment performance page renders scoreboard shell', (
  tester,
) async {
  await pumpInteractivePage(tester, const InvestmentPerformancePage());

  expect(find.text('투자성과 분석'), findsOneWidget);
  expect(find.text('성과 스코어보드'), findsOneWidget);
  expect(find.text('순 투자성과'), findsOneWidget);
  expect(find.text('수익률'), findsOneWidget);
  expect(find.text('벤치마크 대비'), findsOneWidget);
  expect(find.text('리스크'), findsOneWidget);
});
```

If the page requires a database setup that the smoke harness does not provide, add the test to the existing page walkthrough file that already initializes app services.

- [ ] **Step 2: Run the focused smoke test**

Run:

```bash
flutter test test/ui_component_smoke_test.dart --plain-name "investment performance page renders scoreboard shell"
```

Expected: pass without widget exceptions.

- [ ] **Step 3: Run existing related tests**

Run:

```bash
flutter test test/investment_performance_judgment_test.dart test/risk_adjusted_performance_calculator_test.dart test/benchmark_data_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Run analyzer**

Run:

```bash
flutter analyze lib/pages/investment_performance_page.dart
```

Expected: no analyzer errors.

- [ ] **Step 5: Commit**

```bash
git add test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
git commit -m "test: cover performance scoreboard shell"
```

## Task 6: Verify State And Error Handling

**Files:**
- Modify: `lib/pages/investment_performance_page.dart`
- Test: `test/investment_performance_judgment_test.dart`

- [ ] **Step 1: Add unit coverage for state labels**

Append these cases to `test/investment_performance_judgment_test.dart`:

```dart
test('reports performance unavailable when period return is missing', () {
  final judgment = resolvePerformanceJudgment(
    netPerformance: 0,
    periodReturn: null,
    benchmarkDelta: null,
    volatility: null,
    maxDrawdown: null,
    dailyReturnCount: 0,
  );

  expect(judgment.performanceStatus, PerformanceStatus.unavailable);
  expect(judgment.benchmarkDeltaStatus, BenchmarkDeltaStatus.unavailable);
  expect(judgment.riskStatus, RiskStatus.unavailable);
  expect(judgment.headlineReason, contains('데이터'));
});

test('marks elevated risk when drawdown is large', () {
  final judgment = resolvePerformanceJudgment(
    netPerformance: 240000,
    periodReturn: 0.021,
    benchmarkDelta: 0.002,
    volatility: 0.18,
    maxDrawdown: -0.14,
    dailyReturnCount: 40,
  );

  expect(judgment.riskStatus, RiskStatus.elevated);
});
```

- [ ] **Step 2: Confirm Loading and Empty Data rendering**

In `lib/pages/investment_performance_page.dart`, keep this FutureBuilder fallback shape:

```dart
final report = snapshot.data ?? const _InvestmentPerformanceReport.empty();
```

Confirm the empty report still renders:

```dart
_PerformanceScoreboardHeader(
  viewModel: viewModel,
  selectedRange: _selectedRange,
  onRangeSelected: _selectRange,
),
```

Expected labels for empty data:

```text
성과 스코어보드
계산 불가
비교 불가
```

- [ ] **Step 3: Confirm Benchmark Failure and Risk Calculation Unavailable states**

Confirm `_MetricValue.reasonText` still feeds `benchmarkCaption` and scoreboard captions:

```dart
String get benchmarkCaption {
  if (!benchmarkReturn.isAvailable) return benchmarkReturn.reasonText!;
  if (!excessReturn.isAvailable) return '참고 수익률만 표시합니다.';
  return '벤치마크는 시장 전체를 대표하지 않는 참고 기준입니다.';
}
```

Confirm the risk tile caption uses:

```dart
viewModel.riskStatusLabel
```

Expected behavior:

```text
Benchmark Failure: 투자성과는 표시하고 벤치마크 대비만 비교 불가로 표시
Risk Calculation Unavailable: 리스크 값은 계산 불가로 표시
```

- [ ] **Step 4: Confirm Zero Or Negative Performance handling**

Keep `_HoldingContributionCard` contribution formatting guarded by the existing total-performance basis logic. For zero or negative totals, display amount-first rows and avoid adding a new percentage based on zero.

Expected behavior:

```text
Zero Or Negative Performance: 종목 행은 금액을 표시하고 무리한 기여율 계산을 하지 않음
```

- [ ] **Step 5: Run focused tests**

Run:

```bash
flutter test test/investment_performance_judgment_test.dart
flutter analyze lib/pages/investment_performance_page.dart
```

Expected: tests pass and analyzer reports no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/investment_performance_page.dart test/investment_performance_judgment_test.dart
git commit -m "test: verify performance state handling"
```

## Task 7: Responsive Verification And Final Sweep

**Files:**
- Modify only if verification finds an issue:
  - `lib/pages/investment_performance_page.dart`
  - `test/ui_component_smoke_test.dart`
  - `test/page_walkthrough_test.dart`

- [ ] **Step 1: Run full focused verification**

Run:

```bash
flutter test test/investment_performance_judgment_test.dart test/risk_adjusted_performance_calculator_test.dart test/benchmark_data_test.dart test/ui_component_smoke_test.dart
flutter analyze lib/pages/investment_performance_page.dart
```

Expected: tests pass and analyzer reports no issues for the modified page.

- [ ] **Step 2: Inspect narrow layout in code**

Confirm `_PerformanceScoreboardHeader` uses:

```dart
final isNarrow = constraints.maxWidth < 520;
crossAxisCount: isNarrow ? 2 : 4;
```

Confirm each scoreboard text value uses:

```dart
maxLines: 2,
overflow: TextOverflow.ellipsis,
```

- [ ] **Step 3: Check git diff scope**

Run:

```bash
git diff -- lib/services/investment_performance/performance_judgment.dart test/investment_performance_judgment_test.dart lib/pages/investment_performance_page.dart test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
```

Expected: changes are limited to the judgment model, its tests, the performance page, and the smoke test file that was actually used.

- [ ] **Step 4: Commit final fixes if any were made**

If Step 1 or Step 2 required fixes:

```bash
git add lib/pages/investment_performance_page.dart test/ui_component_smoke_test.dart test/page_walkthrough_test.dart
git commit -m "fix: polish performance scoreboard layout"
```

If no fixes were made, do not create an empty commit.
