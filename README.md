# MONEYFY

MONEYFY는 투자 자산과 현금 계좌를 함께 관리하는 Flutter 앱입니다. 매수·매도, 배당, 입출금, 환전을 기록하면 거래 원장을 바탕으로 보유 수량, 원가, 실현손익, 현금 잔액을 다시 계산합니다. 일별 스냅샷을 열면 과거 특정 날짜의 자산 구성도 확인할 수 있습니다.

## 앱에서 할 수 있는 일

| 탭 | 주요 기능 |
| --- | --- |
| 홈 | 총자산과 손익을 확인하고 자산군별 비중을 비교합니다. |
| 포트폴 | 보유 종목과 현금 계좌를 관리하고 각 자산의 평가액과 거래 내역을 살펴봅니다. |
| 거래 | 매매, 배당·이자, 입출금, 이체·환전 내역을 기록하고 조회합니다. |
| 분석 | 포트폴리오 성과와 자산 배분을 살펴보고 AI 포트폴리오 진단과 뉴스 요약을 확인합니다. |
| My | 계정에 로그인하고 동기화 상태와 개인 설정을 확인합니다. |

앱은 보유 자산과 거래 내역을 기기의 SQLite 데이터베이스에 저장하고 Drift로 읽고 씁니다. 로그인하면 Supabase를 통해 같은 계정의 데이터를 여러 기기에서 동기화합니다.

## 로컬에서 실행하기

CI에서 사용하는 Flutter 버전은 **3.47.9**입니다. Flutter SDK와 대상 플랫폼의 개발 도구를 설치하고, 기기나 에뮬레이터를 연결한 뒤 저장소 루트에서 실행하세요.

```sh
flutter pub get
flutter devices
flutter run -d <기기-ID>
```

마지막 명령의 `<기기-ID>`에는 `flutter devices`에 표시된 값을 입력합니다. 앱은 서버 설정 없이도 실행할 수 있습니다. 로그인과 동기화를 사용하려면 아래 설정을 추가하세요.

### 로그인과 동기화 연결하기

1. [앱 설정 예시](assets/config.example.json)를 같은 폴더에 `assets/config.json`으로 복사합니다.
2. `SUPABASE_URL`과 `SUPABASE_ANON_KEY`에 연결할 프로젝트의 URL과 클라이언트용 anon 키를 입력합니다.
3. 앱을 다시 실행하고 **My**에서 로그인합니다.

새 Supabase 프로젝트를 연결할 때는 저장소의 마이그레이션을 적용하고 필요한 Edge Functions를 배포하세요. KIS 시세 조회용 키와 서비스 역할 키는 서버에서 관리합니다. [백엔드 구성](supabase/README.md) · [Supabase CLI 운영 가이드](docs/supabase_cli_runbook.md)

### USB로 연결한 iPhone에 설치하기

macOS에서 iOS 15 이상인 iPhone을 연결하고 기기에서 Mac을 신뢰하도록 설정하세요. 개발자 모드가 제공되는 iOS 버전에서는 해당 모드를 켜고, Xcode에서 Runner의 개발 서명을 설정합니다. 다음 스크립트가 릴리스 빌드를 기기에 설치하고 실행합니다.

```sh
./scripts/install_ios_usb.command
```

여러 대가 연결되어 있으면 스크립트 뒤에 기기 ID를 입력하세요. 설치 후 개발자 신뢰 안내가 나타나면 iPhone의 **설정 → 일반 → VPN 및 기기 관리**에서 서명에 사용한 개발자를 신뢰하도록 설정합니다.

## 개발 및 검증

```sh
flutter analyze
flutter test
```

Drift 테이블이나 생성 대상 모델을 수정한 뒤에는 다음 명령으로 생성 코드를 갱신합니다.

```sh
dart run build_runner build --delete-conflicting-outputs
```

## 코드와 문서

| 찾고 싶은 내용 | 위치 |
| --- | --- |
| 포트폴리오, 거래, 분석 등 기능별 화면과 서비스 | [lib/features](lib/features) |
| 거래 원장, 잔액 계산, 동기화 흐름 | [로컬 DB 코드](lib/db) · [데이터 흐름 문서](docs/data_and_sync.md) |
| 서버 함수와 DB 스키마 변경 이력 | [Edge Functions](supabase/functions) · [마이그레이션](supabase/migrations) |
| macOS 앱의 자산·거래를 MCP로 조회하고 변경하는 방법 | [개인용 MCP 가이드](tools/moneyfy-mcp/README.md) |
| 화면 설계 기준과 프로젝트 문서 색인 | [디자인 시스템](docs/design_system.md) · [전체 문서](docs/README.md) |
