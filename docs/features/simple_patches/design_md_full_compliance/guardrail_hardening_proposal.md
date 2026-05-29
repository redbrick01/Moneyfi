# Guardrail Hardening Proposal

작성일: 2026-05-29

## 현재 상태

`tools/check_design_token_guardrails.sh`는 reporting-only로 동작한다.

- match가 있어도 exit 0.
- CI도 `continue-on-error: true`.
- 현재 local result는 clean.
- `--self-test`로 pattern 자체의 동작을 검증할 수 있다.

## 전환 단계

| 단계 | 정책 | 조건 |
| --- | --- | --- |
| 1 | local reporting-only | 현재 상태 |
| 2 | CI self-test reporting-only 추가 | `--self-test`가 local/CI에서 안정적으로 통과 |
| 3 | CI report step blocking 전환 후보 | allowlist와 예외가 안정화 |
| 4 | legacy pattern blocking | 신규 page-level legacy pattern을 실패 처리 |

## Blocking 전환 전 예외

| 영역 | 예외 처리 |
| --- | --- |
| `lib/design_system/**` | token source이므로 direct color/font 허용 |
| `lib/theme/**` | compatibility bridge이므로 허용 |
| chart/canvas geometry | 직접 숫자 허용. color/type은 token 사용 권장 |
| platform assets | SVG/manifest/native resource는 별도 asset audit |
| Flutter intrinsic values | API 요구값은 문서화 후 허용 |

## 추천 CI 추가안

초기에는 reporting-only로 추가한다.

```yaml
- name: Design token guardrail self-test
  continue-on-error: true
  run: tools/check_design_token_guardrails.sh --self-test
```

## 완료 기준

- local self-test pass.
- guardrail clean.
- CI에서 최소 1회 reporting-only로 안정성 확인.
- blocking 전환 시점에 exception list가 문서화되어 있음.
