import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('portfolio allocation colors are fixed by allocation rank', () {
    final source = File('lib/pages/portfolio_page.dart').readAsStringSync();
    final buildAllocations = _functionSource(
      source,
      'List<_AllocationItem> _buildAllocations',
    );
    final rankedColor = _functionSource(source, 'Color _rankedAllocationColor');

    expect(buildAllocations, contains('_rankedAllocationColor'));
    expect(
      buildAllocations,
      isNot(contains('MoneyfyChartPalette.colorForAsset')),
    );
    expect(rankedColor, contains('VisualSpec.brand.allocationRankPalette'));
  });

  test('portfolio allocation rank palette has ten tokens', () {
    final source = File(
      'lib/design_system/spec/visual_spec.dart',
    ).readAsStringSync();
    final palette = _functionSource(
      source,
      'List<Color> get allocationRankPalette',
    );

    expect(palette, contains('allocationRank01'));
    expect(palette, contains('allocationRank10'));
  });
}

String _functionSource(String source, String signature) {
  final start = source.indexOf(signature);
  final nextClass = source.indexOf('\nclass ', start + 1);
  return source.substring(start, nextClass == -1 ? source.length : nextClass);
}
