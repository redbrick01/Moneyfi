import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  final _indicatorKey = GlobalKey<RefreshIndicatorState>();
  bool _atTop = false;

  void _trackPosition(ScrollMetrics metrics, int depth) {
    if (depth == 0 && metrics.axisDirection == AxisDirection.down) {
      _atTop = metrics.extentBefore == 0;
    }
  }

  void _handleSignal(PointerSignalEvent event) {
    if (!_atTop ||
        event is! PointerScrollEvent ||
        event.kind != PointerDeviceKind.mouse ||
        event.scrollDelta.dy >= 0 ||
        event.scrollDelta.dy.abs() <= event.scrollDelta.dx.abs()) {
      return;
    }

    // Let a nested scrollable consume the wheel first if it can still scroll.
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _indicatorKey.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handleSignal,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          _trackPosition(notification.metrics, notification.depth);
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _trackPosition(notification.metrics, notification.depth);
            return false;
          },
          child: RefreshIndicator(
            key: _indicatorKey,
            onRefresh: widget.onRefresh,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
