# App Database Modularization Plan

## Product Goal

`lib/db/app_database.dart`에 DB schema, migration, CRUD, 원장 계산, 스냅샷, sync 변환 몰림. 단계 분리해서 변경 리스크, 리뷰 비용 낮춤.

## Current Baseline

- `app_database.dart` 7,775줄.
- 파일 상단: record DTO, Drift table 정의, 원장 날짜 SQL helper 함께 있음.
- 파일 중간: migration, ledger rebuild, CRUD, snapshot import/query, cache, sync payload 변환 한 클래스에 공존.
- `flutter test test/transaction_flow_test.dart` 변경 전 통과.

## Success Criteria

- DB schema/table 정의 별도 part 파일 분리.
- 원장/스냅샷 record DTO 별도 part 파일 분리.
- 거래 금액/날짜/표시 label 순수 계산 helper 별도 part 파일 분리.
- `AppDatabase` public API, schemaVersion, generated file 변경 없음.
- 원장/스냅샷/sync 회귀 테스트 계속 통과.

## Metric And Data Definitions

- 이번 패치 계산식, DB 컬럼 의미 안 바꿈.
- 분리 단위 ownership:
  - `app_database_records.dart`: query result record와 내부 normalized value DTO
  - `app_database_tables.dart`: Drift table declarations
  - `app_database_calculations.dart`: DB IO 없는 순수 계산/format helper

## Proposed UX

사용자-facing UI 변경 없음.

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

- 안전한 1차 분리만 수행.
- CRUD, migration, snapshot, sync instance method를 extension/mixin 이동하는 2차 개편 제외.
- generated drift 파일 재생성, 필요 없으면 안 함.

## Test Plan

```bash
dart format lib/db/app_database.dart lib/db/app_database_records.dart lib/db/app_database_tables.dart lib/db/app_database_calculations.dart
flutter test test/transaction_flow_test.dart
flutter analyze
flutter test
```

## Risks And Decisions

- `part` 기반 분리: private helper 접근 유지, 회귀 위험 낮음.
- 큰 instance method 이동: extension resolution과 private member 의존성 있어 별도 패치.
- Drift generated file 변경 없게 table class 이름과 annotation 참조 유지.

## Open Questions

- 2차 분리: snapshot/sync/ledger method group을 extension 기반으로 옮길지, repository class로 옮길지 결정 필요.

## Feasibility And Feedback

- 1차 분리 기계적, 테스트 검증 가능, 즉시 적용 좋음.
- 파일 크기 줄지만 `AppDatabase` 클래스 책임 여전히 큼.
- 후속 batch에서 `snapshot`, `sync`, `ledger write`, `migration` method group 순차 분리 적절.