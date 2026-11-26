import { readFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const fields = {
  request_id: {type:'string', pattern:'^[a-zA-Z0-9_-]{8,128}$', description:'변경 요청별 고유 ID(8~128자). 재시도에는 같은 ID와 같은 인수를 사용합니다.'},
  holding_id: {type:'integer', description:'list_assets에서 받은 ID. 종목 양수, 현금 계좌 음수.'},
  source_holding_id: {type:'integer'}, target_holding_id: {type:'integer'},
  event_id: {type:'integer', minimum:1}, date: {type:'string', pattern:'^\\d{4}-\\d{2}-\\d{2}$'},
  name: {type:'string'}, type: {type:'string',enum:['매수','매도','입금','출금','배당','이자']},
  amount: {type:'number',exclusiveMinimum:0,description:'매수/매도는 해당 통화의 주당 단가. 나머지는 총금액. 이체/환전은 출금액.'},
  quantity: {type:'number',exclusiveMinimum:0,description:'매수/매도 수량'},
  fx_rate: {type:'number',exclusiveMinimum:0,description:'1 USD당 KRW. USD 매수 및 환전에 사용합니다.'},
  limit: {type:'integer',minimum:1,maximum:100,default:20},
  offset: {type:'integer',minimum:0,default:0},
  asset_id: {type:'integer',minimum:1,description:'list_assets에서 받은 자산 그룹 ID'},
  symbol: {type:'string',description:'보유 종목의 티커'},
  from_date: {type:'string',pattern:'^\\d{4}-\\d{2}-\\d{2}$'},
  to_date: {type:'string',pattern:'^\\d{4}-\\d{2}-\\d{2}$'},
  as_of: {type:'string',pattern:'^\\d{4}-\\d{2}-\\d{2}$',description:'스냅샷 기준일. 생략하면 최근 저장일.'},
  transaction_type: {type:'string',enum:['매수','매도','입금','출금','배당','이자','이체','환전','수수료','세금','초기','조정']},
  operation: {type:'string',enum:['create_transaction','transfer_cash','exchange_cash','update_transaction','delete_transaction']},
  arguments: {type:'object',description:'선택한 거래 도구에 전달할 인수. 미리보기에는 request_id가 필요 없습니다.'},
  stale_after_days: {type:'integer',minimum:1,maximum:365,default:7},
  currency: {type:'string',enum:['KRW','USD']},
  exchange_code: {type:'string',description:'예: NAS, NYS, AMS. 해당되는 종목에만 입력합니다.'},
  note: {type:'string'},
};
const definitions = [
  ['get_status','MONEYFY 브리지 연결, 앱 로그인, 데이터 준비, 동기화 진행 및 미반영 변경 여부 확인',[],[]],
  ['get_request_status','이전 변경 요청의 로컬 저장 및 동기화 상태를 request_id로 조회. 변경이나 재시도를 실행하지 않습니다.',['request_id'],['request_id']],
  ['search_transactions','기간, 자산 그룹, 종목·계좌, 티커, 유형으로 원장 거래를 검색합니다. 이체·환전은 양쪽 행을 함께 반환합니다. 다음 페이지는 next_offset을 사용하세요.',['from_date','to_date','asset_id','holding_id','symbol','transaction_type','limit','offset'],[]],
  ['get_transaction','event_id로 전체 거래와 각 원장 행을 조회합니다.',['event_id'],['event_id']],
  ['get_portfolio_summary','스냅샷 기준 총자산, 현금 계좌, 종목·통화 비중, 기간 수익률과 데이터 누락 여부를 조회합니다.',['as_of','from_date'],[]],
  ['preview_transaction','거래 입력·이체·환전·수정·삭제 결과와 예상 잔액·수량을 미리 봅니다. 거래를 저장하지 않습니다.',['operation','arguments'],['operation','arguments']],
  ['get_data_issues','거래 중복 후보, 시세·환율의 누락 또는 오래된 값, 미동기화 거래를 읽기 전용으로 점검합니다.',['from_date','to_date','stale_after_days','limit'],[]],
  ['list_assets','실행 중인 MONEYFY 앱의 자산·보유 종목·현금 계좌와 ID 조회',[],[]],
  ['list_recent_transactions','실행 중인 앱의 최근 거래와 수정/삭제용 event_id 조회',['limit'],[]],
  ['create_transaction','매수·매도·입금·출금·배당·이자 기록을 앱에 저장하고 Supabase로 동기화합니다. 수량·현금·평단은 앱 규칙으로 계산됩니다.',['request_id','holding_id','date','type','name','amount','quantity','fx_rate'],['request_id','holding_id','date','type','name','amount']],
  ['transfer_cash','같은 통화의 현금 계좌 사이 이체 기록. 출금·입금 함께 처리 후 Supabase 동기화.',['request_id','source_holding_id','target_holding_id','date','name','amount'],['request_id','source_holding_id','target_holding_id','date','name','amount']],
  ['exchange_cash','KRW/USD 환전 기록. 상대 통화 계좌는 앱 규칙으로 선택/생성됩니다.',['request_id','source_holding_id','date','name','amount','fx_rate'],['request_id','source_holding_id','date','name','amount','fx_rate']],
  ['update_transaction','기존 거래 수정. MONEYFY 앱에서 변경 내역을 승인해야 적용됩니다. 수정 결과의 event_id는 새 거래 ID입니다.',['request_id','event_id','date','name','amount','quantity','fx_rate'],['request_id','event_id']],
  ['delete_transaction','거래 전체 삭제. MONEYFY 앱에서 승인해야 적용됩니다. 이체·환전은 연결된 양쪽 내역을 함께 처리합니다.',['request_id','event_id'],['request_id','event_id']],
  ['create_holding','기존 자산 그룹에 수량 0인 종목 추가. 중복 이름 또는 티커가 있으면 기존 ID를 반환하는 오류를 냅니다.',['request_id','asset_id','name','currency','symbol','exchange_code','note'],['request_id','asset_id','name','currency']],
  ['create_cash_account','기존 자산 그룹에 잔액 0인 현금 계좌 추가. 이름과 통화가 같은 계좌가 있으면 재사용할 ID를 안내합니다.',['request_id','asset_id','name','currency','note'],['request_id','asset_id','name','currency']],
  ['retry_sync','로컬 저장됐으나 Supabase 미반영인 요청의 동기화 재시도. 원래 request_id를 사용하고 새 거래를 생성하지 마세요.',['request_id'],['request_id']],
];
const tools = definitions.map(([name,description,keys,required]) => ({name,description,inputSchema:{type:'object',properties:Object.fromEntries(keys.map(k=>[k,fields[k]])),required,additionalProperties:false},annotations:{readOnlyHint:name.startsWith('list_')||name.startsWith('get_')||name.startsWith('preview_')||name==='search_transactions',destructiveHint:name.startsWith('delete_')||name.startsWith('update_'),idempotentHint:true,openWorldHint:true}}));
const protocolVersion = '2025-11-25';
const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);

