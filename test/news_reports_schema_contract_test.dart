import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final marketSource = File(
    'supabase/functions/get-market-news-summary/index.ts',
  ).readAsStringSync();
  final companySource = File(
    'supabase/functions/get-user-company-news-summaries/index.ts',
  ).readAsStringSync();

  test('market news summary reads and maps news_reports', () {
    expect(marketSource, contains('.from("news_reports")'));
    expect(marketSource, contains('group_key'));
    expect(marketSource, contains(r'market:${category}'));
    expect(marketSource, contains('report_ko'));
    expect(marketSource, contains('final_insight_ko'));
    expect(marketSource, contains('article_count'));
    expect(marketSource, contains('max_importance_score'));
    expect(marketSource, contains('toMarketSummaryPayload'));
    expect(marketSource, contains('market_summary: insight'));
    expect(marketSource, isNot(contains('market_summary: insight || report')));
    expect(marketSource, isNot(contains('overall_assessment')));
    expect(marketSource, isNot(contains('.from("market_news_summaries")')));
  });

  test('company news summaries read and map news_reports by holding symbols', () {
    expect(companySource, contains('.from("news_reports")'));
    expect(companySource, contains('.in("group_key", symbols)'));
    expect(companySource, contains('report_ko'));
    expect(companySource, contains('final_insight_ko'));
    expect(companySource, contains('article_count'));
    expect(companySource, contains('max_importance_score'));
    expect(companySource, contains('toCompanySummaryItem'));
    expect(companySource, contains('company_summary: insight'));
    expect(
      companySource,
      isNot(contains('company_summary: insight || report')),
    );
    expect(companySource, isNot(contains('.from("company_news_summaries")')));
  });
}
