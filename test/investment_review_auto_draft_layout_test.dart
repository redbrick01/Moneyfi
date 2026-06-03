import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automatic draft feedback uses left-aligned stacked rows', () {
    final source = File(
      'lib/pages/investment_review_page.dart',
    ).readAsStringSync();
    final signalLine = _classSource(source, '_DraftSignalLine');

    expect(signalLine, isNot(contains('TextAlign.end')));
    expect(signalLine, contains('Divider('));
  });
}

String _classSource(String source, String className) {
  final start = source.indexOf('class $className');
  final nextClass = source.indexOf('\nclass ', start + 1);
  return source.substring(start, nextClass == -1 ? source.length : nextClass);
}
