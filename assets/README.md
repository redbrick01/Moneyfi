# `assets/` Guide

이 폴더는 앱에서 사용하는 정적 asset과 로컬 설정 예시를 담습니다.

## Files

| 경로 | 역할 |
| --- | --- |
| `config.example.json` | Supabase client 설정 예시 |
| `config.json` | 로컬 실행용 실제 Supabase client 설정. 없으면 로그인/동기화 없이 앱이 시작됩니다. git에 올리지 않습니다. |

## 종목 검색 목록

`market_catalog.json`은 한국투자증권의 코스피·코스닥·나스닥·뉴욕·아멕스 종목 마스터에서 이름과 코드만 추출한 배포용 목록입니다. 원본에 영문명이 있는 경우 검색 별칭으로 포함합니다. 미국 상장 ETF는 앱의 해외주식 시세 경로를 사용합니다. 새 상장이나 명칭 변경을 반영하려면 저장소 루트에서 `python3 scripts/update_market_catalog.py`를 실행한 뒤 앱을 빌드합니다. [원본 파일 형식](https://github.com/koreainvestment/open-trading-api/tree/main/stocks_info)

## Config

`pubspec.yaml`은 `assets/` 디렉터리를 Flutter asset으로 등록합니다. 그래서 `assets/config.json`이 없어도 빌드와 앱 시작은 실패하지 않고, 로그인/동기화 화면에서 설정 안내를 표시합니다.

로컬에서 Supabase 로그인을 사용하려면 예시 파일을 복사해 실제 값을 채웁니다.

```bash
cp assets/config.example.json assets/config.json
```

필요한 값:

```json
{
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_ANON_KEY"
}
```

`SUPABASE_SERVICE_ROLE_KEY`는 절대 이 파일에 넣지 않습니다.
