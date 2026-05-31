# Investment Performance Redesign Plan v2

작성일: 2026-05-30

## Goal

`투자성과 분석` 페이지를 기존 카드 나열형 원장 리포트에서 사용자가 투자 판단을 바로 할 수 있는 성과 대시보드로 완전히 재구성한다.

v2는 기존 v1 계획의 UI 개선안을 단순 확장하지 않는다. `page_information_inventory.md`의 표시 항목과 `investment_judgment_revision_plan.md`의 판단 구조를 새 정보 구조와 레이아웃 요구사항으로 흡수한다. 구현 목표는 "더 많은 카드"가 아니라 "첫 화면에서 판단하고, 아래로 내려가며 근거를 확인하는 화면"이다.

## Current Page Diagnosis

현재 페이지는 데이터가 부족한 화면이 아니다. 오히려 성과, 원인, 위험, 월별, 종목별, 제외 현금흐름을 모두 갖고 있다. 문제는 이 정보들이 같은 위계의 카드로 이어져서 사용자가 어떤 숫자를 기준으로 판단해야 하는지 즉시 알기 어렵다는 점이다.

| 문제 | 현재 상태 | 왜 문제인가 | v2 방향 |
| --- | --- | --- | --- |
| 판단 축 부족 | 요약, 원인, 위험, 월별, 종목별, 현금흐름이 병렬 카드로 나열됨 | 사용자가 "그래서 잘했나?"보다 "숫자가 많다"를 먼저 느낄 수 있음 | 첫 화면을 판단 영역으로 재구성하고 아래는 근거 탐색으로 둔다. |
| 순 투자성과 금액 중심 | `순 투자성과` 금액이 대표 지표 | 자산 규모가 크면 성과가 좋아 보이고, 기간/위험 대비 성과 판단이 약함 | `입출금 보정 기간 수익률`을 대표 판단 지표로 올리고 금액은 영향도 지표로 둔다. |
| 수익률 정의 혼선 | `매수 원금 대비 수익률`과 `기간 수익률`이 같이 존재 | 단순 원금 대비 비율과 일별 수익률 기반 성과가 같은 지표처럼 보일 수 있음 | 두 지표를 시각적으로 분리하고 역할을 명확히 쓴다. |
| S&P 500 단일 벤치마크 | 모든 사용자에게 S&P 500을 시장 비교처럼 표시 | 국내 주식, 현금성, 혼합 포트폴리오에는 부적절한 비교일 수 있음 | `시장` 표현을 줄이고 `참고 벤치마크`로 격하시킨다. |
| 종목별 비용 미배분 | 종목별 총 성과는 실현 + 미실현 + 수입이며 수수료/세금은 전체 비용에만 있음 | 종목별 성과가 실제 순성과보다 좋아 보일 수 있음 | v1에서는 비용 미배분을 명시하고, v2 후보로 부분 배분을 남긴다. |
| 월별 실현성과 오해 | 월별 섹션은 실현손익/수입/비용 중심 | 사용자가 월별 전체 계좌 성과로 읽을 수 있음 | `월별 확정 성과`로 이름을 바꾸고 미실현 평가 변화 제외를 고지한다. |
| 현금흐름과 총자산 변화 미연결 | 제외 현금흐름을 따로 보여줌 | 계좌 총액 변화와 투자성과의 관계를 검산하기 어려움 | 총자산 변화 검산 또는 현금흐름 연결 섹션을 만든다. |
| 위험 지표 해석 부족 | 변동성, Sharpe, 최대 낙폭이 숫자로만 표시 | 일반 사용자가 행동 가능한 의미를 얻기 어려움 | 숫자 + 짧은 해석 문장 + 데이터 부족 사유로 구성한다. |

## Product Principles

### 1. Rate Leads Judgment, Amount Explains Impact

성과 판단의 첫 기준은 금액이 아니라 수익률이다. `입출금 보정 기간 수익률`을 최상단 판단 지표로 사용하고, `순 투자성과` 금액은 사용자가 체감하는 영향도 지표로 함께 보여준다.

| 지표 | 역할 | v2 표시 위치 |
| --- | --- | --- |
| 입출금 보정 기간 수익률 | 투자 판단의 대표 지표 | 첫 화면 primary |
| 순 투자성과 | 실제 금액 영향 | 첫 화면 secondary |
| 매수 원금 대비 수익률 | 원장 기반 보조 비율 | first screen supporting 또는 tooltip |
| 초과수익률 | 참고 벤치마크 대비 판단 | 벤치마크 스냅샷 |

