import 'dart:async';
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/auth_service.dart';
import '../services/market_data_service.dart';
import '../services/sync_service.dart';
import '../utils/display_currency.dart';
import 'analysis_page.dart';
import 'my_page.dart';
import 'portfolio_dashboard_page.dart';
import 'portfolio_page.dart';
import 'statistics_page.dart';

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
      label: '포트폴리오',
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
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
  int _analysisReselectionTick = 0;
  int _portfolioDiagnosisFocusTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageScrollControllers = List.generate(
      _destinations.length,
      (_) => ScrollController(),
    );
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
    _pollingTimer?.cancel();
    _authSubscription?.cancel();
    for (final controller in _pageScrollControllers) {
      controller.dispose();
    }
    super.dispose();
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
      if (index == 2) {
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
    await AppDatabase.instance.clearAllLocalUserData();
    await MarketDataService.instance.clearLocalCache();
    if (!mounted) return;
    setState(() {
      _dataRefreshTick++;
    });
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
                PortfolioDashboardPage(
                  scrollController: _pageScrollControllers[0],
                  onOpenPortfolioDiagnosis: _openPortfolioDiagnosisFromHome,
                  dataRefreshTick: _dataRefreshTick,
                ),
                PortfolioPage(
                  scrollController: _pageScrollControllers[1],
                  diagnosisFocusTick: _portfolioDiagnosisFocusTick,
                  dataRefreshTick: _dataRefreshTick,
                ),
                AnalysisPage(
                  scrollController: _pageScrollControllers[2],
                  reselectionTick: _analysisReselectionTick,
                  dataRefreshTick: _dataRefreshTick,
                ),
                StatisticsPage(
                  scrollController: _pageScrollControllers[3],
                  dataRefreshTick: _dataRefreshTick,
                ),
                MyPage(scrollController: _pageScrollControllers[4]),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: colorScheme.surface.withValues(alpha: 0.92),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    final labelStyle = TextStyle(
      fontSize: 11,
      height: 1.2,
      letterSpacing: -0.12,
      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isSelected ? colorScheme.primary : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 19,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
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
