# Investment Performance Verification Test Plan

이 문서는 `투자성과 분석` 고도화 기능의 검증 및 테스트 계획입니다.

기준 리포트:

- `docs/features/new_feature_development/investment_performance/tmp_development_report.md`

관련 계획:

- `docs/features/new_feature_development/investment_performance/plan.md`
- `docs/design/transaction_ledger_redesign.md`
- `docs/data_and_sync.md`

## Scope

검증 대상은 원장 기반 투자성과 리포트의 첫 제품화 범위입니다.

포함:

- 기간 preset
- ledger aggregate 기간 필터
- 순 투자성과와 순 실현성과 계산
- 외부 입금/출금/내부 이동/결제 현금흐름 분리
- 월별 순 실현성과
- 종목별 성과 기여도와 정렬
- drill-down 준비 API
- walkthrough smoke test

제외:

- 직접 선택 date picker
- 수익률
- 과거 환율 기반 환산
- snapshot 기반 월별 미실현손익 변화
- drill-down 전용 UI
- 세후 예상 수익

## Quality Goals

| 목표 | 설명 |
| --- | --- |
| 계산 정확성 | 입출금, 이체, 환전이 투자성과에 섞이지 않아야 함 |
| 기간 일관성 | 전체, 월별, 종목별 집계가 같은 기간 기준을 사용해야 함 |
| 추적 가능성 | 집계 숫자의 근거 거래를 API로 조회할 수 있어야 함 |
| UI 신뢰성 | 주요 화면이 렌더링되고 핵심 문구가 유지되어야 함 |
| 회귀 방지 | 기존 거래, 원장, sync 관련 테스트가 계속 통과해야 함 |

## Automated Test Plan

### 1. Ledger Calculation Contract

파일:

- `test/transaction_flow_test.dart`

검증 항목:

| 케이스 | 기대 결과 |
| --- | --- |
| 실현손익 + 배당/이자 - 수수료 - 세금 | `pureRealizedPerformance`가 정확히 계산됨 |
| 입금만 있는 경우 | 순 성과는 0, 외부 현금흐름만 증가 |
| 출금만 있는 경우 | 출금이 투자 손실로 반영되지 않음 |
| 계좌 이체 | 내부 이동으로만 집계 |
| 환전 | 내부 이동으로만 집계 |
| 매매 결제 | 결제 현금흐름으로 표시되지만 순 성과 산식에는 직접 미포함 |
| 삭제된 event | 성과 집계에서 제외 |
| `snapshot_restore`, `history_display` source | 성과 집계에서 제외 |

현재 커버:

- `cash ledger summary separates external and internal cash movement`
- `ledger performance subtracts fees and taxes from pure profit`
- `ledger performance ignores deleted events and reads gross-only amounts`

추가 권장:

- withdrawal-only 케이스에서 `pureRealizedPerformance == 0`
- fx-only 케이스에서 `pureRealizedPerformance == 0`
- settlement-only 케이스에서 `pureRealizedPerformance == 0`

### 2. Date Range Filtering

파일:

- `test/transaction_flow_test.dart`

검증 항목:

| 케이스 | 기대 결과 |
| --- | --- |
| `from` 포함 경계 | 시작일 거래 포함 |
| `to` 포함 경계 | 종료일 거래 포함 |
| 기간 이전 거래 | 제외 |
| 기간 이후 거래 | 제외 |
| `YYYY.MM.DD` 형식 | `YYYY-MM-DD`와 같은 기준으로 비교 |
| portfolio aggregate | 기간 내 금액만 반영 |
| currency aggregate | 기간 내 금액만 반영 |
| holding aggregate | 기간 내 금액만 반영 |
| monthly aggregate | 기간 내 월만 반환 |

현재 커버:

- `ledger performance filters by event date range across date formats`

추가 권장:

- `from == null`, `to != null`
- `from != null`, `to == null`
- `from == null`, `to == null` 기존 전체 기간 호환성

### 3. Cash Flow Split

파일:

- `test/transaction_flow_test.dart`

검증 항목:

