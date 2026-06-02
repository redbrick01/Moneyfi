# Sell Quantity Percentage Shortcuts Plan

## Product Goal

매도 거래 입력 때 현재 매도 가능 수량 25%, 50%, 75%, 100% 빠른 선택. 가상화폐처럼 소수점 수량 직접 입력 어려운 자산에서 전량/부분 매도 안정 입력 목표.

## Current Baseline

- 투자 거래 폼은 `매수`/`매도`일 때 수량 입력 필드만 있음.
- 현재 보유 수량은 보유 선택 목록 subtitle/상세 화면에서 확인 가능. 매도 폼에서 비중 선택 불가.
- 거래 수정 때 기존 매도 영향이 이미 보유 수량에 반영됨. 현재 보유 수량만으로 100% 계산하면 수정 가능 수량과 다를 수 있음.

## Success Criteria

- 거래 유형 `매도`일 때 수량 입력 필드 아래 25%, 50%, 75%, 100% 선택 UI 표시.
- 비중 누르면 수량 필드가 매도 가능 수량 기준 자동 입력.
- 100% 선택 후 저장 때 소수 정밀도 문제로 초과 매도 오류 없음.
- 보유 종목 변경 시 비중 버튼은 새 보유 종목 기준 계산.
- `매수`, `배당`, `이자`에서는 비중 버튼 숨김.

## Proposed UX

- 기존 폼 톤과 맞는 작은 action chip/button 사용.
- `MoneyfyChoiceWrap`은 선택 상태 있는 choice UI라 신중 사용. 50% 누른 뒤 수량 직접 수정하면 선택 상태 해제 필요. MVP는 단순 입력 액션 버튼 우선.
- 버튼 라벨은 `25%`, `50%`, `75%`, `100%`.
- 버튼은 수량 필드 바로 아래 배치.
- 매도 가능 수량 0 이하이면 버튼 비활성화 또는 숨김.
- 버튼 입력 후 사용자 직접 수량 수정 가능.

## Calculation Rules

- 신규 매도 거래:
  - 기준 수량은 선택된 `HoldingItem.quantity`.
- 기존 매도 거래 수정:
  - 기준 수량은 `현재 HoldingItem.quantity + 기존 매도 거래 수량`.
  - 수정 중 현재 보유 수량에는 기존 매도 차감 효과 이미 반영됨.
- 기존 매수 거래를 매도로 변경하는 수정:
  - 기준 수량은 현재 보유 수량에서 기존 매수 효과 제거 후 계산.
  - 이 규칙은 DB의 `_ensureSufficientHoldingQuantityForSell()` 편집 보정 로직과 일치 필요.
- 기존 거래의 보유 종목과 새로 선택한 보유 종목이 다른 수정:
  - 기존 거래 효과는 원래 보유 종목에서만 되돌림.
  - 새 선택 보유 종목의 매도 가능 수량은 새 보유 종목 현재 수량 기준.
  - UI 계산과 DB 검증이 서로 다른 holding 기준 보정하지 않게 테스트 고정.
- 계산 결과는 정밀도 보존 formatter로 수량 필드 입력.
- 100%는 DB 검증 tolerance 안에서 매도 가능 수량 초과 금지.
- 25/50/75%는 사용자 기대 + 초과 매도 방지 고려. 수량 formatter 반올림보다 가능하면 tolerance-safe 내림 사용.

## Dependency On Precision Fix

이 기능은 `Crypto Sell Quantity Precision Fix` 먼저 또는 동시 적용 필요. 비중 버튼이 정확한 값 입력해도 저장 formatter가 소수 3자리로 줄이면 100% 매도 오류 재발 가능.

## Data And API Changes

- DB schema 변경 없음.
- Supabase migration 변경 없음.
- `TransactionFormPage` 내부에 매도 가능 수량 계산 helper와 비중 적용 handler 추가.
- `AppDatabase` 편집 가능 수량 검증 규칙과 UI 계산 규칙은 같은 정책 공유 필수.
- 같은 helper 직접 공유 어렵다면, 동일 케이스를 DB 단위 테스트와 widget test 양쪽 추가해 불일치 방지.

## Development Phases

1. 정밀도 보존 formatter와 매도 검증 안정화 먼저 반영.
2. `TransactionFormPage`에서 선택 보유 종목의 매도 가능 수량 계산.
3. 매도 수량 필드 아래 25/50/75/100% 선택 UI 추가.
4. 선택 시 `quantityController.text` 업데이트하고 기존 미리보기 갱신 흐름 재사용.
5. 신규 매도, 거래 수정, 기존 거래 holding과 새 선택 holding 다른 케이스 테스트.

## MVP Scope

- 투자 거래 폼 `매도` 타입에서만 비중 버튼 제공.
- 25%, 50%, 75%, 100% 고정 옵션.
- 선택 보유 종목 현재 수량 기준 자동 입력.
- 기존 거래 수정 시 기존 거래 효과 보정한 기준 수량 적용.

## Out Of Scope

- 사용자 비중 값 커스터마이즈.
- 거래소별 최소 주문 수량, 호가 단위, 수수료 차감 후 실수령 수량 계산.
- 현금 출금/이체 잔액 비중 선택.
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

추가 테스트:

- 보유 수량 `0.12345678`에서 100% 선택 값이 저장 가능 수량으로 입력.
- 50% 선택 시 수량 필드가 기준 수량 절반으로 채워짐.
- 거래 유형을 `매도`에서 `매수`로 바꾸면 비중 버튼 사라짐.
- 매도 거래 수정 화면에서 100%가 `현재 보유 + 기존 매도 수량` 기준 계산.
- 기존 거래 holding과 새 선택 holding 다를 때, 새 holding 현재 보유 수량 기준으로 버튼 값 계산.
- 버튼 탭 후 `quantityController` 값이 기대값으로 바뀌는 widget test 추가.
- 버튼 입력 뒤 사용자가 직접 수량 수정해도 저장 흐름 정상.

## Risks And Decisions

- UI 계산 기준과 DB 검증 기준 다르면 버튼 눌러도 저장 실패 가능. 가능하면 같은 보정 규칙 helper로 맞춤.
- `double` 연산 결과가 `0.30000000000000004`처럼 표시되지 않게 수량 formatter 필수.
- 100% 버튼 가장 민감. DB 검증 기준 초과하지 않는 포맷 우선.
- 선택 상태 유지 chip UI 쓰면 직접 입력 수정 후 상태 불일치 가능. MVP는 액션 버튼으로 처리해 상태 모델 단순화.

## Open Questions

- 버튼 선택 상태 유지 표시 vs 단순 입력 액션 결정 필요.
- 25/50/75% 계산 결과를 보유 수량 자릿수에 맞춰 내림 처리할지, formatter 반올림 쓸지 결정 필요.