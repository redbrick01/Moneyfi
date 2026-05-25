# Simple Patch Process Guidelines

이 문서는 MONEYFY에서 구조 개선, 보안/품질 강화, 테스트/CI 보강, 정책 정리처럼 기존 사용자 기능을 크게 바꾸지 않는 단순 패치를 진행할 때 따르는 규칙입니다.

## When To Use

다음 중 하나에 해당하면 이 프로세스를 사용합니다.

- 코드 구조 분리, 모듈화, 네이밍 정리
- 인증, 권한, RLS, 입력 검증 같은 보안/품질 강화
- CI/CD, 테스트, 린트, 문서 인덱스 개선
- sync 충돌 정책, fallback 정책 같은 운영/계산 기준 정리
- 기존 기능의 동작은 유지하면서 안정성만 높이는 변경

사용자가 새 화면이나 새 기능을 체감하면 `development_process_guidelines.md`의 새 기능 개발 프로세스를 사용합니다. 실행 실패나 깨진 화면을 바로잡는 목적이면 `bug_fix_process_guidelines.md`를 사용합니다.

## Document Location

단순 패치 문서는 아래 경로에 저장합니다.

```text
docs/features/simple_patches/<work>/
```

`<work>`는 snake_case를 사용합니다.

## Required Artifacts

| 문서 | 필수 여부 | 목적 |
| --- | --- | --- |
| `plan.md` | 필수 | 패치 목적, 범위, 영향, 제외 범위, 검증 계획 |
| `verification_test_plan.md` | 필수 | 실행할 자동 테스트와 미수행 수동 확인 항목 |
| `test_report_YYYYMMDD.md` | 필수 | 실제 실행 결과와 잔여 리스크 |
| `tmp_execution_plan.md` | 권장 | 여러 파일을 바꾸거나 순서가 중요한 경우 사용 후 삭제 |
| `tmp_development_report.md` | 선택 | 판단 근거가 복잡할 때만 사용 |

영구 문서를 추가하면 `docs/README.md`와 `docs/features/simple_patches/README.md`에 링크를 추가합니다.

## Required Process

이 순서는 필수입니다. 구현이나 파일 수정은 Stage 1의 scope check와 Stage 2의 `plan.md` 작성 이후에 진행합니다. `verification_test_plan.md`는 실행할 검증 기준을 구현 전에 고정하는 문서이고, `test_report_YYYYMMDD.md`는 테스트 실행 후 실제 결과를 기록하는 문서입니다. 패치를 먼저 끝낸 뒤 계획서와 검증 계획을 사후 작성하는 방식은 허용하지 않습니다.

### Stage 1. Scope Check

목표: 변경이 단순 패치 범위에 맞는지 확인합니다.

작업:

1. `git status --short`로 기존 미커밋 변경을 확인합니다.
2. 관련 코드, 테스트, 문서를 `rg` 또는 `rg --files`로 찾습니다.
3. 변경이 사용자-facing 새 기능인지, 버그 픽스인지, 단순 패치인지 분류합니다.
4. DB, sync, auth, 원장, snapshot에 닿으면 관련 회귀 테스트 후보를 정합니다.

완료 기준:

- 패치 범위와 제외 범위가 명확합니다.
- 기존 사용자 변경을 되돌리지 않는 계획이 있습니다.

### Stage 2. Patch Plan

`docs/features/simple_patches/<work>/plan.md`를 작성합니다.

필수 내용:

- Patch goal
- Current baseline
- Non-goals
- Files/modules affected
- Compatibility promise
- Test plan
- Risks and rollback notes
- Follow-up candidates

큰 구조 변경이면 `tmp_execution_plan.md`도 작성합니다.

### Stage 3. Minimal Implementation

규칙:

- public API와 user-facing behavior를 유지하는 쪽을 우선합니다.
- 큰 리팩터를 한 번에 하지 말고, mechanical move와 behavior change를 분리합니다.
- schema, migration, generated file 변경은 정말 필요한 경우에만 포함합니다.
- 보안/권한 패치는 적용 전후 검증 쿼리나 테스트 기준을 문서화합니다.
- Supabase migration 적용이나 Edge Function 배포가 패치 검증에 필요하면 Stage 3 구현 중간에도 실행할 수 있습니다. 단, 해당 변경 batch에 대한 로컬/자동 검증이 완료된 이후에만 허용합니다. 적용 전에는 Stage 2의 계획과 검증 기준, 적용할 migration/배포할 함수 목록, 검증 결과를 확인합니다.
- Supabase 원격 DB/Edge Function 상태 확인이 필요하면 `docs/guides/development_process_guidelines.md`의 Remote Supabase Verification Rules와 `docs/supabase_cli_runbook.md`를 따릅니다. 필요한 경우 Supabase CLI로 원격 schema, migration 이력, function 상태, catalog, 제한된 운영 데이터를 확인할 수 있습니다.
- 테스트 보강 패치는 production 코드 변경 없이 실패/통과 기준을 명확히 고정합니다.

완료 기준:

- 변경 이유가 파일 단위로 설명 가능합니다.
- 예상한 compatibility promise가 유지됩니다.

### Stage 4. Verification

기본 명령:

```bash
flutter analyze
```

변경 범위에 따라 추가합니다.

| 변경 범위 | 추가 테스트 |
| --- | --- |
| DB/원장/snapshot/sync | `flutter test test/transaction_flow_test.dart` |
| UI component 구조 | `flutter test test/ui_component_smoke_test.dart` |
| 화면 진입 영향 | `flutter test test/page_walkthrough_test.dart` |
| 서비스 parsing/fallback | 관련 service test |
| 넓은 영향 범위 | `flutter test` |

Flutter/Dart 명령은 `development_process_guidelines.md`의 Flutter Tooling Rules를 그대로 따릅니다.

Supabase 관련 패치는 원격 적용/배포를 Stage 4까지 미루지 않아도 됩니다. 다만 구현 중간에 `supabase db push`나 `supabase functions deploy`를 실행하려면 해당 변경 batch의 검증이 먼저 완료되어야 합니다. 원격 상태 확인용 `supabase db query --linked`, `supabase migration list`, `supabase functions list`는 적용/배포 전후에 실행할 수 있으며, 결과와 잔여 리스크를 `test_report_YYYYMMDD.md`에 남깁니다.

### Stage 5. Report And Cleanup

`test_report_YYYYMMDD.md`에 실제 결과를 남깁니다.

필수 내용:

- Summary
- Commands run
- Command results
- Compatibility result
- Manual QA status
- Risk assessment
- Follow-up recommendations
- Final result

작업 완료 전 체크:

1. `tmp_execution_plan.md`가 있으면 삭제합니다.
2. `docs/README.md`와 `docs/features/simple_patches/README.md` 링크를 확인합니다.
3. `git diff --check`를 실행합니다.
4. `git status --short`로 변경 범위를 확인합니다.

## Classification Examples

| 작업 | 분류 이유 |
| --- | --- |
| Edge Function 인증 검증 강화 | 기존 API 보안 강화 |
| Supabase RLS/grant hardening | 운영 권한 정리 |
| 입력 validator 공통화 | 기존 입력 품질 강화 |
| CI/CD 최소 구성 | 개발 안정성 보강 |
| 원장 계산 회귀 테스트 추가 | 테스트 보강 |
| `app_database.dart` 모듈화 | 구조 개선 |

## Final Response Requirements

최종 응답에는 다음을 포함합니다.

- 변경 요약
- 주요 파일 링크
- 실행한 테스트와 결과
- 남은 리스크나 후속 분리 후보
- 임시 문서 삭제 여부
