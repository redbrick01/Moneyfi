# Benchmark And Risk-Adjusted Performance Verification Plan

이 문서는 벤치마크 비교와 위험조정 성과 기능을 구현할 때 사용할 검증 계획서입니다.

## Verification Goals

검증의 핵심은 세 가지입니다.

1. 입금/출금이 수익률로 오해되지 않아야 합니다.
2. Sharpe Ratio, 변동성, 최대 낙폭이 같은 입력에서 항상 같은 값을 내야 합니다.
3. 분석용 파생 데이터 생성이 기존 자산/보유/원장 데이터를 변경하지 않아야 합니다.

## Unit Test Matrix

| 테스트 | 입력 | 기대 결과 |
| --- | --- | --- |
| `daily_return_excludes_deposit` | 전일 1,000,000원, 당일 1,500,000원, 입금 500,000원 | 수익률 0% |
| `daily_return_excludes_withdrawal` | 전일 1,000,000원, 당일 700,000원, 출금 -300,000원 | 수익률 0% |
| `daily_return_includes_market_gain` | 전일 1,000,000원, 당일 1,100,000원, 외부 현금흐름 0원 | 수익률 10% |
| `daily_return_excludes_deposit_and_keeps_gain` | 전일 1,000,000원, 당일 1,650,000원, 입금 500,000원 | 수익률 15% |
| `daily_return_excludes_withdrawal_and_keeps_loss` | 전일 1,000,000원, 당일 600,000원, 출금 -300,000원 | 수익률 -10% |
| `daily_return_handles_zero_beginning_value` | 전일 0원 | 수익률 null 또는 데이터 부족 |
| `cumulative_return_compounds_daily_returns` | +10%, -10% | -1% |
| `annualized_return_uses_daily_mean` | 일별 평균 0.1% | 연율화 수익률 25.2% |
| `volatility_annualizes_daily_stddev` | 고정 일별 수익률 배열 | `stddev * sqrt(252)` |
| `sharpe_ratio_returns_null_for_zero_volatility` | 변동성 0 | null 또는 데이터 부족 |
| `max_drawdown_uses_running_peak` | 100, 120, 90, 130 | 최대 낙폭 -25% |
| `benchmark_uses_common_dates_only` | 포트폴리오 5일, 벤치마크 3일 | 공통 3일만 비교 |
| `benchmark_requires_minimum_common_dates` | 공통 19거래일 | 데이터 부족 |
| `benchmark_uses_adjusted_close_when_available` | close와 adjusted close가 모두 있음 | adjusted close 기준 |

## Data Integrity Tests

| 테스트 | 목적 |
| --- | --- |
| `derived_update_does_not_mutate_assets` | 파생 수익률 생성 후 자산 원본 불변 |
| `derived_update_does_not_mutate_holdings` | 보유 수량, 평균단가, 환율 평균 불변 |
| `derived_update_does_not_mutate_transaction_lines` | 원장 금액과 action 불변 |
| `derived_update_failure_keeps_existing_derived_rows` | 갱신 실패 시 기존 분석 데이터 유지 |
| `missing_snapshot_marks_insufficient_data` | 스냅샷 부족 시 0 표시가 아니라 데이터 부족 표시 |
| `derived_update_preserves_holding_totals` | 보유 수량/평가금액/매수원금 합계 불변 |
| `derived_rows_store_data_quality` | 스냅샷/환율 누락 상태 기록 |

## Widget Test Matrix

| 화면 상태 | 기대 UI |
| --- | --- |
| 벤치마크 데이터 없음 | `데이터 부족` 표시 |
| 공통 관측치 20거래일 미만 | 벤치마크 비교 데이터 부족 표시 |
| 기간 데이터 60거래일 미만 | Sharpe Ratio 숨김 또는 데이터 부족 표시 |
| 정상 데이터 | 입출금 보정 기간 수익률, 벤치마크 수익률, 초과수익률 표시 |
| 포트폴리오가 벤치마크 초과 | 초과수익률 양수 색상 |
| 포트폴리오가 벤치마크 미달 | 초과수익률 음수 색상 |
| 기존 수익률과 고급 수익률 동시 표시 | `매수 원금 대비`, `입출금 보정 기간 수익률` 라벨 분리 |
| 고급 지표 설명 | 각 지표에 사용자가 이해할 수 있는 1-2줄 설명 표시 |