### 2. Benchmark Is A Reference, Not The Market

기본 S&P 500 비교는 유지하되, 모든 사용자에게 시장 전체 평가처럼 보이지 않게 한다. `시장 대비` 대신 `S&P 500 대비`, `참고 벤치마크` 같은 표현을 사용한다.

### 3. Reconcile Before Explaining Details

투자성과와 현금흐름을 분리해서 보여주는 데서 끝내지 않는다. 가능하면 시작/종료 총자산, 순 투자성과, 외부 입출금, 잔차를 연결해 사용자가 숫자를 검산할 수 있게 한다.

### 4. State Scope Clearly

월별, 종목별, 수익률, 미실현손익은 모두 계산 범위가 다르다. v2는 범위가 좁은 지표에 작은 helper/caption을 붙여 오해를 줄인다.

### 5. Translate Risk Metrics Into Meaning

위험 지표는 숫자 그리드로 끝내지 않는다. 변동성, Sharpe, 최대 낙폭은 짧은 해석 문장과 데이터 부족 이유를 같이 표시한다.

### 6. Mobile-First, Dense But Readable, Non-Marketing Dashboard

390dp 모바일을 기준으로 정보 밀도와 가독성을 맞춘다. 마케팅식 hero, 장식적인 카드, 큰 배경 그래픽은 쓰지 않는다. 업무형/SaaS형 화면처럼 차분하고 반복 사용에 강한 구조를 목표로 한다.

## New Information Architecture

v2의 정보 구조는 "판단 -> 비교 -> 원인 -> 검산 -> 상세 -> 기준" 순서다.

| 순서 | 영역 | 핵심 질문 | 기존 섹션 처리 |
| --- | --- | --- | --- |
| 1 | 첫 화면 판단 영역 | 이 기간 투자는 잘됐나? | 기존 요약 카드 재작성 |
| 2 | 벤치마크 스냅샷 | 참고 기준 대비 어땠나? | 기존 시장 비교 일부 분리 |
| 3 | 성과 원인 분석 | 무엇이 성과를 만들었나? | 기존 성과 원인 강화 |
| 4 | 총자산 변화 검산/현금흐름 연결 | 계좌 변화와 투자성과가 어떻게 이어지나? | 기존 제외 현금흐름 재구성 |
| 5 | 월별 확정 성과 | 어느 달에 확정 성과가 났나? | 기존 월별 실현성과 이름/범위 수정 |
| 6 | 종목별 기여도 | 어떤 종목이 기여했나? | 기존 종목별 성과 유지+명확화 |
| 7 | 위험 해석 | 성과의 흔들림과 낙폭은 어땠나? | 기존 위험 지표 재배치/해석 추가 |
| 8 | 데이터 기준/제외 항목 | 숫자는 어떤 기준인가? | 하단 부록성 안내로 이동 |

## Layout Plan

### 390dp Mobile Order

390dp 폭에서는 단일 컬럼을 기준으로 한다. 첫 화면에는 기간 선택, 대표 수익률, 순 투자성과, 참고 벤치마크 상태의 일부가 보여야 한다. 사용자가 스크롤하기 전부터 "성과 판단"이 가능해야 한다.

```text
MoneyfyPage(title: 투자성과 분석)

[Period selector: 1개월 | 3개월 | 6개월 | 올해 | 전체]

Judgment Header
  기간 수익률 +4.2%
  입출금 영향을 제외한 성과
  순 투자성과 +420,000원
  매수 원금 대비 +3.8%

Benchmark Strip
  참고 벤치마크 S&P 500 대비 +1.2%p
  S&P 500 +3.0%

Attribution Summary
  가장 큰 플러스/마이너스 원인
  실현 / 미실현 / 수입 / 비용 breakdown

Reconciliation
  순 투자성과 + 외부 입출금 -> 계좌 변화 설명

Monthly Confirmed Performance
  mini bar + 최근 12개월 row

Holding Contribution
  filter + sort + rows

Risk Interpretation
  변동성 / Sharpe / 최대 낙폭

Data Basis
  제외 항목, 비용 미배분, 월별 범위, 환율 기준
```

