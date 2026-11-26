import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';

class SnapshotVisibility {
  SnapshotVisibility(List<AssetItem> assets)
    : _assets = assets,
      _assetsById = {
        for (final asset in assets)
          if (asset.id != null) asset.id!: asset,
      },
      _assetsByClientId = {
        for (final asset in assets)
          if (asset.clientId?.isNotEmpty == true) asset.clientId!: asset,
      },
      _holdingsById = {
        for (final asset in assets)
          for (final holding in asset.holdings)
            if (holding.id != null) holding.id!: holding,
      },
      _holdingsByClientId = {
        for (final asset in assets)
          for (final holding in asset.holdings)
            if (holding.clientId?.isNotEmpty == true)
              (_isCashHolding(holding), holding.clientId!): holding,
      };

  final List<AssetItem> _assets;
  final Map<int, AssetItem> _assetsById;
  final Map<String, AssetItem> _assetsByClientId;
  final Map<int, HoldingItem> _holdingsById;
  final Map<(bool, String), HoldingItem> _holdingsByClientId;

  AssetItem? _asset(int? id, String? clientId, String title) {
    if (clientId != null && clientId.isNotEmpty) {
      return _assetsByClientId[clientId];
    }
    final normalizedTitle = _normalize(title);
    return _assetsById[id] ??
        (normalizedTitle.isEmpty
            ? null
            : _assets
                  .where(
                    (asset) =>
                        _normalize(asset.title) == normalizedTitle ||
                        _normalize(asset.displayName) == normalizedTitle,
                  )
                  .singleOrNull);
  }

  String _assetKey(int? id, String? clientId, String title) {
    final asset = _asset(id, clientId, title);
    final resolvedClientId = asset?.clientId ?? clientId;
    if (resolvedClientId != null && resolvedClientId.isNotEmpty) {
      return 'client:$resolvedClientId';
    }
    final resolvedId = asset?.id ?? id;
    return resolvedId != null && resolvedId > 0
        ? 'asset:$resolvedId'
        : 'title:${_normalize(title)}';
  }

  bool _childIsHidden(
    AssetItem? asset, {
    required int? id,
    required String? clientId,
    required String name,
    required bool cash,
    String? symbol,
    String? currencyCode,
  }) {
    if (clientId != null && clientId.isNotEmpty) {
      return _holdingsByClientId[(cash, clientId)]?.isHidden ?? false;
    }
    final byId = _holdingsById[id];
    if (byId != null && _isCashHolding(byId) == cash) return byId.isHidden;

    // Legacy snapshots can lack local child IDs. Match names only in their
    // owning group and only when the match is unambiguous.
    final normalizedName = _normalize(name);
    if (asset == null || normalizedName.isEmpty) return false;
    final normalizedSymbol = _normalize(symbol ?? '');
    final normalizedCurrency = _normalize(currencyCode ?? '');
    return asset.holdings
            .where(
              (holding) =>
                  _isCashHolding(holding) == cash &&
                  _normalize(holding.name) == normalizedName &&
                  (normalizedSymbol.isEmpty ||
                      _normalize(holding.symbol) == normalizedSymbol) &&
                  (normalizedCurrency.isEmpty ||
                      _normalize(holding.currencyCode) == normalizedCurrency),
            )
            .singleOrNull
            ?.isHidden ??
        false;
  }

  bool includesTransaction(SnapshotTransactionRecord row) {
    final asset = _asset(row.assetId, null, row.assetTitle);
    return asset?.isHidden != true &&
        !_childIsHidden(
          asset,
          id: row.holdingId,
          clientId: null,
          name: row.holdingName,
          cash: false,
        );
  }

  bool includesCashTransaction(SnapshotCashTransactionRecord row) {
    final asset = _asset(row.assetId, null, row.assetTitle);
    return asset?.isHidden != true &&
        !_childIsHidden(
          asset,
          id: _cashHoldingId(row.cashAccountId),
          clientId: null,
          name: row.cashAccountName,
          cash: true,
          currencyCode: row.currencyCode,
        );
  }

