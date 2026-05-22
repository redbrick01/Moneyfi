import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/pages/sync_overlay.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    required List<SyncStepItem> steps,
    required bool isRunning,
    String? errorMessage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SyncOverlay(
            steps: steps,
            isRunning: isRunning,
            errorMessage: errorMessage,
            onRetry: () {},
            onClose: () {},
            onBackground: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('SyncOverlay renders running bottom-sheet state', (tester) async {
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
      errorMessage: '뉴스 데이터 단계에서 실패했어요.',
      steps: const [
        SyncStepItem(title: '코어 데이터', state: SyncStepState.done),
        SyncStepItem(title: '뉴스', state: SyncStepState.failed),
        SyncStepItem(title: '스냅샷', state: SyncStepState.pending),
      ],
    );

    expect(find.text('동기화 확인'), findsOneWidget);
    expect(find.text('뉴스 데이터 단계에서 실패했어요.'), findsOneWidget);
    expect(find.text('재시도'), findsWidgets);
    expect(find.text('나중에'), findsOneWidget);
  });
}
