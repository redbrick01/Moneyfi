import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/services/company_news_summary_service.dart';
import 'package:moneyfy/services/market_news_summary_service.dart';
import 'package:moneyfy/services/portfolio_diagnosis_service.dart';
import 'package:moneyfy/widgets/market_news_summary_card.dart';

void main() {
  group('external API fallback payloads', () {
    test('market news fallback renders as a non-empty summary', () {
      final response =
          MarketNewsSummaryService.buildFallbackSummaryForTesting();

      final summary = MarketNewsSummary.fromJson(
        response.summary,
        model: response.model,
        newsCount: response.newsCount,
        updatedAt: response.updatedAt,
      );

      expect(response.found, isTrue);
      expect(response.model, 'fallback-local');
      expect(summary.marketSummary.trim(), isNotEmpty);
      expect(summary.issues, isNotEmpty);
      expect(summary.keyRisk.trim(), isNotEmpty);
    });

    test('company news fallback creates visible stock and coin items', () {
      final items = CompanyNewsSummaryService.buildFallbackSummariesForTesting({
        'AAPL': '주식',
        'BTC': '코인',
        'USD': '현금',
      });

      expect(items.map((item) => item.symbol), containsAll(['AAPL', 'BTC']));
      expect(items.any((item) => item.symbol == 'USD'), isFalse);
      for (final item in items) {
        expect(item.found, isTrue);
        expect(item.hasKnownAssetType, isTrue);
        expect(item.model, 'fallback-local');
        expect('${item.summary?['company_summary'] ?? ''}'.trim(), isNotEmpty);
        expect(item.summary?['issues'], isA<List>());
      }
    });

    test('portfolio diagnosis fallback keeps diagnosis UI populated', () {
      final diagnosis =
          PortfolioDiagnosisService.buildFallbackDiagnosisForTesting({
            'holdings': [
              {'symbol': 'AAPL'},
              {'symbol': 'BTC'},
            ],
          });

      expect(diagnosis.summary.trim(), isNotEmpty);
      expect(diagnosis.score, inInclusiveRange(0, 100));
      expect(diagnosis.riskLevel, isNotEmpty);
      expect(diagnosis.weaknesses, isNotEmpty);
      expect(diagnosis.suggestions, isNotEmpty);
      expect(diagnosis.uncertainty, isTrue);
      expect(diagnosis.analysisSource, 'fallback_rule_based');
      expect(diagnosis.model, 'fallback-local');
    });
  });
}
