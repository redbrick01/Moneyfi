import 'package:flutter/material.dart';
import 'package:moneyfy/components/charts/value_history_card.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';

class HoldingPriceHistoryCard extends StatelessWidget {
  const HoldingPriceHistoryCard({
    super.key,
    required this.holding,
    required this.marketData,
    this.refreshVersion = 0,
  });

  final HoldingItem holding;
  final MarketDataService marketData;
  final int refreshVersion;

  @override
  Widget build(BuildContext context) {
    return ValueHistoryCard(
      title: '시세',
      valueLabel: '종가',
      chartLabel: '거래일별 종가 차트',
      through: marketData.latestDailyCloseDate(holding),
      sourceKey: (
        marketData,
        refreshVersion,
        holding.symbol,
        holding.exchangeCode,
        holding.currencyCode,
        holding.assetType ?? holding.assetTitle,
      ),
      loadPoints: (from, through, isCancelled) async {
        final closes = await marketData.fetchDailyCloses(
          holding,
          from: from,
          through: through,
          isCancelled: isCancelled,
        );
        return [
          for (final close in closes)
            HistoryPoint(date: close.date, value: close.price),
        ];
      },
      currencyCode: holding.currencyCode,
      transactions: holding.transactions,
      averagePrice: holding.averagePriceInTradingCurrency,
    );
  }
}
