import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const basePath =
      'docs/features/new_feature_development/'
      'risk_adjusted_benchmark_performance';

  test('rollout documentation links every implementation stage', () {
    final requiredFiles = [
      '$basePath/implementation_report_01_calculation_contract.md',
      '$basePath/implementation_report_02_derived_daily_returns.md',
      '$basePath/implementation_report_03_benchmark_data.md',
      '$basePath/implementation_report_04_ui_integration.md',
      '$basePath/implementation_report_05_supabase_and_sync_safety.md',
      '$basePath/implementation_report_06_rollout_gate.md',
      '$basePath/release_gate_06.md',
      '$basePath/remote_schema_draft_05.sql',
    ];

    for (final path in requiredFiles) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('release gate records remote apply safety checks', () {
    final releaseGate = File(
      '$basePath/release_gate_06.md',
    ).readAsStringSync().toLowerCase();

    expect(releaseGate, contains('supabase 원격 적용은 2026-05-29에 완료'));
    expect(releaseGate, contains('assets'));
    expect(releaseGate, contains('holdings'));
    expect(releaseGate, contains('수량 합계'));
    expect(releaseGate, contains('매수원금 합계'));
    expect(releaseGate, contains('zero 분포'));
    expect(releaseGate, contains('데이터 부족'));
    expect(releaseGate, isNot(contains('update holdings')));
    expect(releaseGate, isNot(contains('delete from holdings')));
    expect(releaseGate, isNot(contains('truncate')));
  });
}
