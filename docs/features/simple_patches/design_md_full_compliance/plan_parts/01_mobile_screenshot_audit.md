# 01 Mobile Screenshot Audit

## 목표

360/390/430dp 모바일 폭에서 before screenshot을 수집하고, 토큰 가드레일로 잡히지 않는 실제 화면 단위의 design-md 불일치를 식별한다.

## 대상

| 우선순위 | 대상 |
| --- | --- |
| P0 | shell, dashboard, portfolio, transactions, detail pages, forms/sheets, shared components가 노출되는 화면 |
| P1 | statistics, news cards, analysis family, auth/my/sync, charts/icons |

## 구현 작업

1. `audit_matrix.md`의 route/state 순서대로 화면에 진입한다.
2. 캡처 방식은 우선순위대로 선택한다: Flutter widget/integration test screenshot, in-app browser screenshot, 수동 simulator/device screenshot.
3. 캡처 방식, 실행 기기/도구, seed data 조건을 `audit_matrix.md`의 note 또는 별도 QA note에 기록한다.
4. 가능한 화면은 `data`, `empty`, `loading`, `error` 중 최소 1개 상태를 캡처한다.
5. P0 화면은 360/390/430dp 중 최소 2개 폭을 캡처한다.
6. 각 캡처별로 아래 checklist를 채운다.
7. `needs fix`는 파일/컴포넌트/현상/수정 후보까지 기록한다.

## Capture Reproducibility

| 항목 | 기록 기준 |
| --- | --- |
| 도구 | widget/integration test, in-app browser, iOS/Android simulator, macOS runner 등 |
| viewport | 360/390/430dp 중 실제 캡처 폭 |
| text scale | 1.0 또는 1.3 |
| seed data | 기존 local DB, test fixture, manual seed, empty state 등 |
| route/state | 탭/route/sheet/dialog/keyboard 상태까지 기록 |
| 실패 시 | screenshot 대신 manual QA note를 남기고 실패 사유와 재시도 조건 기록 |

## Checklist

| 항목 | Pass 기준 |
| --- | --- |
| Color | primary blue는 CTA/selected/link에 제한됨 |
| Semantic | positive/negative는 text/icon/chart mark 중심이며 filled background가 없음 |
| Typography | 금액/비율/수익률/tooltip 숫자가 number role 또는 tabular figure 사용 |
| Spacing | 360dp에서 card/row/button/chip이 겹치거나 잘리지 않음 |
| Radius | button/chip/search는 pill, input은 12dp, card는 contract 기준 유지 |
| Card | 불필요한 card-in-card 중첩 없음 |
| Row | 최소 44dp touch target, 주요 list row는 56dp 이상 |
| Button | primary/secondary/tertiary hierarchy가 명확함 |
| Chip | 선택/필터 chip이 pill이고 text overflow 없음 |
| Chart | legend/tooltip/grid/selected state가 overflow 없이 렌더링 |
| Icon | circular asset plate와 icon tap target이 유지됨 |
| State | empty/loading/error/retry가 같은 tone과 action hierarchy를 가짐 |

## 산출물

- `audit_matrix.md` 업데이트
- `screenshots/before/{screen}_{state}_{width}dp.png`
- `needs_fix` 목록

## 검증

```bash
tools/check_design_token_guardrails.sh
flutter test test/page_walkthrough_test.dart
```

## 완료 기준

- P0 화면별 before screenshot이 최소 2개 폭 이상 존재한다.
- P0 needs-fix 항목이 파일/컴포넌트 단위로 구체화된다.
- P1 누락 화면이 없고, screenshot 또는 manual QA note가 등록된다.
- 각 screenshot/manual note가 도구, viewport, text scale, seed data 조건을 가진다.
