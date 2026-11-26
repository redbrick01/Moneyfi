#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Moneyfy release 앱을 빌드하고 연결된 기기에 설치합니다..."
flutter run --release

