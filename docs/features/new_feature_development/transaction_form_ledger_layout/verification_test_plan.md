# Transaction Form Ledger Layout Verification Test Plan

## Scope

거래/현금 거래 폼의 계좌 선택 UX와 원장 이벤트 재생성 계약을 검증한다.

## Quality Goals

- 수정 시 선택한 새 보유/현금 계좌로 이벤트가 재생성된다.
- 이체 수정 시 source와 target 계좌 변경이 모두 반영된다.
- 기존 원장 계산, sync payload, snapshot 관련 회귀 테스트가 유지된다.
- 폼 첫 프레임이 계속 안정적으로 렌더링된다.

## Automated Test Plan

```bash
dart format lib/models/asset_item.dart lib/db/app_database.dart lib/pages/forms/transaction_form_page.dart lib/pages/forms/cash_transaction_form_page.dart test/transaction_flow_test.dart test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 투자 거래 추가 폼에서 보유 종목을 바꾼 뒤 저장한다.
- 투자 거래 수정 폼에서 보유 종목을 바꾼 뒤 기존 보유와 새 보유 수량 변화를 확인한다.
- 현금 입금/출금 폼에서 source 계좌를 바꾼 뒤 저장한다.
- 현금 이체 폼에서 계산 반영 토글이 꺼져 있어도 target 계좌 field가 보이는지 확인한다.
- 현금 이체 폼에서 source와 target 계좌를 모두 선택하고 저장한다.
- 작은 화면에서 계좌 선택 필드, 금액 필드, preview가 겹치지 않는지 확인한다.

## Responsive Checklist

- 계좌 선택 field의 긴 이름이 한 줄 말줄임으로 처리된다.
- 원장 preview row의 값이 오른쪽 영역에서 줄바꿈 없이 과도하게 깨지지 않는다.
- bottom sheet 목록이 SafeArea 안에 표시된다.

## Regression Test Commands

- `flutter test test/transaction_flow_test.dart`
- `flutter test test/page_walkthrough_test.dart`
- `flutter analyze`

## Acceptance Criteria

- 새 계좌 변경 테스트가 통과한다.
- 기존 50개 거래 흐름 테스트가 통과한다.
- page walkthrough가 통과한다.
- analyzer와 whitespace check가 통과한다.

## Release Risk Matrix

| Risk | Impact | Mitigation |
| --- | --- | --- |
| 수정 대상 계좌가 기존 계좌로 저장됨 | High | DB replace API 테스트 추가 |
| 이체 source/target이 같은 계좌가 됨 | Medium | UI option filtering과 DB existing guard 유지 |
| 계산 반영 꺼짐 상태에서 이체 target이 숨겨짐 | Medium | 이체 유형이면 target field를 항상 표시하고 수동 QA 항목으로 확인 |
| 폼 레이아웃이 작은 화면에서 복잡함 | Medium | 수동 QA 항목으로 남김 |

## Future Test Expansion

- Widget test로 bottom sheet 선택 흐름을 직접 검증한다.
- 환전 target 계좌 직접 선택 기능 추가 시 통화별 계좌 선택 테스트를 추가한다.
