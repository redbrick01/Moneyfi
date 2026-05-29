# Stage 05 Regression Automation Report

작성일: 2026-05-29

## Scope

Design-MD full compliance 회귀 방지 체계를 정리했다.

대상:

- `tools/check_design_token_guardrails.sh`
- `.github/workflows/flutter-ci.yml`
- `test/ui_component_smoke_test.dart`
- `test/page_walkthrough_test.dart`
- design-md full compliance docs

## Changes

### Guardrail Self-Test

`tools/check_design_token_guardrails.sh --self-test`를 추가했다.

특징:

- repo source에 임시 legacy pattern을 삽입하지 않는다.
- shell sample string을 `rg`에 전달해 패턴 탐지를 검증한다.
- legacy palette, spacing, helper, direct color, direct `Colors.*`, direct `fontSize`를 확인한다.
- tokenized spacing sample은 ignore되는지 확인한다.

### Verification Plan

`verification_test_plan.md`를 추가했다.

포함 내용:

- 항상 실행할 guardrail/test 명령
- batch-specific analyze 기준
- broad `flutter test` 기준
- reporting-only guardrail 정책
- screenshot/golden 후보
- manual QA note 필수 필드
- current walkthrough coverage와 missing visual coverage

### Screenshot / Golden Candidates

P0/P1 후보를 등록했다.

핵심:

- 390dp는 smoke 기준.
- 360dp는 overflow-risk 기준.
- transaction form keyboard-safe state를 360dp 후보로 등록.
- statistics/news/portfolio diagnosis는 P1 visual candidate로 등록.

## CI Policy

현재 `.github/workflows/flutter-ci.yml`은 design token guardrail을 reporting-only로 실행한다.

```yaml
- name: Design token guardrail report
  continue-on-error: true
  run: tools/check_design_token_guardrails.sh
```

이번 Stage 05에서는 CI를 blocking으로 바꾸지 않았다.

권장 후속:

1. CI에 `tools/check_design_token_guardrails.sh --self-test` reporting-only step 추가.
2. 최소 1회 reporting-only 기간 후 blocking 전환 여부 검토.
3. screenshot harness가 준비되면 P0 후보부터 golden 또는 artifact screenshot으로 연결.

## Verification

```bash
tools/check_design_token_guardrails.sh
tools/check_design_token_guardrails.sh --self-test
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

## Result

- `tools/check_design_token_guardrails.sh`: passed, clean.
- `tools/check_design_token_guardrails.sh --self-test`: passed.
  - legacy palette: detected.
  - legacy spacing: detected.
  - legacy helper: detected.
  - direct `Color(...)`: detected.
  - direct `Colors.*`: detected.
  - direct `fontSize`: detected.
  - tokenized spacing sample: ignored.
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `flutter test`: passed, 193 tests.

판정:

- Stage 05 regression automation baseline은 pass.
- Guardrail은 여전히 reporting-only 정책이다.
- Visual screenshot/golden coverage는 아직 pending이며 후속 harness 구현 대상이다.

## Remaining Work

- PNG screenshot harness 구현.
- 360/390/430dp forced viewport capture.
- text scale 1.3 visual capture.
- platform generated icon visual diff.
- CI self-test step 추가 여부 결정.
