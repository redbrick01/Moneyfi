# 데이터 흐름 정리 — 서버 DB 통합 1단계

작성일: 2026-08-05  
범위: 코드·스키마·동기화 경로 정리. 이번 단계에서는 애플리케이션 코드를 변경하지 않음.

## 1. 현재 결론

현재 구조는 완전한 서버 원본 구조가 아니라 **local-first + 선택적 Supabase 동기화**다.

- 일반 화면 조회는 대부분 `AppDatabase`(Drift/SQLite)를 직접 읽는다.
- 로그인 상태에서 `SyncService`가 dirty 로컬 row를 `sync-local-db`로 업로드한다.
- 서버에서 내려받는 core payload는 `assets`, `holdings`, `cash_accounts`, `transaction_events`, `transaction_lines`, `snapshot_notes`로 제한된다.
- pull 전 dirty core 데이터가 남아 있으면 먼저 push하고, 성공한 경우에만 `get-sync-local-db` 결과로 로컬 core 데이터를 교체한다.
- 스냅샷은 core sync와 별도로 `get-portfolio-snapshots`에서 내려받아 로컬에 import한다.
- `hidden` 상태는 서버에 저장/필터링하지 않고 로컬 표시 기준으로만 사용한다.

따라서 “서버 DB 통합”의 1차 대상은 원장과 포트폴리오 상태이며, 로컬 캐시·표시 설정·분석 산출물은 별도 분류 후 결정해야 한다.

## 2. 로컬 ↔ 서버 테이블 매핑

상태의 의미:

- **양방향 core**: 현재 dirty push와 remote pull이 모두 확인됨.
- **remote pull/import**: 서버에서 받아 로컬에 저장하지만 현재 일반 dirty push 대상은 아님.
- **로컬 전용/캐시**: 현재 화면 계산 또는 캐시 목적이며 서버 원본으로 쓰지 않음.
- **확인 필요**: 서버 테이블/함수는 있으나 현재 앱 sync 경로에서 연결 여부를 추가 검증해야 함.

| 로컬 Drift 테이블 | 서버 테이블 | 현재 경로 | 1단계 판정 |
|---|---|---|---|
| `Assets` | `assets` | core push/pull | 양방향 core. 서버 원본 후보 |
| `Holdings` | `holdings` | core push/pull | 양방향 core. 서버 원본 후보 |
| `CashAccounts` | `cash_accounts` | core push/pull | 양방향 core. 서버 원본 후보 |
| `TransactionEvents` | `transaction_events` | core push/pull | 양방향 core. 서버 원본 후보 |
| `TransactionLines` | `transaction_lines` | core push/pull | 양방향 core. 서버 원본 후보 |
| `DailyPortfolioSnapshots` | `daily_portfolio_snapshots` | `create-portfolio-snapshot`, `get-portfolio-snapshots` → local import | remote pull/import. 서버 원본 후보 |
| `DailyPortfolioSnapshotItems` | `daily_portfolio_snapshot_items` | snapshot pull/import | remote pull/import. 서버 원본 후보 |
| `DailyPortfolioSnapshotHoldingItems` | `daily_portfolio_snapshot_holding_items` | snapshot pull/import | remote pull/import. 서버 원본 후보 |
| `DailyPortfolioSnapshotCashAccounts` | `daily_portfolio_snapshot_cash_accounts` | snapshot pull/import | remote pull/import. 서버 원본 후보 |
| `SnapshotNotes` | `snapshot_notes` | core payload에 포함 | 양방향 core에 준함. 날짜 unique 정책 확인 필요 |
| `AssetAllocationTargets` | 직접 대응 확인 안 됨 | 로컬 `fetchAssetAllocationTargets` | 로컬 전용 후보. 서버 이관 여부 결정 필요 |
| `ExchangeRates` | `exchange_rates` | 외부 환율/서버 함수 및 로컬 조회 | 확인 필요. 환율 기준 시각과 source 정책 확정 필요 |
| `MarketNewsCaches` | `market_news`, `market_news_summaries` | 서버 함수 조회 후 로컬 cache | 로컬 전용 캐시. 서버 콘텐츠가 원본 |
| `CompanyNewsCaches` | `company_news`, `company_news_summaries` | 서버 함수 조회 후 로컬 cache | 로컬 전용 캐시. 서버 콘텐츠가 원본 |
| `PortfolioDailyReturns` | 직접 대응 확인 안 됨 | 로컬 ledger/snapshot 계산 | 로컬 계산 캐시/산출물 후보. 재계산 가능성 검증 필요 |
| `BenchmarkPrices` | 직접 대응 확인 안 됨 | benchmark/risk-free 서비스가 로컬 DB 사용 | 로컬 전용 데이터 후보. 서버 이관 여부 결정 필요 |
| `DailyInvestmentReviews` | 직접 대응 확인 안 됨 | `DailyInvestmentReviewRepository`가 로컬 DB 사용 | 로컬 전용 사용자 기록 후보. 서버 원본화 여부 결정 필요 |
| `Transactions` | 과거 `transactions`는 archive/drop 이력 | legacy 호환 코드/테스트에 잔존 | 신규 서버 원본 매핑에서 제외 |
| `CashTransactions` | 대응 없음/legacy | legacy 로컬 코드 잔존 가능 | 신규 서버 원본 매핑에서 제외 |

