# Supabase RLS And Grants Hardening Plan

## Product Goal

원격 Supabase DB의 `anon`/`authenticated` 권한과 RLS policy 조합을 실제 상태 기준으로 점검하고, 앱이 필요로 하지 않는 직접 DB 접근 권한을 제거합니다.

## Current Baseline

- 앱은 Supabase 테이블을 직접 호출하지 않고 Edge Functions를 통해 sync, snapshot, news, diagnosis 데이터를 조회/쓰기합니다.
- 원격 DB 조회 결과 public 테이블 전체에 RLS는 켜져 있었습니다.
- 원격 DB 조회 결과 여러 사용자 데이터 테이블과 snapshot/ledger 테이블에 `anon`/`authenticated` `ALL` 권한이 남아 있었습니다.
- 원격 DB 조회 결과 public sequence `USAGE` 권한과 `set_updated_at()` 함수 `EXECUTE` 권한도 `anon`/`authenticated`에 남아 있었습니다.

## Success Criteria

- `anon`/`authenticated`는 공개 읽기 데이터 테이블에만 `SELECT` 권한을 가집니다.
- 사용자 데이터, snapshot, ledger, diagnosis, token 테이블은 client role direct grant를 갖지 않습니다.
- public sequence와 internal trigger/helper function에 대한 `anon`/`authenticated` 권한이 없습니다.
- 사용자 row RLS policy는 `authenticated` role로 제한됩니다.
- 공개 읽기 테이블은 `anon, authenticated` 대상 `SELECT using (true)` policy만 유지합니다.

## Data/API Changes

- DB schema shape와 데이터는 변경하지 않습니다.
- client role grants와 RLS policy role 범위만 변경합니다.
- Edge Functions는 service role client를 사용하므로 기존 앱 API 호출 경로는 유지됩니다.

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

- Flutter 앱이 직접 `.from()`/`.rpc()`를 쓰지 않는 것을 확인했으므로 사용자 데이터 direct DB grant를 제거합니다.
- 공개 뉴스/환율 테이블은 기존 문서화된 공개 읽기 의도를 유지해 `SELECT`만 남깁니다.
- 향후 앱이 직접 Supabase table API를 사용하려면 별도 migration으로 필요한 테이블/operation만 명시적으로 열어야 합니다.
