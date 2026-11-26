#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f "config.json" ]]; then
  echo "config.json 파일이 없습니다. 먼저 다음 명령으로 생성하세요:"
  echo "  cp config.example.json config.json"
  read -r -p "Enter 키를 누르면 종료합니다..."
  exit 1
fi

echo "Moneyfy release 앱을 빌드하고 연결된 기기에 설치합니다..."
flutter run --release --dart-define-from-file=config.json

