import { readFile } from 'node:fs/promises';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const fields = {
  request_id: {type:'string', description:'변경 요청별 고유 ID(8~128자). 재시도에는 같은 ID와 같은 인수를 사용합니다.'},
  holding_id: {type:'integer', description:'list_assets에서 받은 ID. 종목 양수, 현금 계좌 음수.'},
  source_holding_id: {type:'integer'}, target_holding_id: {type:'integer'},
  event_id: {type:'integer', minimum:1}, date: {type:'string', pattern:'^\\d{4}-\\d{2}-\\d{2}$'},
  name: {type:'string'}, type: {type:'string',enum:['매수','매도','입금','출금','배당','이자']},
  amount: {type:'number',exclusiveMinimum:0,description:'매수/매도는 해당 통화의 주당 단가. 나머지는 총금액. 이체/환전은 출금액.'},
  quantity: {type:'number',exclusiveMinimum:0,description:'매수/매도 수량'},
  fx_rate: {type:'number',exclusiveMinimum:0,description:'1 USD당 KRW. USD 매수 및 환전에 필요.'},
  limit: {type:'integer',minimum:1,maximum:100,default:20},
};
const definitions = [
  ['list_assets','실행 중인 MONEYFY 앱의 자산·보유 종목·현금 계좌와 ID 조회',[],[]],
  ['list_recent_transactions','실행 중인 앱의 최근 거래와 수정/삭제용 event_id 조회',['limit'],[]],
  ['create_transaction','매수·매도·입금·출금·배당·이자 기록을 앱에 저장하고 Supabase로 동기화합니다. 수량·현금·평단은 앱 규칙으로 계산됩니다.',['request_id','holding_id','date','type','name','amount','quantity','fx_rate'],['request_id','holding_id','date','type','name','amount']],
  ['transfer_cash','같은 통화의 현금 계좌 사이 이체 기록. 출금·입금 함께 처리 후 Supabase 동기화.',['request_id','source_holding_id','target_holding_id','date','name','amount'],['request_id','source_holding_id','target_holding_id','date','name','amount']],
  ['exchange_cash','KRW/USD 환전 기록. 상대 통화 계좌는 앱 규칙으로 선택/생성됩니다.',['request_id','source_holding_id','date','name','amount','fx_rate'],['request_id','source_holding_id','date','name','amount','fx_rate']],
  ['update_transaction','기존 거래의 날짜·제목·단가/금액·수량·환율 수정. event_id는 목록에서 확인하세요. 거래 유형과 계좌 변경은 삭제 후 새 거래로 기록합니다.',['request_id','event_id','date','name','amount','quantity','fx_rate'],['request_id','event_id']],
  ['delete_transaction','event_id에 해당하는 전체 거래 삭제. 이체/환전은 양쪽 내역을 함께 삭제하고 잔고 재계산 후 Supabase 동기화.',['request_id','event_id'],['request_id','event_id']],
  ['retry_sync','로컬 저장됐으나 Supabase 미반영인 요청의 동기화 재시도. 원래 request_id를 사용하고 새 거래를 생성하지 마세요.',['request_id'],['request_id']],
];
const tools = definitions.map(([name,description,keys,required]) => ({name,description,inputSchema:{type:'object',properties:Object.fromEntries(keys.map(k=>[k,fields[k]])),required,additionalProperties:false},annotations:{readOnlyHint:name.startsWith('list_'),destructiveHint:name.startsWith('delete_')||name.startsWith('update_'),idempotentHint:true,openWorldHint:true}}));
async function call(name, args) {
  const definition = tools.find(t=>t.name===name);
  if (!definition) throw new Error('알 수 없는 도구입니다.');
  if (!args || typeof args!=='object' || Array.isArray(args)) throw new Error('인수가 올바르지 않습니다.');
  for (const key of Object.keys(args)) if (!(key in definition.inputSchema.properties)) throw new Error(`지원하지 않는 인수: ${key}`);
  for (const key of definition.inputSchema.required) if (!(key in args)) throw new Error(`필수 인수: ${key}`);
  let config;
  try { config=JSON.parse(await readFile(`${root}/tools/moneyfy-mcp/.bridge.json`,'utf8')); }
  catch { throw new Error('터미널에서 node tools/moneyfy-mcp/start.mjs 를 실행하고 MONEYFY 앱에서 로그인하세요.'); }
  // Never send the local bridge credential to an arbitrary host.
  const res=await fetch('http://127.0.0.1:47831/mcp',{method:'POST',headers:{Authorization:`Bearer ${config.token}`,'Content-Type':'application/json'},body:JSON.stringify({operation:name,arguments:args}),signal:AbortSignal.timeout(120000)});
  const result=await res.json();
  if (!res.ok) throw new Error(result.error ?? `MONEYFY 오류 ${res.status}`);
  return result;
}
function send(obj) { process.stdout.write(JSON.stringify(obj)+'\n'); }
const rl=createInterface({input:process.stdin,crlfDelay:Infinity});
rl.on('line',async line=>{
  let msg;
  try {msg=JSON.parse(line);}catch {return send({jsonrpc:'2.0',id:null,error:{code:-32700,message:'Parse error'}});}
  if (!msg || typeof msg!=='object' || Array.isArray(msg)) return send({jsonrpc:'2.0',id:null,error:{code:-32600,message:'Invalid request'}});
  if (msg.id===undefined) return;
  let result;
  if (msg.method==='initialize') result={protocolVersion:msg.params?.protocolVersion??'2025-03-26',capabilities:{tools:{}},serverInfo:{name:'moneyfy',version:'0.2.0'}};
  else if (msg.method==='ping') result={};
  else if (msg.method==='tools/list') result={tools};
  else if (msg.method==='tools/call') {
    try {result={content:[{type:'text',text:JSON.stringify(await call(msg.params?.name,msg.params?.arguments??{}))}]};}
    catch(e) {result={isError:true,content:[{type:'text',text:`${e.message}. 변경 요청이 시간 초과됐다면 원래 request_id로 retry_sync를 호출해 결과를 확인하세요.`}]};}
  } else return send({jsonrpc:'2.0',id:msg.id,error:{code:-32601,message:'Method not found'}});
  send({jsonrpc:'2.0',id:msg.id,result});
});