function validateArgs(definition, args, preview = false) {
  if (!isObject(args)) throw new Error('인수가 올바르지 않습니다.');
  const {required, properties} = definition.inputSchema;
  for (const key of required) {
    if (preview && key === 'request_id') continue;
    if (!Object.hasOwn(args, key)) throw new Error('필수 인수: ' + key);
  }
  for (const [key, value] of Object.entries(args)) {
    if (!Object.hasOwn(properties, key)) throw new Error('지원하지 않는 인수: ' + key);
    const field = properties[key];
    const validType = field.type === 'integer'
      ? Number.isSafeInteger(value)
      : field.type === 'number'
        ? Number.isFinite(value)
        : field.type === 'object' ? isObject(value) : typeof value === field.type;
    if (!validType ||
        (field.pattern && !new RegExp(field.pattern).test(value)) ||
        (field.enum && !field.enum.includes(value)) ||
        (field.minimum !== undefined && value < field.minimum) ||
        (field.maximum !== undefined && value > field.maximum) ||
        (field.exclusiveMinimum !== undefined && value <= field.exclusiveMinimum)) {
      throw new Error('올바르지 않은 인수: ' + key);
    }
  }
  if (definition.name === 'preview_transaction') {
    validateArgs(tools.find(tool => tool.name === args.operation), args.arguments, true);
  }
}

