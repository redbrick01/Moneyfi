# Bug Fix Process Guidelines

이 문서는 MONEYFY에서 실행 실패, 깨진 화면, 잘못된 안내, 누락 파일, 외부 API 실패처럼 사용자가 겪을 수 있는 문제를 바로잡을 때 따르는 버그 픽스 프로세스입니다.

## When To Use

다음 중 하나에 해당하면 이 프로세스를 사용합니다.

- 앱 시작, 빌드, 로그인, 동기화, 화면 렌더링이 실패하는 문제
- 외부 API 실패로 화면이 비거나 깨지는 문제
- 사용자가 다음 행동을 알 수 없는 오류 UX
- 누락 파일, 잘못된 config, fallback 부재
- 계산/표시 값이 잘못되어 기존 기대 동작과 어긋나는 문제

새 사용자 기능을 만드는 경우에는 `development_process_guidelines.md`를 사용합니다. 기존 동작을 유지하며 품질만 높이는 구조/보안/테스트 변경이면 `simple_patch_process_guidelines.md`를 사용합니다.

## Document Location

버그 픽스 문서는 아래 경로에 저장합니다.

```text
docs/features/bug_fixes/<work>/
```

`<work>`는 snake_case를 사용합니다.

## Required Artifacts

| 문서 | 필수 여부 | 목적 |
| --- | --- | --- |
| `plan.md` | 필수 | 증상, 영향, 원인 가설, 수정 범위, 검증 계획 |
| `verification_test_plan.md` | 필수 | 재현/회귀 테스트와 수동 확인 기준 |
| `test_report_YYYYMMDD.md` | 필수 | 실제 재현 여부, 수정 후 결과, 잔여 리스크 |
| `tmp_investigation.md` | 선택 | 원인 탐색이 길거나 실패 시도가 많을 때 사용 후 정리 |
| `tmp_execution_plan.md` | 선택 | 수정 순서가 복잡할 때 사용 후 삭제 |

영구 문서를 추가하면 `docs/README.md`와 `docs/features/bug_fixes/README.md`에 링크를 추가합니다.

## Required Process

이 순서는 필수입니다. 구현이나 파일 수정은 Stage 1의 triage와 Stage 2의 `plan.md` 작성, 그리고 가능한 경우 Stage 3의 회귀 테스트/검증 기준 고정 이후에 진행합니다. `test_report_YYYYMMDD.md`는 테스트 실행 후 실제 결과를 기록하는 문서이며, 패치를 먼저 끝낸 뒤 계획서와 검증 계획을 사후 작성하는 방식은 허용하지 않습니다.

### Stage 1. Triage And Reproduction

목표: 문제를 정확히 식별하고 재현 가능성을 확인합니다.

작업:

1. 사용자 증상을 구체적인 입력, 화면, 명령, 날짜, 환경으로 정리합니다.
2. `git status --short`로 기존 미커밋 변경을 확인합니다.
3. 관련 코드와 테스트를 `rg` 또는 `rg --files`로 찾습니다.
4. 가능한 경우 실패를 재현하는 targeted test나 명령을 먼저 실행합니다.
5. 재현이 어려우면 코드 경로와 기존 로그/상태를 근거로 가설을 문서화합니다.

완료 기준:

- 증상, 영향 범위, 재현 여부가 분리되어 있습니다.
- 기존 실패인지 이번 요청 범위의 실패인지 구분됩니다.

### Stage 2. Fix Plan

`docs/features/bug_fixes/<work>/plan.md`를 작성합니다.

필수 내용:

- Bug summary
- User impact
- Reproduction or evidence
- Root cause hypothesis
- Fix strategy
- Non-goals
- Regression test plan
- Risk and rollback notes

원인 탐색이 길어지면 `tmp_investigation.md`를 사용하고, 결론은 영구 문서에 반영합니다.

### Stage 3. Regression Test First

가능하면 수정 전 실패하는 테스트를 먼저 추가하거나 기존 실패 명령을 고정합니다.

예외:

- 외부 API 장애나 원격 상태처럼 deterministic test 작성이 어려운 경우
- UI copy/fallback처럼 기존 테스트가 너무 무거운 경우
- config 누락처럼 환경 재현 비용이 큰 경우

예외인 경우에도 `verification_test_plan.md`에 수동 QA나 코드 경로 검증 기준을 남깁니다.

### Stage 4. Minimal Fix

규칙:

- 증상을 고치는 최소 변경을 우선합니다.
- 같은 파일의 unrelated refactor를 함께 하지 않습니다.
- fallback은 비어 있거나 깨진 화면 대신 명확한 상태, 캐시, 샘플, 재시도 안내 중 하나를 제공합니다.
- 에러 메시지는 사용자가 다음에 할 수 있는 행동을 포함해야 합니다.
- 외부 API/config/auth 문제는 secret이나 token을 문서에 남기지 않습니다.
- 계산 버그는 fixture와 기대값을 테스트로 고정합니다.

완료 기준:

- 재현 시나리오가 더 이상 실패하지 않습니다.
- 기존 정상 경로가 유지됩니다.

### Stage 5. Verification

기본 명령:

```bash
flutter analyze
```

변경 범위에 따라 추가합니다.

| 버그 범위 | 추가 테스트 |
| --- | --- |
| 로그인/동기화 UX | 관련 widget/service test, 필요 시 `flutter test test/sync_overlay_test.dart` |
| 외부 API fallback | 관련 service fallback test |
| config/startup | startup smoke/widget test |
| DB/원장/snapshot 계산 | `flutter test test/transaction_flow_test.dart` |
| 화면 깨짐 | `flutter test test/page_walkthrough_test.dart` 또는 관련 widget test |
| 넓은 영향 범위 | `flutter test` |

실패가 있으면 아래처럼 분류합니다.

- 재현된 버그가 아직 남음
- 수정 중 새 회귀 발생
- 테스트 기대값 노후화
- 환경/도구 문제
- 범위 밖 기존 실패

### Stage 6. Test Report And Cleanup

`test_report_YYYYMMDD.md`에 실제 결과를 남깁니다.

필수 내용:

- Summary
- Reproduction status
- Root cause
- Fix summary
- Commands run
- Command results
- Regression coverage
- Manual QA status
- Remaining risk
- Final result

작업 완료 전 체크:

1. 임시 문서의 결론을 영구 문서에 반영합니다.
2. `tmp_execution_plan.md`와 불필요한 `tmp_investigation.md`를 삭제합니다.
3. `docs/README.md`와 `docs/features/bug_fixes/README.md` 링크를 확인합니다.
4. `git diff --check`를 실행합니다.
5. `git status --short`로 변경 범위를 확인합니다.

## Classification Examples

| 작업 | 분류 이유 |
| --- | --- |
| 외부 API 실패 fallback 정리 | API 실패 시 화면이 비거나 깨지는 문제 방지 |
| 로그인/동기화 실패 UX 개선 | 실패 후 사용자 행동 안내 부족 수정 |
| `assets/config.json` 누락 대응 | 필수 asset 누락으로 시작 실패 가능성 제거 |

## Final Response Requirements

최종 응답에는 다음을 포함합니다.

- 고친 증상
- 원인 요약
- 변경 파일 링크
- 재현/회귀 테스트 결과
- 미수행 수동 QA 또는 남은 리스크
