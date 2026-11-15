import { randomBytes } from 'node:crypto';
import { writeFile, chmod } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
const root=fileURLToPath(new URL('../../',import.meta.url));
// Preserve the active app's credential when accidentally launching twice.
const busy=await new Promise(resolve=>{const s=net.connect(47831,'127.0.0.1');s.once('connect',()=>{s.destroy();resolve(true);});s.once('error',()=>resolve(false));});
if (busy) {console.error('47831 포트가 이미 사용 중입니다. 실행 중인 MONEYFY MCP 앱을 먼저 종료하세요.');process.exit(1);}
const token=randomBytes(32).toString('hex');
const path=`${root}/tools/moneyfy-mcp/.bridge.json`;
await writeFile(path,JSON.stringify({token}),{mode:0o600});
await chmod(path,0o600);
console.log('MONEYFY MCP 모드로 앱을 실행합니다. 앱에서 로그인하고 초기 동기화가 끝난 뒤 코덱스를 사용하세요.');
const app=spawn('flutter',['run','-d','macos',`--dart-define=MONEYFY_MCP_TOKEN=${token}`],{cwd:root,stdio:'inherit'});
app.on('error',()=>{console.error('flutter를 실행하지 못했습니다. Flutter 설치와 PATH를 확인하세요.');process.exitCode=1;});
app.on('exit',code=>{process.exitCode=code??1;});
