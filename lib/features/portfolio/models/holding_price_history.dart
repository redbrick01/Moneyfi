class HoldingDailyClose {
  const HoldingDailyClose({required this.date, required this.price});

  /// Exchange-local trading date represented as a UTC date key.
  final DateTime date;
  final double price;
}
