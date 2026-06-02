# Transaction Percentage Shortcuts Expansion Plan

## Product Goal

`25%`, `50%`, `75%`, `100%` 빠른 선택 UX를 매도 외 거래로 확장. 현재 보유 현금/매수 가능 현금 안에서 일부 금액 빠르게 입력. 코인/해외 자산처럼 소수 수량 필요한 매수는 수량 계산까지 안정 연결.

## Target Flows

1. 현금 출금
2. 현금 이체
3. 환전
4. 매수

## Current Baseline

- 매도 폼: 보유 수량 기준 `25%`, `50%`, `75%`, `100%` 액션 버튼 있음.
- 현금 거래 폼: 금액 직접 입력.
- 매수 폼: 단가 + 수량 직접 입력.
- 매수 가능 현금 부족 검증은 DB에 있음. UI 현금 기준 비중 선택 없음.

## Success Criteria

- 현금 출금/이체/환전: source 현금 잔액 기준 비중 버튼 표시.
- 매수: 결제 가능 현금 기준 비중 버튼 표시. 단가 입력됨 → 수량 자동 계산.
- `100%` 버튼 입력값은 DB 잔액/수량 검증 통과 + 저장 성공.
- 버튼 입력 뒤 사용자 직접 금액/수량 수정 가능.
- 거래 유형/source 계좌/보유 종목 변경 시 버튼 계산 기준 즉시 변경.

## UX Proposal

- 매도 선택 상태 없는 action button 패턴 재사용.
- 버튼 라벨: `25%`, `50%`, `75%`, `100%`.
- 현금 거래 폼: 금액 필드 아래.
- 매수 폼: 수량 필드 아래 또는 단가/수량 그룹 하단.
- 기준 잔액/매수 가능 현금 <= 0이면 숨김 또는 비활성.
- 버튼 근처 과한 설명 없음. 기존 필드 라벨 + 미리보기로 의미 전달.

## Calculation Rules

### 1. 현금 출금

- 기준 금액: DB가 계산 반영 거래 저장 시 쓰는 source 현금 계좌 사용 가능 잔액과 같은 의미.
  - 기본값: 선택된 source cash holding 현재 `quantity`/cash account balance.
  - record-only 거래는 현재 잔액 미반영. 기준 금액 보정에도 되돌리지 않음.
- `25/50/75/100%` 선택 시 `amountController.text`에 기준 금액 * 비율 입력.
- 기존 출금 거래 수정:
  - 같은 source 계좌 + 기존 거래 계산 반영 → `현재 잔액 + 기존 출금 금액`.
  - 기존 거래 record-only → 현재 잔액에 기존 출금 효과 없음. 기존 출금 금액 더하지 않음.
  - 다른 source 계좌로 변경 → 새 source 계좌 현재 잔액만 기준.
- 입금 수정 중 거래를 출금으로 변경:
  - 같은 source 계좌 + 기존 거래 계산 반영 → 현재 잔액에서 기존 입금 효과 제거한 값 기준.
  - 보정 결과 <= 0이면 숨김 또는 비활성.

### 2. 현금 이체

- 기준 금액: 선택된 source 현금 계좌 사용 가능 잔액.
- target 계좌는 계산 기준 제외.
- source와 target 같으면 기존 검증처럼 저장 차단.
- 기존 이체 거래 수정:
  - 같은 source 계좌 + 기존 거래 계산 반영 → 기존 이체 출금 되돌림. `현재 잔액 + 기존 이체 금액`.
  - 기존 거래 record-only → 현재 잔액에 기존 이체 효과 없음. 기존 금액 더하지 않음.
  - source 계좌 변경 → 새 source 계좌 현재 잔액 기준.
  - target 계좌 변경은 기준 금액 영향 없음. linked deposit 정합성은 저장 테스트로 확인.

### 3. 환전

