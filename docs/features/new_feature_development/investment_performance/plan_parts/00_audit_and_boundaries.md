# 00. Audit And Boundaries

상태: 완료

## Role

v2 리디자인을 시작하기 전에 현재 페이지의 구조, 데이터 의존성, 디자인 시스템 준수 여부, 구현 경계를 확정한다.

이 단계는 구현 단계가 아니다. 화면을 바꾸지 않는다.

## Inputs

- `lib/pages/investment_performance_page.dart`
- `docs/features/new_feature_development/investment_performance/redesign_plan_v2.md`
- `docs/features/new_feature_development/investment_performance/page_information_inventory.md`
- `docs/design_system.md`
- `docs/features/simple_patches/design_md_full_compliance/component_contract.md`
- `docs/features/simple_patches/design_token_unification/plan.md`
- `lib/design_system/tokens.dart`
- `lib/design_system/context_extensions.dart`
- `lib/design_system/spec/visual_spec.dart`

## Audit Summary

| 항목 | 결정 |
| --- | --- |
| 현재 페이지 구조 | 단일 `InvestmentPerformancePage` 파일 안에 화면, report loading, view model 성격의 private model이 모두 공존 |
| 리디자인 방식 | 기존 카드 구조 위 덧칠이 아니라 section 재배열 + 일부 widget 재작성 필요 |
| 총자산 검산 가능 여부 | `불확실` |
| 총자산 검산 판단 이유 | 스냅샷 table/API는 있으나 기간 시작/종료 기준과 snapshot 가용성 fallback 규칙이 아직 확정되지 않음 |
| 디자인 시스템 준수 상태 | 대체로 `context.*`, `SectionCard`, `MoneyfyBadge`, `AppMetricTile` 사용 중이나 chart geometry/divider height 등 직접 수치가 존재 |
| 구현 시작 가능 여부 | 01/02 계약 확정 이후 가능. 이 문서만으로 UI 구현 금지 |

## Widget Map

| Widget/Class | 현재 역할 | v2 처리 |
| --- | --- | --- |
| `InvestmentPerformancePage` | 페이지 shell, FutureBuilder, section 순서, 기간/필터/정렬 state 관리 | 유지하되 section 순서와 child widget 구성을 재작성 |
| `_DateRangeSelector` | 기간 preset chip row | 유지. header 내부로 이동 가능 |
| `_PerformanceCockpitCard` | 현재 핵심 요약. 순 투자성과 금액이 primary | 재작성. `_PerformanceJudgmentHeader` 성격으로 변경 |
| `_StatusPill` | 원금 대비/benchmark 상태 badge | 일부 재사용 가능. copy/state는 02/03 계약 기준으로 변경 |
| `_MiniMetricGrid` | 요약 카드 하단 2열 metric grid | 축소/재배치. header supporting metric 또는 제거 후보 |
| `_MiniMetricTile` | `AppMetricTile` wrapper | 재사용 가능하나 중첩 카드/metric 과밀 여부 확인 필요 |
| `_PerformanceAttributionCard` | 실현/미실현/수입/비용 breakdown + 요약 row | 유지 기반 재작성. 해석 문장과 compact breakdown 추가 |
| `_AttributionRow` | 금액, 기여율, bar 표시 | 재사용 가능. bar geometry/token 점검 필요 |
| `_MarketAndRiskCard` | benchmark와 risk metric을 한 grid에 표시 | 분리 대상. benchmark strip과 risk interpretation tiles로 나눔 |
| `_RiskMetricTile` | risk metric `AppMetricTile` wrapper | risk tile 재작성 시 일부 재사용 가능 |
| `_CashFlowExclusionCard` | 제외 현금흐름 row 목록 | 재작성. reconciliation/fallback section으로 변경 |
| `_MonthlyTrendCard` | 최근 최대 12개월 월별 실현성과 | 유지 기반 수정. 이름/caption을 `월별 확정 성과`로 변경 |
| `_MonthlyBarStrip` | 월별 mini bar strip | 유지 가능. chart geometry 예외로 관리 |
| `_MonthlyBar` | 단일 월 bar | 유지 가능. height/radius/token 확인 필요 |
| `_MonthlyTrendRow` | 월별 row | copy 변경 및 row density 조정 |
| `_HoldingContributionCard` | 종목별 필터, 정렬, row 목록 | 유지 기반 수정. 비용 미배분 caption과 row density 조정 |
| `_HoldingContributionRow` | 종목별 성과 row | 유지 기반 수정. 긴 텍스트/금액 overflow 검증 필요 |
| `_MetricPill` | 종목별 실현/미실현/수입 badge | 재사용 가능. badge copy/색상 token 확인 필요 |
| `_InvestmentChoiceChip` | ChoiceChip token wrapper | 유지. period/filter chip 공용 사용 |
| `_MetricRow` | label/value/trailing row | reconciliation/detail row로 재사용 가능 |

