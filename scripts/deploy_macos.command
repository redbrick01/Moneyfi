#!/bin/bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/flutter/bin:$PATH"

finish() {
  result=${1:-$?}
  if (( result != 0 )); then
    echo
    echo "배포에 실패했습니다. 위의 오류를 확인하세요. (종료 코드: $result)"
  fi
  if [[ -t 0 ]]; then read -r -p "Enter 키를 누르면 창을 닫습니다..."; fi
}
trap finish EXIT

if ! command -v flutter >/dev/null; then
  echo "Flutter를 찾을 수 없습니다. Flutter 설치와 PATH를 확인하세요."
  exit 1
fi
if [[ ! -f config.json ]]; then
  echo "config.json이 없습니다. config.example.json을 복사하고 KIS 키를 입력하세요."
  exit 1
fi
if ! /usr/bin/python3 -c 'import json, sys
try:
    with open("config.json", encoding="utf-8") as f: config = json.load(f)
    missing = [k for k in ("KIS_APP_KEY", "KIS_APP_SECRET") if not isinstance(config.get(k), str) or not config[k].strip() or config[k].startswith("YOUR_")]
    if missing: raise ValueError("입력되지 않은 설정: " + ", ".join(missing))
except (OSError, ValueError, TypeError) as e:
    print("KIS 설정을 확인하세요:", e, file=sys.stderr)
    sys.exit(1)' ; then
  exit 1
fi

BUILD_SOURCE=""
STAGING=""
cleanup() {
  result=$?
  [[ -z "$STAGING" ]] || rm -rf "$STAGING"
  [[ -z "$BUILD_SOURCE" ]] || rm -rf "$BUILD_SOURCE"
  finish "$result"
}
trap cleanup EXIT

echo "현재 작업 폴더의 소스를 기준으로 빌드합니다."
BUILD_SOURCE="$(mktemp -d "${TMPDIR:-/tmp}/moneyfy-build.XXXXXX")"
git ls-files --cached --others --exclude-standard -z | /usr/bin/python3 -c '
import os
from pathlib import Path
import shutil
import sys

build_source = Path(sys.argv[1])
for name in dict.fromkeys(sys.stdin.buffer.read().split(b"\0")):
    if not name:
        continue
    source = Path(os.fsdecode(name))
    if not (source.is_symlink() or source.is_file()):
        continue
    target = build_source / source
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target, follow_symlinks=False)
' "$BUILD_SOURCE"
cp config.json "$BUILD_SOURCE/config.json"
if [[ -f assets/config.json ]]; then
  mkdir -p "$BUILD_SOURCE/assets"
  cp assets/config.json "$BUILD_SOURCE/assets/config.json"
fi
cd "$BUILD_SOURCE"
# 최신 Xcode는 일부 Flutter 플러그인의 오래된 macOS 타깃을 허용하지 않습니다.
/usr/bin/python3 -c 'from pathlib import Path
p = Path("macos/Podfile")
s = p.read_text()
needle = "    flutter_additional_macos_build_settings(target)\n"
if s.count(needle) != 1: raise SystemExit("Podfile 형식이 바뀌었습니다. macOS 빌드 설정을 확인하세요.")
p.write_text(s.replace(needle, needle + "    target.build_configurations.each do |config|\n      config.build_settings[\x27MACOSX_DEPLOYMENT_TARGET\x27] = \x2712.0\x27\n    end\n"))'

echo "Moneyfy macOS 릴리스 빌드 중..."
# Enable the listener only in this personal installation build.
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.network.server bool true' macos/Runner/Release.entitlements
flutter build macos --release --dart-define-from-file=config.json --dart-define=MONEYFY_MCP_INSTALLED=true

APP="build/macos/Build/Products/Release/Moneyfy.app"
[[ -d "$APP" ]] || { echo "빌드된 앱을 찾을 수 없습니다: $APP"; exit 1; }
DEST="$HOME/Applications"
mkdir -p "$DEST"
STAGING="$(mktemp -d "$DEST/.moneyfy-install.XXXXXX")"
ditto "$APP" "$STAGING/Moneyfy.app"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$STAGING/Moneyfy.app/Contents/Info.plist")"
if [[ "$BUNDLE_ID" != com.example.moneyfy ]]; then
  echo "MONEYFY MCP가 예상한 앱 식별자와 일치하지 않습니다."
  exit 1
fi
if ! codesign -d --entitlements :- "$STAGING/Moneyfy.app" 2>/dev/null \
  | plutil -convert xml1 -o - - \
  | /usr/bin/python3 -c 'import plistlib, sys; raise SystemExit(plistlib.loads(sys.stdin.buffer.read()).get("com.apple.security.network.server") is not True)'; then
  echo "설치용 앱에 로컬 MCP 연결을 받는 권한이 없습니다."
  exit 1
fi

