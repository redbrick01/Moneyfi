# Investment Performance Redesign Plan v1

작성일: 2026-05-29

## Goal

`투자성과 분석` 페이지를 현재의 카드 나열형 MVP 리포트에서 사용자가 성과의 크기, 원인, 비교 기준, 위험 신호를 한 흐름으로 읽을 수 있는 제품급 성과 대시보드로 재구성합니다.

핵심 목표는 다음 네 가지입니다.

1. 사용자가 이번 기간 순 투자성과를 첫 화면에서 즉시 판단할 수 있게 합니다.
2. 실현손익, 미실현손익, 배당/이자, 비용이 성과에 어떻게 기여했는지 시각적으로 분해합니다.
3. 벤치마크, 변동성, Sharpe Ratio, 최대 낙폭을 별도 부록이 아니라 성과 해석 흐름 안에 배치합니다.
4. 월별/종목별 성과 탐색을 리스트 나열에서 추세와 기여도 중심으로 전환합니다.

## Recommended v1 Layout

구현 착수 기준 레이아웃은 아래 순서를 기본으로 합니다.

1. `Performance Cockpit`: 기간 선택, 순 투자성과, 매수 원금 대비 수익률, 벤치마크 대비 문구
2. `Performance Attribution`: 실현손익, 미실현손익, 배당/이자, 수수료, 세금의 원인 분해
3. `Market And Risk`: 기간 수익률, S&P 500, 초과수익률, 변동성, Sharpe Ratio, 최대 낙폭
4. `Monthly Trend`: 최근 12개월 실현성과 bar strip과 월별 row
5. `Holding Contribution`: 전체/실현/손실 필터를 가진 종목별 성과
6. `Excluded Cash Flow`: 투자성과에서 제외한 외부 입출금, 결제, 내부 이동

v1의 핵심 결정:

- `고급 성과`라는 섹션명은 쓰지 않고, 사용자가 이해하기 쉬운 `시장 비교와 위험` 또는 `Market And Risk` 계열 이름으로 바꿉니다.
- 기존 `종목별 실현손익` 랭킹은 완전히 삭제하지 않고, `Holding Contribution`의 `실현` 필터로 보존합니다.
- 벤치마크 데이터가 부족하거나 fetch가 실패해도 cockpit은 유지하고, 비교 문구만 낮은 위계의 fallback 문구로 바꿉니다.
- attribution bar는 `maxAbsComponent` 기준 길이로 계산하고, total 대비 비중은 텍스트로만 표시합니다.

## Current Baseline

현재 화면은 `lib/pages/investment_performance_page.dart`에 구현되어 있으며, 데이터와 계산 기반은 이미 충분히 갖춰져 있습니다.

| 영역 | 현재 상태 |
| --- | --- |
| 대표 데이터 | `_InvestmentPerformanceReport` |
| 기간 선택 | 1개월, 3개월, 6개월, 올해, 전체 preset |
| 핵심 성과 | 순 투자성과, 순 실현성과, 미실현손익, 배당/이자, 비용 |
| 원장 집계 | portfolio/monthly/holding aggregate API |
| 고급 성과 | 기간 수익률, S&P 500, 초과수익률, 변동성, 무위험수익률, Sharpe Ratio, 최대 낙폭 |
| 탐색 섹션 | 월별 실현성과, 종목별 실현손익, 보유 항목별 성과 |
| 주요 한계 | 동일한 위계의 `SectionCard`가 세로로 나열되어 정보 우선순위가 약함 |

현재 순서는 다음과 같습니다.

1. 기간 선택 칩
2. 순 투자성과 요약
3. 성과 구성
4. 고급 성과
5. 제외 현금흐름
6. 월별 실현성과
7. 종목별 실현손익
8. 보유 항목별 성과

## Reference Direction

### Sharesight Performance Report

참고 링크: https://help.sharesight.com/eu/performance_report/

적용할 점:

- 기간 선택, 그룹핑, open/closed position, benchmark 비교를 리포트 컨트롤로 묶습니다.
- 금액 성과와 퍼센트 성과를 혼동하지 않게 토글 또는 병렬 표시합니다.
- 보유 항목 표는 사용자가 정렬하고 drill-down할 수 있는 분석 테이블처럼 다룹니다.

### StakeView

참고 링크: https://stakeview.io/