- 기준 금액: 선택된 source 현금 계좌 사용 가능 잔액.
- 버튼은 source 통화 금액 입력 필드 채움.
- 환율 필드 비어도 source 금액 비중 선택 가능.
- 기존 환전 거래 수정:
  - 같은 source 계좌 + 기존 거래 계산 반영 → 기존 source 출금 금액 되돌린 금액 기준.
  - 기존 거래 record-only → 기존 source 금액 되돌리지 않음.
  - source 계좌 변경 → 새 source 계좌 현재 잔액 기준.
  - target 통화 계좌 자동 선택/생성 규칙은 기존 DB API 따름. 이 계획은 source 금액 입력만 책임.
  - 100% 환전 저장 후 source 잔액/target 잔액 기대 반영 테스트.

### 4. 매수

- 기준 금액: DB `_ensureSufficientSettlementCashForBuy()`가 쓰는 결제 현금 계좌 매수 가능 현금.
- 선행 조사:
  - 현재 DB가 어떤 cash account를 settlement 계좌로 선택하는지 확인 + 문서화.
  - 동일 통화 cash account 여러 개일 때 선택 규칙 확인.
- 단가 입력됨 + > 0:
  - 선택 비중 금액 / `단가` → `quantityController.text`에 수량 입력.
  - 수량은 `formatPlainQuantity()` 사용.
  - 총 매수금액은 `단가 * 수량`. 수수료/세금은 MVP 계산 제외.
- 단가 비어 있거나 0:
  - 버튼 숨김 또는 비활성.
  - MVP는 비활성 우선.
- 기존 매수 거래 수정:
  - 같은 결제 현금 계좌/보유 종목 + 기존 거래 계산 반영 → 기존 매수 현금 지출 되돌림. `현재 현금 + 기존 매수 총액`.
  - 기존 거래 record-only → 현재 현금에 기존 매수 효과 없음. 기존 매수 총액 더하지 않음.
  - 새 보유 종목으로 변경되어 결제 현금 계좌 변경 → 새 계좌 현재 현금 기준.
  - 같은 결제 현금 계좌 쓰는 다른 holding으로 변경 → 새 holding 기준 아님. 같은 settlement cash 기준.
- 계산 수량이 DB 매수 가능 현금 검증 초과하지 않게 금액 기준 tolerance-safe 처리.

## Formatting And Tolerance

- 현금 금액 입력: 기존 금액 formatter 정책.
- 매수 수량 입력: `formatPlainQuantity()` 사용.
- `100%`는 잔액/매수 가능 현금 초과 금지.
- `25/50/75%`는 formatter 거쳐 double 노이즈 숨김.
- 금액은 MVP에서 기존 앱 3자리 소수 정책 유지. 100% 입력은 기준 금액 이하.
- USD 등 소수 통화 4자리 이상 금액 정밀도 이슈는 후속 currency scale 작업.

## Shared Component Direction

- 매도 폼 비중 버튼을 폼 공통 컴포넌트로 추출.
- 후보 위치:
  - `lib/pages/forms/form_design.dart`
  - 이름 예: `MoneyfyPercentageShortcutButtons`
- 컴포넌트는 선택 상태 없는 액션 버튼.
- 입력 대상 + 기준 금액/수량 계산은 각 폼 책임. 컴포넌트는 ratio 선택만 전달.

## Data And API Changes

- DB schema 변경 없음.
- Supabase migration 변경 없음.
- 현금 계좌 잔액 계산은 `_ensureSufficientCashBalance()`와 같은 편집 보정 의미 따라야 함.
- 매수 가능 현금 계산은 `_ensureSufficientSettlementCashForBuy()`와 같은 settlement cash 선택/편집 보정 의미 따라야 함.
- UI에서 DB 계산 helper 직접 공유 어렵다면 DB 테스트 + widget test에 같은 편집 케이스 추가.

## Development Phases

