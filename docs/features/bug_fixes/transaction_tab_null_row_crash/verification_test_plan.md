# Transaction Tab Null Row Crash Verification Test Plan

## Scope

- 거래 탭과 상세 거래내역 row에 쓰이는 원장 조회의 null-safe fallback.
- 거래 탭 화면 진입 회귀 확인.
- 원장 계산 회귀 확인.

## Automated Tests

```bash
flutter test test/transaction_flow_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Manual QA

- 첨부 스크린샷과 같은 거래 탭에서 빨간 error widget이 사라지는지 확인한다.
- 검색/필터/정렬을 변경해도 목록이 정상 표시되는지 확인한다.
- 외부 입금/출금 색상과 내부 거래 기본색이 유지되는지 확인한다.

## Acceptance Criteria

- 거래 탭 목록 영역이 런타임 타입 오류 없이 렌더링된다.
- null 또는 누락된 표시 문자열은 안전한 fallback으로 대체된다.
- transaction flow 테스트와 page walkthrough가 통과한다.

## Residual Risk

자동 테스트는 사용자의 실제 로컬 DB row를 그대로 재현하지 않는다. 실제 기기/데스크톱 앱 DB로 수동 확인이 필요하다.
