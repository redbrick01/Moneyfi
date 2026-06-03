import 'equity_research_service.dart';

class EquityResearchMetricPresentation {
  const EquityResearchMetricPresentation({
    required this.label,
    required this.value,
    required this.meta,
    required this.isTextOnly,
  });

  final String label;
  final String value;
  final String meta;
  final bool isTextOnly;
}

EquityResearchMetricPresentation presentEquityResearchMetric(
  EquityResearchMetric metric,
) {
  return EquityResearchMetricPresentation(
    label: equityResearchMetricLabel(metric.name),
    value: _metricValue(metric),
    meta: metric.fiscalPeriod,
    isTextOnly: metric.value == null && metric.text.trim().isNotEmpty,
  );
}

String equityResearchMetricLabel(String name) {
  final normalized = _normalizeResearchKey(name);
  return _metricLabels[normalized] ?? equityResearchDisplayLabel(normalized);
}

String equityResearchDisplayLabel(String value) {
  final normalized = _normalizeResearchKey(value);
  if (normalized.isEmpty) return '';
  return _researchLabels[normalized] ?? _humanizeKey(normalized);
}

String equityResearchUpsideLabel(double value) {
  if (value > 0) return '업사이드';
  if (value < 0) return '하락 여지';
  return '변동 여지';
}

const _metricLabels = <String, String>{
  'revenue': '매출',
  'full_year_revenue_guidance_low': '연간 매출 가이던스 하단',
  'full_year_revenue_guidance_high': '연간 매출 가이던스 상단',
  'remaining_performance_obligations': '잔여 수행 의무',
  'commercial_customer_revenue_mix': '상업 고객 매출 비중',
  'international_revenue_mix': '해외 매출 비중',
  'adjusted_ebitda': '조정 EBITDA',
  'cash_equivalents_and_available_for_sale_securities': '현금성 자산 및 단기 투자',
};

const _researchLabels = <String, String>{
  'bull': '상방',
  'bear': '하방',
  'base': '기준',
  'neutral': '중립',
  'monitoring': '관찰',
  'positive': '긍정',
  'very_positive': '매우 긍정',
  'negative': '부정',
  'mixed': '혼재',
  'buy': '매수',
  'hold': '보유',
  'sell': '매도',
  'outperform': '시장 상회',
  'underperform': '시장 하회',
  'high': '높음',
  'medium': '보통',
  'low': '낮음',
  'near_term': '단기',
  'medium_term': '중기',
  'long_term': '장기',
  'quarterly': '분기별',
  'monthly': '월별',
  'weekly': '주별',
  'daily': '일별',
  'annual': '연간',
  'annually': '연간',
  'relative_valuation': '상대가치 평가',
  'consensus_target_price': '컨센서스 목표가',
  'fair_value_estimate': '공정가치 추정',
  'dcf': 'DCF',
  'discounted_cash_flow': '할인현금흐름',
  'multiples': '멀티플',
  'revenue_multiple': '매출 멀티플',
  'ev_sales': 'EV/Sales',
  'ev_ebitda': 'EV/EBITDA',
  'sum_of_parts': '사업부별 가치합산',
  'scenario_weighted': '시나리오 가중',
  'execution_risk': '실행 리스크',
  'valuation_risk': '밸류에이션 리스크',
  'competition_risk': '경쟁 리스크',
  'competitive_risk': '경쟁 리스크',
  'regulatory_risk': '규제 리스크',
  'technology_risk': '기술 리스크',
  'financing_risk': '자금조달 리스크',
  'liquidity_risk': '유동성 리스크',
  'macro_risk': '거시경제 리스크',
  'customer_concentration_risk': '고객 집중 리스크',
  'dilution_risk': '희석 리스크',
  'profitability_risk': '수익성 리스크',
  'balance_sheet_risk': '재무구조 리스크',
  'earnings': '실적',
  'guidance': '가이던스',
  'product_launch': '제품 출시',
  'partnership': '파트너십',
  'contract': '계약',
  'regulatory_approval': '규제 승인',
  'funding': '자금조달',
  'investor_day': '투자자의 날',
  'index_inclusion': '지수 편입',
  'financials': '재무',
  'valuation': '밸류에이션',
  'product': '제품',
  'market': '시장',
  'competitive': '경쟁',
  'customer': '고객',
  'execution': '실행',
  'overview': '개요',
  'summary': '요약',
  'investment_thesis': '투자 논지',
  'risks': '리스크',
  'catalysts': '촉매',
  'conclusion': '결론',
  'source': '출처',
  'source_document': '출처 문서',
  'company_filing': '공시 자료',
  'earnings_call': '실적 발표',
  'analyst_report': '애널리스트 리포트',
  'press_release': '보도자료',
  'primary': '1차 자료',
  'secondary': '2차 자료',
};

String _metricValue(EquityResearchMetric metric) {
  final value = metric.value;
  if (value == null) {
    final text = metric.text.trim();
    return text.isNotEmpty ? text : '-';
  }

  final currency = metric.currency.trim().toUpperCase();
  final unit = metric.unit.trim();

  if (unit == '%') {
    return '${_formatNumber(value)}%';
  }

  var displayValue = value;
  var displayUnit = unit;
  if (unit.toUpperCase() == 'M' && value.abs() >= 1000) {
    displayValue = value / 1000;
    displayUnit = 'B';
  }

  return [
    if (currency.isNotEmpty) currency,
    _formatNumber(displayValue),
    if (displayUnit.isNotEmpty) displayUnit,
  ].join(' ');
}

String _humanizeKey(String name) {
  if (name.isEmpty) return '지표';
  return name.split('_').where((part) => part.isNotEmpty).join(' ');
}

String _normalizeResearchKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  if (value.abs() >= 10) return value.toStringAsFixed(1);
  return value.toStringAsFixed(1);
}
