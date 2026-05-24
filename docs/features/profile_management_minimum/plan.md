# Profile Management Minimum Plan

## Product Goal

My 화면에서 로그아웃만 제공하던 계정 관리를 최소 수준으로 확장해, 사용자가 표시 이름과 비밀번호를 직접 변경할 수 있게 한다.

## Current Baseline

- My 화면은 로그인 사용자 이름/이메일을 보여준다.
- 계정 액션은 동기화, 코어 데이터 가져오기, 내부 DB 요약 복사, 로그아웃 중심이다.
- AuthService는 Supabase 로그인/회원가입/로그아웃만 래핑한다.

## Success Criteria

- My 화면에서 이름 수정 액션을 제공한다.
- My 화면에서 비밀번호 변경 액션을 제공한다.
- 이름은 빈 값 저장을 막는다.
- 비밀번호는 빈 값, 6자 미만, 확인 불일치를 막는다.
- Supabase `auth.updateUser`를 AuthService wrapper로만 호출한다.
- 기존 My/Login walkthrough가 깨지지 않는다.

## Proposed UX

- 계정 및 동기화 섹션 상단에 `이름 수정`, `비밀번호 변경` row를 추가한다.
- 이름 수정은 dialog에서 현재 이름을 편집한다.
- 비밀번호 변경은 새 비밀번호와 확인 값을 입력한다.
- 작업 중에는 해당 row를 비활성화하고 progress indicator를 보여준다.
- 성공/실패는 기존 AppSnackBar로 안내한다.

## Data/API Changes

- DB schema와 Supabase Edge Function은 변경하지 않는다.
- Supabase Auth user metadata의 `name`을 업데이트한다.
- Supabase Auth password를 `updateUser`로 변경한다.

## Development Phases

1. MyPage 계정 섹션과 AuthService 구조 확인.
2. AuthService에 profile name/password update wrapper 추가.
3. MyPage에 이름/비밀번호 변경 dialog와 loading state 추가.
4. 비밀번호 입력 검증 테스트 추가.
5. 문서와 검증 결과 업데이트.

## MVP Scope

- 이름 수정.
- 비밀번호 변경.
- 로그아웃/동기화 기존 기능 유지.
- 이메일 변경, 계정 삭제, 재인증 flow는 제외한다.

## Test Plan

```bash
dart format lib/services/auth_service.dart lib/pages/my_page.dart test/profile_management_test.dart
flutter test test/profile_management_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- Supabase 프로젝트 설정에 따라 비밀번호 변경 후 세션 유지 정책이 다를 수 있다. 실패 시 재로그인 안내 문구를 표시한다.
- 이메일 변경과 계정 삭제는 인증/확인 정책 영향이 크므로 최소 구현에서 제외한다.
- 이름은 Supabase user metadata에 저장해 기존 표시 로직과 호환한다.

## Feasibility And Feedback

- 기존 MyPage stateful 구조에 action row를 추가하는 방식이라 변경 범위가 작다.
- AuthService wrapper를 통해 Supabase SDK 호출 위치를 한 곳에 유지할 수 있다.
- 후속 작업에서 프로필 전용 페이지, 이메일 변경, 계정 삭제, 재인증을 별도 설계할 수 있다.
