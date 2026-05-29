# Design-MD Full Compliance Plan Parts

작성일: 2026-05-29

이 디렉터리는 `docs/features/simple_patches/design_md_full_compliance/plan.md`의 단계별 세부 구현 계획을 분리한 문서 모음이다.

## 문서 목록

| 단계 | 문서 | 목적 |
| ---: | --- | --- |
| 0 | [00_baseline_audit_matrix.md](00_baseline_audit_matrix.md) | 기준 고정, audit matrix schema, route/state/screenshot 규칙 확정 |
| 1 | [01_mobile_screenshot_audit.md](01_mobile_screenshot_audit.md) | 모바일 폭별 before screenshot audit와 needs-fix 목록 작성 |
| 2 | [02_shared_component_contracts.md](02_shared_component_contracts.md) | button/card/row/chip/icon/state/scaffold contract 보강 |
| 3 | [03_p0_screen_compliance.md](03_p0_screen_compliance.md) | shell, dashboard, portfolio, transactions, detail, forms P0 화면 수정 |
| 4 | [04_p1_surface_compliance.md](04_p1_surface_compliance.md) | statistics, news, analysis/chart, auth/my/sync, icon/platform asset P1 정리 |
| 5 | [05_regression_automation.md](05_regression_automation.md) | guardrail hardening, screenshot/golden 후보, walkthrough 보강 |
| 6 | [06_screenshot_harness.md](06_screenshot_harness.md) | 모바일 viewport screenshot harness 구축 및 PNG artifact 생성 |
| 7 | [07_p0_visual_compliance.md](07_p0_visual_compliance.md) | screenshot 기반 P0 화면 visual compliance 수정 |
| 8 | [08_rich_data_p0_screenshots.md](08_rich_data_p0_screenshots.md) | DB seed 기반 loaded P0 화면 screenshot 기준선 구축 |
| 9 | [09_430dp_p0_screenshots.md](09_430dp_p0_screenshots.md) | 430dp 넓은 모바일 P0 screenshot 기준선 추가 |

## 운영 원칙

- 각 단계는 독립 batch로 실행한다.
- 한 batch는 가능하면 3-6개 파일로 제한한다.
- 기존 사용자 변경을 되돌리지 않는다.
- `design_token_unification`에서 완료된 토큰 치환을 반복하지 않고, 실제 모바일 화면 compliance gap만 다룬다.
- 단계별 완료 후 test report 또는 audit matrix 업데이트를 남긴다.
