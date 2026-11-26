const platforms = [
  ['Windows', '64비트 · ZIP 압축을 풀고 moneyfy.exe 실행', 'moneyfy-windows-x64.zip'],
  ['macOS', 'Apple Silicon · ZIP 앱 번들 (Apple 공증 미적용)', 'moneyfy-macos-arm64.zip'],
  ['Linux', 'x86_64 · 압축을 풀고 moneyfy 실행', 'moneyfy-linux-x64.tar.gz'],
  ['Android', 'APK 설치 파일', 'moneyfy-android.apk'],
  ['iPhone', 'iOS · TestFlight 배포 준비 중', null],
];

function render(assets) {
  const list = document.querySelector('#downloads');
  list.replaceChildren();
  for (const [name, detail, filename] of platforms) {
    const item = document.createElement('li');
    const description = document.createElement('div');
    const title = document.createElement('strong');
    const note = document.createElement('small');
    title.textContent = name;
    note.textContent = detail;
    description.append(title, note);
    const asset = assets.find(entry => entry.name === filename);
    const action = document.createElement(asset ? 'a' : 'span');
    if (asset) {
      action.href = asset.browser_download_url;
      action.textContent = '다운로드';
      action.setAttribute('aria-label', name + ' 다운로드');
    } else {
      action.textContent = '미배포';
    }
    item.append(description, action);
    list.append(item);
  }
}

async function loadRelease() {
  const status = document.querySelector('#status');
  try {
    const response = await fetch('https://api.github.com/repos/redbrick01/Moneyfi/releases/latest');
    if (response.status === 404) {
      status.textContent = '첫 공개 릴리스를 준비하고 있습니다.';
      return;
    }
    if (!response.ok) throw new Error('Release lookup failed');
    const release = await response.json();
    render(release.assets);
    status.textContent = '최신 버전 · ' + release.tag_name;
  } catch {
    document.querySelector('#downloads').replaceChildren();
    status.textContent = '최신 버전을 확인할 수 없습니다. 전체 릴리스에서 다운로드하세요.';
  }
}

render([]);
loadRelease();