### Section Details

| 섹션 | 표시 정보 | 레이아웃 |
| --- | --- | --- |
| Judgment Header | 기간 수익률, 순 투자성과, 매수 원금 대비 수익률, 데이터 상태 | 카드 느낌을 줄인 상단 패널. 숫자 pair를 세로 배치. |
| Benchmark Strip | 내 기간 수익률, S&P 500 수익률, 초과수익률, 데이터 부족 상태 | 얇은 strip 또는 compact panel. 첫 화면 안에 일부 노출. |
| Attribution Summary | 가장 큰 플러스/마이너스 원인, 실현/미실현/수입/비용, 순 투자성과 | waterfall-like breakdown. 막대는 숫자 보조 역할. |
| Reconciliation | 순 투자성과, 외부 입출금, 내부 이동, 투자 결제, 가능하면 시작/종료 총자산 | row stack. 검산 가능 시 잔차 표시. |
| Monthly Confirmed Performance | 최근 12개월 확정 성과, 실현/수입/비용 | mini bar + rows. 미실현 제외 caption 필수. |
| Holding Contribution | 필터, 정렬, 종목명, 보조 정보, 총 성과, 기여율, 실현/미실현/수입 | dense row/table. 비용 미배분 caption 필수. |
| Risk Interpretation | 변동성, Sharpe, 최대 낙폭, 데이터 부족 사유 | tile grid 또는 stacked compact tiles. 해석 문장 중심. |
| Data Basis | 제외 현금흐름 정의, 환율 기준, 계산식 요약 | accordion/low-emphasis section. |

### Existing Section Mapping

| 기존 섹션 | v2 처리 |
| --- | --- |
| `_PerformanceCockpitCard` | 완전 재작성. 대표 지표를 기간 수익률로 변경. |
| `_PerformanceAttributionCard` | 유지하되 해석 문장과 breakdown 우선순위 추가. |
| `_MarketAndRiskCard` | 분리. 벤치마크는 상단 strip, 위험은 하단 해석 섹션. |
| `_MonthlyTrendCard` | 이름을 `월별 확정 성과`로 변경하고 범위 안내 추가. |
| `_HoldingContributionCard` | 데이터 재사용. 비용 미배분 안내와 더 조밀한 row로 조정. |
| `_CashFlowExclusionCard` | `총자산 변화 검산` 또는 `성과와 현금흐름 연결`로 재구성. |

### First View Requirements

390dp 모바일에서 첫 화면에 들어와야 하는 정보:

1. 기간 selector
2. 기간 수익률 또는 데이터 부족 fallback
3. 순 투자성과 금액
4. 매수 원금 대비 수익률 또는 "원금 대비 데이터 부족"
5. 참고 벤치마크 대비 상태의 첫 줄

스크롤 하단으로 내려도 되는 부록성 정보:

- 제외 현금흐름 상세 정의
- 환율 기준
- 비용 미배분 상세 설명
- 월별 미실현손익 제외 상세 설명
- 데이터 소스/계산식 목록

## Design Direction

### Design Source Of Truth

모든 디자인 요소는 기존 MONEYFY 디자인 문서와 디자인 토큰을 우선한다. 특별한 사유가 명확히 문서화된 경우가 아니라면, 이 리디자인에서 자체적인 하드코딩 값이나 새로운 디자인 문법을 만들지 않는다.

우선 참조 순서:

| 기준 | 용도 |
| --- | --- |
| `docs/design_system.md` | MONEYFY 전체 디자인 시스템 기준 |
| `docs/features/simple_patches/design_md_full_compliance/component_contract.md` | 카드, 패널, row, chip, chart 등 화면 구성 요소 계약 |
| `docs/features/simple_patches/design_token_unification/plan.md` | 토큰 통합 방향과 legacy token 회피 기준 |
| `lib/design_system/tokens.dart` | spacing, radius, color token source |
| `lib/design_system/spec/visual_spec.dart` | 시각 토큰과 표면/경계 규칙 |
| `lib/design_system/context_extensions.dart` | Flutter UI에서 토큰에 접근하는 기본 방식 |
| `lib/widgets/moneyfy_ui.dart` | 기존 Moneyfy page, badge, pill, shared UI 문법 |

금지 원칙:

