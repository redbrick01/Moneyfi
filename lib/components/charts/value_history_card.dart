import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/components/panels/app_detail_section.dart';
import 'package:moneyfy/design_system/brand/brand_palette.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'package:moneyfy/utils/number_formatters.dart';

enum HistoryPeriod {
  week('1주', 0),
  month('1개월', 1),
  quarter('3개월', 3),
  year('1년', 12),
  fiveYears('5년', 60),
  tenYears('10년', 120);

  const HistoryPeriod(this.label, this.months);

  final String label;
  final int months;

  DateTime startAt(DateTime end) {
    if (this == week) return end.subtract(const Duration(days: 6));
    final first = DateTime.utc(end.year, end.month - months);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    return DateTime.utc(
      first.year,
      first.month,
      end.day > lastDay ? lastDay : end.day,
    );
  }
}

typedef HistoryBreakdown = ({String label, Color color, double value});

class HistoryPoint {
  const HistoryPoint({
    required this.date,
    required this.value,
    this.breakdown = const {},
  });

  final DateTime date;
  final double value;
  final Map<Object, HistoryBreakdown> breakdown;
}

typedef HistoryLoader =
    Future<List<HistoryPoint>> Function(
      DateTime from,
      DateTime through,
      bool Function() isCancelled,
    );

class ValueHistoryCard extends StatefulWidget {
  const ValueHistoryCard({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.chartLabel,
    required this.through,
    required this.sourceKey,
    required this.loadPoints,
    this.currencyCode = 'KRW',
    this.transactions = const [],
    this.averagePrice,
    this.periodAverageLabel,
  });

  final String title;
  final String valueLabel;
  final String chartLabel;
  final DateTime through;
  final Object sourceKey;
  final HistoryLoader loadPoints;
  final String currencyCode;
  final List<TransactionItem> transactions;
  final double? averagePrice;
  final String? periodAverageLabel;

  @override
  State<ValueHistoryCard> createState() => _ValueHistoryCardState();
}

class _ValueHistoryCardState extends State<ValueHistoryCard> {
  var _period = HistoryPeriod.quarter;
  var _requestId = 0;
  late Future<List<HistoryPoint>> _points;
  List<HistoryPoint> _cached = const [];
  DateTime? _cachedFrom;
  Set<Object> _enabledSeries = const {};

  @override
  void initState() {
    super.initState();
    _points = _load();
  }

