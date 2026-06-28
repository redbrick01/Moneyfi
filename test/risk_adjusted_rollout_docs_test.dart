import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const archivedPath =
      'docs/reports/archived_artifacts/risk_adjusted_benchmark_performance';
  const historyPath = 'docs/reports/implementation_history.md';

  test('rollout archive keeps schema draft and consolidated history', () {
    final requiredFiles = [
      '$archivedPath/remote_schema_draft_05.sql',
      historyPath,
    ];

    for (final path in requiredFiles) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('implementation history preserves remote apply safety summary', () {
    final history = File(historyPath).readAsStringSync().toLowerCase();

    expect(history, contains('supabase 원격 적용은 2026-05-29에 완료'));
    expect(history, contains('assets'));
    expect(history, contains('holdings'));
    expect(history, contains('수량 합계'));
    expect(history, contains('매수원금 합계'));
    expect(history, contains('zero 분포'));
    expect(history, contains('데이터 부족'));
    expect(history, contains('remote_schema_draft_05.sql'));
  });
}