- 색상 hex, 임의 opacity, 임의 radius, 임의 spacing 값을 새로 하드코딩하지 않는다.
- 기존 token/context extension으로 표현 가능한 typography, color, spacing, radius를 직접 값으로 만들지 않는다.
- 기존 `SectionCard`, `MoneyfyBadge`, `MoneyfyPill`, `AppMetricTile`, row/panel 계열 컴포넌트로 해결 가능한 UI를 새 문법으로 재발명하지 않는다.
- chart/bar 등 시각 요소도 기존 semantic color와 spacing/radius token을 사용한다.
- 예외가 필요하면 해당 값, 이유, 대체 불가 사유, 추후 token화 계획을 구현 문서나 코드 주석에 남긴다.

### Visual Language

MONEYFY의 기존 디자인 시스템을 유지하되 화면 성격은 리포트보다 대시보드에 가깝게 만든다.

| 원칙 | 적용 |
| --- | --- |
| 조용한 정보형 대시보드 | 큰 장식, 마케팅식 hero, 과한 배경 효과를 쓰지 않는다. |
| 촘촘하지만 숨 쉴 공간 | 숫자와 label 간 간격을 작게, 섹션 간 구분은 명확하게 둔다. |
| semantic color 중심 | positive/negative/neutral 색만 성과 방향에 사용한다. |
| 카드 남발 금지 | 모든 섹션을 독립 카드로 띄우지 않고, 페이지 안의 패널/밴드처럼 다룬다. |
| 중첩 카드 금지 | 카드 안에 또 카드형 metric grid를 넣지 않는다. |
| 차트는 보조 | 차트는 숫자 판단을 돕는 작은 bar/strip 수준으로 제한한다. |
| 긴 한글 대응 | 모든 caption/helper는 2줄 wrap 가능, 버튼/칩은 고정 높이와 horizontal scroll 사용. |

### Component Tone

- 상단 judgment header는 `SectionCard`보다 더 넓고 낮은 밀도의 panel로 설계한다.
- 반복 row는 `AppMetricTile`보다 더 압축된 list row를 우선한다.
- 차트는 커스텀 `Container`/`FractionallySizedBox` 기반 mini visualization으로 충분하다.
- lucide 아이콘은 경고/정보/help affordance에만 제한적으로 사용한다.
- 색은 성과 부호에만 쓰고, 영역 구분은 neutral border/background로 처리한다.

## Visual Elements

### 1. Judgment Header

```text
기간 수익률
+4.2%
입출금 영향을 제외한 성과

순 투자성과 +420,000원
원금 대비 +3.8%
```

상태:

| 상태 | 표시 |
| --- | --- |
| 기간 수익률 있음 | 수익률을 primary로 표시 |
| 기간 수익률 없음 | `기간 수익률 데이터 부족` + 순 투자성과 금액 fallback |
| 순 투자성과 0 | neutral color, 보조 문구는 유지 |
| 매수 원금 0 | 원금 대비 수익률 배지 숨김 또는 데이터 부족 표시 |

### 2. Period Control

기존 chip control을 유지하되 상단 전용 segmented/chip control로 고정 높이를 둔다.

요구사항:

- 390dp에서 horizontal scroll 허용
- 선택 chip은 primary tone, 비선택은 neutral outline
- text scale 1.3에서도 label overflow 없어야 함

### 3. Benchmark Comparison Strip

```text
참고 벤치마크
S&P 500 대비 +1.2%p
내 수익률 +4.2% · S&P 500 +3.0%
```

데이터 부족 상태:

- `참고 벤치마크 가격을 아직 확보하지 못했습니다.`
- `평가 데이터가 더 쌓이면 비교할 수 있습니다.`
- 네트워크 실패는 전체 페이지 실패로 전파하지 않고 strip 내부 상태로만 표시한다.

### 4. Attribution Breakdown

성과 원인은 막대와 숫자를 같이 표시한다.

```text
이번 기간 성과는 미실현손익이 가장 크게 만들었습니다.

실현손익      +120,000원     28.6%
미실현손익    +310,000원     73.8%
배당/이자      +20,000원      4.8%
수수료         -8,000원     -1.9%
세금          -22,000원     -5.2%
```

막대 규칙:

