#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SVG_PATH="$ROOT_DIR/assets/app_icon_flat.svg"
ICON_ASSET_DIR="$ROOT_DIR/assets/icon"
IOS_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
MACOS_DIR="$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES_DIR="$ROOT_DIR/android/app/src/main/res"
WEB_DIR="$ROOT_DIR/web"
TMP_DIR="${TMPDIR:-/tmp}/moneyfy_app_icon"
MASTER_PNG="$TMP_DIR/Icon-App-1024x1024@1x.png"

if [ ! -f "$SVG_PATH" ]; then
  echo "Missing SVG source: $SVG_PATH" >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "sips is required but not found." >&2
  exit 1
fi

mkdir -p "$TMP_DIR"
rm -f "$TMP_DIR"/* 2>/dev/null || true

render_svg() {
  if command -v qlmanage >/dev/null 2>&1; then
    qlmanage -t -s 1024 -o "$TMP_DIR" "$SVG_PATH" >/dev/null 2>&1 || true
    if [ -f "$TMP_DIR/app_icon_flat.svg.png" ]; then
      mv "$TMP_DIR/app_icon_flat.svg.png" "$MASTER_PNG"
      return 0
    fi
  fi

  if sips -s format png "$SVG_PATH" --out "$MASTER_PNG" >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

if ! render_svg; then
  echo "Failed to rasterize SVG. Run on macOS with Quick Look enabled or install another SVG renderer." >&2
  exit 1
fi

resize_png() {
  size="$1"
  output="$2"
  mkdir -p "$(dirname "$output")"
  sips -z "$size" "$size" "$MASTER_PNG" --out "$output" >/dev/null
}

mkdir -p "$ICON_ASSET_DIR"
cp "$SVG_PATH" "$ICON_ASSET_DIR/app_icon.svg"
resize_png 1024 "$ICON_ASSET_DIR/app_icon_1024.png"

resize_png 20 "$IOS_DIR/iPhone_20_20.png"
resize_png 29 "$IOS_DIR/iPhone_29_29.png"
resize_png 40 "$IOS_DIR/iPhone_40_40.png"
resize_png 58 "$IOS_DIR/iPhone_58_58.png"
resize_png 60 "$IOS_DIR/iPhone_60_60.png"
resize_png 76 "$IOS_DIR/iPad_76_76.png"
resize_png 80 "$IOS_DIR/iPhone_80_80.png"
resize_png 87 "$IOS_DIR/iPhone_87_87.png"
resize_png 120 "$IOS_DIR/iPhone_120_120.png"
resize_png 152 "$IOS_DIR/iPad_152_152.png"
resize_png 167 "$IOS_DIR/iPad_167_167.png"
resize_png 180 "$IOS_DIR/iPhone_180_180.png"
resize_png 180 "$IOS_DIR/iPhone_180x180.png"
resize_png 1024 "$IOS_DIR/AppStore_1024_1024.png"
resize_png 1024 "$IOS_DIR/AppStore_1024x1024.png"

resize_png 16 "$MACOS_DIR/app_icon_16.png"
resize_png 32 "$MACOS_DIR/app_icon_32.png"
resize_png 64 "$MACOS_DIR/app_icon_64.png"
resize_png 128 "$MACOS_DIR/app_icon_128.png"
resize_png 256 "$MACOS_DIR/app_icon_256.png"
resize_png 512 "$MACOS_DIR/app_icon_512.png"
resize_png 1024 "$MACOS_DIR/app_icon_1024.png"

resize_png 16 "$WEB_DIR/favicon.png"
resize_png 192 "$WEB_DIR/icons/Icon-192.png"
resize_png 512 "$WEB_DIR/icons/Icon-512.png"
resize_png 192 "$WEB_DIR/icons/Icon-maskable-192.png"
resize_png 512 "$WEB_DIR/icons/Icon-maskable-512.png"

resize_png 48 "$ANDROID_RES_DIR/mipmap-mdpi/ic_launcher.png"
resize_png 72 "$ANDROID_RES_DIR/mipmap-hdpi/ic_launcher.png"
resize_png 96 "$ANDROID_RES_DIR/mipmap-xhdpi/ic_launcher.png"
resize_png 144 "$ANDROID_RES_DIR/mipmap-xxhdpi/ic_launcher.png"
resize_png 192 "$ANDROID_RES_DIR/mipmap-xxxhdpi/ic_launcher.png"

echo "App icons generated from $SVG_PATH"
