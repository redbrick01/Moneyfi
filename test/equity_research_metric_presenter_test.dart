import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/analysis/services/equity_research_metric_presenter.dart';
import 'package:moneyfy/features/analysis/services/equity_research_service.dart';

void main() {
  group('presentEquityResearchMetric', () {
    test('maps raw metric names to Korean labels', () {
      final metric = _metric(name: 'full_year_revenue_guidance_low');

      final presented = presentEquityResearchMetric(metric);

      expect(presented.label, '연간 매출 가이던스 하단');
    });

    test('formats large million values as billions', () {
      final metric = _metric(
        name: 'cash_equivalents_and_available_for_sale_securities',
        value: 3092,
        unit: 'M',
        currency: 'USD',
      );

      final presented = presentEquityResearchMetric(metric);

      expect(presented.label, '현금성 자산 및 단기 투자');
      expect(presented.value, 'USD 3.1 B');
    });

    test('keeps smaller million values as millions', () {
      final metric = _metric(
        name: 'revenue',
        value: 64.7,
        unit: 'M',
        currency: 'USD',
      );

      final presented = presentEquityResearchMetric(metric);

      expect(presented.label, '매출');
      expect(presented.value, 'USD 64.7 M');
    });

    test('formats percent values without a space before percent sign', () {
      final metric = _metric(
        name: 'commercial_customer_revenue_mix',
        value: 64,
        unit: '%',
      );

      final presented = presentEquityResearchMetric(metric);

      expect(presented.value, '64%');
    });

    test('prefers numeric values when text and value are both present', () {
      final metric = _metric(
        name: 'commercial_customer_revenue_mix',
        value: 60,
        text: 'approximately 60% of revenue from commercial customers',
        unit: '%',
      );

      final presented = presentEquityResearchMetric(metric);

      expect(presented.value, '60%');
      expect(presented.isTextOnly, isFalse);
    });

    test('classifies text-only metrics separately', () {
      final metric = _metric(
        name: 'international_revenue_mix',
        text: 'approximately 35% of revenue came from international markets',
      );

      final presented = presentEquityResearchMetric(metric);

      expect(presented.label, '해외 매출 비중');
      expect(
        presented.value,
        'approximately 35% of revenue came from international markets',
      );
      expect(presented.isTextOnly, isTrue);
    });
  });

  group('equityResearchDisplayLabel', () {
    test('maps common research taxonomy values to Korean labels', () {
      expect(equityResearchDisplayLabel('execution_risk'), '실행 리스크');
      expect(equityResearchDisplayLabel('relative_valuation'), '상대가치 평가');
      expect(equityResearchDisplayLabel('very_positive'), '매우 긍정');
      expect(equityResearchDisplayLabel('near_term'), '단기');
      expect(equityResearchDisplayLabel('investment_thesis'), '투자 논지');
      expect(equityResearchDisplayLabel('consensus target price'), '컨센서스 목표가');
      expect(equityResearchDisplayLabel('fair value estimate'), '공정가치 추정');
    });

    test('normalizes phrase separators before mapping labels', () {
      expect(equityResearchDisplayLabel('Consensus_Target_Price'), '컨센서스 목표가');
      expect(equityResearchDisplayLabel('fair-value-estimate'), '공정가치 추정');
    });

    test(
      'humanizes unknown snake case values instead of exposing raw keys',
      () {
        expect(
          equityResearchDisplayLabel('custom_database_key'),
          'custom database key',
        );
        expect(equityResearchDisplayLabel(''), '');
      },
    );
  });

  group('equityResearchUpsideLabel', () {
    test('labels upside direction by sign', () {
      expect(equityResearchUpsideLabel(12.3), '업사이드');
      expect(equityResearchUpsideLabel(-6.7), '하락 여지');
      expect(equityResearchUpsideLabel(0), '변동 여지');
    });
  });
}

EquityResearchMetric _metric({
  required String name,
  double? value,
  String text = '',
  String unit = '',
  String currency = '',
  String fiscalPeriod = 'Q1 FY2026',
}) {
  return EquityResearchMetric(
    name: name,
    value: value,
    text: text,
    unit: unit,
    currency: currency,
    fiscalPeriod: fiscalPeriod,
    yoyChangePct: null,
    qoqChangePct: null,
  );
}