## Data Map

### `_InvestmentPerformanceReport`

| Field/Getter | 현재 사용처 | Null 가능성 | v2 사용 |
| --- | --- | --- | --- |
| `holdings` | 종목별 성과 | non-null list | 종목별 기여도 |
| `monthlyPerformance` | 월별 실현성과 | non-null list | 월별 확정 성과 |
| `advancedPerformance` | benchmark/risk | non-null object, 내부 nullable | judgment/benchmark/risk |
| `realizedProfit` | 성과 원인 | non-null double | 성과 원인 |
| `unrealizedProfit` | 요약, 성과 원인 | non-null double | 순 투자성과/성과 원인 |
| `incomeAmount` | 요약, 성과 원인 | non-null double | 성과 원인 |
| `feeAmount` | 성과 원인/비용 | non-null double | 비용 영향 |
| `taxAmount` | 성과 원인/비용 | non-null double | 비용 영향 |
| `externalCashFlowAmount` | 제외 현금흐름 | non-null double | 현금흐름 연결 |
| `externalDepositAmount` | 제외 현금흐름 | non-null double | 현금흐름 연결 |
| `externalWithdrawalAmount` | 제외 현금흐름 | non-null double | 현금흐름 연결 |
| `tradeSettlementCashFlowAmount` | 제외 현금흐름 | non-null double | 데이터 기준/현금흐름 상세 |
| `internalCashMovementAmount` | 제외 현금흐름 | non-null double | 데이터 기준/현금흐름 상세 |
| `buyAmount` | 매수 원금, 수익률 분모 | non-null double, 0 가능 | 원금 대비 수익률 |
| `sellAmount` | 매도 회수금 | non-null double | 부록/데이터 기준 후보 |
| `pureRealizedPerformance` | 요약/성과 원인 | derived non-null | 월별/성과 원인 |
| `pureInvestmentPerformance` | primary amount | derived non-null | 순 투자성과 secondary |
| `pureRealizedPerformanceRate` | 성과 원인 trailing | nullable | 보조 후보 |
| `pureInvestmentPerformanceRate` | 요약 badge | nullable | `원금 대비` |
| `totalExpenseAmount` | 비용 tile/monthly row | derived non-null | 비용 영향 |

### `_AdvancedPerformanceReport`

| Field/Getter | Null 가능성 | Null/상태 원인 | v2 사용 |
| --- | --- | --- | --- |
| `benchmarkCode` | non-null | 기본 `SP500` | 데이터 기준 |
| `benchmarkLabel` | non-null | 기본 `S&P 500` | 참고 벤치마크 |
| `periodReturn` | nullable | daily returns가 비어 있거나 valid return 없음 | header primary |
| `benchmarkReturn` | nullable | benchmark boundary price 부족 또는 portfolio return 없음 | benchmark strip |
| `excessReturn` | nullable | periodReturn 또는 benchmarkReturn 부족 | benchmark strip |
| `annualizedVolatility` | nullable | daily returns 20개 미만 또는 계산 불가 | 위험 해석 |
| `sharpeRatio` | nullable | daily returns 60개 미만, 변동성 0, risk-free invalid | 위험 해석 |
| `riskFreeRate` | non-null double | fallback 시 0 | 위험 해석 |
| `riskFreeRateSource` | nullable | risk-free data 없음 | 데이터 기준 후보 |
| `riskFreeRateDate` | nullable | risk-free data 없음 | 위험 해석 footer |
| `isRiskFreeRateFallback` | non-null bool | risk-free data 없음 | 위험 해석 copy |
| `maxDrawdown` | nullable | portfolio value 관측치 2개 미만 또는 invalid value | 위험 해석 |
| `riskFreeRateLabel` | non-null string | fallback/date 기반 | 위험 해석 |

## Data Loading Map

