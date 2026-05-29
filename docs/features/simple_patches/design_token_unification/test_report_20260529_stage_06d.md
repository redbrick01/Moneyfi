# Design Token Unification Test Report - Stage 06D

작성일: 2026-05-29

## Scope

Stage 06D brand/native/web asset consistency audit.

Changed files:

- `pubspec.yaml`
- `assets/README.md`
- `assets/icon/app_icon.svg`
- `tools/generate_app_icons.sh`
- `web/manifest.json`
- `web/index.html`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `macos/Runner/Configs/AppInfo.xcconfig`

Audited files/directories:

- `assets/app_icon_flat.svg`
- `assets/icon/**`
- `web/favicon.png`
- `web/icons/**`
- `ios/Runner/Assets.xcassets/**`
- `macos/Runner/Assets.xcassets/**`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `macos/Runner/Base.lproj/MainMenu.xib`
- `android/app/src/main/**`

## Changes

- Canonical app icon source를 `assets/app_icon_flat.svg`로 명시하고, `assets/icon/app_icon.svg`를 동일한 SVG로 맞췄습니다.
- `tools/generate_app_icons.sh`가 현재 프로젝트의 실제 web/iOS/macOS/Android icon 파일명으로 산출물을 쓰도록 정리했습니다.
- web manifest와 web index의 app name/title/description을 `Moneyfy` 기준으로 통일했습니다.
- web `theme_color`와 `background_color`를 Flutter seed color인 `#0066CC`로 맞췄습니다.
- Android app label, iOS `CFBundleName`, macOS `PRODUCT_NAME`을 `Moneyfy`로 통일했습니다.
- `pubspec.yaml` description을 Flutter template 문구에서 Moneyfy 설명으로 교체했습니다.

## Audit Findings

| Area | Result |
| --- | --- |
| Canonical SVG | `assets/app_icon_flat.svg` and `assets/icon/app_icon.svg` now match by SHA-256 |
| Web manifest | App name, short name, description, theme/background color aligned |
| Web icons | 192/512 and maskable 192/512 PNG files exist with expected dimensions |
| iOS app icons | Contents.json references existing PNG files with expected dimensions |
| macOS app icons | Contents.json references existing PNG files with expected dimensions |
| Android launcher icons | mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi PNG files exist with expected dimensions |
| Launch surfaces | iOS and Android still use default launch image/background patterns, no branded splash introduced |

## Verification

```bash
sh -n tools/generate_app_icons.sh
plutil -lint ios/Runner/Info.plist macos/Runner/Info.plist
rg -n "A new Flutter project|#0175C2|apple-mobile-web-app-title|<title>|android:label|CFBundleDisplayName|CFBundleName|PRODUCT_NAME|\"name\"|\"short_name\"|theme_color|background_color" pubspec.yaml web/manifest.json web/index.html android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist macos/Runner/Configs/AppInfo.xcconfig
shasum -a 256 assets/app_icon_flat.svg assets/icon/app_icon.svg
flutter analyze
```

Result:

- `sh -n tools/generate_app_icons.sh`: passed
- `plutil -lint`: passed
- brand metadata scan: template description and old `#0175C2` web color removed
- canonical SVG hash check: passed, both SVG files match
- `flutter analyze`: passed, no issues

## Manual QA Notes

No icon raster regeneration was run in this stage. Existing PNG dimensions were audited with `file`; visual screenshot QA was not performed.

## Remaining Risk

- Existing generated PNG assets may still reflect a previous icon render until `./tools/generate_app_icons.sh` is run intentionally.
- iOS AppIcon directory contains a few unreferenced duplicate PNG files from prior generations; they do not affect the active Contents mapping but can be cleaned in a later asset hygiene pass.
- Branded launch/splash artwork is still a separate design decision and was not introduced in this audit.
