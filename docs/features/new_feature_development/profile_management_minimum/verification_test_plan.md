# Profile Management Minimum Verification Test Plan

## Scope

My 화면의 최소 프로필 관리 기능인 이름 수정과 비밀번호 변경을 검증한다.

## Quality Goals

- 계정 관리 기능이 기존 My 화면 동기화/로그아웃 흐름을 깨지 않는다.
- 이름과 비밀번호 입력 오류가 Supabase 호출 전 차단된다.
- Supabase Auth update wrapper가 AuthService에 모인다.

## Automated Test Plan

```bash
dart format lib/services/auth_service.dart lib/pages/my_page.dart test/profile_management_test.dart
flutter test test/profile_management_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Manual QA Plan

- 로그인 상태에서 My 화면에 `이름 수정`, `비밀번호 변경` row가 보이는지 확인한다.
- 이름을 빈 값으로 저장하려고 할 때 오류가 표시되는지 확인한다.
- 이름을 변경하면 My 화면 표시 이름이 갱신되는지 확인한다.
- 6자 미만 비밀번호와 확인 불일치 비밀번호가 차단되는지 확인한다.
- 정상 비밀번호 변경 후 다음 로그인에 새 비밀번호가 동작하는지 확인한다.

## Responsive Checklist

- 작은 화면에서 dialog 입력 필드와 버튼이 잘리지 않는다.
- My 화면 action row의 긴 subtitle이 겹치지 않는다.

## Acceptance Criteria

- 비밀번호 검증 테스트가 통과한다.
- MyPage 포함 walkthrough가 통과한다.
- 정적 분석이 통과한다.
- 수동 Supabase Auth update QA 미수행 항목은 test report에 남긴다.

## Release Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Supabase 설정에 따라 비밀번호 변경 후 세션 정책 차이 | Medium | Medium | 실패 문구에 재로그인 안내 포함 |
| 이름 변경 이벤트가 즉시 화면 반영되지 않음 | Low | Low | `setState`와 auth state stream에 의존 |
| 계정 삭제/이메일 변경 누락 기대 | Medium | Low | 최소 구현 범위로 문서에 제외 명시 |

## Future Test Expansion

- AuthService를 mock 가능한 구조로 분리해 updateUser 호출 widget test 추가.
- 이메일 변경, 계정 삭제, 재인증 flow 별도 설계.
