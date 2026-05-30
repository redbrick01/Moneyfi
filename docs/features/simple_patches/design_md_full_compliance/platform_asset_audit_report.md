# Platform Asset Audit Report

작성일: 2026-05-29
최종 업데이트: 2026-05-30

## Scope

Stage 04 `P1-E Icons / Platform Assets` audit note.

2026-05-30 기준으로 잘못 식별된 앱 아이콘과 중복 launcher raster asset은 제거되었다. 플랫폼 에셋은 Flutter UI token 치환 대상이 아니므로, 남는 변경은 manifest/name/theme color drift 여부로 관리한다.

## Diff Review Command

```bash
git diff -- assets web ios android macos linux windows
```

아이콘 정리에서 변경된 주요 파일:

- `android/app/src/main/AndroidManifest.xml`
- `assets/README.md`
- `ios/Runner/Info.plist`
- `linux/runner/my_application.cc`
- `macos/Runner/Configs/AppInfo.xcconfig`
- `web/index.html`
- `web/manifest.json`
- `windows/runner/Runner.rc`
- deleted generated icon assets under `android`, `assets/icon`, `ios`, `macos`, `web/icons`, `windows`

## Checklist

| 영역 | 파일/위치 | 판정 | 메모 |
| --- | --- | --- | --- |
| source app icon | `assets/icon/**`, `assets/app_icon_flat.svg` | removed | 잘못 식별된 source icon과 duplicate icon source를 제거함 |
| web manifest | `web/manifest.json`, `web/index.html`, `web/icons/**` | updated | manifest theme color는 current primary `#3A6DFF`; deleted icon paths는 제거됨 |
| iOS | `ios/Runner/Assets.xcassets/**`, `ios/Runner/Info.plist` | cleaned | display name은 `Moneyfy`; 불필요한 AppIcon raster files 제거 |
| Android | `android/app/src/main/**` | cleaned | label은 `Moneyfy`; generated launcher raster files 제거, manifest icon reference 제거 |
| macOS | `macos/Runner/Assets.xcassets/**`, `macos/Runner/Configs/AppInfo.xcconfig` | cleaned | product name은 `Moneyfy`; duplicate AppIcon entries/files 제거 |
| Linux | `linux/runner/**` | aligned | runner background가 white로 정리됨 |
| Windows | `windows/runner/**` | cleaned | stale `.ico` resource와 rc icon block 제거 |

## Stage 04 Verdict

- Platform asset source는 현재 중복 보관하지 않는다.
- Web/native metadata는 `Moneyfy` name과 current primary `#3A6DFF` 중심으로 정렬한다.
- 새 launcher icon pipeline을 복구할 경우, source asset, generated outputs, manifest references를 한 단위로 문서화해야 한다.
