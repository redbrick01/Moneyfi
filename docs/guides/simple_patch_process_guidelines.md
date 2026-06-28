# Simple Patch Process Guidelines

이 문서는 MONEYFY에서 구조 개선, 보안/품질 강화, 테스트/CI 보강, 정책 정리처럼 기존 사용자 기능을 크게 바꾸지 않는 단순 패치를 진행할 때 따르는 규칙입니다.

## When To Use

- 코드 구조 분리, 모듈화, 네이밍 정리
- 인증, 권한, RLS, 입력 검증 같은 보안/품질 강화
- CI/CD, 테스트, 린트, 문서 인덱스 개선
- sync 충돌 정책, fallback 정책 같은 운영/계산 기준 정리
- 기존 기능의 동작은 유지하면서 안정성만 높이는 변경

사용자가 새 화면이나 새 기능을 체감하면 `development_process_guidelines.md`를 사용합니다. 실행 실패나 깨진 화면을 바로잡는 목적이면 `bug_fix_process_guidelines.md`를 사용합니다.

## Documentation Policy

단순 패치마다 개별 `plan.md`를 만들지 않습니다. 기본 기록 위치는 작업 이슈, PR 설명, 최종 응답입니다.

장기 보관이 필요한 내용만 아래 문서에 반영합니다.

| 내용 | 반영 위치 |
| --- | --- |
| 앱 구조/폴더 책임 | `docs/folder_guide.md` |
| 디자인/컴포넌트 기준 | `docs/design_system.md` |
| 데이터/sync 기준 | `docs/data_and_sync.md` |
| Supabase 운영 기준 | `docs/supabase_overview.md`, `docs/supabase_cli_runbook.md` |
| 완료 작업 히스토리 | `docs/reports/implementation_history.md` |

## Required Process

### Stage 1. Scope Check

1. `git status --short`로 기존 미커밋 변경을 확인합니다.
2. 관련 코드, 테스트, 문서를 `rg` 또는 `rg --files`로 찾습니다.
3. 변경이 사용자-facing 새 기능인지, 버그 픽스인지, 단순 패치인지 분류합니다.
4. DB, sync, auth, 원장, snapshot에 닿으면 관련 회귀 테스트 후보를 정합니다.

### Stage 2. Patch Plan

작업 전에 다음을 짧게 정리합니다.

- Patch goal
- Current baseline
- Non-goals
- Files/modules affected
- Compatibility promise
- Test plan
- Risks and rollback notes

여러 단계가 필요하면 작업 메모나 PR 본문에 체크리스트를 둡니다. 완료 후 별도 Markdown plan은 남기지 않습니다.

### Stage 3. Minimal Implementation

- public API와 user-facing behavior를 유지하는 쪽을 우선합니다.
- 큰 리팩터를 한 번에 하지 말고, mechanical move와 behavior change를 분리합니다.
- schema, migration, generated file 변경은 정말 필요한 경우에만 포함합니다.
- 보안/권한 패치는 적용 전후 검증 쿼리나 테스트 기준을 확인합니다.
- Supabase 원격 DB/Edge Function 상태 확인이 필요하면 `docs/supabase_cli_runbook.md`를 따릅니다.

### Stage 4. Verification

기본 명령:

```bash
flutter analyze
```

변경 범위에 따라 관련 targeted test 또는 `flutter test`를 추가합니다.

### Stage 5. Report And Cleanup

최종 응답이나 PR 설명에 실제 결과를 남깁니다.

포함할 내용:

- Summary
- Commands run
- Command results
- Compatibility result
- Manual QA status
- Risk assessment
- Follow-up recommendations

작업 완료 전 `git diff --check`와 `git status --short`로 변경 범위를 확인합니다.
