# Investment Performance Report Plan

MONEYFY `투자성과 분석` MVP -> 제품급 성과 리포트 확장 계획.

## Product Goal

사용자, 총자산 변화 원인을 투자성과/현금흐름으로 분리 이해.

핵심 질문:

1. 투자로 얼마 벌거나 잃음?
2. 총자산 변화 중 입금/출금/이체/환전 영향 얼마?
3. 어떤 종목/월/수익원/비용이 성과 기여 큼?

현재 `transaction_events`, `transaction_lines` 원장 모델, `InvestmentPerformancePage`, 월별/종목별 ledger aggregate API 있음. 방향: 신규 개발 아님. 기존 MVP 정확도/탐색성 강화.

## Current Baseline

현재 기반:

| 영역 | 현재 상태 |
| --- | --- |
| 진입점 | 분석 탭 `투자성과 분석` 카드 |
| 화면 | `lib/pages/investment_performance_page.dart` |
| 전체 집계 | `fetchLedgerPortfolioPerformanceByCurrency()` |
| 월별 집계 | `fetchLedgerMonthlyPerformanceByCurrency()` |
| 종목별 집계 | `fetchLedgerHoldingPerformanceByHoldingId()` |
| 성과 정의 | `실현손익 + 미실현손익 + 배당/이자 - 수수료 - 세금` |
| 제외 현금흐름 | 외부 입출금, 매매 결제 현금흐름, 내부 이동 별도 표시 |
| 통화 처리 | 통화별 ledger 집계 후 화면에서 KRW 환산 |

현재 화면: 요약, 성과 구성, 제외 현금흐름, 월별 성과, 실현손익 랭킹, 보유 항목별 성과. 다음: 기간 필터, 수익률, 기여도, 상세 drill-down, 검증 가능한 계산 규칙.

## Success Criteria

1차 제품화 기준:

| 기준 | 목표 |
| --- | --- |
| 이해 가능성 | 총자산 변화와 투자성과 차이 한 화면 구분 |
| 정확성 | 입금/출금/이체/환전이 순 투자성과에 섞이지 않음 |
| 추적 가능성 | 월별/종목별/수익원별 원인 확인 |
| 기간 탐색 | 1개월, 3개월, 6개월, 올해, 전체, 직접 선택 |
| 검증 가능성 | 주요 집계식 unit/widget test 고정 |

## Metric Definitions

표시 지표 정의:

| 지표 | 계산식 | 포함 항목 | 제외 항목 |
| --- | --- | --- | --- |
| 순 실현성과 | `실현손익 + 배당/이자 - 수수료 - 세금` | 매도 확정 손익, 배당, 이자, 수수료, 세금 | 미실현손익, 입출금, 이체, 환전 |
| 순 투자성과 | `순 실현성과 + 미실현손익` | 보유 중 평가손익 포함 | 입출금, 이체, 환전 |
| 미실현손익 | 현재 보유 평가금액 - 남은 원가 | 표시 대상 보유 종목 | 현금 평가 차이 |
| 외부 현금흐름 | `deposit + withdrawal + opening_cash` | 사용자 입금/출금/초기 현금 | 투자성과 |
| 내부 이동 | `transfer_out/in + fx_out/in`의 절대 이동량 | 계좌 이체, 환전 이동 규모 | 투자성과 |
| 결제 현금흐름 | `settlement` | 매수/매도 결제 현금 | 순 투자성과 산식에는 직접 미포함 |
| 총 성과 기여도 | 항목 성과 / 전체 순 투자성과 | 종목, 월, 수익원 | 전체가 0이면 표시 생략 |

주의: `settlement`는 거래 규모 설명용. 순 투자성과에 직접 더하지 않음. 성과는 `buy`, `sell`, `realized_pnl`, `dividend`, `interest`, `fee`, `tax`, 현재 평가손익에서 계산.

## Proposed UX

### 1. Summary Header

상단: 기간 선택 + 핵심 성과.

| 요소 | 내용 |
| --- | --- |
| 기간 선택 | 1개월, 3개월, 6개월, 올해, 전체, 직접 선택 |
| 대표 지표 | 순 투자성과 |
| 보조 지표 | 순 실현성과, 미실현손익, 배당/이자, 비용 |
| 비교 문구 | "입출금 제외 기준" 작은 설명 |

