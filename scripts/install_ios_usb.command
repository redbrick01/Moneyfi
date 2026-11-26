#!/bin/bash
set -euo pipefail

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:$HOME/flutter/bin"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

finish() {
  if [[ -t 0 ]]; then
    read -r -p 'Enter 키를 누르면 창을 닫습니다... ' || true
  fi
}

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  printf '사용법: %s [기기-ID]\n' "${0##*/}"
  exit 0
fi
(( $# <= 1 )) || fail "사용법: ${0##*/} [기기-ID]"
trap finish EXIT

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

command -v flutter >/dev/null || fail 'Flutter를 찾을 수 없습니다. 설치 경로와 PATH를 확인하세요.'
xcrun --find xcodebuild >/dev/null || fail 'Xcode를 설치하고 활성 개발자 디렉터리를 확인하세요.'
[[ -f config.json ]] || fail 'config.json이 없습니다. config.example.json을 복사하고 로컬 설정을 입력하세요.'

echo 'USB로 연결된 iOS 기기를 찾는 중입니다...'
DEVICE_JSON="$(flutter devices --machine --device-connection=attached)" || fail 'Flutter에서 연결된 기기를 조회하지 못했습니다.'
DEVICE_ID="$(printf '%s\n' "$DEVICE_JSON" | /usr/bin/python3 -c '
import json
import sys

try:
    devices = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit("Flutter 기기 목록을 읽을 수 없습니다.")

attached = [device for device in devices
            if device["targetPlatform"] == "ios" and not device["emulator"]
            and device["isSupported"]]
if not attached:
    sys.exit("USB로 연결된 iOS 기기가 없습니다. 아이폰 잠금을 풀고 이 컴퓨터를 신뢰한 뒤 개발자 모드를 확인하세요.")

requested = sys.argv[1]
if requested:
    for device in attached:
        if device["id"] == requested:
            print(requested)
            sys.exit(0)
elif len(attached) == 1:
    print(attached[0]["id"])
    sys.exit(0)

print("아래 USB 기기 중 하나의 ID를 인수로 지정하세요.", file=sys.stderr)
for device in attached:
    print("  {} ({})".format(device["name"], device["id"]), file=sys.stderr)
sys.exit(1)
' "${1:-}")"

echo 'Moneyfy iOS 릴리스 앱을 빌드하고 설치합니다...'
flutter run --release --no-resident --device-connection=attached \
  -d "$DEVICE_ID" --dart-define-from-file=config.json
echo 'Moneyfy 설치가 완료되었습니다.'
