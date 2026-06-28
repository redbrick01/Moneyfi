import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/auth/screens/login_page.dart';
import 'package:moneyfy/features/sync/screens/sync_overlay.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    required List<SyncStepItem> steps,
    required bool isRunning,
    String? errorMessage,
    String? errorDetail,
    String? retryMessage,
    String? closeLabel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SyncOverlay(
            steps: steps,
            isRunning: isRunning,
            errorMessage: errorMessage,
            errorDetail: errorDetail,
            retryMessage: retryMessage,
            closeLabel: closeLabel,
            onRetry: () {},
            onClose: () {},
            onBackground: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('SyncOverlay renders running centered modal state', (
    tester,
  ) async {
    await pumpOverlay(
      tester,
      isRunning: true,
      steps: const [
        SyncStepItem(title: '코어 데이터', state: SyncStepState.done),
        SyncStepItem(title: '뉴스', state: SyncStepState.active),
        SyncStepItem(title: '스냅샷', state: SyncStepState.pending),
      ],
    );

    expect(find.text('데이터를 맞추는 중'), findsOneWidget);
    expect(find.text('로그인된 계정의 최신 데이터를 가져오고 있어요.'), findsOneWidget);
    expect(find.text('백그라운드로'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.byKey(SyncOverlay.cardKey), findsOneWidget);

    final cardCenter = tester.getCenter(find.byKey(SyncOverlay.cardKey));
    expect(cardCenter.dy, closeTo(300, 80));
  });

  testWidgets('SyncOverlay scrolls instead of clipping on short windows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOverlay(
      tester,
      isRunning: true,
      steps: const [
        SyncStepItem(title: '코어 데이터', state: SyncStepState.done),
        SyncStepItem(title: '뉴스', state: SyncStepState.active),
        SyncStepItem(title: '스냅샷', state: SyncStepState.pending),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(SyncOverlay.cardKey), findsOneWidget);
    expect(find.text('스냅샷'), findsOneWidget);
    expect(find.text('백그라운드로'), findsOneWidget);
  });

  testWidgets('SyncOverlay renders success state', (tester) async {
    await pumpOverlay(
      tester,
      isRunning: false,
      steps: const [
        SyncStepItem(title: '코어 데이터', state: SyncStepState.done),
        SyncStepItem(title: '뉴스', state: SyncStepState.done),
        SyncStepItem(title: '스냅샷', state: SyncStepState.done),
      ],
    );

    expect(find.text('동기화 완료'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('SyncOverlay renders retry state', (tester) async {
    await pumpOverlay(
      tester,
      isRunning: false,
      errorMessage: '뉴스 데이터를 준비하지 못했어요.',
      errorDetail: '자산과 거래 데이터는 적용됐어요.',
      retryMessage: '뉴스 요약이 꼭 필요하면 재시도하세요.',
      closeLabel: '앱으로 이동',
      steps: const [
        SyncStepItem(title: '코어 데이터', state: SyncStepState.done),
        SyncStepItem(
          title: '뉴스',
          state: SyncStepState.failed,
          meta: '시장/종목 뉴스 요약은 나중에 다시 받을 수 있어요.',
        ),
        SyncStepItem(title: '스냅샷', state: SyncStepState.pending),
      ],
    );

    expect(find.text('동기화 확인'), findsOneWidget);
    expect(find.text('뉴스 데이터를 준비하지 못했어요.'), findsOneWidget);
    expect(find.text('자산과 거래 데이터는 적용됐어요.'), findsOneWidget);
    expect(find.text('시장/종목 뉴스 요약은 나중에 다시 받을 수 있어요.'), findsOneWidget);
    expect(find.text('뉴스 요약이 꼭 필요하면 재시도하세요.'), findsOneWidget);
    expect(find.text('재시도'), findsWidgets);
    expect(find.text('앱으로 이동'), findsOneWidget);
  });

  test('LoginPage places sync overlay outside Scaffold body', () {
    final source = File(
      'lib/features/auth/screens/login_page.dart',
    ).readAsStringSync();
    final returnStackIndex = source.indexOf('return Stack(');
    final scaffoldIndex = source.indexOf('Scaffold(', returnStackIndex);
    final overlayIndex = source.indexOf('if (_showSyncOverlay)');

    expect(returnStackIndex, isNonNegative);
    expect(scaffoldIndex, isNonNegative);
    expect(overlayIndex, isNonNegative);
    expect(returnStackIndex, lessThan(scaffoldIndex));
    expect(overlayIndex, greaterThan(scaffoldIndex));
    expect(source, isNot(contains('body: Stack(')));
  });

  test('LoginPage requests app-wide refresh after login sync completion', () {
    final source = File(
      'lib/features/auth/screens/login_page.dart',
    ).readAsStringSync();

    expect(source, contains("refreshReason: 'login_sync_complete'"));
    expect(source, contains("refreshReason: 'login_sync_partial'"));
    expect(
      source,
      contains(
        '} on AuthException catch (error) {\n'
        '      AppDataLifecycleService.completeReplacement();',
      ),
    );
  });

  test('login sync failure copy gives stage-specific actions', () {
    final core = loginSyncFailureCopyForTesting('core');
    final news = loginSyncFailureCopyForTesting('news');
    final snapshots = loginSyncFailureCopyForTesting('snapshots');

    expect(core.detail, contains('앱을 안전하게 시작'));
    expect(news.detail, contains('앱 진입 후 My'));
    expect(snapshots.detail, contains('분석 차트'));
    expect(news.retryMessage, contains('앱으로 이동'));
    expect(snapshots.stepMeta, contains('나중에 다시'));
  });
}