  @override
  void didUpdateWidget(covariant ValueHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceKey != widget.sourceKey ||
        oldWidget.through != widget.through) {
      _cached = const [];
      _cachedFrom = null;
      _points = _load();
    }
  }

  Future<List<HistoryPoint>> _load() async {
    final requestId = ++_requestId;
    final through = widget.through;
    final from = _period.startAt(through);
    final cachedFrom = _cachedFrom;
    if (cachedFrom == null || from.isBefore(cachedFrom)) {
      final older = await widget.loadPoints(
        from,
        cachedFrom?.subtract(const Duration(days: 1)) ?? through,
        () => !mounted || requestId != _requestId,
      );
      if (!mounted || requestId != _requestId) return const [];
      _cached = cachedFrom == null ? older : [...older, ..._cached];
      _cachedFrom = from;
    }
    return _cachedPoints(from);
  }

  List<HistoryPoint> _cachedPoints(DateTime from) =>
      _cached.where((item) => !item.date.isBefore(from)).toList();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return AppDetailSection(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs / 2,
            children: [
              for (final period in HistoryPeriod.values)
                _PeriodChip(
                  period: period,
                  selected: period == _period,
                  onSelected: () {
                    if (period == _period) return;
                    setState(() {
                      _period = period;
                      _points = _load();
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: spacing.md),
          FutureBuilder<List<HistoryPoint>>(
            future: _points,
            builder: (context, snapshot) {
              final waiting =
                  snapshot.connectionState == ConnectionState.waiting;
              final loaded = !waiting && !snapshot.hasError;
              final from = _period.startAt(widget.through);
              final points = loaded
                  ? snapshot.data ?? const <HistoryPoint>[]
                  : _cachedPoints(from);
              final periodAverage =
                  widget.periodAverageLabel != null &&
                      loaded &&
                      points.isNotEmpty
                  ? points.fold(0.0, (sum, point) => sum + point.value) /
                        points.length
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (points.isNotEmpty)
                    _ValueHistoryChart(
                      key: ValueKey(_period),
                      points: points,
                      currencyCode: widget.currencyCode,
                      transactions: widget.transactions,
                      averagePrice: periodAverage ?? widget.averagePrice,
                      averageLabel: widget.periodAverageLabel ?? '평단',
                      valueLabel: widget.valueLabel,
                      chartLabel: widget.chartLabel,
                      enabledSeries: _enabledSeries,
                      onSeriesChanged: (series, enabled) {
                        setState(() {
                          _enabledSeries = {..._enabledSeries};
                          if (enabled) {
                            _enabledSeries.add(series);
                          } else {
                            _enabledSeries.remove(series);
                          }
                        });
                      },
                    ),
                  if (waiting || snapshot.hasError)
                    Padding(
                      padding: EdgeInsets.only(
                        top: points.isEmpty ? 0 : spacing.sm,
                      ),
                      child: _historyStatus(
                        context,
                        waiting: waiting,
                        hasPoints: points.isNotEmpty,
                      ),
                    )
                  else if (points.isEmpty)
                    Text(
                      '선택한 기간에 표시할 데이터가 없어요.',
                      textAlign: TextAlign.center,
                      style: context.typography.meta,
                    )
                  else if (points.first.date.difference(from) >
                      const Duration(days: 7))
                    Padding(
                      padding: EdgeInsets.only(top: spacing.sm),
                      child: Text(
                        '${_period.label} 중 제공 구간 · ${_dateLabel(points.first.date)} ~ ${_dateLabel(points.last.date)}',
                        style: context.typography.caption,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _historyStatus(
    BuildContext context, {
    required bool waiting,
    required bool hasPoints,
  }) {
    final subject = widget.title;
    if (!waiting) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            hasPoints
                ? '${_period.label} 전체 데이터를 불러오지 못했어요.'
                : '데이터를 불러오지 못했어요.',
            style: context.typography.meta,
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _points = _load();
              });
            },
            child: const Text('다시 시도'),
          ),
        ],
      );
    }
    final status = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.spacing.xs,
      children: [
        SizedBox.square(
          dimension: VisualSpec.icon.progressSize,
          child: CircularProgressIndicator(
            semanticsLabel: '$subject 불러오는 중',
            strokeWidth: VisualSpec.icon.progressStroke,
          ),
        ),
        Text(
          '${_period.label} $subject 불러오는 중',
          style: context.typography.meta,
        ),
      ],
    );
    return hasPoints
        ? status
        : SizedBox(
            height: context.spacing.xxxl * 2,
            child: Center(child: status),
          );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.period,
    required this.selected,
    required this.onSelected,
  });

  final HistoryPeriod period;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final style = MoneyfyPillStyle.resolve(
      context,
      tone: selected ? MoneyfyPillTone.primary : MoneyfyPillTone.neutral,
      variant: selected
          ? MoneyfyPillVariant.selected
          : MoneyfyPillVariant.outline,
    );
    return ChoiceChip(
      label: Text(period.label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      backgroundColor: style.background,
      selectedColor: style.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radius),
      ),
      side: BorderSide(color: style.border, width: style.borderWidth),
      padding: style.padding,
      labelPadding: EdgeInsets.zero,
      labelStyle: style.textStyle,
    );
  }
}

