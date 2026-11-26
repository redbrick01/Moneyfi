# MONEYFY 개인용 MCP

이 Mac에서 실행 중인 MONEYFY 앱을 통해 자산·거래를 조회하고 변경합니다. 변경은 앱의 기존 거래 처리 함수로 계산한 뒤 로그인된 계정의 Supabase에 동기화합니다. 별도 서버 배포나 서비스 역할 키는 필요하지 않습니다.

## 시작

이 Mac에 설치해 사용할 때는 바탕화면의 `Moneyfy 배포.command`를 실행합니다. 설치된 `~/Applications/Moneyfy.app`을 아이콘으로 열면 로컬 브리지가 함께 시작됩니다. 기존 `moneyfy` MCP 등록을 그대로 사용하고, 앱에 로그인한 뒤 초기 데이터가 준비되면 조회할 수 있습니다.

### 개발 빌드에서 실행

Node.js 18 이상, Flutter, macOS 개발 환경과 기존 `assets/config.json`이 필요합니다.

1. 기존 MONEYFY 앱을 종료합니다.
2. 프로젝트 폴더에서 다음 명령으로 앱을 실행합니다.
   ```bash
   node tools/moneyfy-mcp/start.mjs
   ```
3. 열린 MONEYFY 앱에서 로그인하고 초기 데이터 로딩이 끝날 때까지 기다립니다. 이 터미널과 앱은 사용하는 동안 열어 둡니다.
4. 코덱스에 등록된 `moneyfy` MCP를 다시 로드하거나 새 대화를 시작합니다. 미등록 상태라면 다음 명령을 실행합니다.
   ```bash
   codex mcp add moneyfy -- "$(command -v node)" "$PWD/tools/moneyfy-mcp/server.mjs"
   ```
5. “MONEYFY 자산을 조회해 줘” 또는 “삼성전자 10주를 주당 6만 원에 매수한 걸 기록해 줘”라고 요청합니다. 없는 종목이나 계좌는 앱에서 먼저 만듭니다.

이 버전은 앱의 로그인 세션을 사용합니다. 이전 버전의 `login.mjs`는 필요하지 않습니다. 이전 `.session.json` 파일이 있으면 삭제해도 됩니다.

## 도구와 금액 규칙

- `get_status`: 브리지 연결, 로그인, 데이터 준비, 동기화 진행, 미반영 변경 여부를 조회합니다. 브리지에서 응답을 받지 못하면 앱과 로그인 상태는 확인 불가(`null`)입니다.
- `get_request_status`: `request_id`의 저장·동기화 상태를 조회합니다. 상태는 `not_found`, `pending`, `synced`, `unverified`, `invalidated`입니다. 상태를 조회해도 거래 저장이나 동기화 재시도가 실행되지 않습니다.
- `search_transactions`: `from_date`, `to_date`(양끝 포함), `asset_id`, `holding_id`, `symbol`, `transaction_type`으로 검색합니다. 날짜·이벤트 ID 내림차순이며, 다음 페이지는 같은 필터에 `next_offset`을 `offset`으로 전달합니다. 계좌 필터는 `list_assets`에서 받은 음수 ID를 사용합니다.
- `get_transaction`: `event_id`로 거래 한 건과 연결된 원장 행 전체를 조회합니다. 이체·환전은 양쪽 행을 반환하며, `cash_delta`는 각 행 통화로 표시한 증감액입니다.
- `get_portfolio_summary`: `as_of` 날짜의 저장된 스냅샷을 조회합니다. 생략하면 최신 스냅샷, 지정 날짜의 기록이 없으면 `found: false`를 반환합니다. 총자산, 현금 계좌별 잔액, 종목·통화별 평가 비중, 스냅샷 생성 시각, USD/KRW 환율을 포함합니다. 수익률은 `from_date`부터 기준일까지 일별 수익률을 복리로 계산하며 기본 기간은 기준일을 포함한 30일입니다. `complete: false`이면 계산 가능한 일만 반영됐거나 대체 환율이 적용된 경우입니다. 수익률과 비중의 `ratio` 필드에서 0.1은 10%입니다.
- `preview_transaction`: `operation`에 거래 도구 이름, `arguments`에 해당 도구의 인수를 넣습니다. 예를 들어 `{"operation":"update_transaction","arguments":{"event_id":123,"amount":20000}}`으로 수정 전후 거래와 예상 잔액·수량을 비교할 수 있습니다. 미리보기에는 `request_id`가 필요 없습니다.
- `get_data_issues`: 중복 거래 후보, 시세·환율의 누락·노후화, 미동기화 거래를 조회합니다. `from_date`와 `to_date`는 거래에 적용하고, 시세·환율은 현재 시각으로부터 `stale_after_days`일을 기준으로 점검합니다(기본 7일). 같은 날 같은 유형에서 원장 행이 일치하는 거래를 중복 후보로 묶으므로 실제 중복 여부는 거래 상세에서 확인할 수 있습니다.
- `list_assets`: 자산·종목·현금 계좌와 로컬 ID 조회. 종목 ID는 양수, 현금 계좌 ID는 음수입니다.
- `list_recent_transactions`: 날짜순 최대 100개 거래 행과 수정/삭제용 event_id 조회. 이체/환전은 같은 event_id에 양쪽 행이 있습니다.
- `create_transaction`: 매수·매도·입금·출금·배당·이자 기록. 매수/매도의 amount는 종목 통화의 **주당 단가**, quantity는 수량입니다. 나머지 amount는 총금액입니다. USD 매수에는 1 USD당 KRW 환율인 fx_rate가 필요합니다.
- `transfer_cash`: 같은 통화의 현금 계좌 간 이체. amount는 출금액입니다.
- `exchange_cash`: KRW/USD 환전. amount는 출금 통화 금액, fx_rate는 1 USD당 KRW입니다. 상대 통화 계좌는 앱 규칙으로 선택하거나 생성합니다.
- `update_transaction`: 거래의 날짜, 제목, 단가/금액, 수량, 환율 수정. MONEYFY 앱의 확인 창에서 변경 전후를 검토하고 60초 안에 승인해야 적용됩니다. 응답의 `event_id`가 새 거래 ID입니다. 환율은 환전과 USD 매수에, 수량은 수량이 있는 종목 거래에 적용할 수 있습니다.
- `delete_transaction`: MONEYFY 앱의 확인 창에서 승인한 거래 전체를 삭제합니다. 이체·환전의 두 행도 함께 처리합니다. 취소·시간 초과 또는 승인 대기 중 잔액이나 거래가 바뀌면 요청을 적용하지 않습니다.
- `create_holding`, `create_cash_account`: `asset_id`, 이름, 통화(KRW 또는 USD)를 지정해 기존 자산 그룹에 수량이나 잔액이 0인 종목·계좌를 추가합니다. 종목은 `symbol`과 `exchange_code`도 지정할 수 있습니다. 같은 그룹과 통화에 같은 이름이나 티커가 있으면 기존 ID를 안내합니다. 초기 수량은 매수, 잔액은 입금 등 거래로 기록할 수 있습니다.
- `retry_sync`: 로컬 저장은 됐지만 Supabase 동기화가 확인되지 않은 요청을 원래 request_id로 재시도합니다.

