# Bug Fix Process Guidelines

이 문서는 MONEYFY에서 실행 실패, 깨진 화면, 잘못된 안내, 누락 파일, 외부 API 실패처럼 사용자가 겪을 수 있는 문제를 바로잡을 때 따르는 버그 픽스 프로세스입니다.

## When To Use

- 앱 시작, 빌드, 로그인, 동기화, 화면 렌더링이 실패하는 문제
- 외부 API 실패로 화면이 비거나 깨지는 문제
- 사용자가 다음 행동을 알 수 없는 오류 UX
- 누락 파일, 잘못된 config, fallback 부재
- 계산/표시 값이 잘못되어 기존 기대 동작과 어긋나는 문제

새 사용자 기능을 만드는 경우에는 `development_process_guidelines.md`를 사용합니다. 기존 동작을 유지하며 품질만 높이는 구조/보안/테스트 변경이면 `simple_patch_process_guidelines.md`를 사용합니다.

## Documentation Policy

버그 픽스마다 개별 `plan.md`를 만들지 않습니다. 기본 기록 위치는 작업 이슈, PR 설명, 최종 응답입니다.

장기 보관이 필요한 내용만 아래 문서에 반영합니다.

| 내용 | 반영 위치 |
| --- | --- |
| 데이터/sync 계산 기준 | `docs/data_and_sync.md` |
| Supabase 운영/권한 기준 | `docs/supabase_overview.md`, `docs/supabase_cli_runbook.md` |
| UI/상태 표현 기준 | `docs/design_system.md` |
| 완료 작업 히스토리 | `docs/reports/implementation_history.md` |

## Required Process

### Stage 1. Triage And Reproduction

1. 사용자 증상을 구체적인 입력, 화면, 명령, 날짜, 환경으로 정리합니다.
2. `git status --short`로 기존 미커밋 변경을 확인합니다.
3. 관련 코드와 테스트를 `rg` 또는 `rg --files`로 찾습니다.
4. 가능한 경우 실패를 재현하는 targeted test나 명령을 먼저 실행합니다.
5. 재현이 어려우면 코드 경로와 기존 로그/상태를 근거로 가설을 정리합니다.

### Stage 2. Fix Plan

작업 전에 다음을 짧게 정리합니다.

- Bug summary
- User impact
- Reproduction or evidence
- Root cause hypothesis
- Fix strategy
- Non-goals
- Regression test plan
- Risk and rollback notes

### Stage 3. Regression Test First

가능하면 수정 전 실패하는 테스트를 먼저 추가하거나 기존 실패 명령을 고정합니다.

예외:

- 외부 API 장애나 원격 상태처럼 deterministic test 작성이 어려운 경우
- UI copy/fallback처럼 기존 테스트가 너무 무거운 경우
- config 누락처럼 환경 재현 비용이 큰 경우

예외인 경우에도 최종 응답이나 PR 설명에 수동 QA 기준을 남깁니다.

### Stage 4. Minimal Fix

- 증상을 고치는 최소 변경을 우선합니다.
- 같은 파일의 unrelated refactor를 함께 하지 않습니다.
- fallback은 비어 있거나 깨진 화면 대신 명확한 상태, 캐시, 샘플, 재시도 안내 중 하나를 제공합니다.
- 에러 메시지는 사용자가 다음에 할 수 있는 행동을 포함해야 합니다.
- 외부 API/config/auth 문제는 secret이나 token을 문서에 남기지 않습니다.
- 계산 버그는 fixture와 기대값을 테스트로 고정합니다.

### Stage 5. Verification

기본 명령:

```bash
flutter analyze
```

변경 범위에 따라 관련 targeted test 또는 `flutter test`를 추가합니다.

Supabase 관련 버그는 `docs/supabase_cli_runbook.md`를 따릅니다. 원격 확인 결과에는 비밀값과 개인 데이터를 남기지 않습니다.

### Stage 6. Cleanup

작업 완료 전 체크:

1. 현재 기준 문서에 남길 내용만 반영합니다.
2. 오래된 조사 메모나 계획서를 새 Markdown으로 남기지 않습니다.
3. `git diff --check`를 실행합니다.
4. `git status --short`로 변경 범위를 확인합니다.

## Final Response Requirements

최종 응답에는 다음을 포함합니다.

- 고친 증상
- 원인 요약
- 변경 파일 링크
- 재현/회귀 테스트 결과
- 미수행 수동 QA 또는 남은 리스크