## Manual QA Scenarios

### Scenario 1. 입금만 있는 기간

1. 포트폴리오 가치 1,000,000원 상태에서 500,000원을 입금합니다.
2. 자산 가격은 변하지 않았다고 가정합니다.
3. 투자성과 분석을 엽니다.

기대 결과:

- 금액 기준 총자산은 증가할 수 있습니다.
- 입출금 보정 기간 수익률은 0%에 가깝게 표시됩니다.
- 입금액은 외부 현금흐름으로 분리됩니다.
- 입출금 보정 기간 수익률 설명이 함께 표시됩니다.

### Scenario 2. 매수만 있는 기간

1. 현금으로 종목을 매수합니다.
2. 가격은 변하지 않았다고 가정합니다.
3. 투자성과 분석을 엽니다.

기대 결과:

- 매수 결제는 외부 현금흐름으로 잡히지 않습니다.
- 입출금 보정 기간 수익률은 0%에 가깝게 표시됩니다.
- 매수 원금 대비 금액 성과와 입출금 보정 기간 수익률을 혼동하지 않도록 표시됩니다.
- 두 수익률의 차이를 설명하는 짧은 안내가 표시됩니다.

### Scenario 3. 벤치마크 데이터 누락

1. 포트폴리오 스냅샷은 있지만 벤치마크 가격이 없는 기간을 선택합니다.
2. 투자성과 분석을 엽니다.

기대 결과:

- 기존 투자성과 금액 카드는 정상 표시됩니다.
- 벤치마크 비교 영역만 `데이터 부족`으로 표시됩니다.
- 화면 전체가 에러 상태로 바뀌지 않습니다.
- 벤치마크가 무엇인지 설명하는 짧은 문구는 유지됩니다.

### Scenario 4. USD 중심 포트폴리오

1. USD 종목이 포함된 포트폴리오를 준비합니다.
2. S&P 500 또는 NASDAQ 100 벤치마크를 선택합니다.
3. KRW 기준 비교를 확인합니다.

기대 결과:

- 포트폴리오와 벤치마크가 같은 기준 통화로 비교됩니다.
- 환율 데이터가 없으면 fallback 상태가 표시됩니다.
- 원화 평균단가, 원통화 평균단가, 평균 환율 값은 변경되지 않습니다.
- KRW 기준 비교라는 설명이 표시됩니다.

## Supabase Preflight Checklist

원격 적용 전 반드시 확인합니다.

- 로컬 마이그레이션이 새 테이블 추가만 수행하는지 확인합니다.
- 기존 원본 테이블에 `update`, `delete`, `truncate`가 없는지 확인합니다.
- Edge Function sync payload가 기존 자산을 빈 배열로 덮어쓸 수 없는지 확인합니다.
- rollback SQL 또는 새 테이블 drop 계획을 문서화합니다.
- 원격 적용 전 로컬 DB 백업 또는 export 절차를 확보합니다.
- 적용 전후 holdings row count, quantity sum, valuation sum, purchase amount sum을 비교합니다.
- 적용 전후 원화 평균단가, 원통화 평균단가, 평균 환율의 null/zero 분포를 비교합니다.

## Required Commands

구현 단계에서 최소 아래 명령을 통과해야 합니다.

```bash
flutter test test/widget_test.dart
flutter test test/transaction_flow_test.dart
flutter analyze lib/pages/investment_performance_page.dart
git diff --check
```

DB migration이 포함되면 추가로 수행합니다.

```bash
flutter test test/usd_currency_seed_migration_test.dart
flutter test test/sync_currency_basis_contract_test.dart
```

## Release Gate

아래 조건을 모두 만족하기 전에는 Supabase 원격 적용을 진행하지 않습니다.

- 계산 순수 함수 테스트 통과
- 파생 데이터가 원본 테이블을 변경하지 않는 테스트 통과
- 벤치마크 데이터 누락 상태 UI 검증
- 스냅샷 부족 상태 UI 검증
- 각 지표의 1-2줄 설명 표시 검증
- 원격 migration SQL에 원본 테이블 destructive write 없음
- 원격 적용 전후 holdings 핵심 합계 불변 검증
- 기존 투자성과 금액 계산 회귀 없음