### 핵심 식별자

- 로컬 integer `id`는 기기/복원 시 달라질 수 있다.
- 동기화와 스냅샷 상세 연결의 안정 식별자는 `client_id`다.
- 서버 upsert 충돌 키는 일반적으로 `user_id + client_id`다.
- 스냅샷 상세는 `asset_client_id`, `holding_client_id`, `cash_account_client_id`를 우선 사용하고 서버 integer id를 fallback으로 사용한다.

## 3. 화면별 데이터 조회 경로

| 화면/기능 | 현재 조회 원본 | 주요 로컬 조회 | 서버/외부 갱신 | 서버 원본화 시 주의점 |
|---|---|---|---|---|
| 대시보드/포트폴리오 요약 | 로컬 DB | assets, holdings, cash accounts, ledger 계산, 최신 환율 | 시장 가격 갱신, 필요 시 sync/refresh | 서버 pull 완료 전 로컬 값이 표시될 수 있음 |
| 거래 내역 | 로컬 DB | `fetchAssets`, ledger transaction 조회 | 진입/새로고침 시 `refreshFromServer`; 삭제 후 `syncNow` | 이벤트/라인을 함께 원자적으로 처리해야 함 |
| 자산/보유 상세 | 로컬 DB | asset/holding/cash 조회, ledger 계산 | 가격 서비스, background sync | `hidden`은 로컬 표시 필터 |
| 투자 성과 분석 | 로컬 DB 계산 | ledger holding/portfolio/monthly performance, `PortfolioDailyReturns`, snapshots, `BenchmarkPrices` | benchmark/risk-free/환율 서비스 | 계산 산출물을 서버 원본으로 만들지, 입력만 서버화할지 결정 필요 |
| 배당·이자 분석 | 로컬 DB | ledger income transactions, 환율 | sync로 원장 갱신 | 원장 서버화가 선행 조건 |
| 연간 자산 분석 | 로컬 DB + 시장가격 | snapshot/asset 계산, `MarketDataService.refreshAllMarketData` | 시장 가격 외부 API | 가격의 authoritative source와 timestamp 필요 |
| 스냅샷/자산 변화 | 로컬 import DB | snapshots 및 detail rows | `get-portfolio-snapshots` | snapshot header/item 합계 불일치 검증 필요 |
| 시장 뉴스 요약 | 로컬 cache 우선/서버 함수 | `MarketNewsCaches` | `get-market-news-summary` | 캐시는 삭제·재생성 가능, 서버 콘텐츠 원본 |
| 보유 종목 뉴스 | 로컬 cache 우선/서버 함수 | `CompanyNewsCaches` | `get-user-company-news-summaries` | symbol 기준 중복·최신일 정책 확인 |
| 일일 투자 리뷰 | 로컬 DB | `DailyInvestmentReviews` repository | 현재 서버 sync 경로 미확인 | 개인 기록 서버 보관 여부 별도 결정 |
| 마이페이지/데이터 관리 | 로컬 DB + sync 상태 | assets, targets, transaction dates, recent snapshots | 수동 push/pull, local data clear | clear는 서버 삭제가 아니므로 사용자 안내 필요 |

## 4. 업로드·다운로드·dirty 처리 목록

### 업로드

`AppDatabase.buildDirtySyncPayload()` → `sync-local-db`:

- `assets`
- `holdings`
- `cash_accounts`
- `transaction_events`
- `transaction_lines`
- `snapshot_notes`

성공 확인은 단순 HTTP 200이 아니다. 앱은 `ok`, payload count, `accepted_client_ids`, relation failures, conflict count를 확인한 뒤 accepted row만 dirty 해제한다.

### 다운로드

`get-sync-local-db` → `replaceLocalSyncData()`:

- `assets`
- `holdings`
- `cash_accounts`
- `transaction_events`
- `transaction_lines`

별도 `get-portfolio-snapshots` → `importRemotePortfolioSnapshots()`:

- snapshot header
- asset snapshot items
- holding snapshot items
- cash-account snapshot items
- snapshot notes

### dirty/충돌 규칙

- 변경 row에는 `dirty`, `last_modified_at`, `deleted_at`가 사용된다.
- 삭제는 hard delete가 아니라 soft delete payload로 전송된다.
- 충돌 기준은 `last_modified_at` last-writer-wins이며, tie는 client accept다.
- 서버가 더 최신이면 해당 row는 push 거절되고 dirty가 남는다.
- pull은 dirty core가 남아 있으면 중단된다. 즉 서버 원본화 전에도 local 변경 유실 방지 장치가 있다.
- transaction event와 lines는 같은 사용자 조작에서 같은 변경 시각과 안정 참조를 유지해야 한다.

## 5. 서버 원본 vs 로컬 전용 분류

### 서버를 원본으로 삼을 후보

