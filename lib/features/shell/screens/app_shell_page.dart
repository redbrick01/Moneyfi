import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/navigation/moneyfy_routes.dart';
import 'package:moneyfy/features/auth/services/app_data_lifecycle_service.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
import 'package:moneyfy/ui_scaffold/app_insets.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'package:moneyfy/features/analysis/screens/analysis_page.dart';
import 'package:moneyfy/features/account/screens/my_page.dart';
import 'package:moneyfy/features/portfolio/screens/portfolio_dashboard_page.dart';
import 'package:moneyfy/features/portfolio/screens/portfolio_page.dart';
import 'package:moneyfy/features/account/screens/statistics_page.dart';
import 'package:moneyfy/features/transactions/screens/transactions_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialLocation = MoneyfyRoutePaths.home,
  });

  final String initialLocation;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage>
    with WidgetsBindingObserver {
  static const _pollingInterval = Duration(minutes: 1);
  static const _destinations = <_NavItem>[
    _NavItem(
      label: '홈',
      routeName: MoneyfyRouteNames.home,
      routePath: MoneyfyRoutePaths.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: '포트폴',
      routeName: MoneyfyRouteNames.portfolio,
      routePath: MoneyfyRoutePaths.portfolio,
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
    ),
    _NavItem(
      label: '거래',
      routeName: MoneyfyRouteNames.transactions,
      routePath: MoneyfyRoutePaths.transactions,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _NavItem(
      label: '분석',
      routeName: MoneyfyRouteNames.analysis,
      routePath: MoneyfyRoutePaths.analysis,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    _NavItem(
      label: 'My',
      routeName: MoneyfyRouteNames.my,
      routePath: MoneyfyRoutePaths.my,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  int selectedIndex = 0;
  Timer? _pollingTimer;
  StreamSubscription<Object?>? _authSubscription;
  bool _isPolling = false;
  late final List<ScrollController> _pageScrollControllers;
  int _dataRefreshTick = 0;
  int _dataScopeVersion = 0;
  int _analysisReselectionTick = 0;
  bool _isClearingSignedOutData = false;
  bool _isReplacingAccountData = false;
  String? _accountDataReplacementMessage;
  Future<void>? _signOutClearOperation;
  late AppDataLifecycleState _appDataLifecycleState;

  @override
  void initState() {
    super.initState();
    selectedIndex = _tabIndexForLocation(widget.initialLocation);
    WidgetsBinding.instance.addObserver(this);
    _pageScrollControllers = List.generate(
      _destinations.length,
      (_) => ScrollController(),
    );
    _appDataLifecycleState = AppDataLifecycleService.state.value;
    _isReplacingAccountData = _appDataLifecycleState.isReplacing;
    _accountDataReplacementMessage = _appDataLifecycleState.message;
    AppDataLifecycleService.state.addListener(_handleAppDataLifecycleChanged);
    _syncDisplayCurrencySettings();
    _authSubscription = AuthService.authStateChanges.listen((authState) {
      if (authState.session == null) {
        unawaited(_clearLocalDataAfterSignOut());
      } else if (SyncService.instance.canSync) {
        _refreshRemoteData(reason: 'auth_state_change');
      } else if (mounted) {
        setState(() {
          _dataRefreshTick++;
        });
      }
    });
    _refreshRemoteData(reason: 'startup');
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _runPollingCycle();
    });
  }

  @override
  void didUpdateWidget(covariant AppShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLocation == widget.initialLocation) {
      return;
    }
    final nextIndex = _tabIndexForLocation(widget.initialLocation);
    if (nextIndex != selectedIndex) {
      setState(() {
        selectedIndex = nextIndex;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppDataLifecycleService.state.removeListener(
      _handleAppDataLifecycleChanged,
    );
    _pollingTimer?.cancel();
    _authSubscription?.cancel();
    for (final controller in _pageScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleAppDataLifecycleChanged() {
    final previousState = _appDataLifecycleState;
    final nextState = AppDataLifecycleService.state.value;
    if (nextState.version == previousState.version) {
      return;
    }
    _appDataLifecycleState = nextState;
    if (!mounted) return;

    final shouldRefreshData =
        nextState.refreshToken != previousState.refreshToken;

    setState(() {
      _isReplacingAccountData = nextState.isReplacing;
      _accountDataReplacementMessage = nextState.message;
      if (shouldRefreshData) {
        _dataScopeVersion++;
        _dataRefreshTick++;
      }
    });

    if (shouldRefreshData) {
      unawaited(_syncDisplayCurrencySettings());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshRemoteData(reason: 'resume');
    }
  }

  void _handleTabSelected(int index) {
    final destination = _destinations[index];
    if (selectedIndex == index &&
        _normalizedLocation != destination.routePath) {
      context.go(destination.routePath);
      return;
    }

    if (selectedIndex == index) {
      final controller = _pageScrollControllers[index];
      if (controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
      if (index == 3) {
        setState(() {
          _analysisReselectionTick++;
        });
      }
      return;
    }

    context.go(destination.routePath);
  }

  int _tabIndexForLocation(String location) {
    final path = _normalizeLocation(location);
    if (path == MoneyfyRoutePaths.statistics) {
      return _analysisTabIndex;
    }
    final index = _destinations.indexWhere((item) => item.routePath == path);
    return index < 0 ? 0 : index;
  }

  String get _normalizedLocation => _normalizeLocation(widget.initialLocation);

  bool get _showsStatisticsRoute {
    return _normalizedLocation == MoneyfyRoutePaths.statistics;
  }

  String _normalizeLocation(String location) {
    return Uri.tryParse(location)?.path ?? location;
  }

  void _openPortfolioDiagnosisFromHome() {
    unawaited(context.openPortfolioDiagnosis());
  }

  Future<void> _runPollingCycle() async {
    if (_isPolling) return;

    _isPolling = true;
    try {
      await MarketDataService.instance.refreshAllMarketData();
      await _syncDisplayCurrencySettings();
      if (!mounted) return;
      setState(() {});
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _refreshRemoteData({required String reason}) async {
    final refreshed = await SyncService.instance.refreshFromServer(
      reason: reason,
    );
    if (!refreshed) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _dataRefreshTick++;
    });
  }

  Future<void> _clearLocalDataAfterSignOut() async {
    final existingOperation = _signOutClearOperation;
    if (existingOperation != null) {
      await existingOperation;
      return;
    }

    setState(() {
      _isClearingSignedOutData = true;
      _dataScopeVersion++;
      _dataRefreshTick++;
    });

    final operation = () async {
      try {
        await AppDatabase.instance.clearAllLocalUserData();
        await MarketDataService.instance.clearLocalCache();
      } finally {
        if (mounted) {
          setState(() {
            _isClearingSignedOutData = false;
            _dataScopeVersion++;
            _dataRefreshTick++;
          });
        }
        _signOutClearOperation = null;
      }
    }();
    _signOutClearOperation = operation;
    await operation;
  }

  Future<void> _syncDisplayCurrencySettings() async {
    final rate = await AppDatabase.instance.fetchLatestExchangeRate() ?? 1.0;
    MoneyfyDisplayCurrencySettings.update(rate: rate);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                _DataScopedTabPage(
                  scopeVersion: _dataScopeVersion,
                  replacementMessage: _dataReplacementMessage,
                  title: '홈',
                  child: PortfolioDashboardPage(
                    scrollController: _pageScrollControllers[0],
                    onOpenPortfolioDiagnosis: _openPortfolioDiagnosisFromHome,
                    dataRefreshTick: _dataRefreshTick,
                  ),
                ),
                _DataScopedTabPage(
                  scopeVersion: _dataScopeVersion,
                  replacementMessage: _dataReplacementMessage,
                  title: '포트폴리오',
                  child: PortfolioPage(
                    scrollController: _pageScrollControllers[1],
                    dataRefreshTick: _dataRefreshTick,
                  ),
                ),
                _DataScopedTabPage(
                  scopeVersion: _dataScopeVersion,
                  replacementMessage: _dataReplacementMessage,
                  title: '거래',
                  child: TransactionsPage(
                    scrollController: _pageScrollControllers[2],
                    dataRefreshTick: _dataRefreshTick,
                  ),
                ),
                _DataScopedTabPage(
                  scopeVersion: _dataScopeVersion,
                  replacementMessage: _dataReplacementMessage,
                  title: _showsStatisticsRoute ? '통계' : '분석',
                  child: _showsStatisticsRoute
                      ? StatisticsPage(
                          scrollController:
                              _pageScrollControllers[_analysisTabIndex],
                          dataRefreshTick: _dataRefreshTick,
                        )
                      : AnalysisPage(
                          scrollController:
                              _pageScrollControllers[_analysisTabIndex],
                          reselectionTick: _analysisReselectionTick,
                          dataRefreshTick: _dataRefreshTick,
                        ),
                ),
                _DataScopedTabPage(
                  scopeVersion: _dataScopeVersion,
                  replacementMessage: _dataReplacementMessage,
                  title: 'My',
                  child: MyPage(scrollController: _pageScrollControllers[4]),
                ),
              ],
            ),
          ),
          Positioned(
            left: context.spacing.sm,
            right: context.spacing.sm,
            bottom: bottomInset > 0 ? bottomInset : 14,
            child: _FloatingTabBar(
              items: _destinations,
              selectedIndex: selectedIndex,
              onSelected: _handleTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  String? get _dataReplacementMessage {
    if (_isClearingSignedOutData) {
      return '로그아웃 정보를 정리하고 있어요.';
    }
    if (_isReplacingAccountData) {
      return _accountDataReplacementMessage ?? '계정 정보를 불러오고 있어요.';
    }
    return null;
  }
}

const _analysisTabIndex = 3;

class _DataScopedTabPage extends StatelessWidget {
  const _DataScopedTabPage({
    required this.scopeVersion,
    required this.replacementMessage,
    required this.title,
    required this.child,
  });

  final int scopeVersion;
  final String? replacementMessage;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('data-tab-$title-$scopeVersion'),
      child: replacementMessage != null
          ? _AccountDataReplacementPage(
              title: title,
              message: replacementMessage!,
            )
          : child,
    );
  }
}

@visibleForTesting
Widget buildDataScopedTabPageForTesting({
  required int scopeVersion,
  required String? replacementMessage,
  required String title,
  required Widget child,
}) {
  return _DataScopedTabPage(
    scopeVersion: scopeVersion,
    replacementMessage: replacementMessage,
    title: title,
    child: child,
  );
}

class _AccountDataReplacementPage extends StatelessWidget {
  const _AccountDataReplacementPage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ColoredBox(
      color: context.colors.neutralBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.contentHorizontalPadding,
            context.spacing.sectionGap,
            context.contentHorizontalPadding,
            context.spacing.xxxl + context.spacing.md + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: VisualSpec.icon.progressIndicatorSizeLarge,
                      height: VisualSpec.icon.progressIndicatorSizeLarge,
                      child: CircularProgressIndicator(
                        strokeWidth:
                            VisualSpec.icon.progressIndicatorStrokeLarge,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: context.spacing.md),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.routeName,
    required this.routePath,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String routeName;
  final String routePath;
  final IconData icon;
  final IconData selectedIcon;
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final itemCount = items.length;
    final safeSelectedIndex = itemCount == 0
        ? 0
        : selectedIndex.clamp(0, itemCount - 1).toInt();
    final horizontalPadding = context.spacing.xs - context.spacing.xs / 4;
    final verticalPadding = context.spacing.xs;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: colors.neutralSurfaceOverlay.withValues(alpha: 0.92),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radius.rPill),
            side: BorderSide(color: colors.neutralOutline),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final trackWidth = math.max(
                0.0,
                availableWidth - horizontalPadding * 2,
              );
              final indicatorWidth = itemCount == 0
                  ? 0.0
                  : trackWidth / itemCount;
              final indicatorLeft =
                  horizontalPadding + indicatorWidth * safeSelectedIndex;

              return SizedBox(
                height: AppInsets.floatingNavHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: indicatorLeft,
                      top: verticalPadding,
                      bottom: verticalPadding,
                      width: indicatorWidth,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.xs / 4,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              context.radius.rPill,
                            ),
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Expanded(
                                child: _FloatingTabBarItem(
                                  item: items[i],
                                  isSelected: safeSelectedIndex == i,
                                  onTap: () => onSelected(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FloatingTabBarItem extends StatelessWidget {
  const _FloatingTabBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    assert(item.routeName.isNotEmpty && item.routePath.isNotEmpty);
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.xs / 4),
      child: Semantics(
        label: item.label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          key: ValueKey('bottom-tab-${item.label}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: VisualSpec.icon.minTapTarget,
            child: Center(
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: VisualSpec.icon.sizeDefault,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
