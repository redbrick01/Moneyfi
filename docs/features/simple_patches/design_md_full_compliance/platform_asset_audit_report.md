# Platform Asset Audit Report

작성일: 2026-05-29

## Scope

Stage 04 `P1-E Icons / Platform Assets` audit note.

이번 Stage 04에서는 platform asset 파일을 직접 수정하지 않았다. 현재 워크트리에 이미 존재하는 platform/asset 변경을 design-md 관점에서 review 대상으로 기록한다.

## Diff Review Command

```bash
git diff -- assets web ios android macos linux
```

현재 변경 파일:

- `android/app/src/main/AndroidManifest.xml`
- `assets/README.md`
- `assets/app_icon_flat.svg`
- `assets/icon/app_icon.svg`
- `ios/Runner/Info.plist`
- `linux/runner/my_application.cc`
- `macos/Runner/Configs/AppInfo.xcconfig`
- `web/index.html`
- `web/manifest.json`

## Checklist

| 영역 | 파일/위치 | 판정 | 메모 |
| --- | --- | --- | --- |
| source app icon | `assets/app_icon_flat.svg`, `assets/icon/app_icon.svg` | pending visual review | 현재 아이콘은 white canvas, `#EEF0F3`, `#0A0B0D`, `#05B169` 중심. Coinbase Blue가 app icon에 드러나지 않는 점은 brand strategy로 재검토 필요 |
| web manifest | `web/manifest.json`, `web/index.html`, `web/icons/**` | pending visual review | manifest theme color가 `#0052FF`, background가 white로 design-md와 정렬됨 |
| iOS | `ios/Runner/Assets.xcassets/**`, `ios/Runner/Info.plist` | pending visual review | display name이 `Moneyfy`로 정리됨. icon raster set은 source SVG와 실제 일치 여부 확인 필요 |
| Android | `android/app/src/main/**` | pending visual review | label이 `Moneyfy`로 정리됨. launcher raster set은 source SVG와 실제 일치 여부 확인 필요 |
| macOS | `macos/Runner/Assets.xcassets/**`, `macos/Runner/Configs/AppInfo.xcconfig` | pending visual review | product name이 `Moneyfy`로 정리됨. icon raster set 확인 필요 |
| Linux | `linux/runner/**` | pending visual review | runner background가 white로 정리됨 |

## Stage 04 Verdict

- Platform asset source 변경은 이번 Stage 04에서 수행하지 않음.
- 현재 변경은 design-md 방향과 대체로 정렬되어 보이나, generated raster icon과 source SVG 일치 여부는 별도 visual diff가 필요하다.
- 최종 pass는 Stage 05 screenshot/golden 또는 platform visual review 이후 확정한다.
