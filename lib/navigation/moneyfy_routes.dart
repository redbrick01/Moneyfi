abstract final class MoneyfyRouteNames {
  static const home = 'home';
  static const portfolio = 'portfolio';
  static const transactions = 'transactions';
  static const analysis = 'analysis';
  static const statistics = 'statistics';
  static const my = 'my';

  static const assetDetail = 'assetDetail';
  static const holdingDetail = 'holdingDetail';
  static const cashAccountDetail = 'cashAccountDetail';

  static const portfolioDiagnosis = 'portfolioDiagnosis';
  static const investmentPerformance = 'investmentPerformance';
  static const dividendInterest = 'dividendInterest';

  static const login = 'login';
  static const signup = 'signup';

  static const assetCreate = 'assetCreate';
  static const assetEdit = 'assetEdit';
  static const holdingCreate = 'holdingCreate';
  static const holdingEdit = 'holdingEdit';
  static const cashAccountCreate = 'cashAccountCreate';
  static const cashAccountEdit = 'cashAccountEdit';
  static const transactionCreate = 'transactionCreate';
  static const transactionEdit = 'transactionEdit';
  static const cashTransactionCreate = 'cashTransactionCreate';
  static const cashTransactionEdit = 'cashTransactionEdit';

  static String shellRouteNameForPath(String path) {
    return switch (path) {
      MoneyfyRoutePaths.home => home,
      MoneyfyRoutePaths.portfolio => portfolio,
      MoneyfyRoutePaths.transactions => transactions,
      MoneyfyRoutePaths.analysis => analysis,
      MoneyfyRoutePaths.statistics => statistics,
      MoneyfyRoutePaths.my => my,
      _ => home,
    };
  }
}

abstract final class MoneyfyRoutePaths {
  static const home = '/';
  static const portfolio = '/portfolio';
  static const transactions = '/transactions';
  static const analysis = '/analysis';
  static const statistics = '/statistics';
  static const my = '/my';

  static const shellTabPaths = <String>[
    home,
    portfolio,
    transactions,
    analysis,
    my,
  ];

  static const shellCompatiblePaths = <String>[...shellTabPaths, statistics];

  static const assetDetailPattern = '/assets/:assetId';
  static const holdingDetailPattern = '/holdings/:holdingId';
  static const cashAccountDetailPattern = '/cash-accounts/:holdingId';

  static const portfolioDiagnosis = '/analysis/portfolio-diagnosis';
  static const investmentPerformance = '/analysis/investment-performance';
  static const dividendInterest = '/analysis/dividend-interest';

  static const login = '/login';
  static const signup = '/signup';

  static const assetCreate = '/assets/new';
  static const assetEditPattern = '/assets/:assetId/edit';
  static const holdingCreatePattern = '/assets/:assetId/holdings/new';
  static const holdingEditPattern = '/holdings/:holdingId/edit';
  static const cashAccountCreatePattern = '/assets/:assetId/cash-accounts/new';
  static const cashAccountEditPattern = '/cash-accounts/:holdingId/edit';
  static const transactionCreatePattern =
      '/holdings/:holdingId/transactions/new';
  static const transactionEditPattern = '/transactions/:transactionId/edit';
  static const cashTransactionCreatePattern =
      '/cash-accounts/:holdingId/transactions/new';
  static const cashTransactionEditPattern =
      '/cash-transactions/:transactionId/edit';

  static String assetDetail(int assetId) => '/assets/$assetId';
  static String assetDetailWithClientId(int assetId, String? assetClientId) {
    return _withOptionalQuery(
      assetDetail(assetId),
      'assetClientId',
      assetClientId,
    );
  }

  static String holdingDetail(int holdingId) => '/holdings/$holdingId';
  static String holdingDetailWithClientId(
    int holdingId,
    String? holdingClientId,
  ) {
    return _withOptionalQuery(
      holdingDetail(holdingId),
      'holdingClientId',
      holdingClientId,
    );
  }

  static String cashAccountDetail(int holdingId) => '/cash-accounts/$holdingId';
  static String cashAccountDetailWithClientId(
    int holdingId,
    String? holdingClientId,
  ) {
    return _withOptionalQuery(
      cashAccountDetail(holdingId),
      'holdingClientId',
      holdingClientId,
    );
  }

  static String assetEdit(int assetId) => '/assets/$assetId/edit';
  static String holdingCreate(int assetId) => '/assets/$assetId/holdings/new';
  static String holdingEdit(int holdingId) => '/holdings/$holdingId/edit';
  static String cashAccountCreate(int assetId) =>
      '/assets/$assetId/cash-accounts/new';
  static String cashAccountEdit(int holdingId) =>
      '/cash-accounts/$holdingId/edit';
  static String transactionCreate(int holdingId) =>
      '/holdings/$holdingId/transactions/new';
  static String transactionCreateWithArgs({
    required int assetId,
    required int holdingId,
    String? holdingClientId,
    String? defaultName,
  }) {
    return _withQuery(transactionCreate(holdingId), {
      'assetId': '$assetId',
      if (holdingClientId != null && holdingClientId.isNotEmpty)
        'holdingClientId': holdingClientId,
      if (defaultName != null && defaultName.isNotEmpty)
        'defaultName': defaultName,
    });
  }

  static String transactionEdit(int transactionId) =>
      '/transactions/$transactionId/edit';
  static String cashTransactionCreate(int holdingId) =>
      '/cash-accounts/$holdingId/transactions/new';
  static String cashTransactionCreateWithArgs({
    required int assetId,
    required int holdingId,
    String? holdingClientId,
    String? defaultName,
  }) {
    return _withQuery(cashTransactionCreate(holdingId), {
      'assetId': '$assetId',
      if (holdingClientId != null && holdingClientId.isNotEmpty)
        'holdingClientId': holdingClientId,
      if (defaultName != null && defaultName.isNotEmpty)
        'defaultName': defaultName,
    });
  }

  static String cashTransactionEdit(int transactionId) =>
      '/cash-transactions/$transactionId/edit';

  static String _withOptionalQuery(String path, String key, String? value) {
    if (value == null || value.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: {key: value}).toString();
  }

  static String _withQuery(String path, Map<String, String> queryParameters) {
    if (queryParameters.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: queryParameters).toString();
  }
}

class AssetDetailRouteArgs {
  const AssetDetailRouteArgs({required this.assetId, this.assetClientId});

  final int assetId;
  final String? assetClientId;
}

class HoldingDetailRouteArgs {
  const HoldingDetailRouteArgs({required this.holdingId, this.holdingClientId});

  final int holdingId;
  final String? holdingClientId;
}

class CashAccountDetailRouteArgs {
  const CashAccountDetailRouteArgs({
    required this.holdingId,
    this.holdingClientId,
  });

  final int holdingId;
  final String? holdingClientId;
}
