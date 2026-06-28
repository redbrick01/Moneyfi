# Login Refresh All Pages After Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로그인 후 서버 데이터 동기화가 끝나면 홈, 포트폴리오, 거래, 분석/통계, My 화면이 새 계정 데이터 기준으로 한 번씩 다시 읽히도록 보장한다.

**Architecture:** 기존 `AppDataLifecycleService`는 계정 데이터 교체 중/완료 상태를 `ValueNotifier`로 알리고, `AppShellPage`는 이 이벤트를 받아 `_dataScopeVersion`과 `_dataRefreshTick`을 올릴 수 있다. 이 계획은 그 경로를 유지하되, 단순 상태 변경 `version`과 실제 데이터 새로고침 신호 `refreshToken`을 분리한다. 로그인 성공/부분 성공 시에만 `refreshToken`을 올리고, 앱 셸은 `refreshToken` 변화에 반응해 모든 탭 페이지를 재생성하거나 reload tick을 전달한다.

**Tech Stack:** Flutter, Dart, `ValueNotifier`, `flutter_test`, existing `AppDataLifecycleService`, existing `AppShellPage`, existing `LoginPage`.

---

## Root Cause

- `lib/features/auth/screens/login_page.dart:97-115`에서 로그인 후 `pullRemoteCoreData`, 뉴스 캐시, 스냅샷 pull을 수행한 뒤 로그인 화면을 닫는다.
- `lib/features/shell/screens/app_shell_page.dart:100-163`은 `AppDataLifecycleService.state`를 구독하고, 상태 `version`이 바뀌면 `_dataScopeVersion++`, `_dataRefreshTick++`를 수행한다.
- 하지만 `AppDataLifecycleService`의 현재 상태 모델은 `version`, `isReplacing`, `message`만 가진다.
- 이 때문에 “로딩 오버레이 상태가 바뀜”과 “동기화 완료 후 모든 화면이 새 데이터를 다시 읽어야 함”이 같은 `version` 이벤트에 섞여 있다.
- 로그인 실패, 로그인 시작, 로그인 성공 모두 같은 `completeReplacement()` 또는 `beginReplacement()` 경로를 타므로, 코드만 보면 어떤 이벤트가 화면 새로고침을 의도하는지 명확하지 않다.

## File Structure

- Modify: `lib/features/auth/services/app_data_lifecycle_service.dart`
  - `AppDataLifecycleState`에 `refreshToken`과 `refreshReason`을 추가한다.
  - `completeReplacement({String? refreshReason})`에서 `refreshReason`이 있을 때만 `refreshToken`을 증가시킨다.
  - 테스트 격리를 위해 `resetForTesting()`을 `@visibleForTesting`으로 추가한다.
- Modify: `lib/features/shell/screens/app_shell_page.dart`
  - replacement UI 상태 변경은 `version`으로 처리한다.
  - 전체 탭/페이지 데이터 새로고침은 `refreshToken` 변화가 있을 때만 처리한다.
  - refresh 이벤트에서 `_dataScopeVersion++`, `_dataRefreshTick++`, `_syncDisplayCurrencySettings()`를 실행한다.
- Modify: `lib/features/auth/screens/login_page.dart`
  - 로그인 동기화 전체 성공 시 `completeReplacement(refreshReason: 'login_sync_complete')`를 호출한다.
  - 뉴스/스냅샷 실패 후 “앱으로 이동”을 선택하는 부분 성공 시 `completeReplacement(refreshReason: 'login_sync_partial')`를 호출한다.
  - 로그인 인증 실패/예외 시에는 `completeReplacement()`만 호출해 화면 refresh 이벤트를 만들지 않는다.
- Create: `test/app_data_lifecycle_service_test.dart`
  - lifecycle 이벤트 계약을 단위 테스트한다.
- Modify: `test/sync_overlay_test.dart`
  - 로그인 성공/부분 성공 호출부가 refresh reason을 넘기는지 source contract 테스트를 추가한다.

---

### Task 1: Add Lifecycle Service Contract Tests

**Files:**
- Create: `test/app_data_lifecycle_service_test.dart`
- Modify later: `lib/features/auth/services/app_data_lifecycle_service.dart`

- [ ] **Step 1: Write failing tests for refresh token behavior**