async function call(name, args) {
  const configs = [{path: join(root, 'tools/moneyfy-mcp/.bridge.json'), installed: false}];
  if (process.platform === 'darwin') {
    configs.unshift({
      path: join(homedir(), 'Library/Containers/com.example.moneyfy/Data/Documents/.moneyfy-mcp-bridge.json'),
      installed: true,
    });
  }

  const tokens = new Set();
  for (const {path, installed} of configs) {
    const token = await readFile(path, 'utf8')
      .then(contents => JSON.parse(contents)?.token)
      .catch(() => null);
    if (typeof token !== 'string' || token.length < 32) continue;
    if (installed && !/^[a-f0-9]{64}$/.test(token)) continue;
    tokens.add(token);
  }

  for (const token of tokens) {
    const response = await fetch('http://127.0.0.1:47831/mcp', {
      method: 'POST',
      headers: {Authorization: 'Bearer ' + token, 'Content-Type': 'application/json'},
      body: JSON.stringify({operation: name, arguments: args}),
      signal: AbortSignal.timeout(name === 'get_status' ? 3000 : 120000),
    });
    // The bridge rejects credentials before executing an operation.
    if (response.status === 403) {
      await response.body?.cancel();
      continue;
    }
    const result = await response.json();
    if (!response.ok) throw new Error(result.error ?? 'MONEYFY 오류 ' + response.status);
    return result;
  }

  if (name === 'get_status') {
    return bridgeUnavailable(tokens.size ? 'bridge_auth_failed' : 'bridge_config_missing');
  }
  throw new Error('MONEYFY 브리지 설정을 확인할 수 없습니다. 설치된 앱을 열거나 개발용 MCP 모드로 실행하세요.');
}

function bridgeUnavailable(reason) {
  return {
    bridge_connected: reason === 'bridge_timeout' ? null : false,
    app_running: null,
    logged_in: null,
    data_loading: null,
    data_ready: null,
    sync_in_progress: null,
    pending_local_changes: null,
    reason,
  };
}

function send(message) {
  process.stdout.write(JSON.stringify({jsonrpc: '2.0', ...message}) + '\n');
}

function error(id, code, message) {
  send({id, error: {code, message}});
}

let initialized = false;
let initializing = false;
const lines = createInterface({input: process.stdin, crlfDelay: Infinity});
lines.on('line', async line => {
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return error(null, -32700, 'Parse error');
  }
  if (!isObject(msg) || msg.jsonrpc !== '2.0' || typeof msg.method !== 'string' ||
      (msg.id !== undefined && typeof msg.id !== 'string' && !Number.isSafeInteger(msg.id))) {
    return error(null, -32600, 'Invalid request');
  }
  const {id, method, params} = msg;
  if (id === undefined) {
    if (method === 'notifications/initialized' && initializing) initialized = true;
    return;
  }
  if (method === 'initialize') {
    if (initializing || initialized) return error(id, -32600, 'Already initialized');
    if (!isObject(params) || typeof params.protocolVersion !== 'string' ||
        !isObject(params.capabilities) || !isObject(params.clientInfo) ||
        typeof params.clientInfo.name !== 'string' || typeof params.clientInfo.version !== 'string') {
      return error(id, -32602, 'Invalid initialization parameters');
    }
    initializing = true;
    return send({id, result: {
      protocolVersion, capabilities: {tools: {}}, serverInfo: {name: 'moneyfy', version: '0.4.0'},
    }});
  }
  if (method === 'ping') return send({id, result: {}});
  if (!initialized) return error(id, -32000, 'Server not initialized');
  if (method === 'tools/list') return send({id, result: {tools}});
  if (method !== 'tools/call') return error(id, -32601, 'Method not found');

  const tool = tools.find(tool => tool.name === params?.name);
  if (!tool) return error(id, -32602, '알 수 없는 도구입니다.');
  const args = Object.hasOwn(params, 'arguments') ? params.arguments : {};
  let result;
  try {
    validateArgs(tool, args);
    result = {content: [{type: 'text', text: JSON.stringify(await call(tool.name, args))}]};
  } catch (cause) {
    let message = cause.message;
    if (tool.name === 'get_status' && (cause.name === 'TimeoutError' || cause.cause?.code === 'ECONNREFUSED')) {
      const reason = cause.name === 'TimeoutError' ? 'bridge_timeout' : 'bridge_unreachable';
      return send({id, result: {content: [{type: 'text', text: JSON.stringify(bridgeUnavailable(reason))}]}});
    }
    if (cause.name === 'TimeoutError' && !tool.annotations.readOnlyHint && args?.request_id) {
      message = '응답 시간이 초과됐습니다. 원래 request_id로 retry_sync를 호출해 결과를 확인하세요.';
    } else if (cause.cause?.code === 'ECONNREFUSED') {
      message = 'MONEYFY 앱의 브리지에 연결할 수 없습니다. 앱이 MCP 모드로 열려 있는지 확인하세요.';
    }
    result = {isError: true, content: [{type: 'text', text: message}]};
  }
  send({id, result});
});
