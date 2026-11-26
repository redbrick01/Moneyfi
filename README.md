# Moneyfy

투자 자산과 현금 계좌를 한곳에서 관리하는 포트폴리오 앱입니다. 매수·매도와 입출금을 기록하면 보유 수량, 원가, 실현손익, 현금 잔액에 반영됩니다. 일별 스냅샷으로 과거의 자산 구성도 다시 볼 수 있습니다.

**[Moneyfy 앱 다운로드](https://fast-harp-jzo6rrz.tmp.now/)** · [GitHub 릴리스 노트](https://github.com/redbrick01/Moneyfi/releases)

## 내 기기에 설치하기

다운로드 페이지에서 운영체제를 선택하면 최신 릴리스의 설치 파일과 설치 방법이 표시됩니다. 파일을 직접 찾으려면 [최신 릴리스의 Assets](https://github.com/redbrick01/Moneyfi/releases/latest)를 여세요.

| 기기 | 설치 파일 | 설치 방법 |
| --- | --- | --- |
| Windows x64 | `moneyfy-windows-x64.zip` | 압축을 모두 풀고 같은 폴더의 DLL과 `data` 폴더를 그대로 둔 채 `moneyfy.exe`를 실행합니다. |
| macOS · Apple Silicon | `moneyfy-macos-arm64.zip` | 압축을 풀고 `Moneyfy.app`을 응용 프로그램 폴더로 옮깁니다. Apple 공증 전 빌드이므로 실행이 제한될 수 있습니다. |
| Linux x86_64 | `moneyfy-linux-x64.tar.gz` | 압축을 푼 폴더에서 `./moneyfy`를 실행합니다. Ubuntu 24.04에서 빌드하며 GTK 3와 libsecret이 필요합니다. |
| Android | `moneyfy-android.apk` | 기기에서 APK를 열고 설치 안내를 따릅니다. |

iPhone용 공개 배포는 보류 중입니다. 개발용 iPhone에는 아래의 USB 설치 절차를 사용할 수 있습니다.

## 포트폴리오 기록하기

1. **포트폴**에서 현금 계좌와 보유 종목을 관리합니다. 종목별 평가액과 거래 내역도 여기서 확인합니다.
2. **거래**에서 매수·매도, 배당·이자, 입출금, 이체·환전을 기록합니다. **홈**에서 거래가 반영된 총자산과 손익, 자산군별 비중을 확인합니다.
3. **분석**에서 포트폴리오 성과와 자산 배분을 살펴봅니다. 일별 스냅샷을 열면 해당 날짜의 보유 자산과 평가액을 확인할 수 있습니다.

거래와 보유 내역은 기기의 SQLite 데이터베이스에 저장됩니다. 여러 기기에서 같은 포트폴리오를 사용하려면 **My**에서 같은 계정으로 로그인하고 동기화 상태를 확인하세요.

## 소스에서 실행하기

Flutter SDK와 대상 플랫폼의 개발 도구를 설치한 뒤 저장소 루트에서 실행합니다. 정적 분석과 테스트를 수행하는 CI의 Flutter 버전은 `3.47.9`입니다.

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

`<device-id>`에는 `flutter devices`가 표시한 기기 ID를 입력합니다. 로그인과 동기화를 개발하려면 [설정 예시](assets/config.example.json)를 `assets/config.json`으로 복사하고 `SUPABASE_URL`과 `SUPABASE_ANON_KEY`를 지정한 뒤 다시 실행하세요.

**iPhone USB 설치**에는 macOS, Xcode 개발 서명, USB로 연결한 iOS 15 이상 기기가 필요합니다. iPhone에서 Mac을 신뢰하고, 개발자 모드가 제공되는 기기에서는 해당 모드를 켠 뒤 실행합니다.

```sh
./scripts/install_ios_usb.command
```

**변경 사항 검증**에는 다음 명령을 사용합니다. Drift 테이블을 수정했다면 먼저 `dart run build_runner build --delete-conflicting-outputs`로 생성 코드를 갱신하세요.

```sh
flutter analyze
flutter test
```

## 다운로드 페이지와 앱 릴리스

Vercel은 [distribution](distribution)의 정적 다운로드 페이지를 제공합니다. Vercel 프로젝트의 Root Directory는 `distribution`이며, 이 디렉터리를 그대로 게시하도록 [vercel.json](distribution/vercel.json)에 설정되어 있습니다.

앱 설치 파일은 GitHub Releases에서 제공합니다. `v1.2.3`처럼 `v` 다음에 숫자가 오는 태그를 푸시하면 [릴리스 워크플로](.github/workflows/release.yml)가 네 플랫폼의 패키지를 빌드해 게시합니다. [다운로드 페이지](distribution/downloads.js)는 열릴 때마다 최신 릴리스에서 운영체제에 맞는 파일을 찾으므로 새 버전을 배포할 때 다운로드 링크를 교체할 필요가 없습니다.

## 개발 문서

- [기능별 앱 코드](lib/features) · [프로젝트 문서 색인](docs/README.md)
- [거래 원장과 동기화 흐름](docs/data_and_sync.md) · [백엔드 구성](supabase/README.md)
- [macOS 앱을 MCP로 연결하기](tools/moneyfy-mcp/README.md)