# Keep the installation credential out of the app bundle and the build output.
/usr/bin/python3 - "$BUNDLE_ID" <<'PY'
import json
import os
from pathlib import Path
import re
import secrets
import sys
import tempfile

documents = Path.home() / 'Library/Containers' / sys.argv[1] / 'Data/Documents'
documents.mkdir(mode=0o700, parents=True, exist_ok=True)
config = documents / '.moneyfy-mcp-bridge.json'
with tempfile.NamedTemporaryFile(mode='w', dir=documents) as candidate:
    json.dump({'token': secrets.token_hex(32)}, candidate)
    candidate.flush()
    try:
        os.link(candidate.name, config)
    except FileExistsError:
        pass

with os.fdopen(os.open(config, os.O_RDONLY | os.O_NOFOLLOW)) as installed:
    os.fchmod(installed.fileno(), 0o600)
    token = json.load(installed)['token']
    if not isinstance(token, str) or not re.fullmatch(r'[a-f0-9]{64}', token):
        raise SystemExit('설치된 로컬 MCP 설정을 읽을 수 없습니다.')
PY

echo "기존 Moneyfy 앱을 종료합니다..."
/usr/bin/swift - "$BUNDLE_ID" <<'SWIFT'
import AppKit
import Foundation
let apps = NSRunningApplication.runningApplications(withBundleIdentifier: CommandLine.arguments[1])
for app in apps { _ = app.terminate() }
let deadline = Date().addingTimeInterval(20)
while apps.contains(where: { !$0.isTerminated }) && Date() < deadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.25))
}
if apps.contains(where: { !$0.isTerminated }) {
    fputs("Moneyfy가 종료되지 않았습니다. 앱을 종료한 뒤 다시 실행하세요.\n", stderr)
    exit(1)
}
SWIFT
if [[ -e "$DEST/Moneyfy.app" ]]; then
  mv "$DEST/Moneyfy.app" "$STAGING/previous.app"
fi
if ! mv "$STAGING/Moneyfy.app" "$DEST/Moneyfy.app"; then
  [[ ! -e "$STAGING/previous.app" ]] || mv "$STAGING/previous.app" "$DEST/Moneyfy.app"
  echo "앱 설치에 실패했습니다."
  exit 1
fi
echo "설치 완료: $DEST/Moneyfy.app"
open -n "$DEST/Moneyfy.app"
/usr/bin/swift - "$BUNDLE_ID" "$DEST/Moneyfy.app" <<'SWIFT'
import AppKit
import Foundation
let id = CommandLine.arguments[1]
let expected = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL.path
let deadline = Date().addingTimeInterval(15)
while Date() < deadline {
    if NSRunningApplication.runningApplications(withBundleIdentifier: id).contains(where: {
        $0.bundleURL?.standardizedFileURL.path == expected && !$0.isTerminated
    }) {
        print("실행 확인: \(expected)")
        exit(0)
    }
    RunLoop.current.run(until: Date().addingTimeInterval(0.25))
}
fputs("설치된 Moneyfy가 실행되는지 확인하지 못했습니다.\n", stderr)
exit(1)
SWIFT
/usr/bin/python3 - "$BUNDLE_ID" "$PROJECT_DIR" <<'PY'
import json
import os
from pathlib import Path
import sys
import tempfile
import time
from urllib.error import URLError
from urllib.request import ProxyHandler, Request, build_opener

config = Path.home() / 'Library/Containers' / sys.argv[1] / 'Data/Documents/.moneyfy-mcp-bridge.json'
token = json.loads(config.read_text())['token']
request = Request(
    'http://127.0.0.1:47831/mcp',
    data=b'{"operation":"get_status","arguments":{}}',
    headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
)
opener = build_opener(ProxyHandler({}))
deadline = time.monotonic() + 15
while time.monotonic() < deadline:
    try:
        with opener.open(request, timeout=1) as response:
            status = json.load(response)
        if status.get('bridge_connected') is True:
            # Already-running Codex MCP processes still read the original path.
            legacy_config = Path(sys.argv[2]) / 'tools/moneyfy-mcp/.bridge.json'
            with tempfile.NamedTemporaryFile(mode='w', dir=legacy_config.parent, delete=False) as legacy:
                try:
                    json.dump({'token': token}, legacy)
                    legacy.flush()
                    os.replace(legacy.name, legacy_config)
                finally:
                    Path(legacy.name).unlink(missing_ok=True)
            print('로컬 MCP 연결과 인증을 확인했습니다.')
            if not status.get('data_ready'):
                print('MONEYFY에 로그인하고 초기 데이터 로딩을 완료하면 자산을 조회할 수 있습니다.')
            break
    except (URLError, TimeoutError):
        pass
    time.sleep(0.5)
else:
    raise SystemExit('설치된 MONEYFY 앱의 로컬 MCP 연결을 확인하지 못했습니다.')
PY