적용할 점:

- 상단을 "성과 cockpit"으로 구성합니다.
- NAV, cash, realized/unrealized, time-series performance를 한눈에 판단하는 구조를 참고합니다.
- 종목별 영역은 sortable matrix의 밀도와 명확성을 참고합니다.

### Portfoyo

참고 링크: https://www.portfoyo.app/

적용할 점:

- 가격 추적이 아니라 사용자 거래 이력 기준의 "true performance"를 강조합니다.
- realized/unrealized 분리를 모바일 친화적으로 표현합니다.
- ROI, cost basis, realized gains의 관계를 요약 카드에서 자연스럽게 보여줍니다.

### Wealthfolio

참고 링크: https://wealthfolio.app/

적용할 점:

- local-first 투자 tracker에 맞는 차분한 톤을 참고합니다.
- 큰 숫자, 조용한 차트, 충분한 여백을 유지합니다.
- MONEYFY의 `calm, minimal, iOS feeling` 디자인 원칙과 가장 잘 맞는 시각 방향입니다.

### OpenStocky

참고 링크: https://www.openstocky.com/about-us

적용할 점:

- `Holdings`, `Market`, `History`, `Transactions`처럼 분석 목적별 탭 구조를 참고합니다.
- P/L attribution, weight vs return, growth chart의 아이디어를 장기 후보로 둡니다.
- Sharpe, volatility, CAGR, IRR 같은 지표를 별도 고급 목록이 아니라 분석 카드로 구조화합니다.

## Product Principles

### 1. First Screen Answers First

첫 화면은 다음 질문에 바로 답해야 합니다.

- 이번 기간 투자로 얼마를 벌거나 잃었나?
- 입출금과 내부 이동을 제외한 성과인가?
- 시장 기준보다 나았나?
- 성과를 만든 가장 큰 원인은 무엇인가?

### 2. Amount And Rate Stay Distinct

MONEYFY는 원장 기반 금액 성과가 강점입니다. 따라서 금액 성과와 수익률 성과를 섞어 보이지 않게 합니다.

| 표현 | 역할 |
| --- | --- |
| 순 투자성과 금액 | 대표 지표 |
| 매수 원금 대비 수익률 | 보조 지표 |
| 입출금 보정 기간 수익률 | 고급 비교 지표 |
| 벤치마크 대비 초과수익률 | 시장 비교 지표 |

### 3. Attribution Before Detail

사용자는 긴 숫자 표보다 "무엇이 성과를 만들었는지"를 먼저 봐야 합니다.

표시 우선순위:

1. 실현손익
2. 미실현손익
3. 배당/이자
4. 수수료/세금
5. 제외 현금흐름
6. 종목/월별 상세

### 4. Progressive Disclosure

복잡한 리스크 지표와 거래 근거는 처음부터 모두 펼치지 않습니다.

- 기본 화면: 핵심 숫자와 원인
- 확장 화면: 리스크/벤치마크 지표 설명
- drill-down: 월/종목/비용별 근거 거래

## Proposed Information Architecture

### Section 1. Performance Cockpit

상단 hero 영역입니다.

구성:

- 기간 segmented control
- 순 투자성과 금액
- 매수 원금 대비 수익률
- 벤치마크 대비 문구
- 보조 mini metrics
  - 순 실현성과
  - 미실현손익
  - 배당/이자
  - 비용

예시 구조:

```text
[1개월][3개월][6개월][올해][전체]

순 투자성과
+1,240,000원
+8.4% 매수 원금 대비

S&P 500보다 +2.1%p
입출금과 내부 이동 제외 기준

실현 +420,000  미실현 +690,000
수입 +160,000  비용 -30,000
```

디자인 메모:

- 현재 `_PerformanceSummaryCard`를 대체합니다.
- `SectionCard`보다 header emphasis가 큰 별도 private widget을 둡니다.
- 금액은 `context.typography.heroNumber` 또는 page title급 숫자를 사용합니다.
- 양수/음수 색은 semantic positive/negative만 사용합니다.

벤치마크 fallback:

