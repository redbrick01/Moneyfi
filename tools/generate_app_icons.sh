#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SVG_PATH="$ROOT_DIR/assets/app_icon_flat.svg"
IOS_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES_DIR="$ROOT_DIR/android/app/src/main/res"
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

resize_png 1024 "$IOS_DIR/Icon-App-1024x1024@1x.png"
resize_png 20 "$IOS_DIR/Icon-App-20x20@1x.png"
resize_png 40 "$IOS_DIR/Icon-App-20x20@2x.png"
resize_png 60 "$IOS_DIR/Icon-App-20x20@3x.png"
resize_png 29 "$IOS_DIR/Icon-App-29x29@1x.png"
resize_png 58 "$IOS_DIR/Icon-App-29x29@2x.png"
resize_png 87 "$IOS_DIR/Icon-App-29x29@3x.png"
resize_png 40 "$IOS_DIR/Icon-App-40x40@1x.png"
resize_png 80 "$IOS_DIR/Icon-App-40x40@2x.png"
resize_png 120 "$IOS_DIR/Icon-App-40x40@3x.png"
resize_png 120 "$IOS_DIR/Icon-App-60x60@2x.png"
resize_png 180 "$IOS_DIR/Icon-App-60x60@3x.png"
resize_png 76 "$IOS_DIR/Icon-App-76x76@1x.png"
resize_png 152 "$IOS_DIR/Icon-App-76x76@2x.png"
resize_png 167 "$IOS_DIR/Icon-App-83.5x83.5@2x.png"

resize_png 48 "$ANDROID_RES_DIR/mipmap-mdpi/ic_launcher.png"
resize_png 72 "$ANDROID_RES_DIR/mipmap-hdpi/ic_launcher.png"
resize_png 96 "$ANDROID_RES_DIR/mipmap-xhdpi/ic_launcher.png"
resize_png 144 "$ANDROID_RES_DIR/mipmap-xxhdpi/ic_launcher.png"
resize_png 192 "$ANDROID_RES_DIR/mipmap-xxxhdpi/ic_launcher.png"

echo "App icons generated from $SVG_PATH"