Create `test/app_data_lifecycle_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/auth/services/app_data_lifecycle_service.dart';

void main() {
  setUp(AppDataLifecycleService.resetForTesting);

  test('beginReplacement marks replacement without requesting refresh', () {
    AppDataLifecycleService.beginReplacement(message: '로그인 정보를 불러오고 있어요.');

    final state = AppDataLifecycleService.state.value;
    expect(state.isReplacing, isTrue);
    expect(state.message, '로그인 정보를 불러오고 있어요.');
    expect(state.refreshToken, 0);
    expect(state.refreshReason, isNull);
  });

  test('completeReplacement without reason clears replacement only', () {
    AppDataLifecycleService.beginReplacement(message: '로그인 정보를 불러오고 있어요.');

    AppDataLifecycleService.completeReplacement();

    final state = AppDataLifecycleService.state.value;
    expect(state.isReplacing, isFalse);
    expect(state.message, isNull);
    expect(state.refreshToken, 0);
    expect(state.refreshReason, isNull);
  });

  test('completeReplacement with reason requests one app-wide refresh', () {
    AppDataLifecycleService.beginReplacement(message: '로그인 정보를 불러오고 있어요.');

    AppDataLifecycleService.completeReplacement(
      refreshReason: 'login_sync_complete',
    );

    final state = AppDataLifecycleService.state.value;
    expect(state.isReplacing, isFalse);
    expect(state.message, isNull);
    expect(state.refreshToken, 1);
    expect(state.refreshReason, 'login_sync_complete');
  });

  test('refresh token increments once per explicit refresh completion', () {
    AppDataLifecycleService.beginReplacement(message: '첫 번째 교체');
    AppDataLifecycleService.completeReplacement(
      refreshReason: 'login_sync_complete',
    );
    AppDataLifecycleService.beginReplacement(message: '두 번째 교체');
    AppDataLifecycleService.completeReplacement(
      refreshReason: 'login_sync_partial',
    );

    final state = AppDataLifecycleService.state.value;
    expect(state.refreshToken, 2);
    expect(state.refreshReason, 'login_sync_partial');
  });
}
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```bash
flutter test test/app_data_lifecycle_service_test.dart
```

Expected: FAIL because `resetForTesting`, `refreshToken`, `refreshReason`, and `completeReplacement(refreshReason: ...)` do not exist yet.

---

### Task 2: Implement Explicit Refresh Event in AppDataLifecycleService

**Files:**
- Modify: `lib/features/auth/services/app_data_lifecycle_service.dart:1-45`
- Test: `test/app_data_lifecycle_service_test.dart`

- [ ] **Step 1: Replace the service implementation**

Update `lib/features/auth/services/app_data_lifecycle_service.dart` to:

```dart
import 'package:flutter/foundation.dart';

class AppDataLifecycleService {
  AppDataLifecycleService._();

  static final ValueNotifier<AppDataLifecycleState> state =
      ValueNotifier<AppDataLifecycleState>(const AppDataLifecycleState.ready());

  static int _version = 0;
  static int _refreshToken = 0;

  static void beginReplacement({required String message}) {
    _version++;
    state.value = AppDataLifecycleState(
      version: _version,
      isReplacing: true,
      message: message,
      refreshToken: _refreshToken,
      refreshReason: null,
    );
  }

  static void completeReplacement({String? refreshReason}) {
    _version++;
    if (refreshReason != null) {
      _refreshToken++;
    }
    state.value = AppDataLifecycleState(
      version: _version,
      isReplacing: false,
      message: null,
      refreshToken: _refreshToken,
      refreshReason: refreshReason,
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _version = 0;
    _refreshToken = 0;
    state.value = const AppDataLifecycleState.ready();
  }
}

class AppDataLifecycleState {
  const AppDataLifecycleState({
    required this.version,
    required this.isReplacing,
    required this.message,
    required this.refreshToken,
    required this.refreshReason,
  });

  const AppDataLifecycleState.ready()
    : version = 0,
      isReplacing = false,
      message = null,
      refreshToken = 0,
      refreshReason = null;