class _ValueHistoryChart extends StatefulWidget {
  const _ValueHistoryChart({
    super.key,
    required this.points,
    required this.currencyCode,
    required this.transactions,
    required this.averagePrice,
    required this.averageLabel,
    required this.valueLabel,
    required this.chartLabel,
    required this.enabledSeries,
    required this.onSeriesChanged,
  });

  final String valueLabel;
  final String chartLabel;
  final List<HistoryPoint> points;
  final String currencyCode;
  final List<TransactionItem> transactions;
  final double? averagePrice;
  final String averageLabel;
  final Set<Object> enabledSeries;
  final void Function(Object series, bool enabled) onSeriesChanged;

  @override
  State<_ValueHistoryChart> createState() => _ValueHistoryChartState();
}

class _ValueHistoryChartState extends State<_ValueHistoryChart> {
  int? _selected;
  late double _minimum;
  late double _maximum;
  late Map<int, Map<_ChartTradeType, _ChartTradeTotals>> _tradesByClose;
  late Map<int, List<_ChartTradeType>> _tradeMarkers;
  late Map<Object, HistoryBreakdown> _series;
  late Map<Object, Color> _visibleSeries;

  @override
  void initState() {
    super.initState();
    _updateSeries();
    _setPriceBounds();
    _updateTrades();
  }