| 필드 | 기대 결과 |
| --- | --- |
| `externalDepositAmount` | deposit + opening_cash 절대값 합 |
| `externalWithdrawalAmount` | withdrawal 절대값 합 |
| `externalCashFlowAmount` | deposit/withdrawal/opening_cash signed net |
| `internalCashMovementAmount` | transfer/fx 양쪽 line 절대 이동량 합 |
| `tradeSettlementCashFlowAmount` | settlement signed sum |

현재 커버:

- 입금 200, 출금 50, 이체 25 상황에서 deposit 200, withdrawal 50, net 150, internal 50 검증

추가 권장:

- opening_cash가 deposit bucket에 포함되는지 검증
- USD cash flow가 currency별 aggregate에서 분리되는지 검증

### 4. Drill-Down API

파일:

- `test/transaction_flow_test.dart`

검증 항목:

| 케이스 | 기대 결과 |
| --- | --- |
| 기간 필터 | 기간 내 event line만 반환 |
| action 필터 | 지정 action만 반환 |
| holding 필터 | 지정 holding line만 반환 |
| amount 선택 | realized_pnl 우선, 없으면 gross_amount, 없으면 cash_delta |
| 정렬 | 최신 날짜, 최신 event, line sort 순서 |

현재 커버:

- `ledger performance events support drill-down filters`

추가 권장:

- dividend line의 amount가 gross/cash 기준으로 반환되는지 검증
- cash account line 조회가 `cashAccountName`을 채우는지 검증
- action/holding filter 없이 기간만 준 경우의 반환 목록 검증

### 5. UI Walkthrough

파일:

- `test/page_walkthrough_test.dart`

검증 항목:

| 화면 | 기대 결과 |
| --- | --- |
| 분석 탭 | `투자성과 분석` entry card가 열림 |
| 투자성과 화면 | `순 투자성과` 문구가 표시됨 |
| page build smoke | `InvestmentPerformancePage`가 build됨 |

현재 커버:

- `stage 2: analysis entry cards open their child pages`
- `stage 3: investment performance builds once`

추가 권장:

- 기간 preset chip이 표시되는지 확인
- `올해` 기본 선택 상태 확인
- 정렬 dropdown이 표시되는지 확인

## Manual QA Plan

### QA Dataset Scenarios

수동 확인은 작은 데이터셋으로 진행합니다.

| 시나리오 | 입력 데이터 | 확인할 화면 결과 |
| --- | --- | --- |
| 거래 없음 | 자산 없음 또는 거래 없음 | empty/0 state가 깨지지 않음 |
| 입금만 있음 | 현금 계좌 입금 100만원 | 순 투자성과 0, 외부 입금 100만원 |
| 출금만 있음 | 현금 계좌 출금 20만원 | 순 투자성과 0, 외부 출금 -20만원 |
| 이체만 있음 | A 계좌에서 B 계좌로 10만원 | 내부 이동 표시, 순 투자성과 0 |
| 환전만 있음 | KRW -> USD 환전 | 내부 이동 표시, 순 투자성과 0 |
| 매수만 있음 | 종목 매수, 가격 변화 없음 | 순 실현성과 0, 매수 원금 표시 |
| 매도 수익 | 평균가보다 높은 가격으로 매도 | 실현손익과 순 실현성과 증가 |
| 매도 손실 | 평균가보다 낮은 가격으로 매도 | 실현손익과 순 실현성과 감소 |
| 배당/이자 | dividend/interest 거래 | 배당/이자 수입 증가 |
| 수수료/세금 | fee/tax line | 비용과 순 성과 차감 |
| 전량 매도 | 보유 수량 0, ledger activity 있음 | 종목별 실현손익 랭킹에 남음 |

### UI Checklist

투자성과 화면에서 확인합니다.

1. 기간 preset이 가로 스크롤 또는 칩 형태로 표시됩니다.
2. 기본 기간이 `올해`로 표시됩니다.
3. 기간을 바꾸면 summary, breakdown, cash-flow, monthly, holding 값이 함께 바뀝니다.
4. `순 투자성과` 대표 금액이 상단에서 가장 먼저 보입니다.
5. 보조 chip의 긴 금액이 줄바꿈되더라도 겹치지 않습니다.
6. 외부 입금과 외부 출금이 서로 다른 row로 보입니다.
7. 수수료와 세금은 음수 비용처럼 보입니다.
8. 월별 row에서 비용이 함께 표시됩니다.
9. 종목별 정렬 dropdown이 작동합니다.
10. 기여도는 전체 기준이 0에 가까울 때 표시되지 않거나 어색하지 않습니다.
11. 긴 종목명과 긴 금액이 겹치지 않습니다.
12. 다크 모드에서 금액 색상과 chip 배경이 읽힙니다.

