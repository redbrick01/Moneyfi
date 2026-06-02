# Profile Management Minimum Plan

## Product Goal

My 화면 계정 관리 최소 확장. 지금 로그아웃만 있음. 사용자가 표시 이름, 비밀번호 직접 변경 가능하게.

## Current Baseline

- My 화면: 로그인 사용자 이름/이메일 표시.
- 계정 액션: 동기화, 코어 데이터 가져오기, 내부 DB 요약 복사, 로그아웃 중심.
- AuthService: Supabase 로그인/회원가입/로그아웃만 래핑.

## Success Criteria

- My 화면 이름 수정 액션 제공.
- My 화면 비밀번호 변경 액션 제공.
- 이름 빈 값 저장 차단.
- 비밀번호 빈 값, 6자 미만, 확인 불일치 차단.
- Supabase `auth.updateUser`는 AuthService wrapper로만 호출.
- 기존 My/Login walkthrough 안 깨짐.

## Proposed UX

- 계정 및 동기화 섹션 상단에 `이름 수정`, `비밀번호 변경` row 추가.
- 이름 수정: dialog에서 현재 이름 편집.
- 비밀번호 변경: 새 비밀번호 + 확인 입력.
- 작업 중 해당 row 비활성화, progress indicator 표시.
- 성공/실패는 기존 AppSnackBar로 안내.

## Data/API Changes

- DB schema, Supabase Edge Function 변경 없음.
- Supabase Auth user metadata의 `name` 업데이트.
- Supabase Auth password를 `updateUser`로 변경.

## Development Phases

1. MyPage 계정 섹션, AuthService 구조 확인.
2. AuthService에 profile name/password update wrapper 추가.
3. MyPage에 이름/비밀번호 변경 dialog, loading state 추가.
4. 비밀번호 입력 검증 테스트 추가.
5. 문서, 검증 결과 업데이트.

## MVP Scope

- 이름 수정.
- 비밀번호 변경.
- 로그아웃/동기화 기존 기능 유지.
- 이메일 변경, 계정 삭제, 재인증 flow 제외.

## Test Plan

```bash
dart format lib/services/auth_service.dart lib/pages/my_page.dart test/profile_management_test.dart
flutter test test/profile_management_test.dart
flutter test test/page_walkthrough_test.dart
flutter analyze
git diff --check
```

## Risks And Decisions

- Supabase 프로젝트 설정 따라 비밀번호 변경 후 세션 유지 정책 다를 수 있음. 실패 시 재로그인 안내 문구 표시.
- 이메일 변경, 계정 삭제는 인증/확인 정책 영향 큼. 최소 구현에서 제외.
- 이름은 Supabase user metadata에 저장. 기존 표시 로직과 호환.

## Feasibility And Feedback

- 기존 MyPage stateful 구조에 action row 추가. 변경 범위 작음.
- AuthService wrapper로 Supabase SDK 호출 위치 한 곳 유지.
- 후속 작업: 프로필 전용 페이지, 이메일 변경, 계정 삭제, 재인증 별도 설계 가능.