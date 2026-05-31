import 'investment_review_models.dart';

abstract final class InvestmentReviewPeriodResolver {
  static InvestmentReviewPeriodRange resolve(
    InvestmentReviewPeriodType type, {
    DateTime? now,
  }) {
    final base = _dateOnly(now ?? DateTime.now());
    return switch (type) {
      InvestmentReviewPeriodType.today => InvestmentReviewPeriodRange(
        type: type,
        from: base,
        to: base,
        label: '오늘',
      ),
      InvestmentReviewPeriodType.weekly => InvestmentReviewPeriodRange(
        type: type,
        from: base.subtract(Duration(days: base.weekday - 1)),
        to: base,
        label: '이번 주',
      ),
      InvestmentReviewPeriodType.monthly => InvestmentReviewPeriodRange(
        type: type,
        from: DateTime(base.year, base.month),
        to: base,
        label: '이번 달',
      ),
    };
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
