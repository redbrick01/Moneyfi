# App Database Modularization Verification Test Plan

## Scope

`app_database.dart` 1차 비대화 분리의 구조 변경을 검증합니다.

## Quality Goals

- Drift table/schema 참조가 깨지지 않습니다.
- 원장 계산, CRUD, snapshot import/display, sync payload 테스트가 계속 통과합니다.
- public API 변경 없이 기존 호출부가 컴파일됩니다.

## Automated Test Plan

| Command | Purpose |
| --- | --- |
| `flutter test test/transaction_flow_test.dart` | DB CRUD, 원장 계산, 스냅샷, sync 변환 집중 회귀 |
| `flutter analyze` | part 파일 분리 후 정적 분석 |
| `flutter test` | 전체 앱 테스트 회귀 |

## Manual QA Plan

UI나 user flow 변경이 없으므로 필수 수동 QA는 없습니다.

## Responsive Checklist

화면 레이아웃 변경이 없어 반응형 QA는 대상이 아닙니다.

## Regression Test Commands

```bash
flutter test test/transaction_flow_test.dart
flutter analyze
flutter test
```

## Acceptance Criteria

- `app_database.dart`의 record/table/calculation helper가 별도 part 파일로 이동합니다.
- `flutter test test/transaction_flow_test.dart`가 통과합니다.
- `flutter analyze`와 `flutter test`가 통과합니다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| part 선언 누락 | Low | High | analyze와 transaction flow test로 확인 |
| Drift table annotation 참조 깨짐 | Low | High | table class 이름 유지, generated file 미변경 |
| 순수 helper 이동 중 호출 누락 | Medium | Medium | format/analyze/full test 실행 |

## Future Test Expansion

- snapshot method extension 분리 후 snapshot detail focused test 추가
- sync repository 분리 후 payload round-trip focused test 추가
- migration runner 분리 후 migration smoke test 추가