| 상태 | cockpit 문구 |
| --- | --- |
| 벤치마크 수익률과 초과수익률 있음 | `S&P 500보다 +2.1%p` |
| 벤치마크 수익률만 있음 | `S&P 500 +6.3%` |
| 벤치마크 데이터 부족 | `시장 비교 데이터 부족` |
| benchmark fetch 실패 | `시장 비교는 나중에 다시 확인할 수 있어요` |
| 전체 기간이나 스냅샷 부족으로 기간 수익률 없음 | `입출금 보정 수익률 데이터 부족` |

### Section 2. Performance Attribution

성과 구성 카드의 v1 대체안입니다.

구성:

- 순서 있는 breakdown row
- 각 row에 금액, 전체 성과 대비 비중, 가로 bar
- 마지막 row는 순 투자성과 total

표시 항목:

| 항목 | 계산 | 표시 방향 |
| --- | --- | --- |
| 실현손익 | `realizedProfit` | 성과 원천 |
| 미실현손익 | `unrealizedProfit` | 보유 평가 변화 |
| 배당/이자 | `incomeAmount` | 수입 |
| 수수료 | `-feeAmount` | 비용 |
| 세금 | `-taxAmount` | 비용 |
| 순 투자성과 | derived total | 합계 |

디자인 메모:

- 막대는 chart library 없이 `FractionallySizedBox` 또는 custom row로 구현 가능합니다.
- 비용 row는 음수 방향 또는 muted negative tone을 사용합니다.
- 수익률 row와 매수/매도 금액은 이 카드의 하단 supplementary row로 낮은 위계에 둡니다.

bar 계산 규칙:

- bar 길이는 전체 합계가 아니라 구성 요소 중 절대값이 가장 큰 `maxAbsComponent`를 기준으로 계산합니다.
- `maxAbsComponent <= 0`이면 모든 bar를 0으로 처리하고 숫자 row만 표시합니다.
- 양수와 음수는 같은 row 안에서 색상과 정렬로 구분하되, 모바일에서는 좌우 대칭 chart보다 단일 bar + 부호 텍스트를 우선합니다.
- 전체 성과 대비 비중은 `amount / pureInvestmentPerformance`로 계산하되, 분모가 0에 가까우면 표시하지 않습니다.
- 비용만 있거나 total이 0인 경우에도 bar overflow와 NaN이 없어야 합니다.

### Section 3. Market And Risk Snapshot

기존 `고급 성과` 긴 리스트를 2열 metric grid로 재구성합니다.

섹션명은 `시장 비교와 위험`을 우선 후보로 사용합니다.

구성:

| 카드 | 값 | 보조 설명 |
| --- | --- | --- |
| 기간 수익률 | `periodReturn` | 입출금 보정 |
| S&P 500 | `benchmarkReturn` | 선택 기간 |
| 초과수익률 | `excessReturn` | %p |
| 변동성 | `annualizedVolatility` | 연율화 |
| Sharpe | `sharpeRatio` | 무위험수익률 차감 |
| 최대 낙폭 | `maxDrawdown` | 고점 대비 하락 |

디자인 메모:

- 설명문은 항상 펼치지 않고, 필요하면 info icon 또는 작은 caption으로 제한합니다.
- `데이터 부족` 상태를 value slot 안에서 낮은 contrast로 표시합니다.
- `무위험수익률`은 grid의 주 지표가 아니라 footer note로 내립니다.
- benchmark/risk-free-rate fetch 실패는 전체 페이지 오류가 아니라 해당 tile 또는 footer note의 fallback으로 처리합니다.

### Section 4. Monthly Performance Trend

기존 월별 리스트를 미니 차트 + row 조합으로 개선합니다.

구성:

- 최근 12개월 bar strip
- 월별 순 실현성과 row
- 월 row에는 실현, 수입, 비용 요약
- v1에서는 월별 미실현손익 변화는 제외하고 현재와 동일하게 실현성과 중심으로 둡니다.

디자인 메모:

- bar strip은 양수/음수 방향을 분리합니다.
- 12개월을 초과하면 "최근 12개월"만 기본 표시합니다.
- 추후 월 row tap 시 drill-down bottom sheet로 연결합니다.

### Section 5. Holding Contribution

기존 `종목별 실현손익`과 `보유 항목별 성과`의 중복을 줄입니다.

v1 선택안:

