# Transaction Percentage Shortcuts Expansion Plan

## Product Goal

`25%`, `50%`, `75%`, `100%` 빠른 선택 UX를 매도 외 거래에도 확장한다. 사용자가 현재 보유 현금이나 매수 가능 현금 안에서 일부 금액을 빠르게 입력하고, 코인/해외 자산처럼 소수 수량이 필요한 매수에서는 수량 계산까지 안정적으로 연결하는 것이 목표다.

## Target Flows

1. 현금 출금
2. 현금 이체
3. 환전
4. 매수

## Current Baseline

- 매도 폼에는 이미 보유 수량 기준 `25%`, `50%`, `75%`, `100%` 액션 버튼이 있다.
- 현금 거래 폼은 금액을 직접 입력해야 한다.
- 매수 폼은 단가와 수량을 직접 입력해야 한다.
- 매수 가능 현금 부족 검증은 DB에 있지만, UI에서 현금 기준 비중을 빠르게 선택하는 기능은 없다.

## Success Criteria

- 현금 출금, 현금 이체, 환전에서 source 현금 잔액 기준 비중 버튼이 표시된다.
- 매수에서 결제 가능 현금 기준 비중 버튼이 표시되고, 단가가 입력되어 있으면 수량을 자동 계산한다.
- `100%` 버튼으로 입력한 값은 DB 잔액/수량 검증을 통과하고 저장까지 성공해야 한다.
- 사용자가 버튼으로 값을 채운 뒤 직접 금액 또는 수량을 수정할 수 있다.
- 거래 유형이나 source 계좌/보유 종목을 바꾸면 버튼 계산 기준도 즉시 바뀐다.

## UX Proposal

- 매도에서 구현한 선택 상태 없는 action button 패턴을 재사용한다.
- 버튼 라벨은 `25%`, `50%`, `75%`, `100%`로 통일한다.
- 현금 거래 폼에서는 금액 필드 아래에 배치한다.
- 매수 폼에서는 수량 필드 아래 또는 단가/수량 그룹 하단에 배치한다.
- 기준 잔액/매수 가능 현금이 0 이하이면 버튼을 숨기거나 비활성화한다.
- 버튼 근처에 별도 설명 문구를 과하게 넣지 않고, 기존 필드 라벨과 미리보기로 의미를 전달한다.

## Calculation Rules

### 1. 현금 출금

- 기준 금액: DB가 계산 반영 거래 저장 시 사용하는 source 현금 계좌의 사용 가능 잔액과 같은 의미여야 한다.
  - 기본값은 선택된 source cash holding의 현재 `quantity`/cash account balance다.
  - record-only 거래는 현재 잔액에 반영되지 않으므로 기준 금액 보정에도 되돌리지 않는다.
- `25/50/75/100%` 선택 시 `amountController.text`에 기준 금액의 해당 비율을 입력한다.
- 기존 출금 거래 수정:
  - 기존 거래와 같은 source 계좌이고 기존 거래가 계산 반영 거래라면 `현재 잔액 + 기존 출금 금액`을 기준으로 계산한다.
  - 기존 거래가 record-only라면 현재 잔액에 기존 출금 효과가 없으므로 기존 출금 금액을 더하지 않는다.
  - 기존 거래와 다른 source 계좌로 변경했다면 새 source 계좌의 현재 잔액만 기준으로 계산한다.
- 입금으로 수정 중인 거래를 출금으로 바꾼 경우:
  - 같은 source 계좌이고 기존 거래가 계산 반영 거래라면 현재 잔액에서 기존 입금 효과를 제거한 값을 기준으로 계산한다.
  - 보정 결과가 0 이하이면 버튼을 숨기거나 비활성화한다.

### 2. 현금 이체

- 기준 금액: 선택된 source 현금 계좌의 사용 가능 잔액.
- target 계좌는 계산 기준에 포함하지 않는다.
- source와 target이 같은 계좌인 경우 기존 검증처럼 저장을 막는다.
- 기존 이체 거래 수정:
  - 같은 source 계좌이고 기존 거래가 계산 반영 거래라면 기존 이체 출금 금액을 되돌려 `현재 잔액 + 기존 이체 금액` 기준으로 계산한다.
  - 기존 거래가 record-only라면 현재 잔액에 기존 이체 효과가 없으므로 기존 금액을 더하지 않는다.
  - source 계좌를 변경했다면 새 source 계좌의 현재 잔액 기준으로 계산한다.
  - target 계좌 변경은 기준 금액에 영향을 주지 않지만, linked deposit 정합성은 저장 테스트로 확인한다.

