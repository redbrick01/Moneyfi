import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('holding detail inner components do not add a third card surface', () {
    final source = File(
      'lib/features/portfolio/screens/holding_detail_page.dart',
    ).readAsStringSync();
    final innerComponentSource = [
      _classSource(source, '_WeekRangeBar'),
      _classSource(source, '_MetricTile'),
    ].join('\n');

    expect(
      innerComponentSource,
      isNot(contains('color: context.colors.neutralSurfaceRaised,')),
      reason:
          'Holding detail sections already render an outer card and inner panel.',
    );
  });

  test('holding detail metric grid separates values with inner lines', () {
    final source = File(
      'lib/features/portfolio/screens/holding_detail_page.dart',
    ).readAsStringSync();
    final gridSource = [
      _classSource(source, '_MetricGrid'),
      _classSource(source, '_MetricGridRow'),
    ].join('\n');

    expect(gridSource, contains('Divider('));
    expect(gridSource, contains('VerticalDivider('));
  });

  test('ETF fund info card requires every value to be available', () {
    final source = File(
      'lib/features/portfolio/screens/holding_detail_page.dart',
    ).readAsStringSync();
    final sectionBuilderStart = source.indexOf(
      'List<_HoldingDetailSection> _buildHoldingDetailSections',
    );
    final fundCaseStart = source.indexOf("case '펀드':", sectionBuilderStart);
    final cashCaseStart = source.indexOf("case '현금':", fundCaseStart);
    final fundCaseSource = source.substring(fundCaseStart, cashCaseStart);

    expect(fundCaseSource, contains('if (market.hasCompleteEtfFundInfo)'));
    expect(fundCaseSource, contains("title: 'ETF / 펀드 정보'"));
  });
}

String _classSource(String source, String className) {
  final start = source.indexOf('class $className');
  final nextClass = source.indexOf('\nclass ', start + 1);
  return source.substring(start, nextClass == -1 ? source.length : nextClass);
}