- bar 길이는 구성 요소 중 최대 절대값 기준
- 양수는 positive, 음수는 negative
- total이 0이면 기여율 생략
- bar가 숫자보다 더 눈에 띄지 않게 높이 6-8px 유지

### 5. Reconciliation Rows

검산 가능 시:

```text
총자산 변화 검산
시작 총자산       10,000,000원
순 투자성과        +420,000원
외부 입출금        +300,000원
종료 총자산       10,720,000원
차이                    0원
```

검산 불가능 시:

```text
성과와 현금흐름
순 투자성과는 입출금과 내부 이동을 제외한 투자 결과입니다.
외부 입금 +300,000원 · 외부 출금 -50,000원
```

### 6. Monthly Mini Bar Chart

`월별 확정 성과`로 표시한다.

요구사항:

- 최근 최대 12개월
- bar label은 `MM`
- row에는 `실현`, `수입`, `비용`, `순 확정 성과`
- caption: `미실현 평가 변화는 포함하지 않습니다.`

### 7. Holding Contribution Rows

종목별 row는 표처럼 스캔 가능해야 한다.

```text
삼성전자
국내주식 · 005930 · KRW
실현 +40,000  미실현 -12,000  수입 +3,000
총 성과 +31,000     전체 대비 7.4%
```

요구사항:

- filter: 전체, 실현, 손실, 수입
- sort: 총 성과, 손실, 실현, 미실현, 배당/이자
- caption: `수수료와 세금은 전체 비용으로 표시되며 종목별로 배분하지 않습니다.`
- row 금액은 FittedBox 또는 wrap-safe layout 사용

### 8. Risk Interpretation Tiles

```text
변동성
연 +18.2%
수익률 변동이 있는 편입니다.

최대 낙폭
-7.4%
선택 기간 중 고점 대비 가장 큰 하락입니다.
```

Sharpe 데이터 부족 시:

```text
Sharpe
데이터 부족
최소 기간 데이터가 더 필요합니다.
```

### 9. Empty And Data-Limited States

| 상황 | 표시 |
| --- | --- |
| 거래 없음 | 판단 header는 0/데이터 부족 상태, 아래 섹션은 빈 상태 문구 |
| 벤치마크 없음 | benchmark strip 내부에만 안내 |
| 환율 없음 | USD 환산 기준 fallback 안내를 데이터 기준 섹션에 표시 |
| 일별 수익률 부족 | 기간 수익률/위험 지표에 구체적 이유 표시 |
| 스냅샷 없음 | 미실현손익 기준점 부족 안내 |

## Data And Calculation Contract

### Existing Report Data Reuse

`_InvestmentPerformanceReport`에서 재사용 가능한 항목:

| 데이터 | v2 사용처 |
| --- | --- |
| `realizedProfit` | 성과 원인, 월별/종목별 보조 |
| `unrealizedProfit` | 순 투자성과, 성과 원인 |
| `incomeAmount` | 성과 원인, 수입 표시 |
| `feeAmount`, `taxAmount` | 비용, 비용 영향, 데이터 기준 |
| `buyAmount`, `sellAmount` | 매수 원금 대비 수익률, 보조 정보 |
| `pureRealizedPerformance` | 월별 확정 성과/요약 |
| `pureInvestmentPerformance` | 순 투자성과 금액 |
| `pureInvestmentPerformanceRate` | 매수 원금 대비 보조 수익률 |
| `monthlyPerformance` | 월별 확정 성과 |
| `holdings` | 종목별 기여도 |
| `advancedPerformance.periodReturn` | judgment header primary |
| `advancedPerformance.benchmarkReturn` | benchmark strip |
| `advancedPerformance.excessReturn` | benchmark strip |
| `advancedPerformance.annualizedVolatility` | risk interpretation |
| `advancedPerformance.sharpeRatio` | risk interpretation |
| `advancedPerformance.maxDrawdown` | risk interpretation |
| `externalDepositAmount`, `externalWithdrawalAmount`, `externalCashFlowAmount` | reconciliation/cash flow |
| `tradeSettlementCashFlowAmount`, `internalCashMovementAmount` | data basis/cash flow detail |

### New Data Needed

