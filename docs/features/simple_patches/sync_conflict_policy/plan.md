# Sync Conflict Policy Plan

## Product Goal

여러 기기 같은 자산, 보유 종목, 현금 계좌, 거래 이벤트/라인 수정 시 어떤 변경이 원격 상태 되는지 명확히 고정.

## Current Baseline

- 로컬 core sync row에 `client_id`, `dirty`, `last_modified_at`, `deleted_at` 있음.
- 기존 payload는 `last_modified_at` 서버 전송 안 함. Edge Function은 `user_id + client_id` upsert로 마지막 도착 payload가 덮어씀.
- 앱은 push 성공 후 payload 전체 dirty 해제.

## Success Criteria

- remote core sync table이 `last_modified_at` 저장.
- push payload와 pull payload가 `last_modified_at` 포함.
- 서버는 row별 incoming timestamp와 server timestamp 비교.
- incoming이 더 최신이거나 같으면 client change 수락.
- server가 더 최신이면 server wins. push 거절, conflict 반환.
- 앱은 서버 수락 row만 dirty 해제.

## Policy

정책은 `last_modified_at` 기반 last-writer-wins.

| Case | Winner |
| --- | --- |
| New server row | Client |
| Server timestamp missing | Client |
| Client timestamp newer | Client |
| Equal timestamp | Client |
| Server timestamp newer | Server |

동일 timestamp는 재시도 idempotency 위해 client wins.

## Data/API Changes

- `assets`, `holdings`, `cash_accounts`, `transaction_events`, `transaction_lines`에 remote `last_modified_at timestamptz` 추가.
- `sync-local-db` 응답에 `accepted_client_ids`, `conflict_count`, `conflicts` 추가.
- 기존 payload version은 `4` 유지. 필드 추가는 optional-compatible 처리.

## Test Plan

- Dirty payload가 `last_modified_at` 포함 확인.
- 서버 수락 client id만 local dirty 해제 확인.
- Deno check로 Edge Function type contract 확인.
- Flutter targeted test로 local sync payload/dirty 처리 회귀 확인.

## Risks And Decisions

- `last_modified_at`은 클라이언트 시계 의존. 현재는 local-first UX와 오프라인 수정 우선, 클라이언트 timestamp를 충돌 기준 사용.
- clock skew 큰 기기에서는 오래된 변경이 최신 판정될 수 있음. 추후 server revision 또는 vector clock 필요 시 별도 설계로 확장.