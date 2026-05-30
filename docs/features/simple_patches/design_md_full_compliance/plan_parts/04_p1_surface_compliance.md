# 04 P1 Surface Compliance

## 목표

P0 이후 브랜드 완성도와 분석 사용성에 영향을 주는 P1 surface를 정리한다.

대상은 statistics, news cards, analysis/chart, auth/my/sync, icon/platform assets다.

## 대상 화면과 파일

| Batch | 대상 파일 |
| --- | --- |
| P1-A Statistics | `lib/pages/statistics_page.dart` |
| P1-B News Cards | `lib/widgets/company_news_summary_card.dart`, `lib/widgets/market_news_summary_card.dart` |
| P1-C Analysis/Charts | `lib/pages/analysis_page.dart`, `lib/pages/annual_asset_analysis_page.dart`, `lib/pages/dividend_interest_analysis_page.dart`, `lib/pages/investment_performance_page.dart`, `lib/pages/portfolio_analysis_mvp_page.dart` |
| P1-D Auth/My/Sync | `lib/pages/login_page.dart`, `lib/pages/signup_page.dart`, `lib/pages/my_page.dart`, `lib/pages/sync_overlay.dart` |
| P1-E Icons/Assets | `lib/components/icons/**`, `assets/**`, `web/manifest.json`, iOS/macOS/Android visual resources |

## 구현 작업

### P1-A Statistics

- 기간/필터 chip의 selected state를 primary blue 또는 strong surface로 제한한다.
- summary metric은 dashboard/detail과 같은 number hierarchy를 따른다.
- chart/table 영역은 hairline과 soft surface 중심으로 정리한다.
- 긴 기간 라벨과 긴 금액이 360dp에서 overflow되지 않도록 한다.

### P1-B News Cards

- heading/source/date/body/link hierarchy를 정리한다.
- loading/error/retry 상태가 shared state tone과 맞는지 확인한다.
- primary blue는 link/action에만 사용한다.
- 긴 뉴스 제목과 한글 줄바꿈을 확인한다.

### P1-C Analysis / Charts

- chart palette, legend, tooltip, selected state를 `VisualSpec.chart` 기준으로 확인한다.
- number role을 chart tooltip, metric, table value까지 적용한다.
- semantic green/red background fill을 제거하거나 예외 문서화한다.
- chart geometry는 보수적으로 유지한다.

### P1-D Auth / My / Sync

- auth CTA hierarchy를 primary/secondary/tertiary로 정리한다.
- my page row/icon/destructive action color를 확인한다.
- sync overlay는 surface-dark/elevated card 문법으로 통일한다.
- progress indicator size와 stroke가 `VisualSpec.icon` 기준과 맞는지 확인한다.

### P1-E Icons / Platform Assets

- app icon, web manifest, native theme color가 Moneyfy primary `#3A6DFF`와 일관되는지 확인한다.
- asset glyph는 circular plate와 충분한 대비를 가진다.
- platform-generated asset은 Flutter UI token 치환 대상이 아니므로 diff/review note로 관리한다.

## Platform Asset Audit Checklist

| 영역 | 파일/위치 | 점검 |
| --- | --- | --- |
| source app icon | `assets/icon/**`, `assets/app_icon_flat.svg` | 현재 제거 상태 유지. 복구 시 primary color, foreground/background 대비, glyph radius 검증 |
| web manifest | `web/manifest.json`, `web/index.html`, `web/icons/**` | theme/background color, icon 경로 제거 상태, generated icon 색상 |
| iOS | `ios/Runner/Assets.xcassets/**`, `ios/Runner/Info.plist` | icon set, launch/theme 관련 색상 |
| Android | `android/app/src/main/**` | launcher icon, adaptive icon, manifest theme |
| macOS | `macos/Runner/Assets.xcassets/**`, `macos/Runner/Configs/AppInfo.xcconfig` | app icon, bundle display name 관련 visual metadata |
| other desktop | `linux/runner/**`, `web/**` | visual metadata drift 여부 |

## 산출물

- `statistics_news_compliance_report.md`
- `chart_compliance_report.md`
- `platform_asset_audit_report.md`
- `screenshots/after/{screen}_{state}_{width}dp.png`
- `audit_matrix.md` P1 result 업데이트

## 검증

```bash
flutter analyze lib/pages/statistics_page.dart lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart
flutter analyze lib/pages/analysis_page.dart lib/pages/annual_asset_analysis_page.dart lib/pages/dividend_interest_analysis_page.dart lib/pages/investment_performance_page.dart lib/pages/portfolio_analysis_mvp_page.dart
flutter analyze lib/pages/login_page.dart lib/pages/signup_page.dart lib/pages/my_page.dart lib/pages/sync_overlay.dart
flutter test test/page_walkthrough_test.dart
git diff -- assets web ios android macos linux
```

필요 시:

```bash
flutter test
```

## 완료 기준

- P1 audit 항목이 pass 또는 승인된 exception.
- chart가 모바일에서 빈 화면/overflow 없이 렌더링.
- statistics/news는 before/after screenshot 또는 수동 QA 메모를 보유.
- platform asset 변경 또는 유지 사유가 문서화됨.
- platform asset audit checklist의 각 영역이 pass 또는 exception 상태를 가진다.
