# Supabase RLS And Grants Hardening Plan

## Product Goal

원격 Supabase DB `anon`/`authenticated` 권한 + RLS policy 조합 실제 상태 기준 점검. 앱 불필요 직접 DB 접근 권한 제거.

## Current Baseline

- 앱은 Supabase 테이블 직접 호출 안 함. Edge Functions 통해 sync, snapshot, news, diagnosis 데이터 조회/쓰기.
- 원격 DB public 테이블 전체 RLS 켜짐.
- 원격 DB 여러 사용자 데이터 테이블 + snapshot/ledger 테이블에 `anon`/`authenticated` `ALL` 권한 남음.
- 원격 DB public sequence `USAGE` 권한 + `set_updated_at()` 함수 `EXECUTE` 권한도 `anon`/`authenticated`에 남음.

## Success Criteria

- `anon`/`authenticated`는 공개 읽기 데이터 테이블에만 `SELECT` 권한 보유.
- 사용자 데이터, snapshot, ledger, diagnosis, token 테이블은 client role direct grant 없음.
- public sequence + internal trigger/helper function에 `anon`/`authenticated` 권한 없음.
- 사용자 row RLS policy는 `authenticated` role로 제한.
- 공개 읽기 테이블은 `anon, authenticated` 대상 `SELECT using (true)` policy만 유지.

## Data/API Changes

- DB schema shape + 데이터 변경 없음.
- client role grants + RLS policy role 범위만 변경.
- Edge Functions는 service role client 사용. 기존 앱 API 호출 경로 유지.

## Development Phases

1. 원격 migration 상태 확인
2. 원격 `information_schema`/`pg_catalog` 기준 grant, sequence, function, RLS, policy 조회
3. 최소 권한 migration 작성
4. 원격 적용
5. 적용 후 원격 카탈로그 재조회로 검증

## Test Plan

- `supabase migration list`
- `supabase db query --linked`로 table grants, sequence grants, function grants, RLS policies 재조회
- 앱 smoke 대상 Edge Function은 service role 경로 유지 여부 확인

## Risks And Decisions

- Flutter 앱 직접 `.from()`/`.rpc()` 미사용 확인. 사용자 데이터 direct DB grant 제거.
- 공개 뉴스/환율 테이블은 기존 문서화된 공개 읽기 의도 유지. `SELECT`만 남김.
- 향후 앱이 직접 Supabase table API 쓰면 별도 migration으로 필요한 테이블/operation만 명시적으로 열기.