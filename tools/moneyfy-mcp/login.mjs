import { readFile, writeFile, chmod } from 'node:fs/promises';
import { createInterface } from 'node:readline/promises';
import { stdin, stdout } from 'node:process';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
if (!stdin.isTTY) { console.error('터미널에서 직접 실행하세요.'); process.exit(1); }
const rl = createInterface({input: stdin, output: stdout});
try {
  const config = JSON.parse(await readFile(`${root}/assets/config.json`, 'utf8'));
  const url = new URL(config.SUPABASE_URL);
  if (url.protocol !== 'https:' || !url.hostname.endsWith('.supabase.co')) throw new Error('안전한 Supabase 프로젝트 URL이 필요합니다.');
  const email = await rl.question('MONEYFY 이메일: ');
  stdout.write('MONEYFY 비밀번호 (화면에 표시되지 않음): ');
  rl.close();
  const password = await new Promise((resolve, reject) => {
    let value = ''; stdin.setRawMode(true); stdin.resume(); stdin.setEncoding('utf8');
    function done() { stdin.setRawMode(false); stdin.pause(); stdin.removeListener('data', onData); stdout.write('\n'); }
    function onData(chunk) { for (const c of chunk) { if (c === '\u0003') { done(); reject(new Error('취소됨')); return; } if (c === '\r' || c === '\n') { done(); resolve(value); return; } if (c === '\u007f' || c === '\b') value = value.slice(0,-1); else value += c; } }
    stdin.on('data', onData);
  });
  const response = await fetch(new URL('/auth/v1/token?grant_type=password', url), {method:'POST',headers:{apikey:config.SUPABASE_ANON_KEY,'Content-Type':'application/json'},body:JSON.stringify({email,password})});
  if (!response.ok) throw new Error(`로그인 실패 (HTTP ${response.status}). 이메일과 비밀번호를 확인하세요.`);
  const result = await response.json();
  if (!result.access_token) throw new Error('로그인 토큰을 받지 못했습니다.');
  const path = `${root}/tools/moneyfy-mcp/.session.json`;
  await writeFile(path, JSON.stringify({access_token:result.access_token}), {mode:0o600});
  await chmod(path, 0o600);
  console.log('로그인 완료. 토큰이 만료되면 이 명령을 다시 실행하세요.');
} catch (e) { console.error(e.message); process.exitCode = 1; } finally { rl.close(); }
