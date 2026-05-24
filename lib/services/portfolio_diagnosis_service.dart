import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import 'auth_service.dart';

class PortfolioDiagnosisService {
  PortfolioDiagnosisService._();

  static final PortfolioDiagnosisService instance =
      PortfolioDiagnosisService._();

  Future<PortfolioDiagnosisResult?>? _inFlightFetch;

  Future<PortfolioDiagnosisResult?> fetchDiagnosis({
    required Map<String, dynamic> portfolioInput,
    bool forceRefresh = false,
  }) async {
    final payloadKey = _buildPayloadKey();

    if (!forceRefresh && _inFlightFetch != null) {
      return _inFlightFetch!;
    }

    if (!forceRefresh) {
      final cached = await _fetchFreshCache(payloadKey: payloadKey);
      if (cached != null) {
        return cached;
      }
    }

    final future = _fetchDiagnosisFromRemote(
      portfolioInput: portfolioInput,
      payloadKey: payloadKey,
    );
    if (!forceRefresh) {
      _inFlightFetch = future;
    }

    try {
      return await future;
    } finally {
      if (identical(_inFlightFetch, future)) {
        _inFlightFetch = null;
      }
    }
  }

  Future<PortfolioDiagnosisCacheEntry?> fetchCachedDiagnosis() async {
    final payloadKey = _buildPayloadKey();
    final row = await AppDatabase.instance.fetchPortfolioDiagnosisCache(
      payloadKey: payloadKey,
    );
    if (row == null || row['diagnosis'] is! Map) return null;
    final diagnosisMap = Map<String, dynamic>.from(row['diagnosis'] as Map);
    if (_isFallbackDiagnosis(diagnosisMap)) return null;

    final cachedAtRaw = row['cached_at']?.toString();
    final cachedAt = cachedAtRaw == null
        ? null
        : DateTime.tryParse(cachedAtRaw);
    if (cachedAt == null) return null;

    return PortfolioDiagnosisCacheEntry(
      diagnosis: PortfolioDiagnosisResult.fromJson(
        diagnosisMap,
        model: row['model']?.toString(),
      ),
      cachedAt: cachedAt,
    );
  }

  Future<PortfolioDiagnosisResult?> _fetchDiagnosisFromRemote({
    required Map<String, dynamic> portfolioInput,
    required String payloadKey,
  }) async {
    if (!await AuthService.ensureInitialized()) {
      debugPrint('[portfolio-diagnosis] skipped: auth not initialized');
      return (await _fetchAnyCache(payloadKey: payloadKey)) ??
          _buildLocalFallbackDiagnosis(portfolioInput);
    }

    try {
      final response = await AuthService.client.functions.invoke(
        'get-portfolio-diagnosis',
        body: <String, Object?>{'portfolio': portfolioInput},
      );

      debugPrint(
        '[portfolio-diagnosis] response status=${response.status} data=${response.data}',
      );

      if (response.status != 200 || response.data is! Map) {
        return (await _fetchAnyCache(payloadKey: payloadKey)) ??
            _buildLocalFallbackDiagnosis(portfolioInput);
      }

      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true || payload['diagnosis'] is! Map) {
        return (await _fetchAnyCache(payloadKey: payloadKey)) ??
            _buildLocalFallbackDiagnosis(portfolioInput);
      }

      final diagnosisJson = Map<String, dynamic>.from(
        payload['diagnosis'] as Map,
      );
      final model = payload['model']?.toString();

      await AppDatabase.instance.savePortfolioDiagnosisCache(
        payloadKey: payloadKey,
        diagnosis: diagnosisJson,
        model: model,
      );

      return PortfolioDiagnosisResult.fromJson(
        diagnosisJson,
        model: payload['model']?.toString(),
      );
    } catch (error, stackTrace) {
      debugPrint('[portfolio-diagnosis] failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      return (await _fetchAnyCache(payloadKey: payloadKey)) ??
          _buildLocalFallbackDiagnosis(portfolioInput);
    }
  }

  Future<PortfolioDiagnosisResult?> _fetchFreshCache({
    required String payloadKey,
  }) async {
    final row = await AppDatabase.instance.fetchPortfolioDiagnosisCache(
      payloadKey: payloadKey,
    );
    if (row == null || row['diagnosis'] is! Map) return null;
    final diagnosisMap = Map<String, dynamic>.from(row['diagnosis'] as Map);
    if (_isFallbackDiagnosis(diagnosisMap)) return null;

    final cachedAtRaw = row['cached_at']?.toString();
    final cachedAt = cachedAtRaw == null
        ? null
        : DateTime.tryParse(cachedAtRaw);
    if (cachedAt == null) return null;

    final age = DateTime.now().difference(cachedAt);
    if (age >= _cacheTtl) return null;

    return PortfolioDiagnosisResult.fromJson(
      diagnosisMap,
      model: row['model']?.toString(),
    );
  }

  Future<PortfolioDiagnosisResult?> _fetchAnyCache({
    required String payloadKey,
  }) async {
    final row = await AppDatabase.instance.fetchPortfolioDiagnosisCache(
      payloadKey: payloadKey,
    );
    if (row == null || row['diagnosis'] is! Map) return null;
    final diagnosisMap = Map<String, dynamic>.from(row['diagnosis'] as Map);
    if (_isFallbackDiagnosis(diagnosisMap)) return null;
    return PortfolioDiagnosisResult.fromJson(
      diagnosisMap,
      model: row['model']?.toString(),
    );
  }

