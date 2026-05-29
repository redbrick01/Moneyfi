import 'dart:async';
import 'package:flutter/material.dart';

import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../db/app_database.dart';
import '../services/app_data_lifecycle_service.dart';
import '../services/auth_service.dart';
import '../services/market_data_service.dart';
import '../services/sync_service.dart';
import '../utils/display_currency.dart';
import 'analysis_page.dart';
import 'my_page.dart';
import 'portfolio_dashboard_page.dart';
import 'portfolio_page.dart';
import 'statistics_page.dart';
import 'transactions_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage>
    with WidgetsBindingObserver {
  static const _pollingInterval = Duration(minutes: 1);
  static const _destinations = <_NavItem>[
    _NavItem(
      label: '홈',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: '포트폴',
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
    ),
    _NavItem(
      label: '거래',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _NavItem(
      label: '분석',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    _NavItem(
      label: '통계',
      icon: Icons.insert_chart_outlined_rounded,
      selectedIcon: Icons.insert_chart_rounded,
    ),
    _NavItem(
      label: 'My',
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
  int _portfolioDiagnosisFocusTick = 0;
  bool _isClearingSignedOutData = false;
  bool _isReplacingAccountData = false;
  String? _accountDataReplacementMessage;
  Future<void>? _signOutClearOperation;
  late AppDataLifecycleState _appDataLifecycleState;

  @override
  void initState() {
    super.initState();
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
    final nextState = AppDataLifecycleService.state.value;
    if (nextState.version == _appDataLifecycleState.version) {
      return;
    }
    _appDataLifecycleState = nextState;
    if (!mounted) return;
    setState(() {
      _isReplacingAccountData = nextState.isReplacing;
      _accountDataReplacementMessage = nextState.message;
      _dataScopeVersion++;
      _dataRefreshTick++;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshRemoteData(reason: 'resume');
    }
  }

  void _handleTabSelected(int index) {
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

    setState(() {
      selectedIndex = index;
    });
  }

  void _openPortfolioDiagnosisFromHome() {
    setState(() {
      selectedIndex = 1;
      _portfolioDiagnosisFocusTick++;
    });
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
                    diagnosisFocusTick: _portfolioDiagnosisFocusTick,
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
                  title: '분석',
                  child: AnalysisPage(
                    scrollController: _pageScrollControllers[3],
                    reselectionTick: _analysisReselectionTick,
                    dataRefreshTick: _dataRefreshTick,
                  ),
                ),
                _DataScopedTabPage(
                  scopeVersion: _dataScopeVersion,
                  replacementMessage: _dataReplacementMessage,
                  title: '통계',
                  child: StatisticsPage(
                    scrollController: _pageScrollControllers[4],
                    dataRefreshTick: _dataRefreshTick,
                  ),
                ),
                MyPage(scrollController: _pageScrollControllers[5]),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
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
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xs - context.spacing.xs / 4,
                  vertical: context.spacing.xs - 1,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _FloatingTabBarItem(
                          item: items[i],
                          isSelected: selectedIndex == i,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final labelStyle = context.typography.caption.copyWith(
      height: 1.2,
      letterSpacing: 0,
      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w400,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.xs / 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.xs - 3,
            vertical: context.spacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.radius.rPill),
            color: isSelected
                ? colors.primary
                : colorScheme.surface.withValues(alpha: 0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : colorScheme.surface.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(context.radius.rMd),
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: VisualSpec.icon.sizeSmall,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.spacing.xs / 2),
              SizedBox(
                height: 14,
                child: Center(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: labelStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