### 3. 환전

- 기준 금액: 선택된 source 현금 계좌의 사용 가능 잔액.
- 버튼은 source 통화 금액 입력 필드에 값을 채운다.
- 환율 필드가 비어 있어도 source 금액 비중 선택은 가능해야 한다.
- 기존 환전 거래 수정:
  - 같은 source 계좌이고 기존 거래가 계산 반영 거래라면 기존 source 출금 금액을 되돌린 금액 기준으로 계산한다.
  - 기존 거래가 record-only라면 기존 source 금액을 되돌리지 않는다.
  - source 계좌가 바뀌면 새 source 계좌의 현재 잔액 기준으로 계산한다.
  - target 통화 계좌 자동 선택/생성 규칙은 기존 DB API를 따른다. 이 계획에서는 source 금액 입력만 책임진다.
  - 100% 환전 저장 후 source 잔액과 target 잔액이 기대대로 반영되는지 테스트한다.

### 4. 매수

- 기준 금액: DB의 `_ensureSufficientSettlementCashForBuy()`가 사용하는 결제 현금 계좌의 매수 가능 현금.
- 선행 조사:
  - 현재 DB가 어떤 cash account를 settlement 계좌로 선택하는지 확인하고 문서화한다.
  - 동일 통화 cash account가 여러 개일 때 선택 규칙을 확인한다.
- 단가가 입력되어 있고 0보다 크면:
  - 선택 비중 금액을 `단가`로 나누어 `quantityController.text`에 수량을 입력한다.
  - 수량은 `formatPlainQuantity()`를 사용한다.
  - 총 매수금액은 `단가 * 수량` 기준이며, 수수료/세금은 MVP 계산에 포함하지 않는다.
- 단가가 비어 있거나 0이면:
  - 버튼을 숨기거나 비활성화한다.
  - MVP에서는 비활성화를 우선한다.
- 기존 매수 거래 수정:
  - 같은 결제 현금 계좌/보유 종목이고 기존 거래가 계산 반영 거래라면 기존 매수 현금 지출을 되돌려 `현재 현금 + 기존 매수 총액` 기준으로 계산한다.
  - 기존 거래가 record-only라면 현재 현금에 기존 매수 효과가 없으므로 기존 매수 총액을 더하지 않는다.
  - 새 보유 종목으로 변경되어 결제 현금 계좌가 달라지면 새 계좌의 현재 현금 기준으로 계산한다.
  - 같은 결제 현금 계좌를 쓰는 다른 holding으로 변경하면 새 holding 기준이 아니라 같은 settlement cash 기준으로 계산한다.
- 계산된 수량이 DB의 매수 가능 현금 검증을 초과하지 않도록 금액 기준을 tolerance-safe하게 처리한다.

## Formatting And Tolerance

- 현금 금액 입력은 기존 금액 formatter 정책을 따른다.
- 매수 수량 입력은 `formatPlainQuantity()`를 사용한다.
- `100%`는 잔액 또는 매수 가능 현금을 초과하지 않아야 한다.
- `25/50/75%`는 double 노이즈가 노출되지 않도록 formatter를 거친다.
- 금액은 MVP에서 기존 앱의 3자리 소수 정책을 유지하되, 100% 입력은 기준 금액 이하가 되도록 처리한다.
- USD 등 소수 통화에서 4자리 이상 금액 정밀도가 필요해지는 문제는 후속 currency scale 작업으로 분리한다.

## Shared Component Direction

- 매도 폼에 들어간 비중 버튼을 폼 공통 컴포넌트로 추출한다.
- 후보 위치:
  - `lib/pages/forms/form_design.dart`
  - 이름 예: `MoneyfyPercentageShortcutButtons`
- 컴포넌트는 선택 상태를 가지지 않는 액션 버튼이어야 한다.
- 입력 대상과 기준 금액/수량 계산은 각 폼에서 담당하고, 컴포넌트는 ratio 선택만 전달한다.

## Data And API Changes

- DB schema 변경은 없다.
- Supabase migration 변경은 없다.
- 현금 계좌 잔액 계산은 `_ensureSufficientCashBalance()`와 같은 편집 보정 의미를 따라야 한다.
- 매수 가능 현금 계산은 `_ensureSufficientSettlementCashForBuy()`와 같은 settlement cash 선택/편집 보정 의미를 따라야 한다.
- UI에서 DB 계산 helper를 직접 공유하기 어렵다면 DB 테스트와 widget test에 같은 편집 케이스를 추가한다.