- 하나의 `종목별 성과` 섹션으로 통합합니다.
- 상단에 필터 chip과 정렬 segmented/dropdown을 둡니다.
- row에는 총 성과, 기여도, 실현/미실현/수입 breakdown을 표시합니다.
- 실현손익 랭킹은 별도 카드로 유지하지 않고, `실현` 필터로 보존합니다.

필터:

| 옵션 | 목적 |
| --- | --- |
| 전체 | 총 성과와 기여도 확인 |
| 실현 | 기존 실현손익 랭킹 대체 |
| 손실 | 손실 원인 확인 |
| 수입 | 배당/이자 기여 확인 |

정렬:

| 옵션 | 목적 |
| --- | --- |
| 총 성과 | 전체 기여도 확인 |
| 손실 | 손실 원인 확인 |
| 실현 | 매도 결과 확인 |
| 미실현 | 보유 평가 변화 확인 |
| 배당/이자 | 수입 기여 확인 |

디자인 메모:

- row trailing은 총 성과와 기여도를 우선합니다.
- 실현/미실현/수입은 row 하단 compact chips 또는 inline meta로 표시합니다.
- 추후 tap 시 보유 상세 또는 거래 근거 bottom sheet로 연결합니다.
- `실현` 필터에서는 realizedProfit이 0에 가까운 row를 숨기고, 기존 `_RealizedProfitRankingCard`와 같은 발견성을 유지합니다.

### Section 6. Excluded Cash Flow

기존 `제외 현금흐름` 카드는 유지하되 위계를 낮춥니다.

구성:

- 외부 입금
- 외부 출금
- 외부 입출금 합계
- 투자 결제 현금흐름
- 내부 이동

디자인 메모:

- "투자성과에 포함하지 않은 돈의 움직임"이라는 역할을 분명히 합니다.
- 상단 hero 아래가 아니라 attribution/risk/monthly 이후에 배치해도 됩니다.
- 단, 사용자 혼란을 줄이기 위해 첫 화면 summary에는 `입출금 제외 기준` 문구를 유지합니다.

## Screen Flow v1

권장 순서:

1. Performance Cockpit
2. Performance Attribution
3. Market And Risk Snapshot
4. Monthly Performance Trend
5. Holding Contribution
6. Excluded Cash Flow

대안 순서:

1. Performance Cockpit
2. Performance Attribution
3. Monthly Performance Trend
4. Holding Contribution
5. Market And Risk Snapshot
6. Excluded Cash Flow

권장안은 "성과 판단 -> 원인 -> 비교/위험 -> 상세 탐색" 흐름입니다. 대안은 고급 지표보다 월/종목 탐색을 더 빨리 보여주는 보수적 모바일 흐름입니다.

## Component Plan

새 private widget 후보:

| Widget | 역할 |
| --- | --- |
| `_PerformanceCockpitCard` | 상단 hero 요약 |
| `_PeriodSegmentedControl` | 기간 선택 UI 대체 |
| `_PerformanceAttributionCard` | 성과 breakdown + bar |
| `_AttributionRow` | 성과 구성 row |
| `_RiskMetricGridCard` | 시장 비교와 위험 metric grid |
| `_RiskMetricTile` | 개별 리스크 지표 |
| `_MonthlyTrendCard` | 월별 bar strip + list |
| `_MonthlyBarStrip` | 12개월 mini chart |
| `_HoldingContributionCard` | 종목별 성과 통합 |
| `_HoldingContributionRow` | 종목 row |
| `_ExcludedCashFlowCard` | 제외 현금흐름 카드 정리 |

재사용/교체 기준:

- 현재 `_MetricRow`는 새 디자인에 맞게 축소하거나 제거합니다.
- 현재 `_AdvancedMetricRow`는 metric tile로 대체합니다.
- 현재 `_RealizedProfitRankingCard`는 `_HoldingContributionCard`의 `실현` 필터로 통합합니다.
- 데이터 모델 `_InvestmentPerformanceReport`, `_AdvancedPerformanceReport`, `_MonthlyPerformance`, `_HoldingPerformance`는 유지합니다.

## Data Scope

v1 리디자인은 데이터 모델 변경을 최소화합니다.

유지:

- `_loadInvestmentPerformanceReport()`
- `_loadAdvancedPerformanceReport()`
- portfolio/monthly/holding aggregate API
- 기간 preset
- 최신 환율 기반 KRW 환산
- 현재 기준 미실현손익 산식