모든 변경에는 8~128자의 영문/숫자/밑줄/하이픈으로 된 고유 request_id가 필요합니다. 재전송할 때는 동일한 ID와 동일한 인수를 유지하세요. DB 트랜잭션에 요청 기록과 변경을 함께 저장해 앱 재실행 후에도 중복을 막습니다. 로그인 계정별로 요청 기록이 분리됩니다.

## 저장 결과

`local_saved: true`는 앱에 저장되었다는 뜻입니다. `supabase_synced: true`는 해당 요청의 원장 이벤트와 거래 행이 모두 동기화 확인을 받은 경우에 반환합니다. 네트워크 단절, 충돌, 부분 수락, 다른 동기화 작업 중에는 false를 반환할 수 있습니다. 이때 새 거래를 생성하지 말고 `retry_sync`를 사용합니다. 거래 생성/수정/삭제가 끝난 뒤 Supabase 동기화가 이루어지므로 동기화 실패가 로컬 변경을 취소하지는 않습니다.

로그인, 앱의 초기 계정 확인, 로컬 데이터 소유자 일치가 모두 확인되어야 접근할 수 있습니다. 로컬 원장을 초기화했거나 이전 버전에서 동기화 완료를 확인할 수 없던 요청은 거래 내역을 확인한 뒤 처리하세요. 앱은 해당 요청 ID를 보존해 재전송으로 거래가 중복되지 않게 합니다. 이 서비스는 127.0.0.1:47831에만 열리고 인증 토큰으로 보호됩니다. 개인 설치용 토큰은 macOS 앱 컨테이너의 `Data/Documents/.moneyfy-mcp-bridge.json`에 사용자 전용 권한으로 저장되며 앱 번들에 포함되지 않습니다. 개발용 `start.mjs`는 별도의 `.bridge.json`을 사용합니다. 개인 설치 스크립트로 빌드하지 않았거나 개발용 설정을 지정하지 않은 앱에서는 브리지가 시작되지 않습니다.

실제 증권사 주문이나 은행 송금은 실행하지 않습니다. 앱의 기존 회계 규칙을 그대로 사용하며, 기존 앱 규칙상 종목의 배당·이자 기록은 현금 계좌를 자동 증가시키지 않습니다. 현금 입금도 기록하려면 별도로 현금 계좌에 입력하세요.