- 자산 구조: `assets`, `holdings`, `cash_accounts`
- 거래 원장: `transaction_events`, `transaction_lines`
- 서버 생성/보관 스냅샷: `daily_portfolio_snapshots` 및 3종 detail
- snapshot notes: 사용자 기기 간 공유가 목적이라면 서버 원본

이 데이터는 서버를 원본으로 삼되, 로컬 DB는 오프라인/성능용 materialized cache로 남기는 방향이 자연스럽다.

### 로컬 전용 또는 재생성 가능한 캐시 후보

- `MarketNewsCaches`, `CompanyNewsCaches`
- `PortfolioDailyReturns`
- `BenchmarkPrices` (단, 여러 기기에서 동일 분석 결과가 필요하면 서버 데이터셋으로 승격)
- UI 표시용 `hidden` 상태
- `AssetAllocationTargets` (사용자 설정이므로 서버 공유가 필요하면 core에 편입)
- `DailyInvestmentReviews` (개인 기록을 여러 기기에서 이어 써야 하면 서버 테이블 신설/매핑 필요)

### 원본 판정이 아직 필요한 데이터

- `ExchangeRates`: 외부 API 응답, 서버 저장값, snapshot에 고정된 환율 중 어느 것을 기준으로 할지
- market/company news의 raw article과 summary: 서버 raw/summary가 원본이고 앱 cache는 replica인지 확인
- portfolio diagnosis cache: 서버 생성 결과와 로컬 저장 cache의 만료/재생성 정책

## 6. 누락·중복·불일치 점검 결과

이번 단계에서 실제 운영 row를 직접 비교한 것은 아니다. 저장소에서 확인 가능한 **구조적 점검 결과**는 다음과 같다.

### 확인된 누락 후보

1. `AssetAllocationTargets`, `PortfolioDailyReturns`, `BenchmarkPrices`, `DailyInvestmentReviews`는 현재 core sync payload에 없다.
2. 로컬 뉴스 cache 테이블은 서버 뉴스/summary 테이블과 의미상 대응하지만 일반 core sync 대상이 아니다.
3. `ExchangeRates`는 로컬 테이블과 서버 테이블이 모두 있으나 동일 row를 동기화하는 계약이 보이지 않는다.
4. `hidden`은 로컬에만 있어 기기 간 표시 상태가 일치하지 않을 수 있다.
5. `Transactions`, `CashTransactions` legacy 흔적이 남아 있어 신규 ledger와 중복 경로로 오인될 위험이 있다.

### 중복 점검 포인트

- 동일 거래가 legacy transaction과 ledger event/line 양쪽에 존재하는지
- 동일 snapshot 날짜가 local import와 local 생성으로 두 번 만들어지는지
- snapshot header 합계와 item 합계가 서로 다른지
- symbol/category/summary date 기준으로 뉴스 cache가 중복되는지
- 동일 `client_id`가 사용자별/테이블별로 중복 생성되지 않는지

### 불일치 점검 포인트

- `client_id` 없는 row 또는 빈 `client_id`
- event와 line의 `event_client_id`, asset/holding/cash reference 불일치
- 서버보다 오래된 local row가 dirty로 남아 있는 충돌 상태
- `deleted_at`은 있으나 화면 조회에서 제외되지 않는 soft-deleted row
- local integer id를 서버 snapshot detail 연결에 직접 사용한 row
- snapshot의 `total_*` 값과 detail 합계 불일치
- 통화가 USD인데 환율 또는 `exchange_rate`가 누락된 금액
- 숨김 처리 전후 대시보드와 snapshot의 합계 차이

## 7. 실제 데이터 대조를 위해 필요한 입력

코드 구조만으로는 운영 데이터의 누락·중복·불일치를 확정할 수 없다. 다음 read-only 추출을 수행하면 1단계 데이터 대조를 완료할 수 있다.

1. 로컬 SQLite에서 각 테이블의 row count, `client_id` null/duplicate, dirty count, deleted count
2. Supabase에서 사용자 scope별 동일 집계
3. `client_id` 기준 local↔remote full outer diff
4. event↔line 관계 누락 및 중복 검사
5. snapshot header↔detail 합계 비교
6. legacy transaction↔ledger 변환/복원 중복 검사

이 작업은 데이터 변경 없이 export와 SQL 조회만 필요하며, 운영 데이터 접근 권한 또는 로컬 DB 파일 경로가 준비되면 별도 점검표로 실행할 수 있다.

## 8. 다음 단계 진입 조건

다음 구현 단계로 넘어가기 전에 아래 정책을 확정해야 한다.

- 서버 원본 대상: core만인지, targets/returns/reviews까지 포함할지
- offline 편집을 계속 허용할지, 서버 online 필수로 전환할지
- local DB를 유지한다면 cache/replica의 만료·재생성 정책
- `hidden`, allocation target, daily review의 기기 간 공유 여부
- 환율과 시장가격의 기준 source 및 snapshot 고정 규칙
- legacy transaction 데이터의 보존/삭제/검증 절차
- 초기 통합 시 충돌 우선순위와 백업·rollback 기준

