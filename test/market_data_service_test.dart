import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moneyfy/models/asset_item.dart';
import 'package:moneyfy/services/market_data_service.dart';

void main() {
  HoldingItem holding({
    required String assetType,
    required String symbol,
    String assetTitle = '테스트 자산',
    String currencyCode = 'KRW',
    String exchangeCode = '',
    double currentPrice = 1000,
  }) {
    return HoldingItem(
      assetTitle: assetTitle,
      assetType: assetType,
      currencyCode: currencyCode,
      exchangeCode: exchangeCode,
      name: assetTitle,
      symbol: symbol,
      quantity: 1,
      averagePrice: 900,
      currentPrice: currentPrice,
      note: '',
      transactions: const [],
    );
  }

  http.Response jsonResponse(
    Map<String, Object?> body, {
    int statusCode = 200,
  }) {
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  group('Coinone ticker API', () {
    test('parses ticker, order book, and volume fields', () async {
      Uri? requestedUri;
      final service = MarketDataService.test(
        coinTickerUrlTemplate:
            'https://coinone.test/public/v2/ticker_utc_new/{quote}/{symbol}?additional_data=true',
        client: MockClient((request) async {
          requestedUri = request.url;
          return jsonResponse({
            'result': 'success',
            'tickers': [
              {
                'quote_currency': 'KRW',
                'target_currency': 'BTC',
                'last': '96000000',
                'yesterday_last': '95000000',
                'first': '95100000',
                'high': '97000000',
                'low': '94000000',
                'target_volume': '12.345',
                'quote_volume': '1180000000',
                'best_asks': [
                  {'price': '96010000', 'qty': '0.25'},
                ],
                'best_bids': [
                  {'price': '95990000', 'qty': '0.5'},
                ],
              },
            ],
          });
        }),
      );

      final snapshot = await service.fetchSnapshot(
        holding(assetType: '코인', assetTitle: '비트코인', symbol: 'btc'),
      );

      expect(
        requestedUri.toString(),
        'https://coinone.test/public/v2/ticker_utc_new/KRW/BTC?additional_data=true',
      );
      expect(snapshot.currentPriceValue, 96000000);
      expect(snapshot.currentPrice, '₩96,000,000');
      expect(snapshot.previousClose, '₩95,000,000');
      expect(snapshot.quoteVolume24h, '₩1,180,000,000');
      expect(snapshot.targetVolume24h, '12.35');
      expect(snapshot.bestAskPrice, '₩96,010,000');
      expect(snapshot.bestBidQty, '0.50');
      expect(snapshot.quoteCurrency, 'KRW');
      expect(snapshot.targetCurrency, 'BTC');
    });

    test('falls back when Coinone returns no tickers', () async {
      final service = MarketDataService.test(
        client: MockClient((_) async => jsonResponse({'tickers': []})),
      );
      final fallbackHolding = holding(
        assetType: '코인',
        symbol: 'ETH',
        currentPrice: 4200000,
      );

      final snapshot = await service.fetchSnapshot(fallbackHolding);

      expect(snapshot.currentPriceValue, fallbackHolding.currentPrice);
      expect(snapshot.targetCurrency, 'ETH');
      expect(snapshot.bestAskPrice, '-');
    });
  });

  group('Korea Investment API', () {
    test('falls back without required KIS credentials', () async {
      var requestCount = 0;
      final service = MarketDataService.test(
        client: MockClient((_) async {
          requestCount += 1;
          return jsonResponse({});
        }),
      );

      final snapshot = await service.fetchSnapshot(
        holding(assetType: '주식', assetTitle: '삼성전자', symbol: '005930'),
      );

      expect(requestCount, 0);
      expect(snapshot.marketName, '삼성전자');
      expect(snapshot.currentPriceValue, 1000);
    });

    test('requests a token and parses domestic stock quotes', () async {
      final requests = <http.BaseRequest>[];
      final service = MarketDataService.test(
        kisBaseUrl: 'https://kis.test',
        kisAppKey: 'app-key',
        kisAppSecret: 'app-secret',
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            expect(request.url.path, '/oauth2/tokenP');
            final body = jsonDecode(request.body) as Map;
            expect(body['grant_type'], 'client_credentials');
            expect(body['appkey'], 'app-key');
            expect(body['appsecret'], 'app-secret');
            return jsonResponse({
              'access_token': 'token-1',
              'expires_in': 3600,
            });
          }

          expect(
            request.url.path,
            '/uapi/domestic-stock/v1/quotations/inquire-price',
          );
          expect(request.url.queryParameters['FID_COND_MRKT_DIV_CODE'], 'J');
          expect(request.url.queryParameters['FID_INPUT_ISCD'], '005930');
          expect(request.headers['authorization'], 'Bearer token-1');
          expect(request.headers['appkey'], 'app-key');
          expect(request.headers['appsecret'], 'app-secret');
          expect(request.headers['tr_id'], 'FHKST01010100');
          return jsonResponse({
            'rt_cd': '0',
            'output': {
              'stck_prpr': '70000',
              'bstp_kor_isnm': '전기전자',
              'prdy_vrss': '500',
              'prdy_vrss_sign': '2',
              'prdy_ctrt': '0.72',
              'stck_prdy_clpr': '69500',
              'stck_oprc': '69600',
              'stck_hgpr': '71000',
              'stck_lwpr': '69000',
              'acml_vol': '1234567',
              'acml_tr_pbmn': '86420000000',
              'per': '12.3',
              'pbr': '1.5',
              'eps': '5200',
              'bps': '45000',
              'w52_hgpr': '80000',
              'w52_lwpr': '60000',
              'hts_frgn_ehrt': '53.123',
            },
          });
        }),
      );

      final snapshot = await service.fetchSnapshot(
        holding(assetType: '주식', assetTitle: '삼성전자', symbol: '005930'),
      );

      expect(requests.map((request) => request.method), ['POST', 'GET']);
      expect(snapshot.currentPriceValue, 70000);
      expect(snapshot.currentPrice, '₩70,000');
      expect(snapshot.dayChange, '+₩500');
      expect(snapshot.dayChangeRate, '+0.72%');
      expect(snapshot.sectorName, '전기전자');
      expect(snapshot.volume, '1,234,567');
      expect(snapshot.foreignHoldRate, '53.12%');
    });

    test('parses overseas stock quotes and exchange codes', () async {
      final service = MarketDataService.test(
        kisBaseUrl: 'https://kis.test',
        kisAppKey: 'app-key',
        kisAppSecret: 'app-secret',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            return jsonResponse({
              'access_token': 'token-1',
              'expires_in': 3600,
            });
          }

          expect(
            request.url.path,
            '/uapi/overseas-price/v1/quotations/price-detail',
          );
          expect(request.url.queryParameters, {
            'AUTH': '',
            'EXCD': 'NAS',
            'SYMB': 'AAPL',
          });
          expect(request.headers['tr_id'], 'HHDFS76200200');
          return jsonResponse({
            'rt_cd': '0',
            'output': {
              'last': '195.5',
              'base': '190',
              'open': '191',
              'high': '198',
              'low': '189',
              'pvol': '12345',
              'pamt': '2400000',
              'perx': '31.2',
              'pbrx': '44.5',
              'epsx': '6.28',
              'bpsx': '4.41',
              'h52p': '210',
              'l52p': '150',
            },
          });
        }),
      );

      final snapshot = await service.fetchSnapshot(
        holding(
          assetType: '주식',
          assetTitle: '애플',
          symbol: 'AAPL',
          currencyCode: 'USD',
          exchangeCode: 'NAS',
        ),
      );

      expect(snapshot.marketName, 'NASDAQ');
      expect(snapshot.currentPriceValue, 195.5);
      expect(snapshot.currentPrice, r'$195.50');
      expect(snapshot.dayChange, r'+$5.50');
      expect(snapshot.dayChangeRate, '+2.89%');
      expect(snapshot.previousClose, r'$190');
      expect(snapshot.week52High, r'$210');
    });

    test('parses ETF summary and top component quotes', () async {
      final service = MarketDataService.test(
        kisBaseUrl: 'https://kis.test',
        kisAppKey: 'app-key',
        kisAppSecret: 'app-secret',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            return jsonResponse({
              'access_token': 'token-1',
              'expires_in': 3600,
            });
          }

          if (request.url.path.endsWith('/inquire-price')) {
            expect(request.headers['tr_id'], 'FHPST02400000');
            return jsonResponse({
              'rt_cd': '0',
              'output': {
                'stck_prpr': '10250',
                'bstp_kor_isnm': 'ETF',
                'prdy_vrss': '50',
                'prdy_vrss_sign': '2',
                'prdy_ctrt': '0.49',
                'stck_prdy_clpr': '10200',
                'stck_oprc': '10100',
                'stck_hgpr': '10300',
                'stck_lwpr': '10000',
                'acml_vol': '100000',
                'stck_dryy_hgpr': '12000',
                'stck_dryy_lwpr': '9000',
                'nav': '10240',
                'nav_prdy_ctrt': '0.33',
                'nav_prdy_vrss_sign': '2',
                'trc_errt': '0.04',
                'dprt': '0.10',
                'etf_ntas_ttam': '123000000000',
                'frgn_hldn_qty_rate': '2.5',
                'etf_dvdn_cycl': '분기',
                'etf_div_name': '국내주식',
                'stck_lstn_date': '20200102',
                'crcd': 'KRW',
              },
            });
          }

          expect(
            request.url.path.endsWith('/inquire-component-stock-price'),
            isTrue,
          );
          expect(request.headers['tr_id'], 'FHKST121600C0');
          expect(request.url.queryParameters['FID_COND_SCR_DIV_CODE'], '16616');
          return jsonResponse({
            'rt_cd': '0',
            'output1': {
              'etf_cnfg_issu_cnt': '2',
              'etf_cnfg_issu_avls': '1000000000',
              'etf_ntas_ttam': '123000000000',
              'etf_cu_unit_scrt_cnt': '50000',
              'oprc_nav': '10100',
              'hprc_nav': '10300',
              'lprc_nav': '10000',
            },
            'output2': [
              {
                'stck_shrn_iscd': '005930',
                'hts_kor_isnm': '삼성전자',
                'stck_prpr': '70000',
                'prdy_ctrt': '1.2',
                'prdy_vrss_sign': '2',
                'etf_cnfg_issu_rlim': '25.5',
                'etf_vltn_amt': '255000000',
              },
              {
                'stck_shrn_iscd': '000660',
                'hts_kor_isnm': 'SK하이닉스',
                'stck_prpr': '150000',
                'prdy_ctrt': '0.8',
                'prdy_vrss_sign': '5',
                'etf_cnfg_issu_rlim': '18.0',
                'etf_vltn_amt': '180000000',
              },
            ],
          });
        }),
      );

      final snapshot = await service.fetchSnapshot(
        holding(assetType: '펀드', assetTitle: 'KODEX 테스트', symbol: '069500'),
      );

      expect(snapshot.currentPriceValue, 10250);
      expect(snapshot.nav, '₩10,240');
      expect(snapshot.navChangeRate, '+0.33%');
      expect(snapshot.trackingError, '0.04%');
      expect(snapshot.listingDate, '2020-01-02');
      expect(snapshot.etfComponentCount, '2');
      expect(snapshot.etfTopComponents, hasLength(2));
      expect(snapshot.etfTopComponents.first.code, '005930');
      expect(snapshot.etfTopComponents.first.changeRate, '+1.20%');
      expect(snapshot.etfTopComponents.last.changeRate, '-0.80%');
    });

    test(
      'clears stale token and retries once after HTTP auth failure',
      () async {
        var tokenRequests = 0;
        var quoteRequests = 0;
        final service = MarketDataService.test(
          kisBaseUrl: 'https://kis.test',
          kisAppKey: 'app-key',
          kisAppSecret: 'app-secret',
          client: MockClient((request) async {
            if (request.method == 'POST') {
              tokenRequests += 1;
              return jsonResponse({
                'access_token': 'token-$tokenRequests',
                'expires_in': 3600,
              });
            }

            quoteRequests += 1;
            if (quoteRequests == 1) {
              expect(request.headers['authorization'], 'Bearer token-1');
              return http.Response('unauthorized', 401);
            }
            expect(request.headers['authorization'], 'Bearer token-2');
            return jsonResponse({
              'rt_cd': '0',
              'output': {'stck_prpr': '71000'},
            });
          }),
        );

        final snapshot = await service.fetchSnapshot(
          holding(assetType: '주식', assetTitle: '삼성전자', symbol: '005930'),
        );

        expect(tokenRequests, 2);
        expect(quoteRequests, 2);
        expect(snapshot.currentPrice, '₩71,000');
      },
    );

    test(
      'clears stale token and retries once after KIS business auth error',
      () async {
        var tokenRequests = 0;
        var quoteRequests = 0;
        final service = MarketDataService.test(
          kisBaseUrl: 'https://kis.test',
          kisAppKey: 'app-key',
          kisAppSecret: 'app-secret',
          client: MockClient((request) async {
            if (request.method == 'POST') {
              tokenRequests += 1;
              return jsonResponse({
                'access_token': 'token-$tokenRequests',
                'expires_in': 3600,
              });
            }

            quoteRequests += 1;
            if (quoteRequests == 1) {
              return jsonResponse({
                'rt_cd': '1',
                'msg_cd': 'EGW00123',
                'msg1': 'token expired',
              });
            }
            expect(request.headers['authorization'], 'Bearer token-2');
            return jsonResponse({
              'rt_cd': '0',
              'output': {'stck_prpr': '72000'},
            });
          }),
        );

        final snapshot = await service.fetchSnapshot(
          holding(assetType: '주식', assetTitle: '삼성전자', symbol: '005930'),
        );

        expect(tokenRequests, 2);
        expect(quoteRequests, 2);
        expect(snapshot.currentPrice, '₩72,000');
      },
    );
  });
}
