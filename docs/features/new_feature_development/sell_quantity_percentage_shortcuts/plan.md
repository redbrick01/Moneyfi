# Sell Quantity Percentage Shortcuts Plan

## Product Goal

매도 거래 입력 시 현재 매도 가능 수량의 25%, 50%, 75%, 100%를 빠르게 선택할 수 있게 한다. 특히 가상화폐처럼 소수점 수량을 직접 입력하기 어려운 자산에서 전량 또는 부분 매도를 안정적으로 입력하게 하는 것이 목표다.

## Current Baseline

- 투자 거래 폼은 `매수`/`매도`일 때 수량 입력 필드만 제공한다.
- 현재 보유 수량은 보유 선택 목록의 subtitle이나 상세 화면에서 확인할 수 있지만, 매도 폼에서 바로 비중을 선택할 수 없다.
- 거래 수정 시 기존 매도 거래의 영향이 이미 보유 수량에 반영되어 있으므로, 단순히 현재 보유 수량만 기준으로 100%를 계산하면 수정 가능 수량과 다를 수 있다.

## Success Criteria

- 거래 유형이 `매도`일 때 수량 입력 필드 아래에 25%, 50%, 75%, 100% 선택 UI가 표시된다.
- 사용자가 비중을 누르면 수량 필드가 매도 가능 수량 기준으로 자동 입력된다.
- 100% 선택 후 저장했을 때 소수 정밀도 문제로 초과 매도 오류가 발생하지 않는다.
- 보유 종목을 변경하면 비중 버튼은 새 보유 종목 기준으로 계산한다.
- `매수`, `배당`, `이자`에서는 비중 버튼이 표시되지 않는다.

## Proposed UX

- 기존 폼 톤과 맞는 작은 action chip/button을 사용한다.
- `MoneyfyChoiceWrap`은 선택 상태가 있는 choice UI라서 신중히 사용한다. 사용자가 50%를 누른 뒤 수량을 직접 수정하면 선택 상태 해제가 필요하므로, MVP에서는 단순 입력 액션 버튼을 우선한다.
- 버튼 라벨은 `25%`, `50%`, `75%`, `100%`로 간결하게 둔다.
- 버튼은 수량 필드 바로 아래에 배치한다.
- 매도 가능 수량이 0 이하이면 버튼을 비활성화하거나 노출하지 않는다.
- 사용자가 버튼으로 채운 뒤 직접 수량을 수정할 수 있어야 한다.

## Calculation Rules

- 신규 매도 거래:
  - 기준 수량은 선택된 `HoldingItem.quantity`다.
- 기존 매도 거래 수정:
  - 기준 수량은 `현재 HoldingItem.quantity + 기존 매도 거래 수량`이다.
  - 기존 매도 거래를 수정하는 동안 현재 보유 수량에는 기존 매도의 차감 효과가 이미 반영되어 있기 때문이다.
- 기존 매수 거래를 매도로 변경하는 수정:
  - 기준 수량은 현재 보유 수량에서 기존 매수 효과를 제거한 뒤 계산해야 한다.
  - 이 규칙은 DB의 `_ensureSufficientHoldingQuantityForSell()` 편집 보정 로직과 일치해야 한다.
- 기존 거래의 보유 종목과 새로 선택한 보유 종목이 다른 수정:
  - 기존 거래 효과는 원래 보유 종목에서만 되돌린다.
  - 새 선택 보유 종목의 매도 가능 수량은 새 보유 종목의 현재 수량 기준으로 계산한다.
  - UI 계산과 DB 검증이 서로 다른 holding을 기준으로 보정하지 않도록 테스트로 고정한다.
- 계산 결과는 정밀도 보존 formatter로 수량 필드에 입력한다.
- 100%는 DB 검증 tolerance 안에서 매도 가능 수량을 초과하지 않아야 한다.
- 25/50/75%는 사용자 기대와 초과 매도 방지를 모두 고려해, 수량 formatter 반올림이 아니라 가능한 경우 tolerance-safe 내림 정책을 사용한다.

## Dependency On Precision Fix