### Responsive Checklist

아래 화면 폭에서 확인합니다.

| 폭 | 확인 포인트 |
| --- | --- |
| 320px | 칩, dropdown, 금액 overflow 없음 |
| 390px | 일반 모바일 폭에서 row 간격 정상 |
| 768px | 태블릿 폭에서 카드 폭과 여백 정상 |
| desktop/web | 너무 넓게 퍼지지 않고 기존 card width 규칙 유지 |

## Regression Test Commands

필수:

```bash
flutter analyze
flutter test
```

집중 테스트:

```bash
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
```

관련 화면 smoke:

```bash
flutter test test/ui_component_smoke_test.dart
```

## Acceptance Criteria

릴리스 또는 다음 단계 개발로 넘어가기 위한 기준입니다.

| 기준 | 통과 조건 |
| --- | --- |
| 정적 분석 | `flutter analyze` no issues |
| 전체 테스트 | `flutter test` 통과 |
| 거래/원장 테스트 | `transaction_flow_test.dart` 통과 |
| 화면 walkthrough | `page_walkthrough_test.dart` 통과 |
| 기간 필터 | 전체/월별/종목별 집계가 같은 기간 기준 적용 |
| 현금흐름 분리 | 입금/출금/이체/환전이 순 투자성과에 섞이지 않음 |
| UI 기본 상태 | 거래 없음, 데이터 있음 상태 모두 깨지지 않음 |
| 문서 정합성 | 계획서, 개발 리포트, 테스트 계획이 구현 범위와 모순되지 않음 |

## Release Risk Matrix

| 리스크 | 영향 | 가능성 | 검증 방법 | 대응 |
| --- | --- | --- | --- | --- |
| 날짜 필터 누락 | 기간별 성과 오표시 | 중간 | date range unit test | 날짜 helper 테스트 추가 |
| 입출금이 성과로 오인 | 사용자 신뢰 저하 | 중간 | cash-flow split test/manual QA | UI 라벨과 계산 테스트 유지 |
| 외화 환산 왜곡 | 외화 사용자 성과 오해 | 중간 | USD scenario manual QA | 최신 환율 기준임을 표시 |
| 긴 금액 overflow | 모바일 UX 저하 | 중간 | responsive QA | row layout 조정 |
| drill-down API와 aggregate 불일치 | 숫자 근거 신뢰 저하 | 낮음-중간 | filter parity test | API filter를 aggregate와 같은 helper 사용 |

## Future Test Expansion

후속 기능을 추가할 때 필요한 테스트입니다.

### Direct Date Picker

- 시작일만 선택
- 종료일만 선택
- 시작일 > 종료일 방지
- preset에서 직접 선택으로 이동 후 값 유지

### Snapshot-Based Unrealized Trend

- 시작 snapshot 없음
- 종료 snapshot 없음
- 월말 snapshot 누락 fallback
- 숨김 자산/숨김 보유 종목 제외
- 현금 평가손익 0 규칙 유지

### Historical FX

- 거래일 환율 사용
- 월말 환율 사용
- 환율 누락 fallback
- 최신 환율 방식과 과거 환율 방식 차이 표시

### Drill-Down UI

- 월 row tap -> 해당 월 거래 목록
- 종목 row tap -> 해당 종목 거래 목록
- 비용 row tap -> fee/tax 거래 목록
- 목록 empty state
- 긴 거래명/종목명 overflow

## Current Verification Snapshot

마지막 확인 결과:

```text
flutter analyze: passed
flutter test: passed, 80 tests
flutter test test/transaction_flow_test.dart: passed, 43 tests
```

이 수치는 테스트 추가/삭제에 따라 바뀔 수 있으므로, 후속 작업 후에는 이 섹션을 갱신합니다.
