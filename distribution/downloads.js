const platforms = [
  { name: 'Windows', format: 'ZIP · x64', file: 'moneyfy-windows-x64.zip', detail: 'Windows 64비트 PC용 데스크톱 앱입니다.', guide: 'ZIP 파일의 압축을 모두 풀고 폴더 안의 moneyfy.exe를 실행하세요. DLL 파일과 data 폴더도 함께 보관하세요.' },
  { name: 'macOS', format: 'ZIP · Apple Silicon', file: 'moneyfy-macos-arm64.zip', detail: 'Apple Silicon Mac용 앱입니다. 이 빌드는 Apple 공증을 받지 않았습니다.', guide: 'ZIP을 열고 Moneyfy.app을 응용 프로그램 폴더로 옮기세요. macOS 보안 정책에 따라 실행이 제한될 수 있습니다.' },
  { name: 'Linux', format: 'TAR.GZ · x86_64', file: 'moneyfy-linux-x64.tar.gz', detail: 'Ubuntu 24.04 환경에서 빌드한 Linux 데스크톱 앱입니다.', guide: '새 폴더에 압축을 풀고 그 안에서 ./moneyfy를 실행하세요. GTK 3와 libsecret이 필요합니다.' },
  { name: 'Android', format: 'APK', file: 'moneyfy-android.apk', detail: 'Android 기기에 직접 설치하는 서명된 앱입니다.', guide: '기기에서 APK를 열고 Android 설치 안내를 따르세요. 기존 앱과 서명이 다르면 업데이트 설치가 제한됩니다.' },
  { name: 'iPhone', format: 'iOS', detail: 'iPhone 배포는 보류 중입니다.' },
];
const byId = id => document.getElementById(id);
const userAgent = navigator.userAgent;
const detected = /iPhone|iPad|iPod/.test(userAgent) || (/Mac/.test(userAgent) && navigator.maxTouchPoints > 1) ? 'iPhone'
  : /Android/.test(userAgent) ? 'Android' : /Mac/.test(userAgent) ? 'macOS' : /Linux/.test(userAgent) ? 'Linux' : 'Windows';
let current = platforms.find(platform => platform.name === detected);
let assets = [];
let state = 'loading';
const releaseUrl = 'https://github.com/redbrick01/Moneyfi/releases';

function updatePackage() {
  byId('format').textContent = current.format;
  byId('platform').textContent = current.name;
  byId('detail').textContent = current.detail;
  byId('guide').hidden = !current.guide;
  byId('instructions').textContent = current.guide || '';
  const asset = assets.find(item => item.name === current.file);
  const fallback = state === 'error' && current.file;
  const action = document.createElement(asset || fallback ? 'a' : 'span');
  if (asset || fallback) {
    action.className = 'primary';
    action.href = asset ? asset.browser_download_url : releaseUrl;
    action.textContent = asset ? current.name + ' 다운로드' : '릴리스에서 확인';
  } else {
    action.className = 'state';
    action.textContent = !current.file ? '배포 보류' : state === 'loading' ? '확인 중' : '빌드 준비 중';
  }
  byId('action').replaceChildren(action);
}

for (const platform of platforms) {
  const label = document.createElement('label');
  const input = document.createElement('input');
  input.type = 'radio';
  input.name = 'platform';
  input.checked = current === platform;
  input.addEventListener('change', () => {
    current = platform;
    byId('guide').open = false;
    updatePackage();
  });
  const name = document.createElement('span');
  name.textContent = platform.name;
  label.append(input, name);
  byId('choices').append(label);
}
updatePackage();

async function loadRelease() {
  try {
    const response = await fetch('https://api.github.com/repos/redbrick01/Moneyfi/releases/latest');
    if (response.status === 404) {
      state = 'empty';
      byId('status').textContent = '첫 릴리스 준비 중';
    } else {
      if (!response.ok) throw new Error('Release lookup failed');
      const release = await response.json();
      assets = release.assets;
      state = 'ready';
      byId('status').textContent = '최신 버전 · ' + release.tag_name;
    }
  } catch {
    state = 'error';
    byId('status').textContent = '버전 정보 연결 대기';
  }
  updatePackage();
}
loadRelease();

const art = document.querySelector('.art');
if (matchMedia('(hover: hover) and (prefers-reduced-motion: no-preference)').matches) {
  art.addEventListener('pointermove', event => {
    const box = art.getBoundingClientRect();
    art.style.setProperty('--ry', ((event.clientX - box.left) / box.width * 12 - 6) + 'deg');
    art.style.setProperty('--rx', (5 - (event.clientY - box.top) / box.height * 10) + 'deg');
  });
  art.addEventListener('pointerleave', () => {
    art.style.removeProperty('--rx');
    art.style.removeProperty('--ry');
  });
}
