// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_news_summary_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanyNewsSummaryItem _$CompanyNewsSummaryItemFromJson(
  Map<String, dynamic> json,
) => CompanyNewsSummaryItem(
  symbol: CompanyNewsSummaryItem._symbol(json['symbol']),
  found: CompanyNewsSummaryItem._found(json['found']),
  assetType: CompanyNewsSummaryItem._text(json['asset_type']),
  summaryDate: CompanyNewsSummaryItem._text(json['summary_date']),
  model: CompanyNewsSummaryItem._text(json['model']),
  newsCount: CompanyNewsSummaryItem._count(json['news_count']),
  createdAt: CompanyNewsSummaryItem._text(json['created_at']),
  updatedAt: CompanyNewsSummaryItem._text(json['updated_at']),
  cachedAt: CompanyNewsSummaryItem._text(json['cached_at']),
  summary: CompanyNewsSummaryItem._summary(json['summary']),
);

Map<String, dynamic> _$CompanyNewsSummaryItemToJson(
  CompanyNewsSummaryItem instance,
) => <String, dynamic>{
  'symbol': instance.symbol,
  'found': instance.found,
  'asset_type': instance.assetType,
  'summary_date': instance.summaryDate,
  'model': instance.model,
  'news_count': instance.newsCount,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'cached_at': instance.cachedAt,
  'summary': instance.summary,
};