예시:

```text
순 투자성과
+1,240,000원

실현 +420,000원 · 미실현 +690,000원 · 배당/이자 +160,000원 · 비용 -30,000원
입출금과 내부 이동은 제외한 성과입니다.
```

### 2. Waterfall Breakdown

총성과 구성 분해.

| 순서 | 항목 |
| --- | --- |
| 1 | 실현손익 |
| 2 | 미실현손익 |
| 3 | 배당/이자 |
| 4 | 수수료 |
| 5 | 세금 |
| 6 | 순 투자성과 |

초기: 리스트형 카드 충분. 이후 waterfall chart 가능.

### 3. Cash Flow Separation

투자성과 제외 현금흐름 분리.

| 항목 | 설명 |
| --- | --- |
| 외부 입금 | 새로 넣은 돈 |
| 외부 출금 | 뺀 돈 |
| 매매 결제 | 매수/매도 현금 이동 |
| 내부 이동 | 계좌 이체, 환전 |

핵심: "총자산은 늘었지만 투자로 번 것 아님" 설명.

### 4. Monthly Trend

월별 순 실현성과 표시.

MVP: 최근 12개월 리스트. 제품화: 막대 차트.

표시:

- 월
- 순 실현성과
- 실현손익
- 배당/이자
- 수수료/세금

월별 미실현손익은 스냅샷 기간 비교 필요. Phase 5.

### 5. Holding Contribution

종목별 성과 기여 표시.

| 컬럼 | 내용 |
| --- | --- |
| 종목 | 이름, 심볼, 자산군 |
| 실현손익 | 매도 확정 손익 |
| 미실현손익 | 현재 보유 평가손익 |
| 배당/이자 | 해당 종목 수입 |
| 총 성과 | 실현 + 미실현 + 배당/이자 |
| 기여도 | 전체 순 투자성과 대비 비중 |

정렬:

- 총 성과 높은 순
- 총 성과 낮은 순
- 실현손익 높은 순
- 미실현손익 높은 순
- 배당/이자 높은 순

### 6. Drill-Down

항목 탭 -> 성과 만든 거래 이벤트 목록.

1차 범위:

- 종목 row 탭 -> 보유 상세 또는 종목 성과 상세
- 월 row 탭 -> 해당 월 성과 거래 목록
- 비용 row 탭 -> 수수료/세금 거래 목록

초기: 기존 상세 화면 이동. 별도 상세는 Phase 4.

## Data And API Changes

### Required Query Enhancements

기존 aggregate는 전체 기간 기준. 기간 필터 API 추가.

| API | 목적 |
| --- | --- |
| `fetchLedgerPortfolioPerformanceByCurrency({DateTime? from, DateTime? to})` | 기간별 전체 성과 |
| `fetchLedgerMonthlyPerformanceByCurrency({DateTime? from, DateTime? to})` | 기간별 월간 성과 |
| `fetchLedgerHoldingPerformanceByHoldingId({DateTime? from, DateTime? to})` | 기간별 종목 성과 |
| `fetchLedgerPerformanceEvents({from, to, action, holdingId})` | drill-down 거래 목록 |

기간 조건은 `transaction_events.occurred_at` 기준. 기존 `YYYY.MM.DD` 섞임 가능. 쿼리는 현재처럼 `REPLACE(te.occurred_at, '.', '-')`로 비교 통일.

### Date Range Model

UI/DB 공통 기간 모델.

```dart
class PerformanceDateRange {
  const PerformanceDateRange({
    required this.label,
    this.from,
    this.to,
  });

  final String label;
  final DateTime? from;
  final DateTime? to;
}
```

직접 선택 제외 기본 preset:

| Preset | from | to |
| --- | --- | --- |
| 1개월 | 오늘 기준 1개월 전 | 오늘 |
| 3개월 | 오늘 기준 3개월 전 | 오늘 |
| 6개월 | 오늘 기준 6개월 전 | 오늘 |
| 올해 | 올해 1월 1일 | 오늘 |
| 전체 | null | null |

### Currency Conversion

현재 MVP처럼 통화별 ledger 집계 후 화면에서 KRW 환산.

단기:

- KRW 그대로.
- USD는 `fetchLatestExchangeRate()` 최신 환율.
- 다른 통화 추가 시 `ExchangeRates`를 통화 코드별 조회로 확장.

