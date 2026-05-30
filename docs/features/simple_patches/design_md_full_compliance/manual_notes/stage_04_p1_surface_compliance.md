# Stage 04 P1 Surface Compliance Report

작성일: 2026-05-29

## Scope

P1 surface 중 code-assisted 후보를 우선 처리했다.

이번 batch 대상:

- `P1-B News Cards`
- `P1-C Analysis / Charts`
- `P1-E Icons / Platform Assets` audit note

## Changed Files

- `lib/widgets/company_news_summary_card.dart`
- `lib/widgets/market_news_summary_card.dart`
- `lib/pages/portfolio_analysis_mvp_page.dart`
- `docs/features/simple_patches/design_md_full_compliance/audit_matrix.md`
- `docs/features/simple_patches/design_md_full_compliance/manual_notes/needs_fix_20260529.md`
- `docs/features/simple_patches/design_md_full_compliance/manual_notes/stage_04_p1_surface_compliance.md`
- `docs/features/simple_patches/design_md_full_compliance/platform_asset_audit_report.md`

## Changes

### News Importance Badges

Company/market news card의 중요도 pill 배경을 semantic/primary container에서 neutral surface로 통일했다.

유지한 것:

- 중요도 텍스트 색상: 높음 `negativeOn`, 보통 `warningOn`, 낮음 `primary`
- 제목 앞 dot 색상
- pill radius와 compact padding

바꾼 것:

- badge background: `neutralSurfaceBase`

의도:

- 중요도는 text/icon color로 전달하고, 배경은 Moneyfy design system의 restrained surface 문법을 따른다.

### Portfolio Diagnosis / Risk Badges

포트폴리오 진단 MVP에서 HHI/MDD level pill과 diagnosis hero 배경을 neutral surface로 통일했다.

유지한 것:

- status label
- status icon
- status text/accent color
- border color alpha

바꾼 것:

- HHI/MDD pill background: `neutralSurfaceBase`
- diagnosis hero background: `neutralSurfaceRaised`

의도:

- 위험/주의/양호 상태를 filled semantic card로 표현하지 않고, text/icon/border 중심으로 표현한다.

## Manual QA Note

PNG screenshot harness가 아직 없으므로 이번 batch는 manual QA note로 기록한다.

권장 후속 캡처:

| 화면 | 캡처 |
| --- | --- |
| Company news card | `screenshots/after/company_news_card_data_390dp.png` |
| Market news card | `screenshots/after/market_news_card_data_390dp.png` |
| Portfolio diagnosis MVP | `screenshots/after/portfolio_analysis_mvp_data_390dp.png` |
| Portfolio diagnosis overflow-risk | `screenshots/after/portfolio_analysis_mvp_data_360dp.png` |

확인할 항목:

- 뉴스 중요도 badge가 semantic filled chip처럼 보이지 않음.
- 중요도 dot/text color는 유지됨.
- diagnosis hero가 과도한 colored status card로 보이지 않음.
- 360dp에서 status label, long reason, metric values가 overflow되지 않음.

## Verification

```bash
dart format lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart
flutter analyze lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart
flutter test test/page_walkthrough_test.dart
tools/check_design_token_guardrails.sh
git diff -- assets web ios android macos linux
```

## Result

- `dart format lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart`: passed. Flutter SDK cache write가 필요해 권한 상승으로 실행.
- `flutter analyze lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart lib/pages/portfolio_analysis_mvp_page.dart`: passed, no issues.
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests.
- `tools/check_design_token_guardrails.sh`: clean.
- `git diff -- assets web ios android macos linux`: platform asset diff reviewed and recorded in `platform_asset_audit_report.md`.

## Remaining P1 Follow-Up

- Statistics page chart/table/legend screenshot 필요.
- Auth/my/sync overlay CTA hierarchy screenshot 필요.
- Platform asset audit은 diff review 기준으로 pass/exception을 확정해야 함.
