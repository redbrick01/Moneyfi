# Supabase CLI Runbook

MONEYFY 프로젝트에서 Supabase CLI로 원격 Supabase 프로젝트를 관리할 때 사용하는 절차입니다.

## 현재 연결 정보

- Supabase project ref: `oeweumxfabobwlhzrzqk`
- Supabase project name: `Moneyfi`
- Dashboard: `https://supabase.com/dashboard/project/oeweumxfabobwlhzrzqk`
- Flutter client config: `assets/config.json`
- Local Supabase config: `supabase/config.toml`

비밀키 값은 문서에 기록하지 않습니다. 원격 secret 값은 Supabase CLI나 Dashboard에서 이름만 확인합니다.

## 1. CLI 설치 확인

```bash
supabase --version
```

설치되어 있지 않으면 Homebrew로 설치합니다.

```bash
brew install supabase/tap/supabase
```

이 환경에서는 Supabase CLI 실행 시 아래 경고가 나올 수 있습니다.

```text
CPU lacks AVX support
```

현재까지는 명령 실행 자체에는 문제가 없었습니다.

## 2. 로그인

최초 1회 또는 토큰 만료 시 로그인합니다.

```bash
supabase login
```

토큰은 채팅이나 문서에 남기지 않습니다.

## 3. 프로젝트 링크

로컬 프로젝트 루트에서 실행합니다.

```bash
supabase link --project-ref oeweumxfabobwlhzrzqk
```

연결 확인:

```bash
cat supabase/.temp/project-ref
supabase projects list
```

`supabase/.temp/`는 로컬 메타데이터이므로 `.gitignore`에 포함합니다.

## 4. DB Migration 상태 확인

로컬/원격 migration 이력을 확인합니다.

```bash
supabase migration list
```

2026-05-23 확인 기준 정상 상태는 아래 migration이 local/remote 모두 일치하는 것입니다.

```text
20260521043000_baseline_remote_schema
20260521050000_harden_public_permissions
20260522090000_normalize_transaction_amounts
20260522093000_create_transaction_ledger_tables
20260522094500_backfill_transaction_ledger_from_legacy
20260522120000_add_transaction_line_legacy_sources
20260522143000_reconcile_state_from_transaction_ledger
20260522144500_archive_and_drop_legacy_transaction_tables
20260522150000_reclassify_unpaired_legacy_cash_events
20260522151500_restore_state_from_latest_snapshots
20260522153000_rebuild_snapshot_restore_ledger_lines
20260523001000_restore_history_display_ledger
20260523120000_add_snapshot_client_references
```

원격 DB와 로컬 migration 사이 drift 확인:

```bash
supabase db diff --from migrations --to linked --schema public
```

출력 SQL이 없으면 public schema 기준 drift가 없는 상태입니다.

## 5. DB 변경 적용

새 DB 변경은 반드시 새 migration으로 만듭니다.

```bash
supabase migration new migration_name
```

생성된 SQL 파일을 수정한 뒤, 적용 전 상태를 확인합니다.

```bash
supabase migration list
```

원격 적용:

```bash
supabase db push
```

주의: 운영 DB에 적용되는 명령입니다. `db push` 전에 migration 내용을 반드시 확인합니다.

## 6. Secrets 확인

secret 값은 출력되지 않고 이름과 digest만 나옵니다.

```bash
supabase secrets list
```