| 호출 | 현재 용도 | v2 영향 |
| --- | --- | --- |
| `fetchAssets()` | 표시 대상 자산/종목 목록 | 종목별 기여도와 현재 미실현손익 기준 |
| `fetchLedgerHoldingPerformanceByHoldingId(from, to)` | 종목별 실현/수입/매수/매도 | 종목별 기여도 유지 |
| `fetchLedgerPortfolioPerformanceByCurrency(from, to)` | 전체 성과와 현금흐름 | 성과 원인, 현금흐름 연결 |
| `fetchLedgerMonthlyPerformanceByCurrency(from, to)` | 월별 확정 성과 | `월별 확정 성과` 유지 |
| `fetchLatestExchangeRate()` | USD portfolio/monthly 집계 KRW 환산 fallback | 환율 fallback copy 필요 |
| `fetchPreviousPortfolioSnapshot(from)` | 기간 시작 전 미실현손익 기준점 | 스냅샷 부족 상태 필요 |
| `fetchPortfolioSnapshotHoldingItemsByDates()` | 시작 전 종목별 미실현손익 | 스냅샷 기준 helper 필요 |
| `rebuildPortfolioDailyReturns(from, to)` | daily return 파생 재계산 | header periodReturn/risk의 선행 작업 |
| `fetchPortfolioDailyReturns(from, to)` | periodReturn/risk/maxDrawdown | 데이터 부족 reason 필요 |
| `ensureBenchmarkPrices()` | S&P 500 가격 캐시 확보 | 실패 상태가 현재 report에 명시적으로 안 들어옴 |
| `ensureRiskFreeRates()` | risk-free rate 캐시 확보 | fallback 상태는 bool로만 표현 |
| `compareBenchmarkPeriodReturn()` | benchmarkReturn/excessReturn 계산 | benchmark 부족 reason 세분화 필요 |

## Reconciliation Feasibility

결정: `불확실`

근거:

| 근거 | 내용 |
| --- | --- |
| 가능한 단서 | `DailyPortfolioSnapshots`에 `snapshotDate`, `totalValuationAmount`, `totalPurchaseAmount`, `profitAmount`, `profitRate`가 있음 |
| 가능한 API | `fetchPortfolioSnapshotByDate`, `fetchPreviousPortfolioSnapshot`, `fetchNextPortfolioSnapshot`, `fetchRecentPortfolioSnapshots`, `fetchAllPortfolioSnapshots` |
| daily return 단서 | `PortfolioDailyReturns`에 `beginningValueKrw`, `endingValueKrw`, `portfolioValueKrw`, `externalCashFlowKrw`, `dailyReturn`, `dataQuality`가 있음 |
| 제약 | 스냅샷은 on-device 생성이 아니라 server-delivered payload 기반이라 기간 시작/종료 스냅샷이 없을 수 있음 |
| 제약 | 현재 `InvestmentPerformanceReport`에는 시작/종료 총자산이나 reconciliation residual이 없음 |
| 제약 | `전체` 기간은 시작 기준을 무엇으로 둘지 별도 정의가 필요 |
| 제약 | 내부 이동/투자 결제 현금흐름은 총자산 변화 검산에 직접 합산하면 중복/오해 가능 |

Phase 2 결정 필요:

- 시작 총자산: `from` 날짜 이전 snapshot, `from` 날짜 snapshot, 또는 first available snapshot 중 무엇을 쓸지 결정.
- 종료 총자산: `to` 날짜 snapshot, previous snapshot, 또는 현재 `fetchAssets()` 평가액 중 무엇을 쓸지 결정.
- 검산 불가 시 fallback을 `성과와 현금흐름`으로 고정할지 결정.

## Design Compliance Note

현재 페이지는 대체로 MONEYFY 토큰 문법을 따르지만, v2 재작성 시 아래 항목을 주의한다.

### Reusable/Compliant Patterns

| 패턴 | 상태 |
| --- | --- |
| `MoneyfyPage` | 재사용 |
| `SectionCard` | 재사용 가능. 단, 카드 남발을 줄이는 방향 필요 |
| `AppMetricTile` | metric tile에 사용 가능. 중첩 카드처럼 보이지 않게 주의 |
| `MoneyfyBadge`/`MoneyfyPillStyle` | badge/chip에 재사용 |
| `context.spacing` | 대부분 사용 중 |
| `context.radius` | chip/bar radius에 사용 중 |
| `context.typography` | 주요 텍스트에 사용 중 |
| `context.colors` | semantic/neutral color에 사용 중 |

### Hardcoding/Exception Candidates

