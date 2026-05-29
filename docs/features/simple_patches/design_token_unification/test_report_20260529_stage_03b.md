# Design Token Unification Test Report - Stage 03B

작성일: 2026-05-29

## Scope

Stage 03B `analysis_page.dart` 분석 entry 영역 토큰화.

Changed files:

- `lib/pages/analysis_page.dart`

## Changes

- `_AnalysisEntryCard` icon box size를 직접 `36`에서 `VisualSpec.icon.badgeBox`로 교체했습니다.
- `_AnalysisEntryCard` leading icon을 raw `Icon`에서 `AppIcon.raw`로 교체했습니다.
- `_AnalysisEntryCard` trailing chevron을 raw `Icon(Icons.chevron_right_rounded)`에서 `AppIcon(AppIconName.chevronRight)`로 교체했습니다.
- 분석 entry navigation, 뉴스 카드 연결, snapshot/calendar/monthly closing 영역은 변경하지 않았습니다.

## Scope Boundary

이번 batch는 상단 분석 entry 카드만 다룹니다.

`SnapshotCalendarCard`, `YearlyAssetAnalysisCard`, `MonthlyClosingAssetsCard`에 남은 `MoneyfyPalette`와 직접 layout 수치는 Stage 04 Analysis Page Family에서 처리합니다.

## Legacy Pattern Delta

Audit command:

```bash
rg -n "MoneyfyPalette|MoneyfySpacing|Color\\(0x|Colors\\.|fontSize:|EdgeInsets\\.|SizedBox\\(|BorderRadius\\.circular\\(" lib/pages/analysis_page.dart --count-matches
```

Before: `58`

After: `58`

Notes:

- count는 동일하지만, Stage 03B 범위의 직접 icon size/raw icon 사용을 공용 icon token 경로로 옮겼습니다.
- 잔여 legacy pattern은 Stage 04 대상인 calendar/monthly closing analysis 영역에 집중되어 있습니다.

## Verification

```bash
dart format lib/pages/analysis_page.dart
flutter analyze lib/pages/analysis_page.dart
flutter test test/page_walkthrough_test.dart
flutter test test/ui_component_smoke_test.dart
```

Result:

- `dart format`: passed, 1 file formatted, 0 changed
- `flutter analyze`: passed, no issues
- `flutter test test/page_walkthrough_test.dart`: passed, 24 tests
- `flutter test test/ui_component_smoke_test.dart`: passed, 7 tests

## Manual QA Notes

Automated walkthrough and smoke coverage passed. 별도 screenshot/manual QA는 수행하지 않았습니다.

## Remaining Risk

- Stage 04에서 `analysis_page.dart` 하단 calendar/monthly closing 영역을 정리할 때 같은 파일을 다시 수정하게 됩니다.