이 기능은 `Crypto Sell Quantity Precision Fix`가 먼저 적용되거나 동시에 적용되어야 한다. 비중 버튼이 정확한 값을 입력해도 저장 formatter가 소수 3자리로 줄이면 100% 매도 오류가 다시 발생할 수 있다.

## Data And API Changes

- DB schema 변경은 없다.
- Supabase migration 변경은 없다.
- `TransactionFormPage` 내부에 매도 가능 수량 계산 helper와 비중 적용 handler를 추가한다.
- `AppDatabase`의 편집 가능 수량 검증 규칙과 UI 계산 규칙은 반드시 같은 정책을 공유한다.
- 직접 같은 helper를 공유하기 어렵다면, 동일한 케이스를 DB 단위 테스트와 widget test 양쪽에 추가해 불일치를 막는다.

## Development Phases

1. 정밀도 보존 formatter와 매도 검증 안정화 작업을 먼저 반영한다.
2. `TransactionFormPage`에서 선택된 보유 종목의 매도 가능 수량을 계산한다.
3. 매도 수량 필드 아래에 25/50/75/100% 선택 UI를 추가한다.
4. 선택 시 `quantityController.text`를 업데이트하고 기존 미리보기 갱신 흐름을 재사용한다.
5. 신규 매도, 거래 수정, 기존 거래 holding과 새 선택 holding이 다른 케이스를 테스트한다.

## MVP Scope

- 투자 거래 폼의 `매도` 타입에서만 비중 버튼 제공.
- 25%, 50%, 75%, 100% 고정 옵션.
- 선택된 보유 종목의 현재 수량 기준 자동 입력.
- 기존 거래 수정 시 기존 거래 효과를 보정한 기준 수량 적용.

## Out Of Scope

- 사용자가 비중 값을 직접 커스터마이즈하는 기능.
- 거래소별 최소 주문 수량, 호가 단위, 수수료 차감 후 실수령 수량 계산.
- 현금 출금/이체의 잔액 비중 선택.
- 매수 금액 기준 목표 비중 자동 계산.

## Test Plan

```bash
dart format lib/pages/forms/transaction_form_page.dart test/page_walkthrough_test.dart test/transaction_flow_test.dart test/widget_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/widget_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

추가할 테스트:

- 보유 수량 `0.12345678`에서 100% 선택 값이 저장 가능한 수량으로 입력된다.
- 50% 선택 시 수량 필드가 기준 수량의 절반으로 채워진다.
- 거래 유형을 `매도`에서 `매수`로 바꾸면 비중 버튼이 사라진다.
- 매도 거래 수정 화면에서 100%가 `현재 보유 + 기존 매도 수량` 기준으로 계산된다.
- 기존 거래 holding과 새 선택 holding이 다를 때, 새 holding의 현재 보유 수량 기준으로 버튼 값이 계산된다.
- 버튼 탭 후 `quantityController` 값이 기대값으로 바뀌는 widget test를 추가한다.
- 버튼으로 값을 입력한 뒤 사용자가 직접 수량을 수정해도 저장 흐름이 정상 동작한다.

## Risks And Decisions

- UI 계산 기준과 DB 검증 기준이 다르면 사용자가 버튼을 눌러도 저장 실패가 날 수 있다. 가능하면 같은 보정 규칙을 helper로 맞춘다.
- `double` 연산 결과가 `0.30000000000000004`처럼 표시되지 않도록 수량 formatter를 반드시 거친다.
- 100% 버튼은 가장 민감하므로 DB 검증 기준을 초과하지 않는 포맷을 우선한다.
- 선택 상태를 유지하는 chip UI를 쓰면 직접 입력 수정 후 상태 불일치가 생길 수 있다. MVP에서는 액션 버튼으로 처리해 상태 모델을 단순화한다.

## Open Questions

- 버튼 선택 상태를 유지 표시할지, 단순 입력 액션으로만 둘지 결정이 필요하다.
- 25/50/75% 계산 결과를 보유 수량 자릿수에 맞춰 내림 처리할지, formatter 반올림을 사용할지 결정해야 한다.