| 후보 | 현재 예 | v2 처리 |
| --- | --- | --- |
| Divider height 직접값 | `Divider(height: 20/22/24/28)` | spacing token 또는 section rhythm 기준으로 통일 |
| Chart geometry 직접값 | 월별 bar strip `height: 72`, attribution bar `height: 8` | chart geometry 예외로 허용 가능하나 문서화 |
| Opacity 직접값 | `withValues(alpha: 0.52/0.56)` | VisualSpec/context token이 있으면 대체, 없으면 예외 문서화 |
| Width 계산 직접값 | `constraints.maxWidth < 360`, 2-column 계산 | responsive rule로 문서화 또는 공용 helper 검토 |
| Dropdown 기본 Material 문법 | `DropdownButton` | 기존 design contract와 맞는지 Phase 5에서 확인 |
| `FittedBox` scaleDown | 금액 overflow 방지용 | 유지 가능. text scale QA 필수 |

금지:

- 신규 raw hex color 추가
- `Colors.*` 직접 사용
- 임의 `FontWeight` 직접 사용
- 임의 `EdgeInsets` 직접 사용
- 임의 card/panel 문법 신설

## Component/Token Reuse List

| 용도 | 우선 재사용 |
| --- | --- |
| Page shell | `MoneyfyPage` |
| Section surface | `SectionCard`, 또는 design md component contract에 맞는 panel pattern |
| Metric display | `AppMetricTile`, `context.typography.heroNumber`, `context.typography.cardTitle` |
| Badge/chip | `MoneyfyBadge`, `MoneyfyPillStyle`, `_InvestmentChoiceChip` |
| Semantic amount color | `_valueColor` 또는 같은 기준의 derived helper |
| Signed text color | `_valueTextColor` 또는 같은 기준의 derived helper |
| Spacing | `context.spacing`, `context.cardPadding()` |
| Radius | `context.radius`, `VisualSpec.surface` |
| Colors | `context.colors` semantic/neutral tokens |
| Typography | `context.typography`, `AppFontWeights` |

## Phase Risks

| Risk | 영향 | 대응 phase |
| --- | --- | --- |
| periodReturn이 자주 null | header primary가 fallback에 자주 머물 수 있음 | 02, 03 |
| benchmark fetch 실패 reason 없음 | `참고 벤치마크 데이터 부족` 이상의 구체 copy가 어려움 | 02 |
| snapshot availability 불안정 | 총자산 변화 검산을 항상 제공하기 어려움 | 02, 04 |
| 종목별 비용 미배분 | 종목별 기여도와 전체 순성과 합이 다르게 보일 수 있음 | 01, 05 |
| 월별 미실현 제외 | 월별 그래프가 전체 계좌 성과로 오해될 수 있음 | 01, 05 |
| card/panel 문법 과잉 | 완전 리디자인이 카드 나열로 회귀할 수 있음 | 03-06 |
| 긴 한글 copy | 390dp/text scale 1.3에서 overflow 가능 | 06 |

## Open Questions For Later Phases

| 질문 | 담당 phase | 비고 |
| --- | --- | --- |
| daily return 부족 reason을 `dataQuality`로 세분화할지 | 02 | `missing_snapshot`, `missing_fx`, `complete` 활용 가능 |
| benchmark fetch 실패를 report state로 보존할지 | 02 | 현재는 ensure 실패가 명시 state로 남지 않음 |
| 총자산 검산 시작/종료 기준을 어떻게 잡을지 | 02/04 | 현재 결정 보류 |
| Data Basis 섹션을 accordion으로 둘지 static section으로 둘지 | 05/06 | 구현/QA에서 결정 |
| DropdownButton을 design-system 컴포넌트로 대체할지 | 05 | 정렬 control UI 기준 |
| chart geometry를 token화할지 예외로 둘지 | 04/05/06 | height 8, 72 등 |

## Completion Gate

다음 조건을 모두 만족해야 Phase 1로 넘어간다.

- [x] 현재 페이지 widget map이 작성되었다.
- [x] report field 사용처와 null 상태가 정리되었다.
- [x] 총자산 검산 가능 여부가 `가능`, `불확실`, `v1 fallback only` 중 하나로 결정되었다.
- [x] 하드코딩/디자인 문법 이탈 후보가 기록되었다.
- [x] 재사용할 기존 component/token 목록이 기록되었다.
- [x] 다음 phase에서 결정해야 할 open question이 별도로 분리되었다.

## Stop Rule

이 단계에서 구현을 시작하지 않는다. audit 결과만으로 즉시 UI를 수정하지 않는다.

