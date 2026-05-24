# Investment Performance Test Report 2026-05-24

이 문서는 `투자성과 분석` 고도화 기능에 대해 `Investment Performance Verification Test Plan` 기준으로 수행한 테스트 결과 보고서입니다.

검증 기준 문서:

- `docs/investment_performance_verification_test_plan.md`

관련 개발 리포트:

- `docs/tmp_investment_performance_development_report.md`

## Summary

자동 검증 범위는 모두 통과했습니다.

검증 결과:

| 항목 | 결과 |
| --- | --- |
| 정적 분석 | 통과 |
| 거래/원장 집중 테스트 | 통과 |
| 화면 walkthrough 테스트 | 통과 |
| UI component smoke 테스트 | 통과 |
| 전체 테스트 | 통과 |

수동 QA와 반응형 레이아웃 검증은 아직 별도 기기/브라우저 실행으로 수행하지 않았습니다. 이 항목은 기능 배포 전 남은 확인 대상으로 유지합니다.

## Test Environment

| 항목 | 값 |
| --- | --- |
| 날짜 | 2026-05-24 |
| 작업 경로 | `/Users/yw0410/Desktop/Project/MONEYFY` |
| 대상 기능 | 원장 기반 투자성과 리포트 고도화 |
| 테스트 방식 | Flutter 정적 분석, widget/unit/integration-style test |

## Commands Run

```bash
flutter analyze
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
flutter test
```

## Command Results

| 명령 | 결과 | 확인 내용 |
| --- | --- | --- |
| `flutter analyze` | 통과 | no issues found |
| `flutter test test/transaction_flow_test.dart` | 통과 | 43 tests passed |
| `flutter test test/page_walkthrough_test.dart` | 통과 | 16 tests passed |
| `flutter test test/ui_component_smoke_test.dart` | 통과 | 7 tests passed |
| `flutter test` | 통과 | 80 tests passed |

## Verification Against Plan

### 1. Ledger Calculation Contract

상태: 통과

검증된 항목:

- 순 실현성과 계산
- 수수료/세금 차감
- 외부 현금흐름과 내부 이동 분리
- 삭제된 event 제외
- `snapshot_restore`, `history_display` source 제외
- 기존 거래/원장 회귀 방지

관련 테스트:

- `cash ledger summary separates external and internal cash movement`
- `ledger performance subtracts fees and taxes from pure profit`
- `ledger performance ignores deleted events and reads gross-only amounts`
- 기존 transaction/ledger flow tests

비고:

- withdrawal-only, fx-only, settlement-only 단독 케이스는 아직 별도 테스트로 분리되어 있지 않습니다. 현재 관련 동작은 기존 현금/환전/매매 흐름 테스트와 성과 집계 테스트 조합으로 간접 검증됩니다.

### 2. Date Range Filtering

상태: 통과

검증된 항목:

- `from` 포함 경계
- `to` 포함 경계
- 기간 이전 거래 제외
- 기간 이후 거래 제외
- `YYYY.MM.DD`와 `YYYY-MM-DD` 혼합 날짜 처리
- portfolio aggregate 기간 필터
- currency aggregate 기간 필터
- holding aggregate 기간 필터
- monthly aggregate 기간 필터

관련 테스트:

- `ledger performance filters by event date range across date formats`

비고:

- `from == null`, `to != null`, `from != null`, `to == null` 단독 조합은 아직 별도 테스트로 분리되어 있지 않습니다. API는 optional parameter 구조로 구현되어 있으므로 후속 회귀 테스트 확장 대상으로 남깁니다.

### 3. Cash Flow Split

상태: 통과

검증된 항목:

- `externalDepositAmount`
- `externalWithdrawalAmount`
- `externalCashFlowAmount`
- `internalCashMovementAmount`
- `tradeSettlementCashFlowAmount`

관련 테스트:

- `cash ledger summary separates external and internal cash movement`

확인한 fixture:

```text
입금 200
출금 50
이체 25

externalDepositAmount: 200
externalWithdrawalAmount: 50
externalCashFlowAmount: 150
internalCashMovementAmount: 50
pureRealizedPerformance: 0
```

비고:

- `opening_cash`의 deposit bucket 포함 여부와 USD cash flow의 currency별 분리는 후속 테스트 확장 대상으로 남깁니다.

### 4. Drill-Down API

상태: 통과

검증된 항목:

- 기간 필터
- action 필터
- holding 필터
- realized PnL amount 반환

관련 테스트:

- `ledger performance events support drill-down filters`

확인한 fixture:

```text
2026-05 sell holding 11 realized_pnl 40
2026-06 dividend holding 11 gross_amount 20

from: 2026-05-01
to: 2026-05-31
action: sell
holdingId: 11

returned: 5월 매도 / sell / amount 40
```

비고:

