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
