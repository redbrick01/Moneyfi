# Edge Function Auth Hardening Plan

## Product Goal

Edge Function: JWT payload 직접 decode해 `sub` 신뢰하던 auth → Supabase Auth `getUser()` 검증 기반.

## Current Baseline

- `sync-local-db`, `get-sync-local-db`, `get-portfolio-snapshots`, `create-portfolio-snapshot`, `fetch-company-news`, `get-user-company-news-summaries`: `decodeJwtSub`로 payload 읽음.
- 일부 함수: body/query `user_id` fallback 허용 → 사용자 scope 우회 가능.
- DB 작업은 service role client. 함수 내부 auth + `user_id` scope 제한이 보안 경계.

## Success Criteria

- Edge Function 사용자 식별: `supabase.auth.getUser()` 반환 user id만 사용.
- 잘못된 token, 누락 token, 만료 token → 401.
- Auth 검증 env 없음 → 500.
- 입력 `user_id` != 인증 사용자 → 403.
- service role client는 DB 작업 전용. auth 검증은 anon client.

## Data/API Changes

- DB schema 변경 없음.
- `SUPABASE_ANON_KEY`: auth verification 필수 secret.
- `get-portfolio-snapshots`, `create-portfolio-snapshot` `user_id` body/query: 인증 사용자와 일치할 때만 허용.

## Development Phases

1. 기존 `decodeJwtSub` 사용처 + 함수별 scope 규칙 확인
2. 공통 auth helper 추가
3. 각 Edge Function auth 흐름을 `authenticateUser`로 교체
4. 사용자 scope fallback 제거 또는 일치 검증 추가
5. Deno type check + 검색 기반 검증 수행

## Test Plan

- `rg`로 `decodeJwtSub` 잔여 사용 없음 확인.
- `deno check`로 변경 Edge Function TypeScript 확인.
- 수동 QA: 정상 로그인 token, 누락 token, 잘못된 token, 다른 `user_id` 요청 확인.

## Risks And Decisions

- `create-portfolio-snapshot` 기존 전체 사용자 fallback 제거. service role 함수가 사용자 데이터 처리하므로 인증 사용자 1명만 처리가 보안 기준 적합.
- `fetch-company-news`: 인증 사용자 holdings만 대상. 전체 holdings 수집 필요 시 별도 cron secret 또는 운영자 전용 경로 설계 필요.