| 데이터 | 필요성 | v2 처리 |
| --- | --- | --- |
| 시작 총자산 | 총자산 변화 검산 | 스냅샷으로 가능 여부 audit |
| 종료 총자산 | 총자산 변화 검산 | 현재 평가액 또는 종료 스냅샷 필요 |
| reconciliation 잔차 | 검산 신뢰도 | 가능할 때만 표시 |
| 데이터 부족 사유 enum | copy와 빈 상태 분리 | view model에 추가 |
| 벤치마크 fetch 상태 | benchmark strip 상태 표시 | service 결과를 report에 반영 |
| 스냅샷 기준점 상태 | 미실현손익 helper | baseline snapshot 유무 전달 |

### Data-Limited State Model

단순 `null`만으로는 사용자 안내가 약하다. v2 view model에는 상태 이유를 둔다.

```text
PerformanceMetricState
- available(value)
- noTransactions
- missingDailyReturns
- missingBenchmarkPrices
- missingRiskFreeRate
- insufficientObservations
- missingSnapshotBaseline
- unavailable(reason)
```

구현은 Dart sealed class가 아니어도 enum + nullable value로 시작해도 된다.

### Definitions

```text
순 실현성과 = 실현손익 + 배당/이자 - 수수료 - 세금
순 투자성과 = 순 실현성과 + 미실현손익
매수 원금 대비 수익률 = 순 투자성과 / 매수 원금 * 100
기간 수익률 = 일별 입출금 보정 수익률의 누적 복리
초과수익률 = 기간 수익률 - 참고 벤치마크 기간 수익률
종목 총 성과 = 실현손익 + 미실현손익 + 수입
기여율 = 항목 금액 / 전체 순 투자성과 * 100
월별 확정 성과 = 월별 실현손익 + 월별 수입 - 월별 수수료 - 월별 세금
```

### v1 Scope Decisions Inside v2 Redesign

| 항목 | 결정 |
| --- | --- |
| 종목별 비용 배분 | v2 첫 구현에서는 하지 않는다. 화면에 `비용 미배분`을 명시한다. |
| 월별 미실현손익 | v2 첫 구현에서는 제외한다. `월별 확정 성과`로 이름을 바꾸고 caption으로 고지한다. |
| S&P 500 | 기본 참고 벤치마크로 유지한다. 비교 표현만 조정한다. |
| 총자산 검산 | 데이터가 안정적으로 확보되면 표시하고, 아니면 현금흐름 연결 카드로 fallback한다. |
| IRR/MWRR/XIRR | 이번 리디자인 범위에서 제외한다. |

## Implementation Phases

실행 단계는 아래 분리 문서를 기준으로만 진행한다. 이 v2 문서는 총괄 방향 문서이며, 각 단계의 세부 작업과 완료 조건은 `plan_parts` 문서가 source of truth다.

| Phase | 문서 | 역할 | 완료 조건 |
| --- | --- | --- | --- |
| 0 | `plan_parts/00_audit_and_boundaries.md` | 현재 구조, 데이터, 디자인 토큰 이탈, 구현 경계 확정 | widget/data/design audit와 open question 분리 완료 |
| 1 | `plan_parts/01_ia_and_copy_contract.md` | 새 IA, 섹션명, copy, 데이터 부족 문구 고정 | 섹션 순서, first-view wireframe, copy table 완료 |
| 2 | `plan_parts/02_report_view_model_contract.md` | UI용 report/view model과 metric state 계약 정의 | unavailable reason, attribution, reconciliation state 정의 완료 |
| 3 | `plan_parts/03_judgment_header.md` | 첫 화면 판단 영역과 benchmark strip 구현 | 360/390/430dp에서 header와 benchmark strip 검증 완료 |
| 4 | `plan_parts/04_attribution_and_reconciliation.md` | 성과 원인과 현금흐름/총자산 변화 연결 | attribution, 비용 영향, reconciliation/fallback 검증 완료 |
| 5 | `plan_parts/05_detail_sections_and_risk.md` | 월별, 종목별, 위험 해석 영역 재구성 | 월별/종목별/risk null 상태와 overflow 검증 완료 |
| 6 | `plan_parts/06_responsive_empty_states_and_qa.md` | 반응형, 빈 상태, 테스트, visual QA | analyze/test/viewport/text scale/QA report 완료 |

### Phase Boundary Rule

