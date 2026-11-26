import 'package:moneyfy/features/auth/services/auth_service.dart';

class MonthlyPivot {
  const MonthlyPivot(this.day) : assert(day >= 1 && day <= 31);

  final int day;

  static MonthlyPivot fromMetadata(Map<String, dynamic>? metadata) {
    final value = metadata?[AuthService.monthlyPivotMetadataKey];
    return MonthlyPivot(value is int && value >= 1 && value <= 31 ? value : 1);
  }

  static MonthlyPivot get current =>
      fromMetadata(AuthService.currentUser?.userMetadata);

  DateTime inMonth(int year, int month) {
    final last = DateTime(year, month + 1, 0);
    return DateTime(last.year, last.month, day.clamp(1, last.day));
  }

  bool matches(DateTime date) => date.day == inMonth(date.year, date.month).day;

  DateTime periodStart(DateTime date, {bool includeToday = true}) {
    final pivot = inMonth(date.year, date.month);
    if (date.day > pivot.day || (includeToday && date.day == pivot.day))
      return pivot;
    return inMonth(date.year, date.month - 1);
  }

  DateTime periodEnd(DateTime start) {
    final next = inMonth(start.year, start.month + 1);
    return DateTime(next.year, next.month, next.day - 1);
  }
}
