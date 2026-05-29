# 05 Regression Automation

## 목표

Design-MD full compliance가 일회성 정리가 되지 않도록 guardrail, walkthrough, screenshot/golden 후보를 보강한다.

## 대상

| 영역 | 대상 |
| --- | --- |
| Guardrail | `tools/check_design_token_guardrails.sh`, `.github/workflows/flutter-ci.yml` |
| Tests | `test/ui_component_smoke_test.dart`, `test/page_walkthrough_test.dart` |
| Docs | `verification_test_plan.md`, `audit_matrix.md`, batch reports |

## 구현 작업

1. 현재 reporting-only guardrail allowlist를 검토한다.
2. direct color/font/spacing/radius legacy pattern이 새로 추가될 때 탐지되는지 확인한다.
3. blocking 전환 가능성을 문서화하되, 팀 합의 전에는 reporting-only 정책을 유지한다.
4. guardrail self-test 전략을 정한다. 기본은 임시 fixture 파일을 만들지 않는 script-level dry-run 또는 샘플 문자열 검사이며, repo 파일을 오염시키지 않는다.
5. P0 핵심 화면을 screenshot/golden 후보로 선정한다.
6. `page_walkthrough_test.dart`가 design-md 핵심 화면을 안정적으로 방문하는지 보강한다.
7. QA 재현 절차를 `verification_test_plan.md`로 정리한다.

## Screenshot / Golden 후보

| 우선순위 | 후보 |
| --- | --- |
| 1 | dashboard data state 390dp |
| 2 | transactions data/empty state 390dp |
| 3 | dashboard or transactions overflow-risk state 360dp |
| 4 | asset or holding detail 390dp |
| 5 | transaction form keyboard-safe state 360dp |
| 6 | statistics or analysis chart 390dp |

## Screenshot Strategy

- 390dp는 기본 smoke 기준으로 사용한다.
- 360dp는 overflow-risk 화면에 필수로 포함한다.
- 430dp는 넓은 모바일에서 과도한 whitespace나 card width 문제가 있는 화면의 보조 기준으로 사용한다.
- golden test 도입 전에는 screenshot 후보와 manual QA note만으로 시작할 수 있다.

## Guardrail 강화 기준

- `MoneyfyPalette`, `MoneyfySpacing` page-level 사용은 fail 후보.
- direct `Color(0x...)`, `Colors.*`, direct `fontSize:`는 design system/theme 외부에서 fail 후보.
- chart geometry, platform asset, Flutter-required intrinsic value는 allowlist 또는 exception note.
- blocking 전환 전 최소 1회 CI reporting-only 기간을 둔다.

## Guardrail Self-Test Strategy

- 우선 `tools/check_design_token_guardrails.sh`에 dry-run/self-test 모드를 둘 수 있는지 검토한다.
- self-test가 어렵다면 CI 변경 없이 로컬에서 샘플 문자열 매칭 로직을 별도 report로 검증한다.
- 실제 repo source에 legacy pattern을 임시 삽입하는 방식은 사용하지 않는다.
- self-test 결과는 `verification_test_plan.md` 또는 guardrail hardening proposal에 기록한다.

## 산출물

- `docs/features/simple_patches/design_md_full_compliance/verification_test_plan.md`
- CI guardrail hardening proposal
- screenshot/golden 후보 목록
- walkthrough 보강 report
- guardrail self-test note

## 검증

```bash
tools/check_design_token_guardrails.sh
flutter test test/ui_component_smoke_test.dart
flutter test test/page_walkthrough_test.dart
flutter test
```

CI 변경 시:

```bash
git diff -- .github/workflows/flutter-ci.yml tools/check_design_token_guardrails.sh
```

## 완료 기준

- 신규 legacy pattern 추가가 로컬 guardrail에서 탐지된다.
- P0 핵심 화면이 자동 또는 반자동 screenshot 비교 후보에 등록된다.
- 360dp overflow-risk 후보가 최소 1개 이상 포함된다.
- walkthrough test가 design-md 핵심 화면을 포함한다.
- verification plan이 batch별 실행 명령과 수동 QA 기준을 가진다.
