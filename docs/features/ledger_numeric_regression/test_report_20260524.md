# Ledger Numeric Regression Test Report 2026-05-24

## Summary

원장, 현금 계좌, 환전, 스냅샷 표시 계산의 핵심 수치 회귀 테스트를 추가했습니다. Production 계산 로직은 변경하지 않았고, 기존 in-memory Drift 테스트 fixture에 복합 시나리오를 고정했습니다.

## Test Environment

- Date: 2026-05-24
- Workspace: `/Users/yw0410/Desktop/Project/MONEYFY`
- Runtime: Flutter test with in-memory Drift database

## Commands Run

```bash
flutter test test/transaction_flow_test.dart
dart format test/transaction_flow_test.dart
dart format test/transaction_flow_test.dart
flutter test test/transaction_flow_test.dart
dart format test/transaction_flow_test.dart
flutter test test/transaction_flow_test.dart
flutter analyze
flutter test
```

## Command Results

| Command | Result | Notes |
| --- | --- | --- |
| `flutter test test/transaction_flow_test.dart` | Passed | Baseline before edits, 44 tests |
| `dart format test/transaction_flow_test.dart` | Failed then passed | First run failed on Flutter SDK cache permission; same command rerun escalated per tooling rule |
| `flutter test test/transaction_flow_test.dart` | Failed | New snapshot fixture used negative cash-account UI ids for client-id lookup |
| `dart format test/transaction_flow_test.dart` | Passed | Fixture correction formatted |
| `flutter test test/transaction_flow_test.dart` | Passed | 46 tests |
| `flutter analyze` | Passed | No issues found |
| `flutter test` | Passed | 92 tests |

## Verification Against Plan

- Mixed ledger/cash/fx/trade aggregate regression: passed.
- Snapshot cash account balance and exchange-rate import regression: passed.
- Existing transaction flow coverage: passed.
- Full project test suite: passed.

## Manual QA Status

UI 변경이 없으므로 별도 수동 QA는 수행하지 않았습니다. 필요 시 샘플 데이터로 투자성과/자산 상세/스냅샷 상세 화면의 동일 수치를 육안 확인하면 됩니다.

## Responsive QA Status

화면 레이아웃 변경이 없어 반응형 QA는 대상이 아닙니다.

## Acceptance Criteria Result

- 복합 ledger regression test가 명시 기대값을 통과했습니다.
- snapshot cash account regression test가 remap, balance, currency, exchange rate 값을 통과했습니다.
- `flutter analyze`와 `flutter test`가 통과했습니다.

## Risk Assessment After Testing

- 로컬 Drift 계산 회귀 위험은 낮아졌습니다.
- 서버 snapshot function 산출 payload 자체는 이번 범위에서 실행하지 않았으므로 integration risk는 남아 있습니다.
- `internalCashMovementAmount`는 순액이 아니라 양방향 line 절대값 합산 활동량이라는 기준을 테스트와 계획서에 고정했습니다.

## Follow-Up Recommendations

1. `create-portfolio-snapshot` Edge Function의 payload 산출물을 대상으로 integration test를 추가합니다.
2. 삭제/수정 후 복합 원장 aggregate가 유지되는 별도 회귀 테스트를 추가합니다.
3. 다중 통화 valuation의 KRW 환산 화면 테스트를 추가합니다.

## Final Result

Passed. 핵심 수치 계산 회귀 테스트 추가와 전체 검증이 완료되었습니다.
