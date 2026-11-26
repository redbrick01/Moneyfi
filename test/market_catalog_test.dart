import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/portfolio/services/market_instrument_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bundled directory resolves company names and preserves quote exchanges',
    () async {
      for (final (query, symbol, market) in [
        ('셀트리온', '068270', 'KOSPI'),
        ('에코프로비엠', '247540', 'KOSDAQ'),
        ('아마존닷컴', 'AMZN', 'NAS'),
        ('amazon com', 'AMZN', 'NAS'),
        ('일라이릴리', 'LLY', 'NYS'),
        ('aaau', 'AAAU', 'AMS'),
        ('BRK.B', 'BRK/B', 'NYS'),
      ]) {
        final matches = await searchMarketLocally([], {'주식'}, query);
        final instrument = matches.firstWhere(
          (result) => result.symbol == symbol,
        );
        expect(instrument.listingMarket, market);
        expect(
          instrument.asMarketQuote().exchangeCode,
          market.startsWith('KOS') ? '' : market,
        );
        expect(matches.map((item) => item.key).toSet().length, matches.length);
      }
      final exact = await searchMarketLocally([], {'주식'}, 'a');
      expect(exact.first.symbol, 'A');
      expect(exact, hasLength(8));
      expect(await searchMarketLocally([], {'코인'}, '아마존닷컴'), isEmpty);
    },
  );
}
