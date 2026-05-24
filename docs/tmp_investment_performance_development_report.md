# Temporary Investment Performance Development Report

이 문서는 `투자성과 분석` 고도화 구현 결과를 검증 계획 수립용으로 정리한 임시 개발 리포트입니다.

작성일: 2026-05-24

영구 계획 문서:

- `docs/investment_performance_report_plan.md`

후속 검증 문서:

- `docs/investment_performance_verification_test_plan.md`

## Summary

`투자성과 분석` 화면을 전체 기간 고정 요약 화면에서 기간별 탐색이 가능한 원장 기반 성과 리포트로 확장했습니다.

핵심 변경은 다음과 같습니다.

- 기간 preset 추가: 1개월, 3개월, 6개월, 올해, 전체
- ledger aggregate API에 `from/to` 기간 필터 추가
- 순 투자성과 중심의 summary header 적용
- 성과 breakdown에 순 실현성과와 순 투자성과 추가
- 제외 현금흐름을 외부 입금, 외부 출금, 매매 결제, 내부 이동으로 분리
- 월별 성과 row에 비용 표시 추가
- 종목별 성과 기여도와 정렬 옵션 추가
- drill-down 준비용 ledger performance event API 추가
- 관련 unit/widget walkthrough 테스트 보강
- 개발 진행용 임시 실행 계획서 삭제 완료

## Implemented Stages

| Stage | 상태 | 구현 요약 |
| --- | --- | --- |
| Stage 0. Baseline Check | 완료 | 기존 `transaction_flow_test.dart` 통과 확인 |
| Stage 1. Calculation Contract Tests | 완료 | 기간 필터, 현금흐름 분리, drill-down API 테스트 추가 |
| Stage 2. Date Range Model And Query Filters | 완료 | portfolio/monthly/holding aggregate에 `from/to` 적용 |
| Stage 3. Stateful Report Loading | 완료 | `InvestmentPerformancePage`를 `StatefulWidget`으로 전환 |
| Stage 4. Summary Header And Breakdown UX | 완료 | 순 투자성과 중심 header와 breakdown 개선 |
| Stage 5. Cash Flow Separation UX | 완료 | 입금/출금/결제/내부 이동 분리 표시 |
| Stage 6. Monthly Trend Upgrade | 완료 | 월별 row에 비용 항목 반영 |
| Stage 7. Holding Contribution And Sorting | 완료 | 종목별 기여도와 정렬 옵션 추가 |
| Stage 8. Minimal Drill-Down Preparation | 완료 | `fetchLedgerPerformanceEvents()` 추가 |
| Stage 9. Verification | 완료 | `flutter analyze`, `flutter test` 통과 |
| Stage 10. Cleanup | 완료 | `docs/tmp_investment_performance_execution_plan.md` 삭제 |

## Changed Files

| 파일 | 변경 내용 |
| --- | --- |
| `lib/db/app_database.dart` | ledger 성과 집계 기간 필터, 외부 입금/출금 분리, drill-down record/API 추가 |
| `lib/pages/investment_performance_page.dart` | stateful 기간 preset, summary header, breakdown, cash-flow card, 월별 row, 종목별 기여도/정렬 개선 |
| `test/transaction_flow_test.dart` | 기간 필터, 현금흐름 분리, drill-down API 테스트 추가 |
| `test/page_walkthrough_test.dart` | 변경된 `순 투자성과` 화면 문구에 맞춰 walkthrough 기대값 수정 |
| `docs/investment_performance_report_plan.md` | 원장 기반 성과 리포트 계획과 타당성 피드백 |
| `docs/README.md` | 투자성과 리포트 계획 문서와 검증/테스트 계획 문서 링크 추가 |

## Data Layer Changes

### Date Filter Helpers

`AppDatabase`에 ledger event 날짜 비교 helper를 추가했습니다.

- `_ledgerDateText(DateTime? date)`
- `_ledgerDateWhereClause({eventAlias, from, to})`
- `_ledgerDateVariables({from, to})`

날짜 비교 기준:

```text
SUBSTR(REPLACE(te.occurred_at, '.', '-'), 1, 10)
```

이 기준은 `YYYY.MM.DD`와 `YYYY-MM-DD` 형식이 섞인 기존 데이터를 같은 방식으로 비교하기 위해 사용합니다.

### Updated Aggregate APIs

아래 API가 `DateTime? from`, `DateTime? to` optional parameter를 받도록 확장되었습니다.

- `fetchLedgerHoldingPerformanceByHoldingId({from, to})`
- `fetchLedgerPortfolioPerformance({from, to})`
- `fetchLedgerPortfolioPerformanceByCurrency({from, to})`
- `fetchLedgerMonthlyPerformanceByCurrency({from, to})`

기존 호출부는 인자 없이 그대로 사용할 수 있습니다.

### External Cash Flow Split

`LedgerPortfolioPerformanceRecord`에 다음 필드를 추가했습니다.

- `externalDepositAmount`
- `externalWithdrawalAmount`

기존 `externalCashFlowAmount`는 net amount로 유지합니다.

계산 기준:

