# `assets/` Guide

이 폴더는 앱에서 사용하는 정적 asset과 로컬 설정 예시를 담습니다.

## Files

| 경로 | 역할 |
| --- | --- |
| `config.example.json` | Supabase client 설정 예시 |
| `config.json` | 로컬 실행용 실제 Supabase client 설정. git에 올리지 않습니다. |
| `icon/` | 원본 또는 생성된 앱 아이콘 |
| `app_icon_flat.svg` | 앱 아이콘 작업용 SVG |

## Config

`pubspec.yaml`은 `assets/config.json`을 Flutter asset으로 등록합니다. 로컬 실행 전 예시 파일을 복사해 실제 값을 채웁니다.

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

## Icons

앱 아이콘을 다시 생성할 때는 루트의 스크립트를 사용합니다.

```bash
./tools/generate_app_icons.sh
```
