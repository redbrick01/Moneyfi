# Development Process Guidelines

이 문서는 MONEYFY에서 기능을 설계, 구현, 검증할 때 따르는 개발 프로세스 규칙입니다.

## Goals

- 기능 개발 전에 목적, 범위, 위험을 명확히 합니다.
- 계산, 데이터, UI 변경을 테스트로 고정합니다.
- 오래 유지해야 하는 지식은 canonical docs에 반영합니다.
- 완료된 작업 계획은 개별 Markdown으로 남기지 않고 필요할 때 `docs/reports/implementation_history.md`에 짧게 요약합니다.

## When To Use

다음 중 하나에 해당하면 이 프로세스를 사용합니다.

- 새 사용자 기능을 추가할 때
- 기존 핵심 화면을 제품급으로 고도화할 때
- DB, 원장, sync, snapshot, market data처럼 계산 신뢰도가 중요한 영역을 바꿀 때
- 여러 파일과 테스트를 함께 수정해야 할 때
- 후속 QA나 릴리스 판단이 필요한 변경일 때

단순 문구 수정, 작은 스타일 수정, 명확한 버그 1건 수정에는 전체 프로세스를 생략할 수 있습니다. 다만 테스트와 변경 요약은 남깁니다.

## Documentation Policy

| 문서 유형 | 위치 | 기준 |
| --- | --- | --- |
| Current product/architecture knowledge | `docs/project_overview.md`, `docs/folder_guide.md`, domain docs | 계속 읽어야 하는 기준만 반영 |
| Data and sync behavior | `docs/data_and_sync.md` | Drift DB, 원장, Supabase sync 기준 |
| Supabase operation | `docs/supabase_overview.md`, `docs/supabase_cli_runbook.md` | migration, Edge Functions, 운영 절차 |
| UI/design behavior | `docs/design_system.md` | 화면 패턴, 토큰, 컴포넌트 기준 |
| Completed implementation history | `docs/reports/implementation_history.md` | 오래된 계획/스펙의 압축 색인 |

개별 feature plan, temporary execution plan, verification report는 장기 보관하지 않습니다. 구현 완료 후 현재 기준 문서에 필요한 내용만 반영하고, 히스토리 가치가 있으면 `docs/reports/implementation_history.md`에 1-3줄로 남깁니다.

## Required Process

### Stage 1. Discovery

1. `README.md`, `docs/README.md`, 관련 canonical docs를 확인합니다.
2. 관련 화면, service, DB, test 파일을 찾습니다.
3. 기존 테스트와 현재 git 상태를 확인합니다.
4. 변경 전 baseline test가 필요한지 판단합니다.

완료 기준:

- 기존 구현과 변경 지점이 파악됩니다.
- 영향을 받을 파일과 테스트 후보가 정리됩니다.

### Stage 2. Plan The Change

작업 전 다음을 짧게 정리합니다. 문서 파일이 꼭 필요한 경우에만 생성하고, 기본은 이슈/PR/작업 메모에 남깁니다.

- Product goal
- Current baseline
- Success criteria
- Data/API changes
- MVP scope
- Test plan
- Risks and decisions
- Open questions

장기 기준으로 남아야 하는 내용은 해당 canonical doc에 바로 반영합니다.

### Stage 3. Staged Implementation

권장 순서:

1. Baseline check
2. Calculation/data contract tests
3. Data/API changes
4. Screen state/data loading changes
5. UI changes
6. Targeted tests
7. Full verification
8. Cleanup

규칙:

- 계산 로직은 UI보다 먼저 테스트로 고정합니다.
- 기존 호출부와 호환되는 API 변경을 우선합니다.
- DB schema 변경이 필요하면 migration, sync, generated file 영향을 함께 봅니다.
- Supabase migration 적용이나 Edge Function 배포는 로컬/자동 검증이 완료된 batch에 한해 실행합니다.
- UI는 기존 design system과 component를 우선 사용합니다.
- 큰 리팩터는 기능 목표와 직접 관련된 경우에만 수행합니다.

### Stage 4. Verification

기본 명령:

```bash
flutter analyze
flutter test
```

변경 범위가 좁으면 관련 targeted test를 먼저 실행하고, 넓은 영향 범위에서는 전체 테스트를 실행합니다.

Supabase 관련 작업은 `docs/supabase_cli_runbook.md`를 따릅니다. 원격 데이터나 권한을 확인할 때는 비밀값과 개인 데이터를 문서에 남기지 않습니다.

### Stage 5. Cleanup

작업 완료 전 체크:

1. 임시 메모나 작업 계획에서 canonical docs에 남길 내용만 이동합니다.
2. 오래된 계획/스펙을 새 파일로 남기지 않습니다.
3. `git diff --check`를 실행합니다.
4. `git status --short`로 변경 범위를 확인합니다.

## Final Response Requirements

최종 응답에는 다음을 포함합니다.

- 변경 요약
- 주요 파일 링크
- 실행한 테스트와 결과
- 남은 리스크나 후속 분리 후보
