# 00 Baseline Audit Matrix

## 목표

Design-MD full compliance 작업의 기준을 고정하고, 모든 UI-bearing 화면과 주요 컴포넌트가 audit matrix에 배정되도록 만든다.

이 단계는 코드를 수정하지 않는다. 이후 단계가 같은 화면 상태와 같은 폭을 기준으로 판단할 수 있도록 route/state/screenshot 규칙을 먼저 확정한다.

## 대상

| 구분 | 대상 |
| --- | --- |
| 기준 문서 | `docs/design_system.md`, `docs/features/simple_patches/design_md_full_compliance/plan.md` |
| 기존 완료 근거 | `docs/features/simple_patches/design_token_unification/**` |
| 새 산출물 | `docs/features/simple_patches/design_md_full_compliance/audit_matrix.md` |
| screenshot root | `docs/features/simple_patches/design_md_full_compliance/screenshots/` |

## 구현 작업

1. `docs/design_system.md`의 Coinbase design-md 원칙을 모바일 앱 기준으로 요약한다.
2. `lib/pages/**/*.dart`, `lib/components/**`, `lib/widgets/**`, `lib/ui_scaffold/**` 중 UI-bearing 대상을 모두 audit matrix에 등록한다.
3. `lib/main.dart`, `lib/design_system/**`, `lib/theme/**`, `lib/components/separators/**`처럼 화면 baseline에 영향을 주는 source도 audit-only 또는 contract 대상으로 등록한다.
4. `assets/**`, `web/manifest.json`, iOS/Android/macOS visual resources는 Flutter token 치환 대상이 아니라 platform asset audit 대상으로 등록한다.
5. Non-UI 파일은 제외하되 화면 표시 문자열/숫자 포맷에 영향을 주는 formatter는 관련 화면 QA에 연결한다.
6. 각 화면별 route/state를 기록한다.
7. screenshot naming rule을 고정한다.
8. `statistics_page.dart`, company/market news cards, platform assets가 누락되지 않았는지 확인한다.

## Audit Matrix Schema

`audit_matrix.md`는 아래 필드를 가진 표로 작성한다.

| 필드 | 설명 |
| --- | --- |
| `screen` | 사람이 읽는 화면/컴포넌트 이름 |
| `file` | 대표 파일 경로 |
| `route/state` | 진입 route 또는 재현 상태 |
| `priority` | P0/P1/P2 |
| `widthDp` | 360/390/430 중 캡처 폭 |
| `textScale` | 1.0 또는 1.3 |
| `checklist` | color/type/spacing/card/row/button/chip/chart/icon/state 중 점검 항목 |
| `result` | `pending`, `pass`, `needs fix`, `exception` |
| `screenshotPath` | before/after screenshot 경로 |
| `exceptionReason` | 예외인 경우 사유 |
| `nextAction` | 수정 단계 또는 후속 파일 |
| `auditMode` | `screen`, `component`, `contract`, `asset`, `audit-only` 중 하나 |

## Screenshot 규칙

```text
docs/features/simple_patches/design_md_full_compliance/screenshots/
  before/{screen}_{state}_{width}dp.png
  after/{screen}_{state}_{width}dp.png
```

예시:

```text
screenshots/before/dashboard_data_390dp.png
screenshots/after/transactions_empty_360dp.png
```

## 필수 Coverage

| 우선순위 | 화면/컴포넌트 |
| --- | --- |
| P0 | app shell/navigation, dashboard, portfolio, transactions, detail pages, forms/sheets, shared button/card/row/chip/icon/state |
| P1 | statistics, news cards, analysis family, charts, auth, my page, sync overlay, icons, platform assets |
| P2 | guardrail, walkthrough, screenshot/golden candidates |

## Audit-Only Sources

아래 항목은 화면 compliance에 영향을 주지만 직접 화면 screenshot 대상이 아닐 수 있다.

| 구분 | 대상 | 처리 |
| --- | --- | --- |
| app bootstrap | `lib/main.dart` | theme/app shell 영향 확인 |
| design source | `lib/design_system/**` | token/typography/chart/icon contract 확인 |
| theme bridge | `lib/theme/**` | compatibility와 ColorScheme 연결 확인 |
| divider/separator | `lib/components/separators/**` | hairline depth contract 확인 |
| formatter | `lib/utils/display_currency.dart`, `lib/utils/number_formatters.dart`, `lib/components/formatters/number_format.dart` | 긴 숫자/문자열 overflow QA에 연결 |
| platform asset | `assets/**`, `web/manifest.json`, iOS/Android/macOS visual resources | platform asset audit report로 관리 |

## 검증

```bash
tools/check_design_token_guardrails.sh
rg -n "class .*Page|Widget build\\(" lib/pages lib/components lib/widgets --glob "*.dart"
```

## 완료 기준

- UI-bearing 화면과 주요 컴포넌트가 모두 matrix에 배정됨.
- audit-only visual sources가 `auditMode`와 함께 배정됨.
- 각 P0 화면은 route/state와 최소 캡처 폭 계획을 가진다.
- statistics/news/platform assets가 P1 대상으로 명시됨.
- screenshot 저장 규칙이 문서화됨.