  @visibleForTesting
  static PortfolioDiagnosisResult buildFallbackDiagnosisForTesting(
    Map<String, dynamic> portfolioInput,
  ) {
    return _buildLocalFallbackDiagnosis(portfolioInput);
  }
}

const Duration _cacheTtl = Duration(hours: 24);

String _buildPayloadKey() {
  final userId = AuthService.currentUser?.id.trim();
  if (userId != null && userId.isNotEmpty) {
    return 'portfolio_diagnosis:$userId';
  }
  return 'portfolio_diagnosis:local';
}

class PortfolioDiagnosisResult {
  const PortfolioDiagnosisResult({
    required this.summary,
    required this.score,
    required this.riskLevel,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.uncertainty,
    required this.analysisSource,
    this.model,
  });

  factory PortfolioDiagnosisResult.fromJson(
    Map<String, dynamic> json, {
    String? model,
  }) {
    final strengths = _asStringList(json['strengths']);
    final weaknesses = _asStringList(json['weaknesses']);
    final suggestions = _asStringList(json['suggestions']);
    final summary = _asString(json['summary'], fallback: '진단 요약이 없습니다.');
    final score = _resolveScore(json);
    final riskLevel = _resolveRiskLevel(json, score);
    final uncertainty = json['uncertainty'] is bool
        ? json['uncertainty'] as bool
        : true;
    final analysisSource = _resolveAnalysisSource(json['analysis_source']);

    return PortfolioDiagnosisResult(
      summary: summary,
      score: score,
      riskLevel: riskLevel,
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
      uncertainty: uncertainty,
      analysisSource: analysisSource,
      model: model,
    );
  }

  final String summary;
  final int score;
  final String riskLevel;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  final bool uncertainty;
  final String analysisSource;
  final String? model;
}

class PortfolioDiagnosisCacheEntry {
  const PortfolioDiagnosisCacheEntry({
    required this.diagnosis,
    required this.cachedAt,
  });

  final PortfolioDiagnosisResult diagnosis;
  final DateTime cachedAt;
}

String _asString(dynamic value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse('$value');
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => '$item'.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

int _resolveScore(Map<String, dynamic> json) {
  final direct = _asInt(json['score']);
  if (direct != null) {
    return direct.clamp(0, 100).toInt();
  }

  final scoresRaw = json['diagnosis_scores'];
  if (scoresRaw is Map) {
    final values = scoresRaw.values
        .map(_asInt)
        .whereType<int>()
        .toList(growable: false);
    if (values.isNotEmpty) {
      final average = values.reduce((a, b) => a + b) / values.length;
      return average.round().clamp(0, 100).toInt();
    }
  }

  return 60;
}

bool _isFallbackDiagnosis(Map<String, dynamic> diagnosis) {
  final source = diagnosis['analysis_source']?.toString().trim().toLowerCase();
  return source == 'fallback_rule_based';
}

PortfolioDiagnosisResult _buildLocalFallbackDiagnosis(
  Map<String, dynamic> portfolioInput,
) {
  final holdingsCount = _resolvePortfolioHoldingCount(portfolioInput);
  final hasHoldings = holdingsCount > 0;
  return PortfolioDiagnosisResult(
    summary: hasHoldings
        ? 'AI 진단 API가 일시적으로 응답하지 않아 현재 보유 자산 $holdingsCount개 기준의 기본 점검 결과를 표시합니다.'
        : 'AI 진단 API가 일시적으로 응답하지 않아 기본 점검 결과를 표시합니다.',
    score: hasHoldings ? 60 : 50,
    riskLevel: '보통',
    strengths: hasHoldings
        ? const ['보유 자산 데이터가 있어 캐시 또는 기본 규칙으로 최소 점검을 계속할 수 있습니다.']
        : const [],
    weaknesses: const ['외부 AI 응답 지연으로 최신 뉴스와 정성 분석 반영이 제한됩니다.'],
    suggestions: const [
      '외부 API가 회복된 뒤 AI 포트폴리오 분석을 다시 생성하세요.',
      '그 전에는 자산 비중, 현금 비중, 최근 급등락 종목을 우선 점검하세요.',
    ],
    uncertainty: true,
    analysisSource: 'fallback_rule_based',
    model: 'fallback-local',
  );
}

int _resolvePortfolioHoldingCount(Map<String, dynamic> portfolioInput) {
  final candidates = [
    portfolioInput['holdings'],
    portfolioInput['assets'],
    portfolioInput['positions'],
  ];
  for (final candidate in candidates) {
    if (candidate is List) {
      return candidate.length;
    }
  }
  return 0;
}

String _resolveRiskLevel(Map<String, dynamic> json, int score) {
  final direct = '${json['risk_level'] ?? ''}'.trim();
  if (direct == '낮음' || direct == '보통' || direct == '높음') return direct;

  final status = '${json['overall_status'] ?? ''}'.trim();
  if (status == '양호') return '낮음';
  if (status == '점검 필요') return '높음';
  if (status == '주의') return '보통';

  if (score >= 80) return '낮음';
  if (score < 50) return '높음';
  return '보통';
}

String _resolveAnalysisSource(dynamic value) {
  final text = '$value'.trim();
  if (text == 'openai_model') return 'openai_model';
  if (text == 'fallback_rule_based') return 'fallback_rule_based';
  return 'openai_model';
}