  List<SnapshotDisplayItem> buildItems({
    required DailyPortfolioSnapshot snapshot,
    required List<DailyPortfolioSnapshotItem> items,
    required List<DailyPortfolioSnapshotHoldingItem> holdings,
    required List<SnapshotCashAccountRecord> cashAccounts,
  }) {
    final itemKeys = <String, List<String>>{};
    for (final item in items) {
      final title = _normalize(item.assetTitle);
      if (title.isEmpty) continue;
      final key = _assetKey(item.assetId, item.assetClientId, item.assetTitle);
      itemKeys.putIfAbsent(title, () => []).add(key);
    }

    String keyForChild(int? id, String? clientId, String title) {
      final key = _assetKey(id, clientId, title);
      final titleMatch = itemKeys[_normalize(title)]?.singleOrNull;
      // Older rows can have a group ID on only one side of the relation.
      if (titleMatch != null &&
          (key.startsWith('title:') || titleMatch.startsWith('title:'))) {
        return titleMatch;
      }
      return key;
    }

    final holdingsByAsset = <String, List<DailyPortfolioSnapshotHoldingItem>>{};
    for (final row in holdings) {
      final key = keyForChild(row.assetId, row.assetClientId, row.assetTitle);
      holdingsByAsset.putIfAbsent(key, () => []).add(row);
    }
    final cashByAsset = <String, List<SnapshotCashAccountRecord>>{};
    for (final row in cashAccounts) {
      final key = keyForChild(row.assetId, row.assetClientId, row.assetTitle);
      cashByAsset.putIfAbsent(key, () => []).add(row);
    }

    final result = <SnapshotDisplayItem>[];
    for (final item in items) {
      final asset = _asset(item.assetId, item.assetClientId, item.assetTitle);
      if (asset?.isHidden == true) continue;

      final key = _assetKey(item.assetId, item.assetClientId, item.assetTitle);
      final relatedHoldings = holdingsByAsset[key] ?? const [];
      final relatedCash = cashByAsset[key] ?? const [];
      final visibleHoldings = <DailyPortfolioSnapshotHoldingItem>[];
      final visibleCash = <SnapshotCashAccountRecord>[];
      var hiddenCount = 0;
      var hiddenPurchase = 0.0;
      var hiddenValuation = 0.0;

      for (final row in relatedHoldings) {
        if (_childIsHidden(
          asset,
          id: row.holdingId,
          clientId: row.holdingClientId,
          name: row.holdingName,
          cash: false,
          symbol: row.holdingSymbol,
          currencyCode: row.currencyCode,
        )) {
          hiddenCount++;
          hiddenPurchase += row.totalPurchaseAmount;
          hiddenValuation += row.totalValuationAmount;
        } else {
          visibleHoldings.add(row);
        }
      }
      for (final row in relatedCash) {
        if (_childIsHidden(
          asset,
          id: _cashHoldingId(row.cashAccountId),
          clientId: row.cashAccountClientId,
          name: row.cashAccountName,
          cash: true,
          currencyCode: row.currencyCode,
        )) {
          hiddenCount++;
          final value = _cashValue(row, snapshot.exchangeRate);
          hiddenPurchase += value;
          hiddenValuation += value;
        } else {
          visibleCash.add(row);
        }
      }

      if (hiddenCount > 0 &&
          hiddenCount >= item.holdingCount &&
          visibleHoldings.isEmpty &&
          visibleCash.isEmpty) {
        continue;
      }

      result.add(
        SnapshotDisplayItem(
          assetKey: key,
          assetTitle: item.assetTitle,
          holdings: visibleHoldings,
          cashAccounts: visibleCash,
          totalPurchaseAmount: item.totalPurchaseAmount - hiddenPurchase,
          totalValuationAmount: item.totalValuationAmount - hiddenValuation,
        ),
      );
    }
    return result;
  }
}

class SnapshotDisplayItem {
  const SnapshotDisplayItem({
    required this.assetKey,
    required this.assetTitle,
    required this.holdings,
    required this.cashAccounts,
    required this.totalPurchaseAmount,
    required this.totalValuationAmount,
  });

  final String assetKey;
  final String assetTitle;
  final List<DailyPortfolioSnapshotHoldingItem> holdings;
  final List<SnapshotCashAccountRecord> cashAccounts;
  final double totalPurchaseAmount;
  final double totalValuationAmount;

  double get profitAmount => totalValuationAmount - totalPurchaseAmount;
  double get profitRate =>
      totalPurchaseAmount == 0 ? 0 : profitAmount / totalPurchaseAmount * 100;
}

int? _cashHoldingId(int? cashAccountId) =>
    cashAccountId == null ? null : -cashAccountId.abs();

bool _isCashHolding(HoldingItem holding) => (holding.id ?? 0) < 0;

double _cashValue(SnapshotCashAccountRecord row, double exchangeRate) =>
    row.currencyCode.toUpperCase() == 'USD'
    ? row.balance * exchangeRate
    : row.balance;

String _normalize(String value) => value.trim().toLowerCase();