  final int version;
  final bool isReplacing;
  final String? message;
  final int refreshToken;
  final String? refreshReason;
}
```

- [ ] **Step 2: Run lifecycle service tests**

Run:

```bash
flutter test test/app_data_lifecycle_service_test.dart
```

Expected: PASS.

---

### Task 3: Make AppShellPage React Only to Explicit Refresh Tokens

**Files:**
- Modify: `lib/features/shell/screens/app_shell_page.dart:150-163`
- Test: `test/app_data_lifecycle_service_test.dart`
- Existing behavior check: `test/router_smoke_test.dart`

- [ ] **Step 1: Update `_handleAppDataLifecycleChanged`**

Replace the body of `_handleAppDataLifecycleChanged()` with:

```dart
void _handleAppDataLifecycleChanged() {
  final previousState = _appDataLifecycleState;
  final nextState = AppDataLifecycleService.state.value;
  if (nextState.version == previousState.version) {
    return;
  }
  _appDataLifecycleState = nextState;
  if (!mounted) return;

  final shouldRefreshData =
      nextState.refreshToken != previousState.refreshToken;

  setState(() {
    _isReplacingAccountData = nextState.isReplacing;
    _accountDataReplacementMessage = nextState.message;
    if (shouldRefreshData) {
      _dataScopeVersion++;
      _dataRefreshTick++;
    }
  });

  if (shouldRefreshData) {
    unawaited(_syncDisplayCurrencySettings());
  }
}
```

- [ ] **Step 2: Confirm replacement overlay still works conceptually**

Check these invariants in the updated code:

```dart
_isReplacingAccountData = nextState.isReplacing;
_accountDataReplacementMessage = nextState.message;
```

Expected: those assignments still happen for both `beginReplacement` and `completeReplacement`.

- [ ] **Step 3: Run router smoke tests**

Run:

```bash
flutter test test/router_smoke_test.dart
```

Expected: PASS. This verifies the shell still builds core routes after lifecycle model changes.

---

### Task 4: Mark Login Sync Completion as App-Wide Refresh

**Files:**
- Modify: `lib/features/auth/screens/login_page.dart:107-115`
- Modify: `lib/features/auth/screens/login_page.dart:224-233`
- Test: `test/sync_overlay_test.dart`

- [ ] **Step 1: Update successful login sync completion**

In `_handleLogin`, replace:

```dart
AppDataLifecycleService.completeReplacement();
```

after successful `_runPostLoginSync()` with:

```dart
AppDataLifecycleService.completeReplacement(
  refreshReason: 'login_sync_complete',
);
```

Do not change the `AuthException` or generic `catch` branches. They should keep:

```dart
AppDataLifecycleService.completeReplacement();
```

- [ ] **Step 2: Update partial sync continue path**

In `_closeSyncOverlay`, replace:

```dart
AppDataLifecycleService.completeReplacement();
```

inside `_canContinueAfterSyncFailure` with:

```dart
AppDataLifecycleService.completeReplacement(
  refreshReason: 'login_sync_partial',
);
```

The “닫기” path for non-continuable failures should not navigate and should not create a refresh event.

- [ ] **Step 3: Add source contract test for login refresh reasons**

In `test/sync_overlay_test.dart`, add this test after `LoginPage places sync overlay outside Scaffold body`:

```dart
test('LoginPage requests app-wide refresh after login sync completion', () {
  final source = File(
    'lib/features/auth/screens/login_page.dart',
  ).readAsStringSync();

  expect(source, contains("refreshReason: 'login_sync_complete'"));
  expect(source, contains("refreshReason: 'login_sync_partial'"));
  expect(
    source,
    contains('} on AuthException catch (error) {\\n'
        '      AppDataLifecycleService.completeReplacement();'),
  );
});
```

- [ ] **Step 4: Run focused login/sync tests**

Run:

```bash
flutter test test/sync_overlay_test.dart
```

Expected: PASS.

---

### Task 5: Verify End-to-End Contract

**Files:**
- Test: `test/app_data_lifecycle_service_test.dart`
- Test: `test/sync_overlay_test.dart`
- Test: `test/router_smoke_test.dart`
- Analyze: changed Dart files

- [ ] **Step 1: Format changed files**

Run:

```bash
dart format lib/features/auth/services/app_data_lifecycle_service.dart lib/features/shell/screens/app_shell_page.dart lib/features/auth/screens/login_page.dart test/app_data_lifecycle_service_test.dart test/sync_overlay_test.dart
```

Expected: formatter completes successfully.

- [ ] **Step 2: Run focused tests**

Run:

```bash
flutter test test/app_data_lifecycle_service_test.dart test/sync_overlay_test.dart test/router_smoke_test.dart
```

Expected: all focused tests pass.

- [ ] **Step 3: Analyze changed files**

Run:

```bash
dart analyze lib/features/auth/services/app_data_lifecycle_service.dart lib/features/shell/screens/app_shell_page.dart lib/features/auth/screens/login_page.dart test/app_data_lifecycle_service_test.dart test/sync_overlay_test.dart
```

Expected: no issues in changed files.

- [ ] **Step 4: Run full analyzer and record existing unrelated warnings**

Run:

```bash
flutter analyze
```

Expected: either no issues, or only the pre-existing deprecated member info messages in portfolio screens. Do not fix unrelated portfolio deprecations in this task.

---

## Manual QA

- [ ] **Step 1: Login success**

Start signed out, log in with an account that has remote data.

Expected:
- "데이터를 맞추는 중" overlay runs.
- After success, login page closes.
- Home/portfolio/transactions/analysis pages show the logged-in account data without manually switching tabs or restarting the app.

- [ ] **Step 2: Partial sync failure continue path**

Force or simulate news/snapshot failure while core sync succeeds, then tap "앱으로 이동".

Expected:
- Login page closes.
- Core data appears across tabs.
- Failed optional data can still be retried later from My.

- [ ] **Step 3: Login failure**

Enter invalid credentials.

Expected:
- Login page stays open.
- Error appears.
- App shell pages are not unnecessarily refreshed with a new data scope.

---

## Self-Review

- Spec coverage: success login, partial sync continue, login failure, all-tab refresh signal, and verification are covered.
- Placeholder scan: no TBD/TODO/implement-later placeholders remain.
- Type consistency: `refreshToken`, `refreshReason`, `completeReplacement({String? refreshReason})`, and `resetForTesting()` are named consistently across service, tests, login, and shell tasks.
