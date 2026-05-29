# Design Token Unification Test Report - Stage 03A

작성일: 2026-05-29

## Scope

Stage 03A 뉴스 요약 카드 토큰화.

Changed files:

- `lib/widgets/company_news_summary_card.dart`
- `lib/widgets/market_news_summary_card.dart`

## Changes

- `MoneyfyPalette` 의존을 제거하고 `context.colors`, `context.surfaces` 기반 semantic token으로 교체했습니다.
- 직접 `fontSize` 사용을 제거하고 `context.typography` role을 사용했습니다.
- 직접 spacing, padding, pill radius, expand animation duration을 `context.spacing`, `context.radius`, `context.motion`, `VisualSpec` 기반으로 교체했습니다.
- 중요도 badge 색상은 `negative`, `warning`, `primary`, `neutral` semantic role로 매핑했습니다.
- 뉴스 데이터 파싱, 정렬, expand/collapse 동작, 문구는 변경하지 않았습니다.

## Legacy Pattern Delta

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart --count-matches
```

Before: `122`

After: `62`

Notes:

- `MoneyfyPalette`, direct hex color, direct `fontSize`는 두 파일에서 제거했습니다.
- 남은 match는 대부분 `SizedBox`, `EdgeInsets`, `BorderRadius.circular`가 `context.spacing`, `context.radius`, `VisualSpec` 기반으로 사용되는 항목입니다.

## Verification

```bash
dart format lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart
flutter analyze lib/widgets/company_news_summary_card.dart lib/widgets/market_news_summary_card.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
```

Result:

- `dart format`: passed, 2 files formatted
- `flutter analyze`: passed, no issues
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests

## Manual QA Notes

Automated walkthrough and smoke coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- 중요도 badge의 색상은 기존 `MoneyfyPalette` 값에서 design system semantic role로 바뀌어 미세한 색감 차이가 있을 수 있습니다.
- 뉴스 카드가 실제 데이터로 expanded 상태에서 보일 때 긴 제목/요약이 많은 경우 수동 화면 QA가 추가로 필요합니다.
- Stage 03B의 `analysis_page.dart` entry 영역은 아직 후속 작업으로 남아 있습니다.