장기:

- 월별 과거 성과는 최신 환율보다 거래 시점/월말 환율이 정확.
- Phase 4로 분리.

## Development Phases

### Phase 1. Calculation Contract Lock

목표: 화면보다 계산 정의/테스트 먼저 고정.

작업:

- 성과 지표 정의를 `docs/data_and_sync.md` 또는 본 문서에 연결.
- `LedgerPortfolioPerformanceRecord.pureRealizedPerformance` 테스트.
- fee/tax 차감 테스트.
- deposit/withdrawal/transfer/fx가 순 투자성과에 미포함 테스트.
- 기존 `transaction_ledger_redesign.md` Phase 10 규칙/용어 정렬.

완료:

- 전체 포트폴리오 순 실현성과 테스트 통과
- 제외 현금흐름 테스트 통과
- 기존 `flutter test` 통과

### Phase 2. Date Range Support

목표: 전체 기간 리포트 -> 기간별 탐색.

작업:

- `PerformanceDateRange` 모델 추가.
- portfolio, monthly, holding aggregate 쿼리에 `from/to` 조건 추가.
- 직접 선택 전 preset segmented control만 제공.
- 화면을 `StatefulWidget`으로 전환, 선택 기간 따라 reload.

완료:

- 전체/올해/1개월 등 preset 변경 시 모든 카드 같은 기간 기준 갱신.
- 기간 필터 테스트가 거래 발생일 기준 통과.

### Phase 3. Report UX Upgrade

목표: 카드 나열 -> 리포트처럼 읽힘.

작업:

- summary header를 기간 선택 + 대표 지표 중심 재구성.
- 성과 구성 카드를 순서 있는 breakdown으로 정리.
- 제외 현금흐름 카드에서 입금/출금과 내부 이동 명확 분리.
- 월별 성과는 최근 12개월 기본 노출, 더보기 흐름 준비.
- 종목별 성과 row에 기여도/정렬 추가.

완료:

- 사용자가 순 투자성과, 순 실현성과, 제외 현금흐름 구분.
- 모바일 폭에서 숫자/라벨 안 겹침.
- empty state가 거래 없음/보유 없음/기간 내 데이터 없음 구분.

### Phase 4. Drill-Down

목표: 집계 숫자 -> 근거 거래 확인.

작업:

- `fetchLedgerPerformanceEvents()` 추가.
- 월별 row, 종목 row, 비용 row에서 관련 거래 목록 열기.
- 1차는 bottom sheet 또는 기존 상세 화면 이동 중 선택.
- 거래 목록: 날짜, 이벤트 종류, 종목/계좌, 금액, 성과 반영 항목.

완료:

- 특정 월 순 실현성과 만든 거래 확인.
- 특정 종목 실현손익/배당/이자 근거 확인.

### Phase 5. Snapshot-Based Unrealized Trend

목표: 월별 리포트에 미실현손익 변화 포함.

작업:

- 기간 시작/끝 snapshot 조회.
- 보유 종목별 평가손익 변화와 신규 매수/매도 영향 분리 가능성 검증.
- 월말 snapshot 없으면 가장 가까운 이전 snapshot 사용 여부 정책.
- 월별 순 투자성과에 실현성과 + 평가손익 변화 표시.

완료:

- 월별 리포트에서 실현성과/평가손익 변화 분리.
- snapshot 누락 시 UI가 계산 한계 명확 표시.

### Phase 6. Historical FX Accuracy

목표: 외화 성과 KRW 환산 정확도 개선.

작업:

- 거래 시점 환율 또는 월말 환율 저장/조회 정책.
- `ExchangeRates`를 날짜/통화 코드 기준 확장 검토.
- 최신 환율 환산 vs 과거 환율 환산 차이 테스트.

완료:

- 외화 실현손익/배당/수수료/세금이 기간 리포트에서 일관 환율 정책으로 계산.

## Recommended MVP Scope

우선 범위: Phase 1-3.

포함:

- 기간 preset
- 전체 성과 요약
- 실현손익, 미실현손익, 배당/이자, 수수료, 세금 breakdown
- 제외 현금흐름 분리
- 월별 순 실현성과
- 종목별 총 성과와 기여도
- 계산 테스트

제외:

