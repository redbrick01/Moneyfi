# `lib/` Guide

`lib/`는 MONEYFY Flutter 앱의 실제 소스입니다. 화면, 로컬 DB, 서비스, 디자인 시스템이 모두 이 폴더에 있습니다.

## Entry Points

| 파일 | 역할 |
| --- | --- |
| `main.dart` | 앱 초기화, Supabase 초기화, `MoneyfyApp` 실행 |
| `pages/app_shell_page.dart` | 하단 탭, 앱 생명주기, 원격 refresh, 시장 데이터 polling |
| `db/app_database.dart` | Drift DB와 대부분의 데이터 mutation/query |

## Folder Responsibilities

| 폴더 | 설명 |
| --- | --- |
| `components/` | 버튼, row, card, chip, empty/error/loading state 등 재사용 UI |
| `data/` | 샘플 또는 정적 데이터 helper |
| `db/` | Drift table, migration, query, ledger 계산 |
| `design_system/` | theme extension, spacing, typography, brand color, spec |
| `models/` | 앱 내부 데이터 모델 |
| `pages/` | 탭과 상세 화면 단위 widget |
| `pages/forms/` | 입력/수정 폼 화면 |
| `services/` | Supabase, sync, market data, news, diagnosis API 연동 |
| `theme/` | 보조 theme/color 정의 |
| `ui_scaffold/` | 공통 페이지 scaffold와 inset |
| `utils/` | 표시 통화 등 범용 helper |
| `widgets/` | 기존 공용 widget과 복합 카드 |

## Screen Map

| 화면 | 파일 |
| --- | --- |
| 홈 대시보드 | `pages/portfolio_dashboard_page.dart` |
| 포트폴리오 | `pages/portfolio_page.dart` |
| 분석 | `pages/analysis_page.dart` |
| 통계 | `pages/statistics_page.dart` |
| My | `pages/my_page.dart` |
| 자산 상세 | `pages/asset_detail_page.dart` |
| 보유 상세 | `pages/holding_detail_page.dart` |
| 현금 계좌 상세 | `pages/cash_account_detail_page.dart` |
| 스냅샷 상세 | `pages/snapshot_detail_page.dart` |
| 로그인/회원가입 | `pages/login_page.dart`, `pages/signup_page.dart` |

## Service Map

| 서비스 | 책임 |
| --- | --- |
| `AuthService` | `assets/config.json` 로드, Supabase SDK 초기화, auth |
| `SyncService` | dirty payload push, remote core/snapshot pull |
| `MarketDataService` | KIS/코인/환율 조회와 로컬 가격 갱신 |
| `MarketNewsSummaryService` | 시장 뉴스 요약 조회와 캐시 |
| `CompanyNewsSummaryService` | 보유 종목 뉴스 요약 조회와 캐시 |
| `PortfolioDiagnosisService` | OpenAI 기반 포트폴리오 진단 조회와 캐시 |

## Development Notes

- `app_database.g.dart`는 generated file입니다. 직접 수정하지 않습니다.
- DB schema 변경 후에는 `dart run build_runner build --delete-conflicting-outputs`를 실행합니다.
- 화면 UI는 가능하면 `components/`와 `design_system/`의 기존 토큰을 재사용합니다.
- 새 원격 필드를 추가하면 `SyncService`, `AppDatabase`, Supabase migration, Edge Function payload를 함께 확인합니다.
