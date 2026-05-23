# `supabase/` Guide

이 폴더는 MONEYFY의 Supabase 구성을 담습니다. Flutter 앱이 호출하는 Edge Functions와 원격 Postgres schema migration이 이곳에 있습니다.

## Layout

| 경로 | 역할 |
| --- | --- |
| `config.toml` | 로컬 Supabase CLI stack 설정 |
| `migrations/` | 현재 schema 변경 이력 |
| `migrations_archive/` | 과거 migration 보관 |
| `functions/` | Deno Edge Functions |
| `.temp/` | CLI 링크 메타데이터. git 관리 대상이 아닙니다. |

## Linked Project

로컬 메타데이터 기준 연결된 프로젝트:

```text
project ref: oeweumxfabobwlhzrzqk
project name: Moneyfi
```

원격 확인과 배포 절차는 `docs/supabase_cli_runbook.md`를 따릅니다.

## Function Groups

| 그룹 | 함수 |
| --- | --- |
| 동기화 | `sync-local-db`, `get-sync-local-db` |
| 스냅샷 | `create-portfolio-snapshot`, `get-portfolio-snapshots` |
| 시세 | `update-holding-prices` |
| 뉴스 수집 | `fetch-market-news`, `fetch-company-news` |
| 뉴스 요약 | `summarize-market-news`, `summarize-company-news`, `get-market-news-summary`, `get-user-company-news-summaries` |
| AI 진단 | `get-portfolio-diagnosis` |

## Common Commands

```bash
supabase migration list
supabase db diff --from migrations --to linked --schema public
supabase functions list
supabase secrets list
deno check supabase/functions/*/index.ts
deno fmt --check supabase/functions
```

## Safety Notes

- 실제 secret 값은 이 저장소에 쓰지 않습니다.
- `SUPABASE_SERVICE_ROLE_KEY`는 Flutter 앱에 넣지 않습니다.
- DB 변경은 기존 migration 수정이 아니라 새 migration 추가를 기본으로 합니다.
- Edge Function에서 service role을 쓰는 경우 bearer token의 user id 검증과 `user_id` scope 제한을 반드시 확인합니다.