- 과거 환율 기반 KRW 환산
- 월별 미실현손익 변화
- 완전한 거래 drill-down 전용 화면
- 세후 예상 수익률

## Test Plan

### Unit Tests

| 테스트 | 검증 내용 |
| --- | --- |
| pure realized performance | `realized + income - fee - tax` |
| excluded cash flow | deposit/withdrawal/transfer/fx가 순 성과에 포함되지 않음 |
| date range filter | 기간 밖 거래가 집계 제외 |
| monthly grouping | `YYYY.MM.DD`와 `YYYY-MM-DD` 날짜가 같은 월 그룹 |
| currency merge | USD 금액이 지정 환율로 KRW 환산 |
| closed holding inclusion | 전량 매도 종목도 ledger activity 있으면 성과 포함 |

### Widget Tests

| 테스트 | 검증 내용 |
| --- | --- |
| empty state | 기간 내 거래 없을 때 안내 표시 |
| preset switch | 기간 변경 시 표시 값 갱신 |
| breakdown card | 수수료/세금이 음수 성과로 표시 |
| holding ranking | 성과 정렬 올바름 |

### Manual QA

1. 입금만 있는 계정에서 순 투자성과 0 확인.
2. 매수만 있고 가격 변화 없는 계정에서 순 실현성과 0 확인.
3. 매도 손익 있는 종목이 실현손익 반영 확인.
4. 배당/이자 거래가 수입 반영 확인.
5. 수수료/세금이 성과 낮춤 확인.
6. 환전/계좌 이체가 내부 이동으로만 표시 확인.
7. 전량 매도 종목이 종목별 실현손익 랭킹에 남는지 확인.

## Risks And Decisions

| 이슈 | 리스크 | 결정 |
| --- | --- | --- |
| 기간별 미실현손익 | 시작/끝 평가가 snapshot 의존 | MVP는 현재 미실현손익만 표시, 월별 변화 Phase 5 |
| 외화 환산 | 최신 환율이 과거 성과 왜곡 가능 | MVP는 최신 환율, Phase 6 과거 환율 |
| 수익률 계산 | 입출금 timing 반영 복잡 | MVP는 금액 중심, 수익률 별도 설계 |
| legacy mirror | 기존 transaction table과 ledger 불일치 가능 | ledger parity test 유지, ledger를 source of truth |
| drill-down | 새 상세 화면 추가 시 범위 증가 | MVP는 기존 상세 이동 또는 간단 bottom sheet |

## Implementation Order

1. 계산 정의와 테스트 보강
2. 기간 필터 가능한 ledger aggregate API 추가
3. `InvestmentPerformancePage`를 stateful report 화면으로 개편
4. 종목별 성과 기여도와 정렬 옵션 추가
5. 월별 성과 표시 개선
6. drill-down API와 UI 추가
7. snapshot 기반 월별 미실현손익 변화 설계
8. 과거 환율 정책 설계

## Open Questions

- 순 투자성과 대표 수익률은 단순/시간가중/금액가중 중 무엇?
- 직접 선택 기간은 date picker 즉시 추가, 아니면 preset 안정화 후?
- 외화 성과는 원화 환산만, 아니면 원통화도 함께?
- 종목별 성과에서 수수료/세금을 종목에 배부, 아니면 포트폴리오 비용?
- 월별 미실현손익 변화는 snapshot으로 충분, 아니면 거래일별 가격 이력 필요?

## Feasibility And Feedback

### Overall Assessment

계획은 MONEYFY 현재 구조와 잘 맞음. ledger table, 성과 aggregate API, 투자성과 화면, 스냅샷, 통화 환산 흐름 이미 있음. 완전 신규보다 구현 타당성 높음.

장점: 단순 자산 기록 -> 성과 해석 도구. 사용자는 "총자산 얼마" 다음 "잘해서 늘었나, 입금해서 늘었나"를 궁금해함. 이 리포트가 직접 답함.

단, 후반부는 계산 정확도/신뢰 민감. 기간별 미실현손익, 과거 환율, 대표 수익률은 해석 여지 큼. Phase 1-3 강하게 추진, Phase 5-6은 별도 설계 검증 후 진행.

### Feasibility Review

