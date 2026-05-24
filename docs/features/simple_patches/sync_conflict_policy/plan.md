# Sync Conflict Policy Plan

## Product Goal

여러 기기에서 같은 자산, 보유 종목, 현금 계좌, 거래 이벤트/라인을 수정했을 때 어떤 변경이 원격 상태가 되는지 명확히 고정합니다.

## Current Baseline

- 로컬 core sync row에는 `client_id`, `dirty`, `last_modified_at`, `deleted_at`이 있습니다.
- 기존 payload는 `last_modified_at`을 서버로 보내지 않았고, Edge Function은 `user_id + client_id` upsert로 마지막 도착 payload를 덮어썼습니다.
- 앱은 push 성공 후 payload 전체 dirty를 해제했습니다.

## Success Criteria

- remote core sync table이 `last_modified_at`을 저장합니다.
- push payload와 pull payload가 `last_modified_at`을 포함합니다.
- 서버는 row별로 incoming timestamp와 server timestamp를 비교합니다.
- incoming이 더 최신이거나 같으면 client change를 수락합니다.
- server가 더 최신이면 server wins로 push를 거절하고 conflict로 반환합니다.
- 앱은 서버가 수락한 row만 dirty 해제합니다.

## Policy

정책은 `last_modified_at` 기반 last-writer-wins입니다.

| Case | Winner |
| --- | --- |
| New server row | Client |
| Server timestamp missing | Client |
| Client timestamp newer | Client |
| Equal timestamp | Client |
| Server timestamp newer | Server |

동일 timestamp는 재시도 idempotency를 위해 client wins로 둡니다.

## Data/API Changes

- `assets`, `holdings`, `cash_accounts`, `transaction_events`, `transaction_lines`에 remote `last_modified_at timestamptz`를 추가합니다.
- `sync-local-db` 응답에 `accepted_client_ids`, `conflict_count`, `conflicts`를 추가합니다.
- 기존 payload version은 `4`를 유지합니다. 필드 추가는 optional-compatible로 처리합니다.

## Test Plan

- Dirty payload가 `last_modified_at`을 포함하는지 확인합니다.
- 서버가 수락한 client id만 local dirty 해제하는지 확인합니다.
- Deno check로 Edge Function type contract를 확인합니다.
- Flutter targeted test로 local sync payload/dirty 처리 회귀를 확인합니다.

## Risks And Decisions

- `last_modified_at`은 클라이언트 시계에 의존합니다. 현재는 local-first UX와 오프라인 수정을 우선해 클라이언트 timestamp를 충돌 기준으로 삼습니다.
- clock skew가 큰 기기에서는 의도보다 오래된 변경이 최신으로 판정될 수 있습니다. 추후 server revision 또는 vector clock이 필요하면 별도 설계로 확장합니다.