v1에서 추가하지 않는 것:

- 직접 기간 선택 date picker
- 월별 미실현손익 변화
- 과거 환율 기반 성과 재계산
- IRR/CAGR
- 완전한 drill-down 전용 상세 화면
- 종목별 수수료/세금 배부

## Responsive Rules

### Mobile

- cockpit mini metrics는 2열 grid 또는 wrap으로 배치합니다.
- risk metric은 2열을 기본으로 하되 360dp 이하에서는 1열 fallback을 허용합니다.
- holding row trailing 금액은 고정 폭 또는 `FittedBox`로 overflow를 방지합니다.
- bar strip은 카드 폭에 맞춰 12개 이하만 표시합니다.

### Tablet/Desktop Width

- cockpit 내부에서 대표 숫자와 mini metrics를 좌우 배치할 수 있습니다.
- risk metrics는 3열까지 확장할 수 있습니다.
- holding contribution은 더 넓은 matrix 스타일을 사용할 수 있습니다.

## Empty, Loading, Error States

### Loading

현재 빈 리포트 fallback 대신 skeleton을 사용합니다.

- cockpit skeleton
- attribution skeleton
- list skeleton

### Empty

empty state는 원인을 구분합니다.

| 상태 | 문구 방향 |
| --- | --- |
| 전체 투자 거래 없음 | 자산과 투자 거래를 추가하면 성과를 분석할 수 있음 |
| 선택 기간 내 데이터 없음 | 다른 기간을 선택하거나 거래를 추가하라는 안내 |
| 시장 비교와 위험 데이터 부족 | 일별 스냅샷이 충분하지 않아 계산 불가 |
| 월별 데이터 없음 | 기간 내 실현 손익/수입/비용 없음 |

### Error

- section-level `InlineError`와 retry action을 사용합니다.
- 네트워크 기반 benchmark/risk-free-rate 실패는 전체 페이지 에러로 만들지 않습니다.
- fallback 사용 시 risk grid footer에만 표시합니다.
- cockpit의 benchmark 문구도 동일한 fallback 상태를 공유합니다.

## Accessibility And Copy

- 모든 핵심 숫자는 금액/수익률/비교 기준을 함께 제공합니다.
- chart-only 표현을 피하고 row text로 동일한 정보를 제공합니다.
- "순 투자성과", "입출금 제외", "매수 원금 대비" 용어를 유지합니다.
- "고급 성과" 대신 "시장 비교와 위험" 같은 사용자가 이해하기 쉬운 섹션명을 사용합니다.

## Implementation Phases

### Phase 1. Structure Refactor

목표: 화면 순서와 widget 구조만 재배치합니다.

작업:

- `_PerformanceCockpitCard` 추가
- 기존 summary card 대체
- `_AdvancedPerformanceCard`를 `_RiskMetricGridCard` 또는 `_MarketAndRiskCard`로 대체
- 화면 순서를 v1 권장 순서로 변경
- benchmark fallback 문구를 cockpit과 risk grid에 반영

완료 기준:

- 기존 계산 테스트 영향 없음
- 모바일에서 첫 화면이 cockpit 중심으로 보임
- benchmark 데이터 부족 시 상단 문구가 깨지지 않음
- `flutter analyze lib/pages/investment_performance_page.dart` 통과

### Phase 2. Attribution Visual

목표: 성과 구성 카드를 원인 분해형으로 변경합니다.

작업:

- `_PerformanceAttributionCard` 구현
- 실현/미실현/배당/비용 bar 표현 추가
- 매수 원금/매도 회수금은 supplementary row로 정리
- `maxAbsComponent` 기준 bar 계산과 total 0 fallback 적용

완료 기준:

- 양수/음수 성과가 시각적으로 구분됨
- total 0 또는 모든 항목 0일 때 bar overflow 없음
- 비용만 있는 케이스에서도 NaN, infinity, overflow가 없음

### Phase 3. Monthly And Holding Exploration

목표: 리스트 탐색 경험을 개선합니다.

작업:

- `_MonthlyTrendCard`와 `_MonthlyBarStrip` 추가
- `종목별 실현손익`은 `Holding Contribution`의 `실현` 필터로 통합
- sort/filter control polish

완료 기준:

