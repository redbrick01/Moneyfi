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
}

String _classSource(String source, String className) {
  final start = source.indexOf('class $className');
  final nextClass = source.indexOf('\nclass ', start + 1);
  return source.substring(start, nextClass == -1 ? source.length : nextClass);
}