  @override
  void didUpdateWidget(covariant _ValueHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _selected = null;
      _updateSeries();
    }
    if (oldWidget.points != widget.points ||
        oldWidget.transactions != widget.transactions) {
      _updateTrades();
    }
    if (oldWidget.points != widget.points ||
        oldWidget.averagePrice != widget.averagePrice ||
        oldWidget.enabledSeries != widget.enabledSeries) {
      _setPriceBounds();
    }
  }

  void _updateTrades() {
    _tradesByClose = _matchTradesToPoints(widget.points, widget.transactions);
    _tradeMarkers = {};
    for (final MapEntry(key: index, value: trades) in _tradesByClose.entries) {
      _tradeMarkers[index] = [
        for (final type in _ChartTradeType.values)
          if (trades.containsKey(type)) type,
      ];
    }
  }

  void _updateSeries() {
    final latest = {for (final point in widget.points) ...point.breakdown};
    final usedColors = {
      VisualSpec.brand.seedColor,
      VisualSpec.brand.chartNeutral,
    };
    _series = {};
    for (final entry in latest.entries) {
      final item = entry.value;
      final color = usedColors.contains(item.color)
          ? VisualSpec.chart.assetIdentityPalette.firstWhere(
              (candidate) => !usedColors.contains(candidate),
              orElse: () => item.color == VisualSpec.brand.seedColor
                  ? VisualSpec.brand.allocationOther
                  : item.color,
            )
          : item.color;
      usedColors.add(color);
      _series[entry.key] = (label: item.label, color: color, value: item.value);
    }
  }

  void _setPriceBounds() {
    _visibleSeries = {
      for (final entry in _series.entries)
        if (widget.enabledSeries.contains(entry.key))
          entry.key: entry.value.color,
    };
    _minimum = widget.points.first.value;
    _maximum = _minimum;
    for (final point in widget.points) {
      _minimum = math.min(_minimum, point.value);
      _maximum = math.max(_maximum, point.value);
      for (final series in _visibleSeries.keys) {
        if (point.breakdown[series] case final item?) {
          _minimum = math.min(_minimum, item.value);
          _maximum = math.max(_maximum, item.value);
        }
      }
    }
    if (widget.averagePrice case final average?) {
      _minimum = math.min(_minimum, average);
      _maximum = math.max(_maximum, average);
    }
    final padding = _maximum == _minimum
        ? (_maximum == 0 ? 1.0 : _maximum.abs() * 0.03)
        : (_maximum - _minimum) * 0.08;
    _minimum = _minimum >= 0
        ? math.max(0, _minimum - padding)
        : _minimum - padding;
    _maximum += padding;
  }

  void _select(int index) {
    final selected = index.clamp(0, widget.points.length - 1);
    if (_selected != selected) setState(() => _selected = selected);
  }

  String _formatValue(double value) {
    final currency = widget.currencyCode.toUpperCase();
    if (currency == 'USD' && value > 0 && value < 1) {
      return '\$${value.toStringAsFixed(value < 0.01 ? 6 : 4)}';
    }
    return MoneyfyDisplayCurrencySettings.formatAmountFromSource(
      value,
      sourceCurrency: currency,
      exchangeRate: 1,
    );
  }

  String _pointLabel(HistoryPoint point) =>
      '${_dateLabel(point.date)} ${_formatValue(point.value)}';

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final colors = context.colors;
    final typography = context.typography;
    final spacing = context.spacing;
    final selected = _selected;
    final selectedTrades = selected == null ? null : _tradesByClose[selected];
    final point = selected == null ? points.last : points[selected];
    final index = selected ?? points.length - 1;
    final stroke = VisualSpec.brand.seedColor;
    final average = widget.averagePrice;
    final averageValue = average == null ? null : _formatValue(average);
    final averageText =
        averageValue != null && widget.currencyCode.toUpperCase() == 'KRW'
        ? '${averageValue.replaceFirst('₩', '')}원'
        : averageValue;
    final start = points.first.value;
    final change = start == 0
        ? 0.0
        : (points.last.value - start) / start.abs() * 100;
    final direction = change.toStringAsFixed(2) == '-0.00' ? 0.0 : change;
    final changeLabel =
        '${direction > 0 ? '+' : ''}${direction.toStringAsFixed(2)}%';
    final axisStyle = typography.caption.copyWith(
      color: colors.neutralTextMuted,
    );
    final plotInset = _tradeMarkers.isEmpty ? 0.0 : _tradeMarkerRadius;
    final height = math.max(spacing.xxxl * 2, plotInset * 2 + spacing.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_dateLabel(point.date)} ${selected == null ? '최근 ' : ''}${widget.valueLabel}',
                    style: axisStyle,
                  ),
                  SizedBox(height: spacing.xs / 2),
                  Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.xs / 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _formatValue(point.value),
                        style: typography.sectionTitle,
                      ),
                      if (points.length > 1 && start != 0 && change.isFinite)
                        Text('기간 등락률 $changeLabel', style: typography.meta),
                    ],
                  ),
                ],
              ),
            ),
            if (selectedTrades != null) ...[
              SizedBox(width: spacing.sm),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: spacing.xs,
                    runSpacing: spacing.xs / 2,
                    children: [
                      for (final type in _ChartTradeType.values)
                        if (selectedTrades[type] case final totals?)
                          MoneyfyBadge(
                            label:
                                '${type.label} ${totals.quantity > 0 ? '${formatPlainQuantity(totals.quantity)}주 · ' : ''}${_formatValue(totals.amount)}',
                            leading: Icon(
                              Icons.circle,
                              size: context.spacing.sm,
                              color: type.markerColor(colors),
                            ),
                            maxLines: 2,
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: spacing.md),
        if (averageText != null) ...[
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              '${widget.averageLabel}  $averageText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.caption.copyWith(
                color: colors.neutralTextMuted,
              ),
            ),
          ),
          SizedBox(height: spacing.xs / 2),
        ],
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final xInset = _tradeMarkers.isEmpty
                  ? 0.0
                  : math.min(_tradeMarkerRadius, width / 2);
              void selectAt(double dx) {
                final plotWidth = width - 2 * xInset;
                if (plotWidth <= 0) return;
                _select(
                  ((dx - xInset) / plotWidth * (points.length - 1)).round(),
                );
              }

              return Semantics(
                container: true,
                explicitChildNodes: true,
                label: widget.chartLabel,
                value: _pointLabel(point),
                increasedValue: index < points.length - 1
                    ? _pointLabel(points[index + 1])
                    : null,
                decreasedValue: index > 0
                    ? _pointLabel(points[index - 1])
                    : null,
                onIncrease: index < points.length - 1
                    ? () => _select(index + 1)
                    : null,
                onDecrease: index > 0 ? () => _select(index - 1) : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => selectAt(details.localPosition.dx),
                  onHorizontalDragStart: (details) =>
                      selectAt(details.localPosition.dx),
                  onHorizontalDragUpdate: (details) =>
                      selectAt(details.localPosition.dx),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: _HistoryPainter(
                            points: points,
                            visibleSeries: _visibleSeries,
                            minimum: _minimum,
                            maximum: _maximum,
                            stroke: stroke,
                            averagePrice: average,
                            averageStroke: colors.neutralTextMuted,
                            inset: plotInset,
                            xInset: xInset,
                            tradeMarkers: _tradeMarkers,
                            buyColor: colors.negativeOn,
                            sellColor: colors.positiveOn,
                            dividendColor: _ChartTradeType.dividend.markerColor(
                              colors,
                            ),
                          ),
                        ),
                      ),
                      if (selected != null)
                        CustomPaint(
                          painter: _HistoryCursor(
                            index: selected,
                            count: points.length,
                            fraction:
                                (_maximum - point.value) /
                                (_maximum - _minimum),
                            color: stroke,
                            seriesPoints: [
                              for (final entry in _visibleSeries.entries)
                                if (point.breakdown[entry.key] case final item?)
                                  (
                                    color: entry.value,
                                    fraction:
                                        (_maximum - item.value) /
                                        (_maximum - _minimum),
                                  ),
                            ],
                            inset: plotInset,
                            xInset: xInset,
                            hasTradeMarker: _tradeMarkers.containsKey(selected),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: spacing.xs),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: spacing.sm,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(_dateLabel(points.first.date), style: axisStyle),
              if (points.length > 1)
                Text(_dateLabel(points.last.date), style: axisStyle),
            ],
          ),
        ),
        if (_series.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs / 2,
            children: [
              for (final entry in _series.entries)
                FilterChip(
                  avatar: Icon(
                    Icons.circle,
                    size: spacing.sm,
                    color: entry.value.color,
                  ),
                  label: Text(
                    widget.enabledSeries.contains(entry.key)
                        ? '${entry.value.label} · ${_breakdownValue(point.breakdown[entry.key])}'
                        : entry.value.label,
                  ),
                  selected: widget.enabledSeries.contains(entry.key),
                  showCheckmark: false,
                  onSelected: (enabled) =>
                      widget.onSeriesChanged(entry.key, enabled),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _breakdownValue(HistoryBreakdown? item) =>
      item == null ? '—' : _formatValue(item.value);
}

String _dateLabel(DateTime date) => date.toIso8601String().split('T').first;

double _chartX(int index, int count, double width, double inset) =>
    count == 1 ? width / 2 : inset + index / (count - 1) * (width - 2 * inset);

double _chartY(double fraction, double height, double inset) =>
    inset + fraction * (height - 2 * inset);

const _guideDotRadius = 0.65;
const _guideDotSpacing = 4.0;
const _tradeMarkerRadius = 4.0;

enum _ChartTradeType {
  buy('매수'),
  sell('매도'),
  dividend('배당');

  const _ChartTradeType(this.label);

  final String label;

  Color markerColor(BrandColors colors) => switch (this) {
    buy => colors.negativeOn,
    sell => colors.positiveOn,
    dividend => VisualSpec.brand.brandYellow,
  };
}

typedef _ChartTradeTotals = ({double quantity, double amount});

Map<int, Map<_ChartTradeType, _ChartTradeTotals>> _matchTradesToPoints(
  List<HistoryPoint> points,
  List<TransactionItem> transactions,
) {
  if (transactions.isEmpty) return const {};
  final priceIndices = {
    for (final (index, point) in points.indexed) _dateLabel(point.date): index,
  };
  final totalsByClose = <int, Map<_ChartTradeType, _ChartTradeTotals>>{};
  final dateEnd = RegExp(r'[T ]');
  final dateSeparator = RegExp(r'[./]');
  for (final transaction in transactions) {
    final type = switch (transaction.ledgerAction ?? transaction.type.trim()) {
      'buy' || '매수' => _ChartTradeType.buy,
      'sell' || '매도' => _ChartTradeType.sell,
      'dividend' || '배당' => _ChartTradeType.dividend,
      _ => null,
    };
    if (type == null) continue;
    final day = transaction.date
        .trim()
        .split(dateEnd)
        .first
        .replaceAll(dateSeparator, '-');
    final index = priceIndices[day];
    if (index == null) continue;
    final totalsByType = totalsByClose.putIfAbsent(index, () => {});
    final current = totalsByType[type] ?? (quantity: 0.0, amount: 0.0);
    final quantity =
        transaction.quantityValue ??
        double.tryParse(transaction.quantity.replaceAll(',', '').trim()) ??
        0.0;
    final amount = transaction.displayTotalAmount;
    totalsByType[type] = (
      quantity:
          current.quantity +
          (type != _ChartTradeType.dividend && quantity.isFinite
              ? quantity.abs()
              : 0),
      amount: current.amount + (amount.isFinite ? amount : 0),
    );
  }
  return totalsByClose;
}

class _HistoryPainter extends CustomPainter {
  const _HistoryPainter({
    required this.points,
    required this.visibleSeries,
    required this.minimum,
    required this.maximum,
    required this.stroke,
    required this.averagePrice,
    required this.averageStroke,
    required this.inset,
    required this.xInset,
    required this.tradeMarkers,
    required this.buyColor,
    required this.sellColor,
    required this.dividendColor,
  });

  final List<HistoryPoint> points;
  final Map<Object, Color> visibleSeries;
  final double minimum;
  final double maximum;
  final Color stroke;
  final double? averagePrice;
  final Color averageStroke;
  final double inset;
  final double xInset;
  final Map<int, List<_ChartTradeType>> tradeMarkers;
  final Color buyColor;
  final Color sellColor;
  final Color dividendColor;

  @override
  void paint(Canvas canvas, Size size) {
    double yFor(double price) =>
        _chartY((maximum - price) / (maximum - minimum), size.height, inset);
    final line = Paint()
      ..color = stroke
      ..strokeWidth = VisualSpec.chart.lineStroke * 0.75
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (final (index, point) in points.indexed) {
      final x = _chartX(index, points.length, size.width, xInset);
      final y = yFor(point.value);
      if (points.length == 1) {
        canvas.drawCircle(
          Offset(x, y),
          VisualSpec.chart.pointRadius,
          Paint()..color = stroke,
        );
      } else if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (points.length > 1) {
      final area = Path.from(path)
        ..lineTo(size.width - xInset, size.height)
        ..lineTo(xInset, size.height)
        ..close();
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          stroke.withValues(alpha: 0.38),
          stroke.withValues(alpha: 0.12),
          stroke.withValues(alpha: 0),
        ],
        stops: const [0, 0.55, 1],
      );
      canvas.drawPath(
        area,
        Paint()..shader = gradient.createShader(Offset.zero & size),
      );
      canvas.drawPath(path, line);
    }
    for (final entry in visibleSeries.entries) {
      final seriesLine = Paint()
        ..color = entry.value
        ..strokeWidth = line.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final seriesPath = Path();
      var continues = false;
      for (final (index, point) in points.indexed) {
        final item = point.breakdown[entry.key];
        if (item == null) {
          continues = false;
          continue;
        }
        final x = _chartX(index, points.length, size.width, xInset);
        final y = yFor(item.value);
        if (continues) {
          seriesPath.lineTo(x, y);
        } else {
          seriesPath.moveTo(x, y);
          canvas.drawCircle(
            Offset(x, y),
            VisualSpec.chart.pointRadius,
            Paint()..color = entry.value,
          );
        }
        continues = true;
      }
      canvas.drawPath(seriesPath, seriesLine);
    }
    if (averagePrice case final average?) {
      final y = yFor(average);
      final dot = Paint()..color = averageStroke;
      for (var x = _guideDotRadius; x < size.width; x += _guideDotSpacing) {
        canvas.drawCircle(Offset(x, y), _guideDotRadius, dot);
      }
    }
    if (tradeMarkers.isEmpty) return;
    for (final MapEntry(key: index, value: markers) in tradeMarkers.entries) {
      final center = Offset(
        _chartX(index, points.length, size.width, xInset),
        yFor(points[index].value),
      );
      const radius = _tradeMarkerRadius;
      final bounds = Rect.fromCircle(center: center, radius: radius);
      final sweep = 2 * math.pi / markers.length;
      for (final (part, marker) in markers.indexed) {
        final paint = Paint()
          ..color = switch (marker) {
            _ChartTradeType.buy => buyColor,
            _ChartTradeType.sell => sellColor,
            _ChartTradeType.dividend => dividendColor,
          };
        if (markers.length == 1) {
          canvas.drawCircle(center, radius, paint);
        } else {
          canvas.drawArc(
            bounds,
            -math.pi / 2 + part * sweep,
            sweep,
            true,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HistoryPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.visibleSeries != visibleSeries ||
      oldDelegate.maximum != maximum ||
      oldDelegate.minimum != minimum ||
      oldDelegate.stroke != stroke ||
      oldDelegate.averagePrice != averagePrice ||
      oldDelegate.averageStroke != averageStroke ||
      oldDelegate.inset != inset ||
      oldDelegate.xInset != xInset ||
      oldDelegate.tradeMarkers != tradeMarkers ||
      oldDelegate.buyColor != buyColor ||
      oldDelegate.sellColor != sellColor ||
      oldDelegate.dividendColor != dividendColor;
}

class _HistoryCursor extends CustomPainter {
  const _HistoryCursor({
    required this.index,
    required this.count,
    required this.fraction,
    required this.color,
    required this.seriesPoints,
    required this.inset,
    required this.xInset,
    required this.hasTradeMarker,
  });

  final int index;
  final int count;
  final double fraction;
  final Color color;
  final List<({Color color, double fraction})> seriesPoints;
  final double inset;
  final double xInset;
  final bool hasTradeMarker;

  @override
  void paint(Canvas canvas, Size size) {
    final x = _chartX(index, count, size.width, xInset);
    final y = _chartY(fraction, size.height, inset);
    final guide = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = VisualSpec.chart.gridThickness;
    if (hasTradeMarker) {
      const gap = _tradeMarkerRadius;
      canvas.drawLine(Offset(x, 0), Offset(x, math.max(0, y - gap)), guide);
      canvas.drawLine(
        Offset(x, math.min(size.height, y + gap)),
        Offset(x, size.height),
        guide,
      );
    } else {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guide);
      canvas.drawCircle(
        Offset(x, y),
        VisualSpec.chart.pointRadiusSelected,
        Paint()..color = color,
      );
    }
    for (final point in seriesPoints) {
      canvas.drawCircle(
        Offset(x, _chartY(point.fraction, size.height, inset)),
        VisualSpec.chart.pointRadiusSelected,
        Paint()..color = point.color,
      );
    }
  }

  @override
  bool shouldRepaint(_HistoryCursor oldDelegate) =>
      oldDelegate.index != index ||
      oldDelegate.count != count ||
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.seriesPoints != seriesPoints ||
      oldDelegate.inset != inset ||
      oldDelegate.xInset != xInset ||
      oldDelegate.hasTradeMarker != hasTradeMarker;
}
