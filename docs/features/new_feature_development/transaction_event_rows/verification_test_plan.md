# Transaction Event Rows Verification Test Plan

## Scope

거래 탭의 원장 라인 표시를 이벤트 표시로 바꾸는 화면 데이터 변환을 검증한다.

## Quality Goals

- 같은 `ledgerEventId`에 속한 여러 라인이 거래 탭에서 하나의 행으로 보인다.
- 기존 거래 생성/수정/삭제와 원장 계산 결과는 유지된다.
- 거래 탭, 하단 탭, 주요 독립 페이지가 계속 첫 프레임을 안정적으로 렌더링한다.

## Automated Test Plan

```bash
dart format lib/pages/transactions_page.dart test/page_walkthrough_test.dart
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 거래 탭에서 매수 거래가 투자 라인과 현금 결제 라인으로 중복 표시되지 않는지 확인한다.
- 거래 탭에서 이체/환전 거래가 한 행으로 보이는지 확인한다.
- 대표 행 삭제 후 관련 계좌 잔액/보유 수량이 함께 되돌아가는지 확인한다.

## Responsive Checklist

- 좁은 화면에서 이벤트 부제목이 한 줄 말줄임으로 유지된다.
- 금액 텍스트가 기존 max width 안에서 잘리지 않는지 확인한다.

## Regression Test Commands

- `flutter test test/transaction_flow_test.dart`
- `flutter test test/page_walkthrough_test.dart`
- `flutter analyze`

## Acceptance Criteria

- 자동 테스트가 통과한다.
- 신규 page-level grouping regression test에서 현금 이체 이벤트가 한 대표 거래로 그룹화된다.
- `git diff --check`가 whitespace 오류를 보고하지 않는다.

## Release Risk Matrix

| Risk | Impact | Mitigation |
| --- | --- | --- |
| 대표 라인 선택이 기대와 다름 | Medium | 투자 라인, 현금 유출 라인, 첫 라인 우선순위를 테스트와 문서에 고정 |
| 상세 화면 표시까지 바뀜 | Medium | 거래 탭 page-level grouping으로 범위 제한 |
| 복합 이벤트 수정 UX 부족 | Low | 기존 수정 차단 메시지를 유지 |

## Future Test Expansion

- 매수 이벤트가 투자/현금 라인 중 투자 대표 행으로 표시되는 widget test를 안정적으로 추가한다.
- 환전 이벤트의 source/target 계좌 표시를 검증한다.
