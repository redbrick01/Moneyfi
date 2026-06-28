# Login Sync Overlay Backdrop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로그인 후 "데이터를 맞추는 중" 모달이 표시될 때 상단 앱바/하단 안전영역까지 포함해 전체 화면이 자연스럽게 어두워지도록 수정한다.

**Architecture:** 현재 `SyncOverlay`는 `LoginPage`의 `Scaffold.body` 내부 `Stack`에 `Positioned.fill`로 추가되어 `body` 영역만 덮는다. 로그인 페이지의 `Scaffold`를 바깥 `Stack` 안으로 옮기고, `SyncOverlay`를 같은 `Stack`의 최상단 자식으로 배치해 앱바를 포함한 라우트 전체를 덮게 한다. `SyncOverlay` 내부의 `SafeArea`는 카드 위치 보정 용도로 유지한다.

**Tech Stack:** Flutter, Dart, flutter_test, existing `AppTheme`, existing `SyncOverlay`.

---

## Root Cause

- `lib/features/auth/screens/login_page.dart:291`에서 로그인 화면은 `Scaffold`를 반환한다.
- `lib/features/auth/screens/login_page.dart:294`의 `Stack`은 `Scaffold.body` 안에만 있다.
- `lib/features/auth/screens/login_page.dart:398-400`의 `Positioned.fill(child: SyncOverlay(...))`는 이 `body`만 채우므로 `AppBar`와 시스템 상하단 영역은 스크림 대상에서 빠진다.
- `lib/features/sync/screens/sync_overlay.dart:76-78`의 `Material(color: scrim)`은 전달받은 부모 제약만 칠한다. 따라서 부모가 `body`이면 전체 화면이 아니라 본문만 어두워진다.

## File Structure

- Modify: `lib/features/auth/screens/login_page.dart`
  - `Scaffold`를 라우트 전체 `Stack`의 첫 번째 자식으로 옮긴다.
  - `_showSyncOverlay`일 때 `Positioned.fill`을 `Scaffold.body` 밖, 같은 라우트 `Stack`의 두 번째 자식으로 배치한다.
- Modify: `test/sync_overlay_test.dart`
  - 로그인 화면과 같은 `Scaffold + AppBar + route-level Stack` 구조에서 스크림이 앱바 영역까지 덮는 회귀 테스트를 추가한다.

---

### Task 1: Add Regression Test

**Files:**
- Modify: `test/sync_overlay_test.dart`

- [ ] **Step 1: Add a widget test that models the fixed route-level overlay**

Add this test near the existing `SyncOverlay` widget tests:

```dart
testWidgets('SyncOverlay backdrop covers the app bar when route-level stacked', (
  tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: const Text('로그인')),
            body: const Center(child: Text('로그인 본문')),
          ),
          Positioned.fill(
            child: SyncOverlay(
              steps: const [
                SyncStepItem(title: '코어 데이터', state: SyncStepState.active),
                SyncStepItem(title: '뉴스', state: SyncStepState.pending),
                SyncStepItem(title: '스냅샷', state: SyncStepState.pending),
              ],
              isRunning: true,
              onRetry: () {},
              onClose: () {},
              onBackground: () {},
            ),
          ),
        ],
      ),
    ),
  );

  final overlayTop = tester.getTopLeft(find.byType(SyncOverlay));
  final appBarTop = tester.getTopLeft(find.byType(AppBar));
  final appBarCenter = tester.getCenter(find.byType(AppBar));

  expect(overlayTop.dy, 0);
  expect(appBarTop.dy, 0);
  expect(
    tester.hitTestOnBinding(appBarCenter).path.any(
      (entry) => entry.target.runtimeType.toString().contains('RenderPhysicalModel'),
    ),
    isTrue,
  );
});
```

- [ ] **Step 2: Run the focused test before implementation**

Run:

```bash
flutter test test/sync_overlay_test.dart
```

Expected: existing tests pass; the new test documents the target structure. If hit testing is too implementation-specific on the local Flutter version, replace the hit-test assertion with a geometry assertion that `find.byType(SyncOverlay)` starts at `dy == 0` and still renders `SyncOverlay.cardKey`.

---

### Task 2: Move Login Sync Overlay Outside Scaffold Body

**Files:**
- Modify: `lib/features/auth/screens/login_page.dart:291-415`

- [ ] **Step 1: Replace the outer return structure**

Change the current `return Scaffold(... body: Stack(...))` shape to:

```dart
return Stack(
  children: [
    Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              horizontal,
              context.spacing.md,
              horizontal,
              context.spacing.xl + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.spacing.sm),
                SectionCard(
                  child: Column(
                    children: [
                      if ((_errorMessage ?? '').trim().isNotEmpty) ...[
                        InlineError(message: _errorMessage!),
                        SizedBox(height: context.spacing.sm),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          hintText: 'name@example.com',
                        ),
                      ),
                      SizedBox(height: context.spacing.sm),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            _isSubmitting ? null : _handleLogin(),
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          hintText: '비밀번호를 입력하세요',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.md),
                AppPrimaryButton(
                  label: '로그인',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _handleLogin();
                        },
                  isLoading: _isSubmitting,
                ),
                SizedBox(height: context.spacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SignupPage(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      disabledBackgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      disabledForegroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.radius.rMd),
                      ),
                    ),
                    child: const Text('회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    if (_showSyncOverlay)
      Positioned.fill(
        child: SyncOverlay(
          steps: _buildSteps(),
          isRunning: _isSubmitting,
          errorMessage: _syncErrorMessage,
          errorDetail: _syncErrorDetail,
          retryMessage: _syncRetryMessage,
          closeLabel: _syncOverlayCloseLabel,
          onRetry: _runPostLoginSync,
          onClose: _closeSyncOverlay,
          onBackground: () {
            setState(() {
              _showSyncOverlay = false;
            });
          },
        ),
      ),
  ],
);
```

- [ ] **Step 2: Keep `SyncOverlay` unchanged unless verification shows system bars remain white**

Do not remove `SafeArea` from `SyncOverlay`. It protects the card from notches and navigation bars while the surrounding `Material` still paints the full parent area.

---

### Task 3: Verify

**Files:**
- Test: `test/sync_overlay_test.dart`
- Manual QA: login flow on emulator/device

- [ ] **Step 1: Run focused tests**

Run:

```bash
flutter test test/sync_overlay_test.dart
```

Expected: all tests pass.

- [ ] **Step 2: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: no new analyzer issues.

- [ ] **Step 3: Manual visual check**

Run the app, log in, and trigger the post-login sync overlay.

Expected:
- The app bar area no longer remains white.
- The modal card is still centered and safe from top/bottom cutouts.
- The background action, retry action, and close action still work.

- [ ] **Step 4: If only Android/iOS system bars remain white**

Add an explicit system UI overlay style while `_showSyncOverlay` is true, or wrap the route-level overlay in an `AnnotatedRegion<SystemUiOverlayStyle>` matching the scrimmed state. Do this only after device verification shows the Flutter route-level fix does not cover the platform system bar color.
