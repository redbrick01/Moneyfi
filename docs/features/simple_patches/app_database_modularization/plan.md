# App Database Modularization Plan

## Product Goal

`lib/db/app_database.dart`에 DB schema, migration, CRUD, 원장 계산, 스냅샷, sync 변환이 집중된 구조를 단계적으로 분리해 변경 리스크와 리뷰 비용을 낮춥니다.

## Current Baseline

- `app_database.dart`는 7,775줄입니다.
- 파일 상단에는 record DTO, Drift table 정의, 원장 날짜 SQL helper가 함께 있습니다.
- 파일 중간에는 migration, ledger rebuild, CRUD, snapshot import/query, cache, sync payload 변환이 한 클래스에 공존합니다.
- `flutter test test/transaction_flow_test.dart`는 변경 전 통과했습니다.

## Success Criteria

- DB schema/table 정의는 별도 part 파일로 분리됩니다.
- 원장/스냅샷 record DTO는 별도 part 파일로 분리됩니다.
- 거래 금액/날짜/표시 label 같은 순수 계산 helper는 별도 part 파일로 분리됩니다.
- `AppDatabase` public API, schemaVersion, generated file은 변경하지 않습니다.
- 원장/스냅샷/sync 회귀 테스트가 계속 통과합니다.

## Metric And Data Definitions

- 이번 패치는 계산식이나 DB 컬럼 의미를 바꾸지 않습니다.
- 분리 단위는 다음 ownership 기준을 따릅니다.
  - `app_database_records.dart`: query result record와 내부 normalized value DTO
  - `app_database_tables.dart`: Drift table declarations
  - `app_database_calculations.dart`: DB IO 없는 순수 계산/format helper

## Proposed UX

사용자-facing UI 변경은 없습니다.

## Data/API Changes

- DB migration 없음
- Supabase schema 변경 없음
- Dart public API 변경 없음
- 파일 구조만 변경

## Development Phases

1. Baseline transaction flow test 실행
2. 영구 계획/검증 문서와 임시 실행 계획 작성
3. record/table/calculation helper를 part 파일로 분리
4. format, targeted test, analyze, full test 실행
5. test report 작성 및 임시 문서 삭제

## MVP Scope

- 안전한 1차 분리만 수행합니다.
- CRUD, migration, snapshot, sync instance method를 extension/mixin으로 옮기는 2차 구조 개편은 이번 범위에서 제외합니다.
- generated drift 파일 재생성은 필요하지 않으면 수행하지 않습니다.

## Test Plan

```bash
dart format lib/db/app_database.dart lib/db/app_database_records.dart lib/db/app_database_tables.dart lib/db/app_database_calculations.dart
flutter test test/transaction_flow_test.dart
flutter analyze
flutter test
```

## Risks And Decisions

- `part` 기반 분리는 private helper 접근을 유지해 회귀 위험이 낮습니다.
- 큰 instance method 이동은 extension resolution과 private member 의존성 때문에 별도 패치로 분리합니다.
- Drift generated file 변경이 없도록 table class 이름과 annotation 참조는 유지합니다.

## Open Questions

- 2차 분리에서는 snapshot/sync/ledger method group을 extension 기반으로 옮길지, repository class로 옮길지 결정해야 합니다.

## Feasibility And Feedback

- 이번 1차 분리는 기계적이고 테스트로 검증 가능해 즉시 적용하기 좋습니다.
- 파일 크기 자체는 크게 줄지만 `AppDatabase` 클래스의 책임은 여전히 큽니다.
- 후속 batch에서 `snapshot`, `sync`, `ledger write`, `migration` method group을 순차적으로 분리하는 것이 적절합니다.
