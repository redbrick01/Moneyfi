import 'package:flutter/material.dart';
import 'package:moneyfy/components/forms/market_search_field.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/features/portfolio/screens/holding_detail_page.dart';
import 'package:moneyfy/features/portfolio/services/market_instrument_search.dart';
import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/navigation/moneyfy_routes.dart';

class PortfolioInstrumentSearch extends StatefulWidget {
  const PortfolioInstrumentSearch({
    super.key,
    required this.assets,
    required this.onHoldingClosed,
    this.assetType,
  });

  final List<AssetItem> assets;
  final String? assetType;
  final VoidCallback onHoldingClosed;

  @override
  State<PortfolioInstrumentSearch> createState() =>
      _PortfolioInstrumentSearchState();
}

class _PortfolioInstrumentSearchState extends State<PortfolioInstrumentSearch> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> openResult(MarketSearchResult result) async {
    FocusScope.of(context).unfocus();
    final matches = [
      for (final asset in widget.assets)
        if (asset.assetType == result.assetType)
          for (final holding in asset.holdings)
            if (holding.id != null &&
                holding.currencyCode == result.currencyCode &&
                holding.symbol.trim().toUpperCase() ==
                    result.symbol.trim().toUpperCase() &&
                (holding.currencyCode != 'USD' ||
                    holding.exchangeCode.isEmpty ||
                    result.exchangeCode.isEmpty ||
                    holding.exchangeCode == result.exchangeCode))
              (asset: asset, holding: holding),
    ];
    if (matches.isEmpty) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => HoldingDetailPage.market(result: result),
        ),
      );
      return;
    }
    final holding = matches.length == 1
        ? matches.single.holding
        : await showModalBottomSheet<HoldingItem>(
            context: context,
            builder: (sheetContext) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(title: Text('조회할 계좌 선택')),
                  for (final match in matches)
                    ListTile(
                      title: Text(match.asset.displayName),
                      subtitle: Text(match.holding.name),
                      onTap: () => Navigator.pop(sheetContext, match.holding),
                    ),
                ],
              ),
            ),
          );
    if (!mounted || holding == null) return;
    await context.openHoldingDetail(
      HoldingDetailRouteArgs(
        holdingId: holding.id!,
        holdingClientId: holding.clientId,
      ),
    );
    if (mounted) widget.onHoldingClosed();
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.assetType == null
        ? const {'주식', '펀드', '코인'}
        : {widget.assetType!};
    return MarketSearchField<MarketSearchResult>(
      controller: controller,
      label: '종목 검색',
      localSearch: (query) => searchMarketLocally(widget.assets, types, query),
      verify: (query, local) async {
        final verified = await verifyMarketSymbol(
          primaryAssetType: widget.assetType ?? '주식',
          searchableAssetTypes: types,
          query: query,
          localResults: local,
        );
        return verified == null ? local : mergeMarketResults(verified, local);
      },
      itemBuilder: (_, result) => ListTile(
        title: Text(result.name),
        subtitle: Text(result.marketLabel),
      ),
      onSelected: openResult,
      onEdited: () {},
    );
  }
}