- 각 phase는 해당 `plan_parts` 문서의 `Completion Gate`를 모두 만족해야 완료된다.
- Completion Gate를 막지 않는 새 아이디어는 즉시 구현하지 않고 follow-up으로 기록한다.
- 다음 phase에 이미 정의된 작업을 현재 phase에서 앞당겨 구현하지 않는다.
- 어느 phase에도 없는 작업은 이 v2 범위에 속하지 않는다. 별도 계획서가 필요하다.

## Test And Verification Plan

### Unit Tests

| 대상 | 테스트 |
| --- | --- |
| 순 실현성과 | `realized + income - fee - tax` |
| 순 투자성과 | `pureRealized + unrealized` |
| 매수 원금 대비 수익률 | 매수 원금 0이면 null |
| 기간 수익률 상태 | daily return 없음/있음 |
| attribution summary | 가장 큰 플러스/마이너스 요인 |
| benchmark state | benchmark return 없음/있음 |
| risk state | 관측치 부족, 금리 fallback |
| reconciliation | 스냅샷 있음/없음, 잔차 계산 |

### Widget Tests

| 상태 | 기대 |
| --- | --- |
| 데이터 없음 | judgment header가 깨지지 않고 empty copy 표시 |
| 일부 데이터 있음 | 순 투자성과는 표시, 기간 수익률은 데이터 부족 표시 |
| 환율 없음 | USD fallback 기준이 데이터 기준 영역에 표시 |
| 벤치마크 없음 | benchmark strip 내부 안내만 표시 |
| Sharpe 부족 | `최소 기간 데이터가 더 필요합니다.` 표시 |
| 종목 필터 결과 없음 | 필터별 빈 상태 문구 표시 |
| 월별 데이터 없음 | 월별 확정 성과 empty state 표시 |

### Visual QA

확인 viewport:

- 360dp, text scale 1.0
- 390dp, text scale 1.0
- 430dp, text scale 1.0
- 390dp, text scale 1.3

확인 항목:

- 기간 chip overflow 없음
- primary 수익률과 순 투자성과 금액이 겹치지 않음
- benchmark strip이 첫 화면에서 과도하게 커지지 않음
- attribution bar가 숫자를 밀어내지 않음
- holding row의 긴 종목명/심볼/통화가 wrap 또는 scaleDown 처리됨
- 빈 상태 문구가 버튼/다음 섹션과 겹치지 않음
- positive/negative 색이 neutral text와 충분히 구분됨

### Regression Guardrails

- 기존 원장 집계 함수의 계산식은 변경하지 않는다.
- `snapshot_restore`, `history_display` 제외 조건을 유지한다.
- USD 환산 기준 변경은 별도 기능으로 분리한다.
- benchmark fetch 실패가 전체 페이지 실패로 이어지지 않아야 한다.
- 비용 미배분 상태를 숨기지 않는다.
- 모든 신규 UI는 `docs/design_system.md`, design md component contract, `lib/design_system` token/context extension을 따른다.
- 특별한 사유 없이 색상, spacing, radius, typography, opacity를 하드코딩하지 않는다.
- 새 디자인 문법이나 일회성 컴포넌트는 기존 컴포넌트/토큰으로 표현할 수 없을 때만 추가한다.

## Deliverables

v2 리디자인 구현이 끝났을 때 기대 산출물:

1. `lib/pages/investment_performance_page.dart`의 IA 재구성
2. 판단 중심 view model 또는 derived state 추가
3. 새 상단 judgment header
4. benchmark strip
5. attribution breakdown + interpretation copy
6. reconciliation/cash flow section
7. monthly confirmed performance section
8. holding contribution section with cost caveat
9. risk interpretation tiles
10. empty/data-limited state tests
11. mobile visual QA 기록

## Open Decisions

| 결정 | 후보 | 권장 |
| --- | --- | --- |
| 총자산 검산 방식 | 스냅샷 기반 / 현재 평가액 기반 / fallback only | Phase 0 audit 후 결정 |
| benchmark 위치 | header 안 / header 바로 아래 strip / risk 영역 | header 바로 아래 strip |
| 위험 영역 위치 | 상단 / 종목별 위 / 하단 | 하단. 판단 보조로 두되 첫 화면을 차지하지 않음 |
| 비용 미배분 표현 | caption / info tooltip / row label | caption + 데이터 기준 부록 |
| 월별 이름 | 월별 실현성과 / 월별 확정 성과 | 월별 확정 성과 |