| 필드 | 계산 |
| --- | --- |
| `externalCashFlowAmount` | `deposit + withdrawal + opening_cash`의 signed sum |
| `externalDepositAmount` | `deposit + opening_cash`의 절대값 합계 |
| `externalWithdrawalAmount` | `withdrawal`의 절대값 합계 |

### Drill-Down API

집계 숫자의 근거 거래를 조회하기 위한 최소 API를 추가했습니다.

```dart
Future<List<LedgerPerformanceEventRecord>> fetchLedgerPerformanceEvents({
  DateTime? from,
  DateTime? to,
  String? action,
  int? holdingId,
})
```

현재 구현은 API 준비 단계이며, 별도 drill-down UI는 아직 추가하지 않았습니다.

## UI Changes

### Date Range Presets

`InvestmentPerformancePage`는 다음 preset을 제공합니다.

- 1개월
- 3개월
- 6개월
- 올해
- 전체

초기 선택값은 `올해`입니다.

### Summary Header

상단 대표 지표를 `순 투자성과`로 정리했습니다.

보조 지표:

- 실현
- 미실현
- 배당/이자
- 비용

기준 문구:

```text
입출금과 내부 이동 제외 기준
```

### Performance Breakdown

성과 구성 카드에 다음 항목을 표시합니다.

- 실현손익
- 미실현손익
- 배당/이자
- 수수료
- 세금
- 순 실현성과
- 순 투자성과
- 매수 원금
- 매도 회수금

### Cash Flow Exclusion

제외 현금흐름 카드는 다음 항목으로 분리되었습니다.

- 외부 입금
- 외부 출금
- 외부 입출금 합계
- 투자 결제 현금흐름
- 내부 이동

### Monthly Trend

월별 row는 다음 내용을 표시합니다.

- 월
- 순 실현성과
- 실현손익
- 배당/이자 수입
- 수수료/세금 비용

### Holding Contribution

보유 항목별 성과 카드에는 다음 기능이 추가되었습니다.

- 총 성과 기준 기여도 표시
- 정렬 옵션
  - 총 성과
  - 손실
  - 실현
  - 미실현
  - 배당/이자

1차 정책상 수수료/세금은 종목별 성과에 배부하지 않고 포트폴리오 비용으로 유지합니다.

## Tests Added Or Updated

### Updated Existing Test

`cash ledger summary separates external and internal cash movement`

추가 검증:

- `externalDepositAmount`
- `externalWithdrawalAmount`

### New Tests

`ledger performance filters by event date range across date formats`

검증:

- `YYYY.MM.DD`와 `YYYY-MM-DD` 혼합 데이터의 기간 필터
- portfolio aggregate 기간 필터
- currency aggregate 기간 필터
- holding aggregate 기간 필터
- monthly aggregate 기간 필터

`ledger performance events support drill-down filters`

검증:

- `fetchLedgerPerformanceEvents()`의 기간, action, holding filter
- 조회된 event title/action/amount

### Updated Walkthrough

`page_walkthrough_test.dart`

변경:

- 기존 `순수 투자성과` 기대값을 `순 투자성과` 기준으로 변경

## Verification Results

실행한 명령:

```bash
flutter analyze
flutter test
flutter test test/transaction_flow_test.dart
```

결과:

```text
flutter analyze: passed, no issues found
flutter test: passed, 80 tests
transaction_flow_test.dart: passed, 43 tests
```

## Known Limitations

- 직접 선택 date picker는 아직 구현하지 않았습니다.
- 수익률은 아직 표시하지 않습니다.
- 과거 환율 기반 환산은 아직 적용하지 않았습니다.
- 월별 미실현손익 변화는 아직 snapshot 기반으로 계산하지 않습니다.
- drill-down UI는 아직 없고 API만 준비되었습니다.
- 종목별 수수료/세금 배부는 아직 하지 않습니다.

## Risk Notes

| 리스크 | 설명 | 대응 |
| --- | --- | --- |
| 기간 필터 경계 | 문자열 날짜 비교 기준이므로 날짜 형식이 더 다양해지면 누락 가능 | 현재 `YYYY.MM.DD`, `YYYY-MM-DD`는 테스트로 고정 |
| 외화 환산 | 최신 환율 기준이 과거 성과를 왜곡할 수 있음 | UI/문서에서 MVP 정책으로 명시, 후속 Phase로 분리 |
| UI 과밀 | summary, breakdown, cash-flow, monthly, holding card가 길어질 수 있음 | 첫 화면 핵심은 summary header로 압축 |
| 종목별 기여도 | 전체 성과가 0에 가까우면 비율이 의미 없음 | basis가 0에 가까우면 기여도 숨김 |
| drill-down 신뢰 | API와 aggregate 기준이 달라지면 근거 목록이 틀어질 수 있음 | 같은 date/action/holding filter 기준 테스트 추가 |

## Follow-Up Items

1. drill-down bottom sheet UI 추가 여부 결정
2. 직접 선택 date picker 설계
3. snapshot 기반 월별 미실현손익 변화 설계
4. 과거 환율 정책 설계
5. 수익률 지표 별도 설계
6. 종목별 비용 배부 정책 결정
7. 모바일 실기기 또는 시뮬레이터에서 긴 금액/긴 종목명 레이아웃 확인
