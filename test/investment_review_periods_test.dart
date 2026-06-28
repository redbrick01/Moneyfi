import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/features/analysis/services/investment_review/investment_review_models.dart';
import 'package:moneyfy/features/analysis/services/investment_review/investment_review_periods.dart';

void main() {
  group('InvestmentReviewPeriodResolver', () {
    test('resolves today as a single calendar day', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.today,
        now: DateTime(2026, 5, 31, 22, 15),
      );

      expect(range.type, InvestmentReviewPeriodType.today);
      expect(range.from, DateTime(2026, 5, 31));
      expect(range.to, DateTime(2026, 5, 31));
      expect(range.label, '오늘');
    });

    test('resolves weekly range from Monday through Sunday', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.weekly,
        now: DateTime(2026, 5, 31, 22, 15),
      );

      expect(range.type, InvestmentReviewPeriodType.weekly);
      expect(range.from, DateTime(2026, 5, 25));
      expect(range.to, DateTime(2026, 5, 31));
      expect(range.label, '이번 주');
    });

    test('caps weekly range at today instead of future Sunday', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.weekly,
        now: DateTime(2026, 5, 27, 22, 15),
      );

      expect(range.from, DateTime(2026, 5, 25));
      expect(range.to, DateTime(2026, 5, 27));
    });

    test('resolves monthly range from first through last day', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.monthly,
        now: DateTime(2026, 5, 31, 22, 15),
      );

      expect(range.type, InvestmentReviewPeriodType.monthly);
      expect(range.from, DateTime(2026, 5, 1));
      expect(range.to, DateTime(2026, 5, 31));
      expect(range.label, '이번 달');
    });

    test('caps monthly range at today instead of future month end', () {
      final range = InvestmentReviewPeriodResolver.resolve(
        InvestmentReviewPeriodType.monthly,
        now: DateTime(2026, 5, 27, 22, 15),
      );

      expect(range.from, DateTime(2026, 5, 1));
      expect(range.to, DateTime(2026, 5, 27));
    });
  });
}
