part of 'app_database.dart';

class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get lastModifiedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  TextColumn get assetType => text().withDefault(const Constant('주식'))();
  TextColumn get title => text()();
  TextColumn get alias => text().withDefault(const Constant(''))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  TextColumn get currencyCode => text().withDefault(const Constant('KRW'))();
  TextColumn get value => text()();
  TextColumn get change => text()();
  IntColumn get iconCodePoint => integer()();
  TextColumn get quantityLabel => text()();
  TextColumn get quantityValue => text()();
  TextColumn get averageLabel => text()();
  TextColumn get averageValue => text()();
  TextColumn get note => text()();
  IntColumn get sortOrder => integer()();
}

class Holdings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().references(Assets, #id)();
  TextColumn get clientId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get lastModifiedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  TextColumn get currencyCode => text().withDefault(const Constant('KRW'))();
  TextColumn get marketUpdatedAt => text().nullable()();
  TextColumn get exchangeCode => text().withDefault(const Constant(''))();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  RealColumn get quantity => real()();
  RealColumn get averagePrice => real()();
  RealColumn get currentPrice => real()();
  TextColumn get note => text()();
  IntColumn get sortOrder => integer()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().nullable().references(Assets, #id)();
  IntColumn get holdingId => integer().nullable().references(Holdings, #id)();
  TextColumn get clientId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get lastModifiedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  TextColumn get date => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get amount => text()();
  TextColumn get quantity => text()();
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get quantityValue => real().withDefault(const Constant(0))();
  RealColumn get grossAmount => real().withDefault(const Constant(0))();
  RealColumn get cashFlowAmount => real().withDefault(const Constant(0))();
  RealColumn get realizedProfitAmount =>
      real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer()();
}

class CashAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().references(Assets, #id)();
  TextColumn get clientId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get lastModifiedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  TextColumn get currencyCode => text().withDefault(const Constant('KRW'))();
  TextColumn get name => text()();
  RealColumn get baseBalance => real().withDefault(const Constant(0))();
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class CashTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().references(Assets, #id)();
  IntColumn get cashAccountId => integer().references(CashAccounts, #id)();
  TextColumn get clientId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get lastModifiedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get linkedTransactionId => integer().nullable()();
  TextColumn get date => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get amount => text()();
  RealColumn get amountValue => real().withDefault(const Constant(0))();
  RealColumn get cashFlowAmount => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class TransactionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get lastModifiedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  TextColumn get occurredAt => text()();
  TextColumn get kind => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get memo => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get flowCategory =>
      text().withDefault(const Constant('internal'))();
  TextColumn get legacySourceTable => text().nullable()();
  IntColumn get legacySourceId => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class TransactionLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(TransactionEvents, #id)();
  IntColumn get assetId => integer().nullable().references(Assets, #id)();
  IntColumn get holdingId => integer().nullable().references(Holdings, #id)();
  IntColumn get cashAccountId =>
      integer().nullable().references(CashAccounts, #id)();
  TextColumn get clientId => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get lastModifiedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  TextColumn get legacySourceTable => text().nullable()();
  IntColumn get legacySourceId => integer().nullable()();
  TextColumn get action => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('KRW'))();
  RealColumn get quantityDelta => real().withDefault(const Constant(0))();
  RealColumn get cashDelta => real().withDefault(const Constant(0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get grossAmount => real().withDefault(const Constant(0))();
  RealColumn get feeAmount => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get costBasisDelta => real().withDefault(const Constant(0))();
  RealColumn get realizedPnl => real().withDefault(const Constant(0))();
  RealColumn get fxRate => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class MarketNewsCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text().unique()();
  BoolColumn get found => boolean().withDefault(const Constant(false))();
  TextColumn get summaryDate => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get newsCount => integer().nullable()();
  TextColumn get summaryJson => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get cachedAt => text()();
}

class CompanyNewsCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get symbol => text().unique()();
  BoolColumn get found => boolean().withDefault(const Constant(false))();
  TextColumn get summaryDate => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get newsCount => integer().nullable()();
  TextColumn get summaryJson => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get cachedAt => text()();
}

class DailyPortfolioSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get snapshotDate => text()();
  RealColumn get totalPurchaseAmount => real()();
  RealColumn get totalValuationAmount => real()();
  RealColumn get profitAmount => real()();
  RealColumn get profitRate => real()();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  TextColumn get createdAt => text()();
}

class DailyPortfolioSnapshotItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get snapshotId =>
      integer().references(DailyPortfolioSnapshots, #id)();
  IntColumn get assetId => integer().references(Assets, #id)();
  TextColumn get assetTitle => text()();
  RealColumn get totalPurchaseAmount => real()();
  RealColumn get totalValuationAmount => real()();
  RealColumn get profitAmount => real()();
  RealColumn get profitRate => real()();
  IntColumn get holdingCount => integer()();
}

class DailyPortfolioSnapshotHoldingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get snapshotId =>
      integer().references(DailyPortfolioSnapshots, #id)();
  IntColumn get assetId => integer().nullable()();
  TextColumn get assetTitle => text()();
  IntColumn get holdingId => integer().nullable()();
  TextColumn get holdingName => text()();
  TextColumn get holdingSymbol => text()();
  TextColumn get currencyCode => text()();
  RealColumn get quantity => real()();
  RealColumn get totalPurchaseAmount => real()();
  RealColumn get totalValuationAmount => real()();
  RealColumn get profitAmount => real()();
  RealColumn get profitRate => real()();
}

class AssetAllocationTargets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().unique().references(Assets, #id)();
  RealColumn get targetRatio => real()();
}

class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get currencyPair => text()();
  RealColumn get rate => real()();
  TextColumn get recordedAt => text()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
}
