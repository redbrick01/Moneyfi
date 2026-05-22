import 'asset_item.dart';

class FundComponentItem {
  const FundComponentItem({
    required this.code,
    required this.name,
    required this.price,
    required this.changeRate,
    required this.weight,
    required this.valuationAmount,
  });

  final String code;
  final String name;
  final String price;
  final String changeRate;
  final String weight;
  final String valuationAmount;
}

class HoldingMarketSnapshot {
  const HoldingMarketSnapshot({
    required this.marketName,
    required this.sectorName,
    required this.currentPrice,
    this.currentPriceValue,
    required this.dayChange,
    required this.dayChangeRate,
    required this.previousClose,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.turnover,
    required this.per,
    required this.pbr,
    required this.eps,
    required this.bps,
    required this.week52High,
    required this.week52Low,
    required this.nav,
    required this.navChangeRate,
    required this.trackingError,
    required this.disparityRate,
    required this.netAssets,
    required this.foreignHoldRate,
    required this.dividendCycle,
    required this.etfCategory,
    required this.listingDate,
    required this.quoteCurrency,
    required this.targetCurrency,
    required this.quoteVolume24h,
    required this.targetVolume24h,
    required this.bestAskPrice,
    required this.bestBidPrice,
    required this.bestAskQty,
    required this.bestBidQty,
    required this.etfComponentCount,
    required this.etfComponentMarketCap,
    required this.etfNetAssetsTotal,
    required this.etfCuUnitCount,
    required this.etfNavOpen,
    required this.etfNavHigh,
    required this.etfNavLow,
    required this.etfTopComponents,
  });

  factory HoldingMarketSnapshot.fallback(HoldingItem holding) {
    return HoldingMarketSnapshot(
      marketName: holding.assetTitle ?? '-',
      sectorName: '-',
      currentPrice: holding.primaryMetricValue,
      currentPriceValue: holding.currentPrice,
      dayChange: '-',
      dayChangeRate: '-',
      previousClose: '-',
      openPrice: '-',
      highPrice: '-',
      lowPrice: '-',
      volume: '-',
      turnover: '-',
      per: '-',
      pbr: '-',
      eps: '-',
      bps: '-',
      week52High: '-',
      week52Low: '-',
      nav: '-',
      navChangeRate: '-',
      trackingError: '-',
      disparityRate: '-',
      netAssets: '-',
      foreignHoldRate: '-',
      dividendCycle: '-',
      etfCategory: '-',
      listingDate: '-',
      quoteCurrency: holding.currencyCode,
      targetCurrency: holding.symbol.isEmpty ? '-' : holding.symbol,
      quoteVolume24h: '-',
      targetVolume24h: '-',
      bestAskPrice: '-',
      bestBidPrice: '-',
      bestAskQty: '-',
      bestBidQty: '-',
      etfComponentCount: '-',
      etfComponentMarketCap: '-',
      etfNetAssetsTotal: '-',
      etfCuUnitCount: '-',
      etfNavOpen: '-',
      etfNavHigh: '-',
      etfNavLow: '-',
      etfTopComponents: const [],
    );
  }

  final String marketName;
  final String sectorName;
  final String currentPrice;
  final double? currentPriceValue;
  final String dayChange;
  final String dayChangeRate;
  final String previousClose;
  final String openPrice;
  final String highPrice;
  final String lowPrice;
  final String volume;
  final String turnover;
  final String per;
  final String pbr;
  final String eps;
  final String bps;
  final String week52High;
  final String week52Low;
  final String nav;
  final String navChangeRate;
  final String trackingError;
  final String disparityRate;
  final String netAssets;
  final String foreignHoldRate;
  final String dividendCycle;
  final String etfCategory;
  final String listingDate;
  final String quoteCurrency;
  final String targetCurrency;
  final String quoteVolume24h;
  final String targetVolume24h;
  final String bestAskPrice;
  final String bestBidPrice;
  final String bestAskQty;
  final String bestBidQty;
  final String etfComponentCount;
  final String etfComponentMarketCap;
  final String etfNetAssetsTotal;
  final String etfCuUnitCount;
  final String etfNavOpen;
  final String etfNavHigh;
  final String etfNavLow;
  final List<FundComponentItem> etfTopComponents;
}