| 항목 | 타당성 | 판단 |
| --- | --- | --- |
| 원장 기반 전체 성과 집계 | 높음 | `transaction_lines` 기반 API 있어 확장 비용 낮음 |
| 기간 필터 | 높음 | `transaction_events.occurred_at` 기준 조건 추가면 됨 |
| 월별 순 실현성과 | 높음 | 월별 aggregate 이미 있고 테스트 고정 가능 |
| 종목별 성과 기여도 | 중간-높음 | 가능하나 수수료/세금 배부 정책 필요 |
| 제외 현금흐름 분리 | 높음 | deposit, withdrawal, transfer, fx action 이미 분리 |
| Drill-down 거래 목록 | 중간 | 데이터 가능, UI 범위 커질 수 있음 |
| 월별 미실현손익 변화 | 중간-낮음 | snapshot 의존 높고 누락/가격 갱신에 취약 |
| 과거 환율 기반 환산 | 중간-낮음 | 정확도 좋아지나 환율 데이터 모델 확장 필요 |
| 대표 수익률 | 낮음-중간 | 단순 수익률 쉬움, 입출금 timing 반영 어려움 |

### Expected Effects

#### Product Effects

- 총자산 변화와 투자성과 분리 이해.
- 입금 증가 vs 투자 수익 증가 구분.
- 분석 탭 존재 이유 명확.
- 배당/이자, 수수료/세금, 실현손익 한 화면. 반복 방문 가치.
- 이후 리밸런싱, 월간 리포트, AI 진단 입력으로 재사용.

#### Technical Effects

- ledger model을 사용자 가치로 연결.
- legacy transaction text parsing 의존 감소.
- 성과 계산 규칙 테스트 고정으로 회귀 감소.
- 기간 필터/drill-down API는 다른 분석 화면 재사용 가능.
- 스냅샷 기반 분석과 ledger 기반 분석 역할 분리.

#### UX Effects

- 사용자는 "얼마나 늘었나"보다 "왜 늘었나" 읽음.
- 비용/세금이 보여 현실적 체감.
- 종목별 기여도 -> 포트폴리오 점검 행동.
- 기간 preset -> 정적 요약이 아니라 탐색 도구.

### Strengths

1. 기존 구조와 궁합 좋음.

   `TransactionEvents`, `TransactionLines`, `LedgerPortfolioPerformanceRecord`, `InvestmentPerformancePage` 이미 있음. 새 schema 크게 불필요.

2. 사용자 체감 가치 큼.

   "입금해서 늘어난 자산"과 "투자로 번 돈" 착시 분리.

3. 계산 규칙을 제품 언어로 만들 수 있음.

   실현손익, 미실현손익, 배당/이자, 수수료/세금, 제외 현금흐름을 일관 용어로 묶음.

4. 후속 기능 기반.

   리밸런싱 제안, 월간 리포트, 종목별 뉴스 영향도, AI 진단이 성과 분해 결과 사용 가능.

5. MVP와 고급 기능 분리 쉬움.

   Phase 1-3만으로 가치. Phase 5-6은 정확도 요구 높아 후순위 가능.

### Weaknesses And Trade-Offs

1. 용어 어려울 수 있음.

   순 실현성과, 순 투자성과, 결제 현금흐름, 내부 이동은 정확하지만 부담. UI는 짧은 라벨 + 보조 설명 필요.

2. 기간별 미실현손익 정확도 리스크 큼.

   시작/끝 가격, 수량, 원가, 환율 일관 필요. snapshot 없거나 가격 갱신 늦으면 신뢰 하락.

3. 최신 환율 환산은 과거 성과 왜곡 가능.

   MVP는 단순하지만 과거 USD 배당/매도 손익을 현재 환율로 환산하면 당시 원화 가치와 다름.

4. 수수료/세금 배부 정책 애매.

   거래 연결 비용은 종목 배부 가능. standalone fee/tax는 포트폴리오 비용일 수 있음. 종목별 총 성과 반영 범위 결정 필요.

5. 수익률 조기 추가는 오해 유발.

   단순 수익률은 쉬우나 입출금 많은 사용자에 부정확. 시간가중/금액가중은 정확하지만 구현/설명 어려움.

### Opportunities

- 월간 리포트 자동 생성 핵심 데이터.
- AI 포트폴리오 진단이 비중 평가 넘어 "성과 원인" 설명 가능.
- 종목 뉴스 요약과 결합해 "성과 큰 종목 최근 이슈" 우선 표시.
- 잘못 입력한 거래 찾는 reconciliation UX로 확장.
- 향후 export에서 성과 리포트 PDF/CSV 생성.