- dividend amount fallback, cash account line의 `cashAccountName`, filter 없는 목록 조회는 후속 테스트 확장 대상으로 남깁니다.

### 5. UI Walkthrough

상태: 통과

검증된 항목:

- 분석 탭에서 `투자성과 분석` 진입
- 투자성과 화면에서 `순 투자성과` 문구 표시
- `InvestmentPerformancePage` build smoke

관련 테스트:

- `stage 2: analysis entry cards open their child pages`
- `stage 3: investment performance builds once`

비고:

- 기간 preset chip 표시, `올해` 기본 선택, 정렬 dropdown 표시는 아직 전용 widget assertion으로 분리되어 있지 않습니다.

### 6. UI Component Smoke

상태: 통과

관련 테스트:

- `SectionCard renders with title/body`
- `DetailHeaderCard renders metrics`
- `AssetRow and TransactionRow render tap targets`
- `State widgets render`
- `MoneyfyPage paints scaffold background on pushed pages`
- `ExpandableTile expands and collapses`
- `AppPageScaffold form renders fixed CTA`

## Manual QA Status

수동 QA는 아직 수행하지 않았습니다.

남은 확인 항목:

| 항목 | 상태 | 비고 |
| --- | --- | --- |
| 거래 없음 empty/0 state | 미수행 | 앱 실행 후 확인 필요 |
| 입금만 있는 계정 | 미수행 | 실제 화면 금액 표시 확인 필요 |
| 출금만 있는 계정 | 미수행 | 출금이 손실처럼 보이지 않는지 확인 필요 |
| 이체만 있는 계정 | 미수행 | 내부 이동 표시 확인 필요 |
| 환전만 있는 계정 | 미수행 | 내부 이동 표시 확인 필요 |
| 매수만 있는 계정 | 미수행 | 순 실현성과 0 확인 필요 |
| 매도 수익/손실 | 미수행 | 실현손익 표시 확인 필요 |
| 배당/이자 | 미수행 | 수입 표시 확인 필요 |
| 수수료/세금 | 미수행 | 비용 표시 확인 필요 |
| 전량 매도 종목 | 미수행 | 랭킹/종목별 목록 잔존 확인 필요 |

## Responsive QA Status

반응형 레이아웃 QA는 아직 수행하지 않았습니다.

남은 확인 폭:

| 폭 | 상태 | 확인 포인트 |
| --- | --- | --- |
| 320px | 미수행 | 칩, dropdown, 금액 overflow |
| 390px | 미수행 | 일반 모바일 row 간격 |
| 768px | 미수행 | 태블릿 카드 폭과 여백 |
| desktop/web | 미수행 | 넓은 화면 card width 규칙 |

## Acceptance Criteria Result

| 기준 | 결과 |
| --- | --- |
| `flutter analyze` no issues | 통과 |
| `flutter test` 통과 | 통과 |
| `transaction_flow_test.dart` 통과 | 통과 |
| `page_walkthrough_test.dart` 통과 | 통과 |
| 기간 필터 자동 검증 | 통과 |
| 현금흐름 분리 자동 검증 | 통과 |
| UI 기본 smoke | 통과 |
| 문서 정합성 | 통과 |
| 수동 QA | 미수행 |
| 반응형 QA | 미수행 |

## Risk Assessment After Testing

| 리스크 | 현재 상태 | 판단 |
| --- | --- | --- |
| 날짜 필터 누락 | 핵심 케이스 자동 테스트 통과 | 낮음 |
| 입출금이 성과로 오인 | 집계 테스트 통과, 수동 화면 확인 필요 | 중간-낮음 |
| 외화 환산 왜곡 | 정책상 MVP 제한, 자동 검증 범위 아님 | 중간 |
| 긴 금액 overflow | 자동 smoke만 통과, 반응형 QA 필요 | 중간 |
| drill-down API와 aggregate 불일치 | 기본 filter 테스트 통과, 추가 케이스 필요 | 중간-낮음 |

## Follow-Up Recommendations

1. 수동 QA dataset을 만들어 투자성과 화면에서 각 cash-flow/성과 시나리오를 확인합니다.
2. 320px, 390px, 768px, desktop width에서 긴 금액/긴 종목명 overflow를 확인합니다.
3. `from` only, `to` only, 전체 기간 호환성 테스트를 추가합니다.
4. `opening_cash`와 USD cash-flow 분리 테스트를 추가합니다.
5. drill-down API의 dividend/cash account/filter-free 케이스를 추가합니다.
6. 기간 preset chip과 정렬 dropdown 전용 widget assertion을 추가합니다.

## Final Result

자동 테스트 기준으로는 이번 투자성과 리포트 고도화 변경이 통과 상태입니다.

릴리스 전에는 수동 QA와 반응형 레이아웃 확인을 추가로 수행하는 것이 좋습니다.

