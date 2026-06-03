import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class EquityResearchService {
  EquityResearchService._();

  static final EquityResearchService instance = EquityResearchService._();
  static const _schemaName = 'equity_research';

  Future<List<EquityResearchReportSummary>> fetchReports({
    int limit = 30,
  }) async {
    if (!await AuthService.ensureInitialized()) {
      debugPrint('[equity-research] skipped: auth not initialized');
      return const [];
    }

    try {
      final schema = AuthService.client.schema(_schemaName);
      final reportRows = await schema
          .from('research_reports')
          .select(_reportColumns)
          .order('report_date', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      final reports = reportRows
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry('$key', value)))
          .toList(growable: false);
      if (reports.isEmpty) return const [];

      final companyIds = reports
          .map((row) => _readInt(row['company_id']))
          .where((id) => id > 0)
          .toSet()
          .toList(growable: false);
      final companiesById = await _fetchCompaniesById(companyIds);

      return reports
          .map(
            (row) => EquityResearchReportSummary.fromJson(
              row,
              companiesById[_readInt(row['company_id'])],
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('[equity-research] failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<EquityResearchReportDetail> fetchReportDetail(int reportId) async {
    if (!await AuthService.ensureInitialized()) {
      debugPrint('[equity-research-detail] skipped: auth not initialized');
      return EquityResearchReportDetail.empty(reportId);
    }

    try {
      final schema = AuthService.client.schema(_schemaName);
      final results = await Future.wait<Object>([
        schema
            .from('report_sections')
            .select(_sectionColumns)
            .eq('report_id', reportId)
            .order('sort_order', ascending: true)
            .order('id', ascending: true),
        schema
            .from('company_metrics')
            .select(_metricColumns)
            .eq('report_id', reportId)
            .order('id', ascending: true),
        schema
            .from('investment_theses')
            .select(_thesisColumns)
            .eq('report_id', reportId)
            .order('sort_order', ascending: true)
            .order('id', ascending: true),
        schema
            .from('risks')
            .select(_riskColumns)
            .eq('report_id', reportId)
            .order('sort_order', ascending: true)
            .order('id', ascending: true),
        schema
            .from('catalysts')
            .select(_catalystColumns)
            .eq('report_id', reportId)
            .order('sort_order', ascending: true)
            .order('id', ascending: true),
        schema
            .from('valuation_views')
            .select(_valuationColumns)
            .eq('report_id', reportId)
            .order('id', ascending: true),
        schema
            .from('scenarios')
            .select(_scenarioColumns)
            .eq('report_id', reportId)
            .order('sort_order', ascending: true)
            .order('id', ascending: true),
        schema
            .from('monitoring_indicators')
            .select(_monitoringColumns)
            .eq('report_id', reportId)
            .order('sort_order', ascending: true)
            .order('id', ascending: true),
        _fetchSourceDocuments(reportId),
      ]);

      return EquityResearchReportDetail(
        reportId: reportId,
        sections: _mapRows(results[0], EquityResearchSection.fromJson),
        metrics: _mapRows(results[1], EquityResearchMetric.fromJson),
        theses: _mapRows(results[2], EquityResearchThesis.fromJson),
        risks: _mapRows(results[3], EquityResearchRisk.fromJson),
        catalysts: _mapRows(results[4], EquityResearchCatalyst.fromJson),
        valuationViews: _mapRows(
          results[5],
          EquityResearchValuationView.fromJson,
        ),
        scenarios: _mapRows(results[6], EquityResearchScenario.fromJson),
        monitoringIndicators: _mapRows(
          results[7],
          EquityResearchMonitoringIndicator.fromJson,
        ),
        sourceDocuments: results[8] as List<EquityResearchSourceDocument>,
      );
    } catch (error, stackTrace) {
      debugPrint('[equity-research-detail] failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<int, EquityResearchCompany>> _fetchCompaniesById(
    List<int> companyIds,
  ) async {
    if (companyIds.isEmpty) return const {};
    final rows = await AuthService.client
        .schema(_schemaName)
        .from('companies')
        .select(_companyColumns)
        .inFilter('id', companyIds);
    return {
      for (final row in rows.whereType<Map>())
        _readInt(row['id']): EquityResearchCompany.fromJson(
          row.map((key, value) => MapEntry('$key', value)),
        ),
    };
  }

  Future<List<EquityResearchSourceDocument>> _fetchSourceDocuments(
    int reportId,
  ) async {
    final schema = AuthService.client.schema(_schemaName);
    final refRows = await schema
        .from('report_source_documents')
        .select('source_document_id,role,sort_order')
        .eq('report_id', reportId)
        .order('sort_order', ascending: true);
    final refs = refRows
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
    final ids = refs
        .map((row) => _readInt(row['source_document_id']))
        .where((id) => id > 0)
        .toList(growable: false);
    if (ids.isEmpty) return const [];

    final documentRows = await schema
        .from('source_documents')
        .select(_sourceDocumentColumns)
        .inFilter('id', ids)
        .order('published_date', ascending: false);
    final documentsById = {
      for (final row in documentRows.whereType<Map>())
        _readInt(row['id']): EquityResearchSourceDocument.fromJson(
          row.map((key, value) => MapEntry('$key', value)),
        ),
    };
    return refs
        .map((row) => documentsById[_readInt(row['source_document_id'])])
        .whereType<EquityResearchSourceDocument>()
        .toList(growable: false);
  }

  static List<T> _mapRows<T>(
    Object value,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map((row) => mapper(row.map((key, value) => MapEntry('$key', value))))
        .toList(growable: false);
  }

  static final _companyColumns = [
    'id',
    'ticker',
    'exchange',
    'company_name',
    'sector',
    'industry',
    'currency',
  ].join(',');

  static final _reportColumns = [
    'id',
    'company_id',
    'report_slug',
    'title',
    'report_type',
    'report_date',
    'as_of_date',
    'author',
    'language',
    'summary',
    'one_line_conclusion',
    'investment_stance',
    'confidence_level',
    'is_investment_advice',
    'created_at',
    'updated_at',
  ].join(',');

  static final _sectionColumns = [
    'id',
    'parent_section_id',
    'section_no',
    'title',
    'section_type',
    'sort_order',
    'body',
  ].join(',');

  static final _metricColumns = [
    'id',
    'metric_name',
    'metric_value',
    'metric_text',
    'metric_unit',
    'currency',
    'fiscal_period',
    'period_end_date',
    'yoy_change_pct',
    'qoq_change_pct',
    'notes',
  ].join(',');

  static final _thesisColumns = [
    'id',
    'thesis_side',
    'title',
    'thesis_text',
    'importance_score',
    'sort_order',
  ].join(',');

  static final _riskColumns = [
    'id',
    'risk_category',
    'title',
    'description',
    'probability_level',
    'impact_level',
    'time_horizon',
    'mitigation_or_watchpoint',
    'sort_order',
  ].join(',');

  static final _catalystColumns = [
    'id',
    'catalyst_category',
    'title',
    'description',
    'expected_timing',
    'expected_direction',
    'sort_order',
  ].join(',');

  static final _valuationColumns = [
    'id',
    'valuation_method',
    'stance',
    'rating',
    'price_at_analysis',
    'target_price',
    'target_price_low',
    'target_price_high',
    'fair_value',
    'implied_upside_pct',
    'currency',
    'time_horizon',
    'key_assumptions',
    'notes',
  ].join(',');

  static final _scenarioColumns = [
    'id',
    'scenario_name',
    'scenario_title',
    'summary',
    'valuation_anchor',
    'expected_outcome',
    'sort_order',
  ].join(',');

  static final _monitoringColumns = [
    'id',
    'area',
    'indicator_name',
    'positive_signal',
    'negative_signal',
    'check_frequency',
    'source_hint',
    'sort_order',
  ].join(',');

  static final _sourceDocumentColumns = [
    'id',
    'source_name',
    'publisher',
    'analyst_or_author',
    'document_title',
    'document_type',
    'published_date',
    'url',
    'access_type',
    'source_quality_grade',
    'stance',
    'rating',
    'price_target',
    'price_target_currency',
    'fair_value',
    'fair_value_currency',
    'notes',
  ].join(',');
}

class EquityResearchCompany {
  const EquityResearchCompany({
    required this.id,
    required this.ticker,
    required this.exchange,
    required this.companyName,
    required this.sector,
    required this.industry,
    required this.currency,
  });

  factory EquityResearchCompany.fromJson(Map<String, dynamic> json) {
    return EquityResearchCompany(
      id: _readInt(json['id']),
      ticker: _readString(json['ticker']),
      exchange: _readString(json['exchange']),
      companyName: _readString(json['company_name']),
      sector: _readString(json['sector']),
      industry: _readString(json['industry']),
      currency: _readString(json['currency']),
    );
  }

  final int id;
  final String ticker;
  final String exchange;
  final String companyName;
  final String sector;
  final String industry;
  final String currency;
}

class EquityResearchReportSummary {
  const EquityResearchReportSummary({
    required this.id,
    required this.companyId,
    required this.company,
    required this.reportSlug,
    required this.title,
    required this.reportType,
    required this.reportDate,
    required this.asOfDate,
    required this.author,
    required this.language,
    required this.summary,
    required this.oneLineConclusion,
    required this.investmentStance,
    required this.confidenceLevel,
    required this.isInvestmentAdvice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EquityResearchReportSummary.fromJson(
    Map<String, dynamic> json,
    EquityResearchCompany? company,
  ) {
    return EquityResearchReportSummary(
      id: _readInt(json['id']),
      companyId: _readInt(json['company_id']),
      company: company,
      reportSlug: _readString(json['report_slug']),
      title: _readString(json['title']),
      reportType: _readString(json['report_type']),
      reportDate: _readDate(json['report_date']),
      asOfDate: _readDate(json['as_of_date']),
      author: _readString(json['author']),
      language: _readString(json['language']),
      summary: _readString(json['summary']),
      oneLineConclusion: _readString(json['one_line_conclusion']),
      investmentStance: _readString(json['investment_stance']),
      confidenceLevel: _readString(json['confidence_level']),
      isInvestmentAdvice: _readBool(json['is_investment_advice']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  final int id;
  final int companyId;
  final EquityResearchCompany? company;
  final String reportSlug;
  final String title;
  final String reportType;
  final DateTime? reportDate;
  final DateTime? asOfDate;
  final String author;
  final String language;
  final String summary;
  final String oneLineConclusion;
  final String investmentStance;
  final String confidenceLevel;
  final bool isInvestmentAdvice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get ticker => company?.ticker ?? '';
  String get companyName => company?.companyName ?? '';
  String get displayTitle => title.isNotEmpty ? title : '$ticker 리서치';

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final haystack = [
      ticker,
      companyName,
      displayTitle,
      summary,
      oneLineConclusion,
      investmentStance,
      confidenceLevel,
      company?.sector ?? '',
      company?.industry ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

class EquityResearchReportDetail {
  const EquityResearchReportDetail({
    required this.reportId,
    required this.sections,
    required this.metrics,
    required this.theses,
    required this.risks,
    required this.catalysts,
    required this.valuationViews,
    required this.scenarios,
    required this.monitoringIndicators,
    required this.sourceDocuments,
  });

  const EquityResearchReportDetail.empty(this.reportId)
    : sections = const [],
      metrics = const [],
      theses = const [],
      risks = const [],
      catalysts = const [],
      valuationViews = const [],
      scenarios = const [],
      monitoringIndicators = const [],
      sourceDocuments = const [];

  final int reportId;
  final List<EquityResearchSection> sections;
  final List<EquityResearchMetric> metrics;
  final List<EquityResearchThesis> theses;
  final List<EquityResearchRisk> risks;
  final List<EquityResearchCatalyst> catalysts;
  final List<EquityResearchValuationView> valuationViews;
  final List<EquityResearchScenario> scenarios;
  final List<EquityResearchMonitoringIndicator> monitoringIndicators;
  final List<EquityResearchSourceDocument> sourceDocuments;
}

class EquityResearchSection {
  const EquityResearchSection({
    required this.id,
    required this.parentSectionId,
    required this.sectionNo,
    required this.title,
    required this.sectionType,
    required this.body,
  });

  factory EquityResearchSection.fromJson(Map<String, dynamic> json) {
    return EquityResearchSection(
      id: _readInt(json['id']),
      parentSectionId: _readNullableInt(json['parent_section_id']),
      sectionNo: _readString(json['section_no']),
      title: _readString(json['title']),
      sectionType: _readString(json['section_type']),
      body: _readString(json['body']),
    );
  }

  final int id;
  final int? parentSectionId;
  final String sectionNo;
  final String title;
  final String sectionType;
  final String body;
}

class EquityResearchMetric {
  const EquityResearchMetric({
    required this.name,
    required this.value,
    required this.text,
    required this.unit,
    required this.currency,
    required this.fiscalPeriod,
    required this.yoyChangePct,
    required this.qoqChangePct,
  });

  factory EquityResearchMetric.fromJson(Map<String, dynamic> json) {
    return EquityResearchMetric(
      name: _readString(json['metric_name']),
      value: _readDouble(json['metric_value']),
      text: _readString(json['metric_text']),
      unit: _readString(json['metric_unit']),
      currency: _readString(json['currency']),
      fiscalPeriod: _readString(json['fiscal_period']),
      yoyChangePct: _readDouble(json['yoy_change_pct']),
      qoqChangePct: _readDouble(json['qoq_change_pct']),
    );
  }

  final String name;
  final double? value;
  final String text;
  final String unit;
  final String currency;
  final String fiscalPeriod;
  final double? yoyChangePct;
  final double? qoqChangePct;
}

class EquityResearchThesis {
  const EquityResearchThesis({
    required this.side,
    required this.title,
    required this.text,
    required this.importanceScore,
  });

  factory EquityResearchThesis.fromJson(Map<String, dynamic> json) {
    return EquityResearchThesis(
      side: _readString(json['thesis_side']),
      title: _readString(json['title']),
      text: _readString(json['thesis_text']),
      importanceScore: _readInt(json['importance_score']),
    );
  }

  final String side;
  final String title;
  final String text;
  final int importanceScore;
}

class EquityResearchRisk {
  const EquityResearchRisk({
    required this.category,
    required this.title,
    required this.description,
    required this.probabilityLevel,
    required this.impactLevel,
    required this.timeHorizon,
    required this.mitigationOrWatchpoint,
  });

  factory EquityResearchRisk.fromJson(Map<String, dynamic> json) {
    return EquityResearchRisk(
      category: _readString(json['risk_category']),
      title: _readString(json['title']),
      description: _readString(json['description']),
      probabilityLevel: _readString(json['probability_level']),
      impactLevel: _readString(json['impact_level']),
      timeHorizon: _readString(json['time_horizon']),
      mitigationOrWatchpoint: _readString(json['mitigation_or_watchpoint']),
    );
  }

  final String category;
  final String title;
  final String description;
  final String probabilityLevel;
  final String impactLevel;
  final String timeHorizon;
  final String mitigationOrWatchpoint;
}

class EquityResearchCatalyst {
  const EquityResearchCatalyst({
    required this.category,
    required this.title,
    required this.description,
    required this.expectedTiming,
    required this.expectedDirection,
  });

  factory EquityResearchCatalyst.fromJson(Map<String, dynamic> json) {
    return EquityResearchCatalyst(
      category: _readString(json['catalyst_category']),
      title: _readString(json['title']),
      description: _readString(json['description']),
      expectedTiming: _readString(json['expected_timing']),
      expectedDirection: _readString(json['expected_direction']),
    );
  }

  final String category;
  final String title;
  final String description;
  final String expectedTiming;
  final String expectedDirection;
}

class EquityResearchValuationView {
  const EquityResearchValuationView({
    required this.method,
    required this.stance,
    required this.rating,
    required this.priceAtAnalysis,
    required this.targetPrice,
    required this.targetPriceLow,
    required this.targetPriceHigh,
    required this.fairValue,
    required this.impliedUpsidePct,
    required this.currency,
    required this.timeHorizon,
    required this.keyAssumptions,
    required this.notes,
  });

  factory EquityResearchValuationView.fromJson(Map<String, dynamic> json) {
    return EquityResearchValuationView(
      method: _readString(json['valuation_method']),
      stance: _readString(json['stance']),
      rating: _readString(json['rating']),
      priceAtAnalysis: _readDouble(json['price_at_analysis']),
      targetPrice: _readDouble(json['target_price']),
      targetPriceLow: _readDouble(json['target_price_low']),
      targetPriceHigh: _readDouble(json['target_price_high']),
      fairValue: _readDouble(json['fair_value']),
      impliedUpsidePct: _readDouble(json['implied_upside_pct']),
      currency: _readString(json['currency']),
      timeHorizon: _readString(json['time_horizon']),
      keyAssumptions: _readString(json['key_assumptions']),
      notes: _readString(json['notes']),
    );
  }

  final String method;
  final String stance;
  final String rating;
  final double? priceAtAnalysis;
  final double? targetPrice;
  final double? targetPriceLow;
  final double? targetPriceHigh;
  final double? fairValue;
  final double? impliedUpsidePct;
  final String currency;
  final String timeHorizon;
  final String keyAssumptions;
  final String notes;
}

class EquityResearchScenario {
  const EquityResearchScenario({
    required this.name,
    required this.title,
    required this.summary,
    required this.valuationAnchor,
    required this.expectedOutcome,
  });

  factory EquityResearchScenario.fromJson(Map<String, dynamic> json) {
    return EquityResearchScenario(
      name: _readString(json['scenario_name']),
      title: _readString(json['scenario_title']),
      summary: _readString(json['summary']),
      valuationAnchor: _readString(json['valuation_anchor']),
      expectedOutcome: _readString(json['expected_outcome']),
    );
  }

  final String name;
  final String title;
  final String summary;
  final String valuationAnchor;
  final String expectedOutcome;
}

class EquityResearchMonitoringIndicator {
  const EquityResearchMonitoringIndicator({
    required this.area,
    required this.name,
    required this.positiveSignal,
    required this.negativeSignal,
    required this.checkFrequency,
    required this.sourceHint,
  });

  factory EquityResearchMonitoringIndicator.fromJson(
    Map<String, dynamic> json,
  ) {
    return EquityResearchMonitoringIndicator(
      area: _readString(json['area']),
      name: _readString(json['indicator_name']),
      positiveSignal: _readString(json['positive_signal']),
      negativeSignal: _readString(json['negative_signal']),
      checkFrequency: _readString(json['check_frequency']),
      sourceHint: _readString(json['source_hint']),
    );
  }

  final String area;
  final String name;
  final String positiveSignal;
  final String negativeSignal;
  final String checkFrequency;
  final String sourceHint;
}

class EquityResearchSourceDocument {
  const EquityResearchSourceDocument({
    required this.id,
    required this.sourceName,
    required this.publisher,
    required this.analystOrAuthor,
    required this.title,
    required this.type,
    required this.publishedDate,
    required this.url,
    required this.accessType,
    required this.qualityGrade,
    required this.stance,
    required this.rating,
    required this.priceTarget,
    required this.priceTargetCurrency,
    required this.fairValue,
    required this.fairValueCurrency,
    required this.notes,
  });

  factory EquityResearchSourceDocument.fromJson(Map<String, dynamic> json) {
    return EquityResearchSourceDocument(
      id: _readInt(json['id']),
      sourceName: _readString(json['source_name']),
      publisher: _readString(json['publisher']),
      analystOrAuthor: _readString(json['analyst_or_author']),
      title: _readString(json['document_title']),
      type: _readString(json['document_type']),
      publishedDate: _readDate(json['published_date']),
      url: _readString(json['url']),
      accessType: _readString(json['access_type']),
      qualityGrade: _readString(json['source_quality_grade']),
      stance: _readString(json['stance']),
      rating: _readString(json['rating']),
      priceTarget: _readDouble(json['price_target']),
      priceTargetCurrency: _readString(json['price_target_currency']),
      fairValue: _readDouble(json['fair_value']),
      fairValueCurrency: _readString(json['fair_value_currency']),
      notes: _readString(json['notes']),
    );
  }

  final int id;
  final String sourceName;
  final String publisher;
  final String analystOrAuthor;
  final String title;
  final String type;
  final DateTime? publishedDate;
  final String url;
  final String accessType;
  final String qualityGrade;
  final String stance;
  final String rating;
  final double? priceTarget;
  final String priceTargetCurrency;
  final double? fairValue;
  final String fairValueCurrency;
  final String notes;
}

String _readString(Object? value) {
  return value == null ? '' : '$value'.trim();
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_readString(value)) ?? 0;
}

int? _readNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_readString(value));
}

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(_readString(value));
}

bool _readBool(Object? value) {
  if (value is bool) return value;
  final raw = _readString(value).toLowerCase();
  return raw == 'true' || raw == '1';
}

DateTime? _readDate(Object? value) {
  final raw = _readString(value);
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

DateTime? _readDateTime(Object? value) {
  final raw = _readString(value);
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}