### Threats

- 계산 결과가 대시보드/스냅샷/보유 상세와 다르면 신뢰 하락.
- 일부 거래 유형이 ledger line 변환 실패하면 특정 사용자 성과 오류.
- 외화 자산 많은 사용자에게 최신 환율 환산 차이 큼.
- drill-down 없이 집계 숫자만 있으면 근거 확인 어려움.
- 카드/숫자 과밀 시 핵심 메시지 흐림.

### Recommended Adjustments

1. Phase 1-3을 첫 릴리스 범위로 유지.

   구현 타당성/사용자 가치 균형 좋음. 기간 필터, 성과 breakdown, 제외 현금흐름, 종목별 기여도까지 적합.

2. 수익률은 첫 릴리스 제외 또는 실험 배지.

   금액 중심 리포트 먼저 안정화. 수익률은 별도 문서에서 단순/시간가중/금액가중 비교 후 결정.

3. 월별 미실현손익은 snapshot 품질 점검 후.

   월말 snapshot 누락, 가격 갱신 실패, 환율 누락 fallback 정책 먼저.

4. 외화 리포트에는 환산 기준 반드시 표시.

   MVP 최신 환율이면 "최신 환율 기준 원화 환산"처럼 짧게 표시.

5. 종목별 비용 배부는 단계적.

   1차는 `실현손익 + 미실현손익 + 배당/이자`, 수수료/세금은 포트폴리오 비용. 이후 거래 연결 비용만 종목 배부.

6. Drill-down은 늦추지 않는 편이 좋음.

   집계 신뢰는 근거 확인에서 나옴. 완전 상세 아니어도 bottom sheet 거래 목록 최소 기능을 Phase 4 우선.

### Final Recommendation

진행 가치 있음. Phase 1-3은 기술 현실성/사용자 가치 분명. 정확도 민감 기능은 한 번에 넣지 말고 순차 진행.

1. 금액 기준 성과 리포트 안정화
2. 기간 필터와 종목별 기여도 추가
3. 집계 근거 drill-down 추가
4. snapshot 기반 미실현손익 추세 검증
5. 과거 환율과 수익률 정책 설계

첫 릴리스 핵심 문장:

```text
입출금과 내부 이동을 제외하고, 투자로 만든 성과만 분리해서 보여준다.
```

이 문장에 안 맞는 기능은 첫 릴리스 제외. 범위 건강 유지.

## 세부 문서 병합 요약

### 핵심 계획

- v1/v2 redesign 방향은 "rate leads judgment, amount explains impact"로 정리. benchmark는 시장 판정 아님, 참고 기준.
- IA는 기간 수익률, 참고 벤치마크, 성과 원인, 성과와 현금흐름, 월별 확정 성과, 보유종목 기여도로 분리.
- report/view model contract는 raw report, view model, metric state, section state 분리. UI copy/계산 상태 안정화.
- judgment header는 390dp first view에서 핵심 판정, 기간, 기준, 부족 상태 우선.
- attribution/reconciliation은 realized/unrealized/dividend/fee/cash-flow 분리, 근거 drill-down 가능.
- detail/risk section은 월별 확정 성과, holding contribution, market/risk 해석을 후순위 detail로.
- responsive/empty state/QA는 partial data, empty data, text scale, mobile width 별도 matrix 검증.

### 구현/보고 결과

- page information inventory로 기존 summary card, attribution, market/risk, monthly realized performance, holding contribution, excluded cash flows 정리.
- temporary development report는 date filter helper, aggregate API, external cash flow split, drill-down API, date range preset, summary header 변경 기록.
- redesign v2 implementation report는 v2 범위와 남은 risk 짧게 기록.
- test report는 ledger calculation, date range filtering, cash flow split, drill-down API, UI walkthrough, widget smoke 검증.

### 남은 기준

- 첫 릴리스는 금액 기준 성과 리포트, 기간 필터, 종목별 기여도, drill-down까지.
- 수익률, 월별 미실현손익, 과거 환율 정책은 별도 설계 후 확장.
- 외화 리포트는 환산 기준 반드시 표시.
- 집계 숫자는 항상 근거 거래 목록 또는 설명으로 추적 가능해야 함.