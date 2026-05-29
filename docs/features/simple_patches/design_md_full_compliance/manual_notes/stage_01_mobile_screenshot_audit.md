# Stage 01 Mobile Screenshot Audit Note

작성일: 2026-05-29

## Scope

`01_mobile_screenshot_audit.md`의 실행 결과를 기록한다.

현재 repo에는 실제 PNG screenshot을 저장하는 golden/screenshot harness가 없다. 따라서 이번 단계에서는 다음을 수행했다.

- route/state 재현 조건 확인
- smoke test 기반 화면 진입 검증
- before screenshot 경로 예약
- screenshot 미생성 사유와 후속 캡처 전략 기록
- code-assisted visual risk 후보 도출

## Capture Method

| 항목 | 값 |
| --- | --- |
| 도구 | `flutter test test/page_walkthrough_test.dart` |
| 역할 | 화면 진입 smoke 검증. PNG screenshot 저장 기능은 없음 |
| viewport | Flutter test 기본 surface. 360/390/430dp 강제 캡처는 미수행 |
| text scale | 앱 전역 `MoneyfyApp`은 `TextScaler.linear(0.94)` 적용. 별도 1.3 캡처는 미수행 |
| seed data | `page_walkthrough_test.dart`의 `_walkthroughIds`와 page별 first-frame fixture |
| screenshot status | PNG 미생성. `screenshots/before/` 경로는 예약됨 |
| manual QA status | 이 문서와 `needs_fix_20260529.md`로 대체 기록 |

## Verification Run

```bash
tools/check_design_token_guardrails.sh
flutter test test/page_walkthrough_test.dart
```

결과:

- `tools/check_design_token_guardrails.sh`: clean.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.

## Route / State Coverage Confirmed By Smoke Test

| Matrix 대상 | 확인 수준 | 비고 |
| --- | --- | --- |
| App shell / bottom tabs | smoke pass | `홈`, `포트폴`, `거래`, `분석`, `통계`, `My` 탭 방문 |
| Analysis hub | smoke pass | entry cards tap 확인 |
| Portfolio diagnosis MVP | smoke pass | analysis entry에서 진입 |
| Investment performance | smoke pass | advanced metrics text 확인 |
| Dividend/interest analysis | smoke pass | analysis entry에서 진입 |
| Annual asset analysis | first-frame pass | fixture snapshot 사용 |
| Transactions | smoke pass | page build, pull refresh, grouping test |
| Asset detail | first-frame pass | fixture id 사용 |
| Holding detail | first-frame pass | fixture id 사용 |
| Cash account detail | first-frame pass | fixture id 사용 |
| Snapshot detail | first-frame pass | fixture snapshot 사용 |
| Asset form | first-frame pass | standalone build |
| Holding form | first-frame pass | fixture id 사용 |
| Cash account form | first-frame pass | fixture id 사용 |
| Transaction form | smoke pass | market item search, calculation switch 확인 |
| Cash transaction form | smoke pass | calculation switch 확인 |
| Login / Signup | first-frame pass | standalone build |

## Screenshot Capture Gap

Stage 01의 원래 목표인 360/390/430dp PNG before screenshot은 아직 완료되지 않았다.

후속 조치:

1. Stage 05에서 screenshot/golden 후보를 확정한다.
2. P0 화면부터 390dp smoke screenshot과 360dp overflow-risk screenshot을 생성할 harness를 추가한다.
3. harness가 준비되기 전 P0/P1 수정 batch는 manual QA note를 필수 산출물로 남긴다.

## Initial Audit Result

이번 단계의 판정은 `pass`가 아니라 `pending with notes`다. 화면 진입 smoke는 통과했지만, design-md full compliance의 시각 판정은 실제 screenshot 또는 manual QA 캡처가 필요하다.

다음 문서를 함께 사용한다.

- `docs/features/simple_patches/design_md_full_compliance/audit_matrix.md`
- `docs/features/simple_patches/design_md_full_compliance/manual_notes/needs_fix_20260529.md`