1. 매도 비중 버튼을 공통 action button 컴포넌트로 추출.
2. 기존 매도 widget/DB 테스트 재실행해 공통화 회귀 확인.
3. 현금 거래 폼에 source 잔액 기준 계산 helper 추가.
4. 현금 출금에 비중 버튼 적용 + 저장까지 검증.
5. 현금 이체에 비중 버튼 적용 + source 변경, target 변경, linked deposit 정합성 테스트.
6. 환전에 source 금액 비중 버튼 적용 + source/target 잔액 반영 테스트.
7. 매수 settlement cash 선택 규칙 확인 + 문서화.
8. 매수 폼에 매수 가능 현금 기준 계산 helper 추가 + 단가 입력 시 수량 자동 계산.
9. 신규/수정/계좌 변경/record-only 케이스를 DB 테스트 + widget test로 고정.

## MVP Scope

- 현금 출금: source 잔액 기준 금액 자동 입력.
- 현금 이체: source 잔액 기준 금액 자동 입력.
- 환전: source 잔액 기준 source 금액 자동 입력.
- 매수: 결제 가능 현금 기준 수량 자동 입력.
- 고정 옵션 `25%`, `50%`, `75%`, `100%`.

## Out Of Scope

- 비중 옵션 커스터마이즈.
- 거래소별 최소 주문 수량, 호가 단위, 수수료 포함 매수 가능 수량 계산.
- 목표 비중 리밸런싱.
- 매도 기능 UX 재설계. 공통 컴포넌트 추출에 필요한 최소 변경만.

## Test Plan

```bash
dart format lib/pages/forms/form_design.dart lib/pages/forms/cash_transaction_form_page.dart lib/pages/forms/transaction_form_page.dart test/transaction_flow_test.dart test/widget_test.dart test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/widget_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

추가 테스트:

- 현금 출금 100% 선택 → source 잔액 전체 입력.
- 현금 출금 100% 선택 후 저장 → source 잔액 0 또는 tolerance-safe 잔액.
- 현금 출금 수정 → 기존 출금 금액 되돌린 기준으로 100% 계산.
- record-only 출금 수정 → 기존 출금 금액 되돌리지 않음.
- 현금 이체 50% 선택 → source 잔액 절반 입력.
- 이체 source 계좌 변경 후 비중 버튼 → 새 source 잔액 기준.
- 이체 target 계좌 변경 후 저장 → source 차감 + target 입금 정합 반영.
- 환전 75% 선택 → source 통화 금액 필드에 source 잔액 75% 입력.
- 환율 비어도 환전 source 금액 버튼 동작.
- 환전 100% 선택 후 저장 → source 잔액/target 잔액 기대 반영.
- 매수 단가 입력 후 100% 선택 → 매수 가능 현금 기준 수량 입력.
- 매수 100% 선택 후 저장 → settlement cash 0 또는 tolerance-safe 잔액.
- 매수 단가 비어 있으면 버튼 숨김 또는 비활성.
- 매수 거래 수정 → 기존 매수 현금 지출 되돌린 기준으로 버튼 값 계산.
- record-only 매수 수정 → 기존 매수 현금 지출 되돌리지 않음.
- 버튼 입력 뒤 사용자 직접 금액/수량 수정 가능.

## Risks And Decisions

- UI 현금 잔액 계산과 DB 잔액 부족 검증 어긋나면 100% 저장 실패 가능. 편집 보정 규칙 테스트로 강하게 고정.
- 매수는 단가 + 결제 현금 계좌 모두 고려. 현금 출금/이체보다 리스크 높음.
- 환전은 source 금액과 target 금액이 환율로 연결. 비중 버튼은 source 금액 입력만 책임.
- 금액 소수 처리 정책은 기존 앱 동작 유지. 수량만 `formatPlainQuantity()` 사용.
- record-only 기존 거래는 현재 잔액 영향 없음. 편집 보정에서 되돌리지 않음.
- 공통 버튼 추출 후 기존 매도 회귀 가능. 매도 테스트 먼저 재실행.

## Open Questions

- 현금 금액 `100%`: MVP에서 기존 소수 입력 허용 정책 유지하되, 기준 금액 초과하지 않게 포맷.
- 매수 가능 현금 계좌 여러 개일 때 기준 계좌는 현재 DB settlement 규칙 선행 조사로 확인.
- 버튼 항상 표시 vs 기준 금액 있을 때만 표시 최종 UX 결정 필요.