## Development Phases

1. 매도 비중 버튼을 공통 action button 컴포넌트로 추출한다.
2. 기존 매도 widget/DB 테스트를 재실행해 공통화 회귀가 없는지 확인한다.
3. 현금 거래 폼에 source 잔액 기준 계산 helper를 추가한다.
4. 현금 출금에 비중 버튼을 적용하고 저장까지 검증한다.
5. 현금 이체에 비중 버튼을 적용하고 source 변경, target 변경, linked deposit 정합성을 테스트한다.
6. 환전에 source 금액 비중 버튼을 적용하고 source/target 잔액 반영을 테스트한다.
7. 매수 settlement cash 선택 규칙을 확인하고 문서화한다.
8. 매수 폼에 매수 가능 현금 기준 계산 helper를 추가하고 단가 입력 시 수량 자동 계산을 적용한다.
9. 신규/수정/계좌 변경/record-only 케이스를 DB 테스트와 widget test로 고정한다.

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
- 매도 기능의 UX 재설계. 공통 컴포넌트 추출에 필요한 최소 변경만 한다.

## Test Plan

```bash
dart format lib/pages/forms/form_design.dart lib/pages/forms/cash_transaction_form_page.dart lib/pages/forms/transaction_form_page.dart test/transaction_flow_test.dart test/widget_test.dart test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/widget_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

추가할 테스트:

- 현금 출금에서 100% 선택 시 source 잔액 전체가 입력된다.
- 현금 출금에서 100% 선택 후 저장하면 source 잔액이 0 또는 tolerance-safe 잔액이 된다.
- 현금 출금 수정에서 기존 출금 금액을 되돌린 기준으로 100%가 계산된다.
- record-only 출금 수정에서는 기존 출금 금액을 되돌리지 않는다.
- 현금 이체에서 50% 선택 시 source 잔액 절반이 입력된다.
- 이체 source 계좌 변경 후 비중 버튼이 새 source 잔액 기준으로 계산된다.
- 이체 target 계좌 변경 후 저장하면 source 차감과 target 입금이 정합적으로 반영된다.
- 환전에서 75% 선택 시 source 통화 금액 필드에 source 잔액의 75%가 입력된다.
- 환율이 비어 있어도 환전 source 금액 버튼은 동작한다.
- 환전에서 100% 선택 후 저장하면 source 잔액과 target 잔액이 기대대로 반영된다.
- 매수에서 단가 입력 후 100% 선택 시 매수 가능 현금 기준 수량이 입력된다.
- 매수에서 100% 선택 후 저장하면 settlement cash가 0 또는 tolerance-safe 잔액이 된다.
- 매수에서 단가가 비어 있으면 버튼이 숨겨지거나 비활성화된다.
- 매수 거래 수정에서 기존 매수 현금 지출을 되돌린 기준으로 버튼 값이 계산된다.
- record-only 매수 수정에서는 기존 매수 현금 지출을 되돌리지 않는다.
- 버튼으로 값을 입력한 뒤 사용자가 직접 금액/수량을 수정할 수 있다.

## Risks And Decisions

- 현금 잔액 기준 UI 계산과 DB의 잔액 부족 검증이 어긋나면 100% 버튼 저장이 실패할 수 있다. 편집 보정 규칙을 테스트로 강하게 고정한다.
- 매수는 단가와 결제 현금 계좌를 모두 고려해야 하므로 현금 출금/이체보다 리스크가 높다.
- 환전은 source 금액과 target 금액이 환율로 연결되므로, 비중 버튼은 source 금액 입력에만 책임을 둔다.
- 금액 소수 처리 정책은 기존 앱 동작을 유지한다. 수량만 `formatPlainQuantity()`를 사용한다.
- record-only 기존 거래는 현재 잔액에 영향을 주지 않으므로 편집 보정에서 되돌리지 않는다.
- 공통 버튼 추출 후 기존 매도 기능 회귀 가능성이 있으므로 매도 테스트를 먼저 재실행한다.

## Open Questions

- 현금 금액의 `100%`는 MVP에서 기존 소수 입력 허용 정책을 유지하되, 기준 금액을 초과하지 않게 포맷한다.
- 매수 가능 현금 계좌가 여러 개일 때 어떤 계좌를 기준으로 할지 현재 DB settlement 규칙을 선행 조사에서 확인해야 한다.
- 버튼을 항상 보여줄지, 기준 금액이 있을 때만 보여줄지 최종 UX 결정을 해야 한다.