- 월별 추세를 스크롤 전에 이해할 수 있음
- 종목 row에서 총 성과와 기여도가 가장 먼저 보임
- 기존 실현손익 랭킹 사용성이 `실현` 필터로 보존됨

### Phase 4. State Polish

목표: 로딩/빈 상태/오류 상태를 제품급으로 정리합니다.

작업:

- FutureBuilder fallback 구조 개선
- skeleton/empty/error state 적용
- benchmark 데이터 부족 문구 정리

완료 기준:

- 빈 데이터, 데이터 부족, 로딩이 서로 다르게 보임
- 네트워크 benchmark 실패가 전체 페이지를 망치지 않음

### Phase 5. Optional Drill-Down Prep

목표: v1 이후 상세 탐색으로 이어질 탭 영역을 준비합니다.

작업:

- 월 row tap hook 준비
- 종목 row tap hook 준비
- 비용/세금 row tap hook 준비

완료 기준:

- 실제 drill-down UI 없이도 row 구조가 확장 가능함
- tap affordance가 있는 row와 없는 row가 시각적으로 구분됨

## Verification Plan

### Static Checks

- `flutter analyze lib/pages/investment_performance_page.dart`
- 가능하면 `flutter analyze`

### Widget/Walkthrough Checks

- `test/page_walkthrough_test.dart`의 `InvestmentPerformancePage` build smoke 유지
- 주요 문구 변경 시 기대 텍스트 업데이트
- `test/widget_test.dart`의 성과 계산 테스트 영향 없음 확인

### Manual QA

1. 기본 기간이 `올해`로 표시되는지 확인합니다.
2. 1개월, 3개월, 6개월, 전체 선택 시 화면 전체가 갱신되는지 확인합니다.
3. 순 투자성과 금액과 수익률이 overflow 없이 표시되는지 확인합니다.
4. 양수/음수 성과에서 색상과 bar 방향이 일관적인지 확인합니다.
5. 시장 비교와 위험 데이터가 부족할 때 `데이터 부족`이 섹션 안에서 표시되는지 확인합니다.
6. 월별 데이터가 없을 때 월별 카드만 empty state가 되는지 확인합니다.
7. 보유 항목이 많을 때 정렬 UI와 row trailing 값이 깨지지 않는지 확인합니다.

## Risks And Decisions

| 이슈 | 리스크 | v1 결정 |
| --- | --- | --- |
| 차트 직접 구현 | 복잡도가 커질 수 있음 | v1은 가벼운 bar/strip만 직접 구현 |
| 종목 카드 통합 | 기존 실현손익 랭킹의 명확성이 줄 수 있음 | `실현` 필터로 실현손익 랭킹을 보존 |
| 고급 지표 설명 축소 | 사용자가 Sharpe/MDD 의미를 모를 수 있음 | `시장 비교와 위험` 섹션명과 caption/info affordance를 사용 |
| benchmark fallback | 상단 hero가 빈 비교 문구로 보일 수 있음 | cockpit에 상태별 fallback 문구를 정의 |
| attribution bar 기준 | total 0 또는 비용만 있는 케이스에서 chart가 왜곡될 수 있음 | `maxAbsComponent` 기준으로 bar 길이를 계산 |
| 미실현손익 기간 해석 | 현재값 기반이라 월별 추세와 다를 수 있음 | v1에서는 기존 계산 유지, 문구로 한계 표시 |
| 외화 환산 | 최신 환율 사용으로 과거 성과 왜곡 가능 | v1 scope 밖, 기존 정책 유지 |

## Open Questions

- 상단 기간 선택은 `ChoiceChip` 유지가 좋은가, segmented control로 바꾸는가?
- 현금흐름 카드는 risk 뒤에 둘 것인가, attribution 바로 뒤에 둘 것인가?
- v1에서 monthly mini chart를 넣을 것인가, row redesign까지만 할 것인가?

## Recommended v1 Scope

바로 구현할 v1 최소 범위:

1. Performance Cockpit
2. Performance Attribution
3. Market And Risk Snapshot
4. Monthly Trend row polish
5. Holding Contribution 통합과 `전체/실현/손실/수입` 필터
6. Excluded Cash Flow 하위 위계 정리

v1에서 미루는 범위:

- 직접 기간 선택
- 완전한 drill-down
- 과거 환율
- 월별 미실현손익
- IRR/CAGR
- export/report 출력
