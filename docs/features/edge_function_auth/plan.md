# Edge Function Auth Hardening Plan

## Product Goal

Edge Function이 Authorization bearer token의 JWT payload를 직접 decode해 `sub`만 신뢰하던 구조를 Supabase Auth의 `getUser()` 검증 기반으로 변경합니다.

## Current Baseline

- `sync-local-db`, `get-sync-local-db`, `get-portfolio-snapshots`, `create-portfolio-snapshot`, `fetch-company-news`, `get-user-company-news-summaries`가 `decodeJwtSub`로 payload를 읽었습니다.
- 일부 함수는 body 또는 query의 `user_id`를 fallback으로 받아 사용자 범위 우회 가능성이 있었습니다.
- DB 작업은 service role client로 수행하므로 함수 내부의 사용자 인증과 `user_id` scope 제한이 보안 경계입니다.

## Success Criteria

- Edge Function 내부에서 사용자 식별은 `supabase.auth.getUser()`가 반환한 user id만 사용합니다.
- 잘못된 token, 누락된 token, 만료된 token은 401 응답을 반환합니다.
- Auth 검증에 필요한 env가 없으면 500으로 실패합니다.
- `user_id` 입력이 인증 사용자와 다르면 403으로 실패합니다.
- service role client는 DB 작업에만 사용하고 인증 검증에는 anon client를 사용합니다.

## Data/API Changes

- DB schema 변경은 없습니다.
- `SUPABASE_ANON_KEY`가 auth verification 필수 secret으로 사용됩니다.
- `get-portfolio-snapshots`와 `create-portfolio-snapshot`의 `user_id` body/query는 인증 사용자와 일치할 때만 허용됩니다.

## Development Phases

1. 기존 `decodeJwtSub` 사용처와 함수별 scope 규칙 확인
2. 공통 auth helper 추가
3. 각 Edge Function의 인증 흐름을 `authenticateUser`로 교체
4. 사용자 scope fallback 제거 또는 일치 검증 추가
5. Deno type check와 검색 기반 검증 수행

## Test Plan

- `rg`로 `decodeJwtSub` 잔여 사용이 없는지 확인합니다.
- `deno check`로 변경된 Edge Function TypeScript를 확인합니다.
- 수동 QA 시 정상 로그인 token, 누락 token, 잘못된 token, 다른 `user_id` 요청을 확인합니다.

## Risks And Decisions

- `create-portfolio-snapshot`의 기존 전체 사용자 fallback은 제거합니다. service role 함수가 사용자 데이터를 처리하므로 인증 사용자 1명만 처리하는 쪽이 보안 기준에 맞습니다.
- `fetch-company-news`는 인증 사용자의 holdings만 대상으로 제한합니다. 전체 holdings 기반 수집이 필요하면 별도의 cron secret 또는 운영자 전용 경로를 설계해야 합니다.
