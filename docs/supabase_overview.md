# Supabase Overview

이 문서는 MONEYFY의 Supabase 구성을 설명합니다. 로컬 저장소의 `supabase/` 폴더와 CLI로 확인한 원격 상태를 기준으로 작성했으며, 원격 운영 절차는 [Supabase CLI Runbook](supabase_cli_runbook.md)에 따릅니다.

## Linked Project

로컬 CLI 메타데이터와 원격 CLI 조회 기준 현재 프로젝트는 다음과 연결되어 있습니다.

| 항목 | 값 |
| --- | --- |
| Project ref | `oeweumxfabobwlhzrzqk` |
| Project name | `Moneyfi` |
| Dashboard | `https://supabase.com/dashboard/project/oeweumxfabobwlhzrzqk` |
| Local config | `supabase/config.toml` |
| Postgres version metadata | `17.6.1.084` |
| Remote migration status | Local/remote matched through `20260523120000` |
| Remote function status | 12 functions checked, all `ACTIVE` |

`supabase/.temp/`는 CLI가 만든 로컬 상태입니다. project ref 확인에는 유용하지만 git에 올리는 대상은 아닙니다.

## Folder Layout

| 경로 | 설명 |
| --- | --- |
| `supabase/config.toml` | 로컬 Supabase stack 포트, Auth, Storage, DB 설정 |
| `supabase/migrations/` | 현재 schema 변경 이력 |
| `supabase/migrations_archive/` | 과거 migration 보관본 |
| `supabase/functions/` | Deno Edge Functions |

## Current Migration Story

2026-05-23 기준 `supabase migration list`에서 로컬과 원격 migration은 `20260523120000`까지 일치합니다. 현재 migration 흐름은 크게 네 단계로 볼 수 있습니다.

1. `20260521043000_baseline_remote_schema.sql`
   원격 schema baseline입니다.
2. `20260521050000_harden_public_permissions.sql`
   public table RLS와 read policy를 정리합니다.
3. `20260522090000`부터 `20260522153000`까지
   transaction amount 정규화, ledger table 생성, legacy transaction table archive/drop, 스냅샷 기반 복원과 ledger 재생성을 수행합니다.
4. `20260523001000`, `20260523120000`
   history 표시용 ledger 복원과 스냅샷 상세 row의 client reference를 추가합니다.

현재 핵심 remote schema는 `assets`, `holdings`, `cash_accounts`, `transaction_events`, `transaction_lines`, `daily_portfolio_snapshots` 계열 테이블을 중심으로 이해하면 됩니다.

## Edge Functions

| 함수 | 역할 | 주요 외부 의존성 |
| --- | --- | --- |
| `sync-local-db` | 앱 dirty payload를 Supabase DB에 upsert | Supabase service role |
| `get-sync-local-db` | 사용자 core data를 ledger-only payload로 반환 | Supabase service role |
| `create-portfolio-snapshot` | 서버에서 특정 사용자의 포트폴리오 스냅샷 생성 | 환율 API 선택 |
| `get-portfolio-snapshots` | 사용자 스냅샷과 상세 row 조회 | Supabase service role |
| `update-holding-prices` | 원격 holdings 가격 갱신 | KIS, Coinone template |
| `fetch-market-news` | 시장 뉴스 수집 | Finnhub |
| `fetch-company-news` | 보유 종목 뉴스 수집 | Finnhub |
| `summarize-market-news` | 시장 뉴스 요약 생성 | OpenAI |
| `summarize-company-news` | 종목 뉴스 요약 생성 | OpenAI |
| `get-market-news-summary` | 저장된 시장 뉴스 요약 조회 | Supabase service role |
| `get-user-company-news-summaries` | 사용자 보유 종목 기준 뉴스 요약 조회 | Supabase service role |
| `get-portfolio-diagnosis` | 포트폴리오 진단 생성/캐시 조회 | OpenAI |

2026-05-23 기준 `supabase functions list`에서 위 12개 함수는 모두 `ACTIVE` 상태입니다. 최근 배포 시각은 동기화 함수가 2026-05-22 14:43:37 UTC, 스냅샷 함수가 2026-05-23 01:26:51 UTC로 확인되었습니다.

## Auth And Authorization

앱은 `assets/config.json`의 `SUPABASE_URL`, `SUPABASE_ANON_KEY`로 Supabase SDK를 초기화합니다. 사용자 로그인은 Supabase Auth email/password 흐름입니다.

사용자 데이터에 접근하는 Edge Functions는 Authorization bearer token을 `SUPABASE_ANON_KEY` 기반 client로 `supabase.auth.getUser()` 검증한 뒤, 검증된 user id만 DB scope에 사용합니다. DB 작업은 service role client로 수행하되, 함수 내부에서 `user_id`를 인증 사용자로 제한해야 합니다. body/query의 `user_id`를 받을 때도 인증 사용자와 일치하는지 확인해야 합니다.

Client role DB grants는 최소 권한으로 유지합니다. `anon`/`authenticated`는 공개 읽기 데이터인 `company_news`, `company_news_summaries`, `exchange_rates`, `market_news`, `market_news_summaries`에만 `SELECT`를 가집니다. 사용자 데이터, snapshot, ledger, diagnosis, token 테이블은 Edge Function service role 경로로만 접근합니다.

## Secrets

문서에는 실제 secret 값을 기록하지 않습니다. 이름만 관리합니다.

필수 또는 주요 secret:

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

## Local Supabase Defaults

`supabase/config.toml` 기준 주요 로컬 포트입니다.

| 서비스 | 포트 |
| --- | --- |
| API | `54321` |
| DB | `54322` |
| Studio | `54323` |
| Inbucket | `54324` |
| Shadow DB | `54320` |

Auth signup은 켜져 있고, email confirmation 설정은 로컬 기본값을 따릅니다. Storage와 Realtime도 로컬에서 enabled 상태입니다.

## Remote Verification

원격 현재 상태를 확인할 때는 아래 순서로 봅니다.

```bash
supabase migration list
supabase db diff --from migrations --to linked --schema public
supabase functions list
supabase secrets list
```

이 명령들은 로그인 토큰과 네트워크가 필요합니다. 출력에 secret 값은 나오지 않지만, 작업 로그나 문서에 토큰과 키를 남기지 않아야 합니다.

## Change Rules

- DB 변경은 새 migration으로 남깁니다.
- Flutter local DB만 바꾸지 말고 Supabase remote schema와 동기화 payload도 함께 확인합니다.
- service role key는 Edge Function과 운영 환경에만 둡니다.
- 읽기 함수라도 사용자 id를 받는 경우 bearer token 기반 사용자 검증을 우선합니다.
- legacy archive migration은 복구 맥락이 있으므로 임의로 삭제하지 않습니다.