현재 Edge Functions에서 사용하는 주요 secret 이름:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_DB_URL
OPENAI_API_KEY
FINNHUB_API_KEY
KIS_APP_KEY
KIS_APP_SECRET
```

선택 secret:

```text
CRON_SECRET
OPENAI_MODEL
KIS_BASE_URL
KIS_STOCK_QUOTE_PATH
KIS_STOCK_QUOTE_TR_ID
KIS_OVERSEAS_STOCK_QUOTE_PATH
KIS_OVERSEAS_STOCK_QUOTE_TR_ID
KIS_FUND_QUOTE_PATH
KIS_FUND_QUOTE_TR_ID
COINONE_TICKER_URL_TEMPLATE
USD_KRW_RATE_URL
```

secret 설정:

```bash
supabase secrets set KEY=value
```

관리자 키인 `SUPABASE_SERVICE_ROLE_KEY`는 Flutter 앱이나 문서에 넣지 않습니다.

## 7. Edge Functions 상태 확인

```bash
supabase functions list
```

모든 함수가 `ACTIVE`인지 확인합니다. 2026-05-23 확인 기준 아래 함수가 모두 `ACTIVE`입니다.

현재 함수 목록:

```text
create-portfolio-snapshot
fetch-company-news
fetch-market-news
get-market-news-summary
get-portfolio-diagnosis
get-portfolio-snapshots
get-sync-local-db
get-user-company-news-summaries
summarize-company-news
summarize-market-news
sync-local-db
update-holding-prices
```

## 8. Edge Functions 로컬 검사

Deno 설치 확인:

```bash
deno --version
```

설치되어 있지 않으면:

```bash
brew install deno
```

타입 검사:

```bash
deno check supabase/functions/*/index.ts
```

포맷 검사:

```bash
deno fmt --check supabase/functions
```

포맷 적용:

```bash
deno fmt supabase/functions
```

## 9. Edge Functions 배포

전체 배포:

```bash
supabase functions deploy --use-api --jobs 1
```

일부 함수만 배포:

```bash
supabase functions deploy sync-local-db get-sync-local-db --use-api --jobs 1
```

배포 후 확인:

```bash
supabase functions list
```

쓰기/외부 API 호출 함수는 실제 호출 시 DB 변경이나 외부 API 사용이 발생할 수 있습니다. smoke test는 읽기 함수 위주로 진행합니다.

## 10. 안전한 Smoke Test

아래 테스트는 쓰기 작업을 피하는 확인용입니다. 실제 anon key는 `assets/config.json`에서 확인합니다.

Market summary 조회:

```bash
curl -sS \
  -H "apikey: ANON_KEY" \
  -H "Authorization: Bearer ANON_KEY" \
  "https://oeweumxfabobwlhzrzqk.supabase.co/functions/v1/get-market-news-summary?category=general"
```

Portfolio snapshots 조회, fake user:

```bash
curl -sS \
  -H "apikey: ANON_KEY" \
  -H "Authorization: Bearer ANON_KEY" \
  "https://oeweumxfabobwlhzrzqk.supabase.co/functions/v1/get-portfolio-snapshots?user_id=00000000-0000-0000-0000-000000000000&limit=1"
```

권한 확인:

```bash
curl -sS \
  -H "apikey: ANON_KEY" \
  -H "Authorization: Bearer ANON_KEY" \
  "https://oeweumxfabobwlhzrzqk.supabase.co/rest/v1/api_tokens?select=provider&limit=1"
```

정상적으로 잠긴 상태라면 `permission denied for table api_tokens`가 나옵니다.

## 11. Flutter 검사

프론트 전체 정적 분석:

```bash
flutter analyze
```

전체 테스트:

```bash
flutter test
```

## 12. 현재 DB 보안 기준

현재 적용된 보안 migration:

```text
supabase/migrations/20260521050000_harden_public_permissions.sql
```

핵심 정책:

- `api_tokens`는 `anon`, `authenticated` 접근 차단
- 뉴스/요약/환율 테이블은 public read-only
- 공개 테이블 insert/update/delete는 차단
- `recompute_asset_metrics` 공개 실행 권한 제거
- 새 public 객체에 `anon/authenticated`가 자동으로 `ALL` 권한을 받지 않도록 default privileges 정리

## 13. 추천 작업 순서

평소 점검 순서:

```bash
flutter analyze
flutter test
deno fmt --check supabase/functions
deno check supabase/functions/*/index.ts
supabase migration list
supabase db diff --from migrations --to linked --schema public
supabase functions list
supabase secrets list
```

배포가 필요한 경우:

```bash
supabase db push
supabase functions deploy --use-api --jobs 1
```

`db push`는 운영 DB 변경이므로 functions 배포보다 더 조심해서 실행합니다.
