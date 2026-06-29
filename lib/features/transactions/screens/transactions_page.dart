import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:moneyfy/components/chips/moneyfy_pill.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/panels/app_sheet_surface.dart';
import 'package:moneyfy/components/rows/transaction_row.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/separators/app_divider.dart';
import 'package:moneyfy/components/states/empty_state.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/components/states/retry_row.dart';
import 'package:moneyfy/components/states/skeletons.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/portfolio/models/asset_item.dart';
import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
import 'package:moneyfy/ui_scaffold/app_page_scaffold.dart';
import 'package:moneyfy/utils/display_currency.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';
import 'package:moneyfy/features/transactions/screens/forms/cash_transaction_form_page.dart';
import 'package:moneyfy/features/transactions/screens/forms/transaction_form_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    this.scrollController,
    this.dataRefreshTick = 0,
    this.remoteRefresh,
    this.assetsFutureForTesting,
  });

  final ScrollController? scrollController;
  final int dataRefreshTick;
  final Future<bool> Function()? remoteRefresh;
  final Future<List<AssetItem>>? assetsFutureForTesting;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const int _defaultVisiblePeriodCount = 1;
  static const int _defaultLoadMorePeriodCount = 1;
  static const String _kSlidableGroupTag = 'transactions_page_slidable_group';
  late Future<_TransactionsPageData> _pageFuture;
  late final TextEditingController _searchController;
  late int _visiblePeriodLimit;
  _TransactionPeriodFilter _selectedPeriod = _TransactionPeriodFilter.all;
  _TransactionCategoryFilter _selectedCategory = _TransactionCategoryFilter.all;
  _TransactionQuickFilter _selectedQuickFilter = _TransactionQuickFilter.all;
  _TransactionSortMode _sortMode = _TransactionSortMode.dateDesc;

  @override
  void initState() {
    super.initState();
    _visiblePeriodLimit = _defaultVisiblePeriodCount;
    _searchController = TextEditingController()
      ..addListener(_handleSearchChanged);
    _pageFuture = _loadPageData();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(_resetVisiblePeriodLimit);
  }

  @override
  void didUpdateWidget(covariant TransactionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataRefreshTick != widget.dataRefreshTick) {
      setState(() {
        _resetVisiblePeriodLimit();
        _pageFuture = _loadPageData();
      });
    }
  }

  Future<_TransactionsPageData> _loadPageData() async {
    final assets =
        await (widget.assetsFutureForTesting ??
            AppDatabase.instance.fetchAssets());
    final accounts = <_TransactionAccountOption>[];
    final rawRows = <_TransactionEntry>[];

    for (final asset in assets) {
      for (final holding in asset.holdings) {
        final assetId = holding.assetId;
        final holdingId = holding.id;
        if (assetId == null || holdingId == null) continue;

        final account = _TransactionAccountOption(
          assetId: assetId,
          holdingId: holdingId,
          holdingClientId: holding.clientId,
          title: holding.name,
          subtitle: asset.alias.isEmpty ? asset.title : asset.alias,
          isCash: holding.isCashLike,
          currencyCode: holding.currencyCode,
          exchangeRate: holding.exchangeRate,
        );
        accounts.add(account);

        for (var index = 0; index < holding.transactions.length; index++) {
          rawRows.add(
            _TransactionEntry(
              transaction: holding.transactions[index],
              account: account,
              currencyCode: holding.currencyCode,
              exchangeRate: holding.exchangeRate,
              originalIndex: index,
            ),
          );
        }
      }
    }

    final rows = _groupEntriesByLedgerEvent(rawRows);
    rows.sort(_compareTransactionEntries);
    return _TransactionsPageData(
      entries: List.unmodifiable(rows),
      accounts: List.unmodifiable(accounts),
    );
  }

  Future<void> _refreshPage() async {
    await _refreshRemoteData();
    final nextFuture = _loadPageData();
    setState(() {
      _resetVisiblePeriodLimit();
      _pageFuture = nextFuture;
    });
    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder renders the error state; pull-to-refresh should settle.
    }
  }

  Future<void> _refreshRemoteData() async {
    try {
      final refresh = widget.remoteRefresh;
      if (refresh != null) {
        await refresh();
        return;
      }
      if (SyncService.instance.canSync) {
        await SyncService.instance.refreshFromServer(
          reason: 'transactions_page_pull_refresh',
        );
      }
    } catch (_) {
      // The local reload below still gives the user the latest available state.
    }
  }

  Future<void> _openCreateFlow(_TransactionsPageData data) async {
    if (data.accounts.isEmpty) return;
    final kind = await showModalBottomSheet<_TransactionCreateKind>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(
        alpha: VisualSpec.surface.modalBarrierAlpha,
      ),
      builder: (context) =>
          _TransactionKindPickerSheet(accounts: data.accounts),
    );
    if (kind == null || !mounted) return;

    final account = data.accounts.firstWhere(
      (account) => kind == _TransactionCreateKind.cash
          ? account.isCash
          : !account.isCash,
    );
    await _openTransactionForm(account);
  }

  Future<void> _openAssetFormForEmptyState() async {
    final changed = await context.openAssetCreate();
    if (changed == true && mounted) {
      setState(() {
        _resetVisiblePeriodLimit();
        _pageFuture = _loadPageData();
      });
    }
  }

  void _resetVisiblePeriodLimit() {
    _visiblePeriodLimit = _defaultVisiblePeriodCount;
  }

  void _showMoreEntries() {
    setState(() {
      _visiblePeriodLimit += _defaultLoadMorePeriodCount;
    });
  }

  void _resetQuery() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    setState(() {
      _resetVisiblePeriodLimit();
      _selectedPeriod = _TransactionPeriodFilter.all;
      _selectedCategory = _TransactionCategoryFilter.all;
      _selectedQuickFilter = _TransactionQuickFilter.all;
      _sortMode = _TransactionSortMode.dateDesc;
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_TransactionFilterDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(
        alpha: VisualSpec.surface.modalBarrierAlpha,
      ),
      builder: (context) => _TransactionFilterSheet(
        initialPeriod: _selectedPeriod,
        initialCategory: _selectedCategory,
        initialSortMode: _sortMode,
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _resetVisiblePeriodLimit();
      _selectedPeriod = result.period;
      _selectedCategory = result.category;
      _selectedQuickFilter = _TransactionQuickFilter.fromCategory(
        result.category,
      );
      _sortMode = result.sortMode;
    });
  }

  void _selectQuickFilter(_TransactionQuickFilter filter) {
    setState(() {
      _resetVisiblePeriodLimit();
      _selectedQuickFilter = filter;
      _selectedCategory = filter.category;
    });
  }

  Future<void> _openTransactionForm(
    _TransactionAccountOption account, {
    TransactionItem? item,
  }) async {
    if (item != null && item.isLedgerBacked) {
      final canEdit = account.isCash
          ? item.canOpenCashFormFromLedger
          : item.canOpenInvestmentFormFromLedger;
      if (!canEdit) {
        _showBlockedLedgerMessage(account);
        return;
      }
    }

    final bool? changed;
    if (item == null) {
      changed = account.isCash
          ? await context.openCashTransactionCreate(
              assetId: account.assetId,
              holdingId: account.holdingId,
              holdingClientId: account.holdingClientId,
              defaultName: account.title,
            )
          : await context.openTransactionCreate(
              assetId: account.assetId,
              holdingId: account.holdingId,
              holdingClientId: account.holdingClientId,
              defaultName: account.title,
            );
    } else {
      changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => account.isCash
              ? CashTransactionFormPage(
                  assetId: account.assetId,
                  holdingId: account.holdingId,
                  holdingClientId: account.holdingClientId,
                  item: item,
                  defaultName: account.title,
                )
              : TransactionFormPage(
                  assetId: account.assetId,
                  holdingId: account.holdingId,
                  holdingClientId: account.holdingClientId,
                  item: item,
                  defaultName: account.title,
                ),
        ),
      );
    }

    if (changed == true && mounted) {
      setState(() {
        _resetVisiblePeriodLimit();
        _pageFuture = _loadPageData();
      });
    }
  }

  void _showBlockedLedgerMessage(_TransactionAccountOption account) {
    final message = account.isCash
        ? '이 원장 라인은 원본 투자 거래에서 관리됩니다.'
        : '이 원장 라인은 직접 수정할 수 없습니다.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTransaction(_TransactionEntry entry) async {
    final item = entry.transaction;
    if (item.id == null && item.ledgerEventId == null) return;
    final confirmed = await _confirmDelete(
      title: '거래 내역 삭제',
      message: '${item.date} ${item.type} 내역을 삭제하시겠습니까?',
    );
    if (confirmed != true) return;

    await AppDatabase.instance.deleteLedgerTransactionItem(item);
    if (SyncService.instance.canSync) {
      await SyncService.instance.syncNow(reason: 'transactions_page_delete');
    }
    if (!mounted) return;
    setState(() {
      _resetVisiblePeriodLimit();
      _pageFuture = _loadPageData();
    });
  }

  Future<bool?> _confirmDelete({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '삭제',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TransactionsPageData>(
      future: _pageFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _TransactionsPageData.empty();
        final visibleEntries = _visibleEntries(data.entries);
        return AppPageScaffold(
          title: '거래',
          subtitle: data.entries.isEmpty
              ? null
              : '${visibleEntries.length}/${data.entries.length}건',
          enablePullToRefresh: true,
          onRefresh: _refreshPage,
          hasFloatingNavInset: true,
          scrollController: widget.scrollController,
          actions: [
            IconButton(
              tooltip: '거래 추가',
              onPressed: data.accounts.isEmpty
                  ? null
                  : () => _openCreateFlow(data),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
          body: _buildBody(snapshot, data, visibleEntries),
        );
      },
    );
  }

  List<_TransactionEntry> _visibleEntries(List<_TransactionEntry> entries) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = entries
        .where((entry) {
          if (!_selectedPeriod.matches(entry)) return false;
          if (!_selectedCategory.matches(entry)) return false;
          if (!_selectedQuickFilter.matches(entry)) return false;
          if (query.isEmpty) return true;
          return entry.searchText.contains(query);
        })
        .toList(growable: false);
    return _sortEntries(filtered, _sortMode);
  }

  Widget _buildBody(
    AsyncSnapshot<_TransactionsPageData> snapshot,
    _TransactionsPageData data,
    List<_TransactionEntry> visibleEntries,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SkeletonList(rows: 8, rowHeight: 72, hasLeading: true);
    }

    if (snapshot.hasError) {
      return Column(
        children: [
          const InlineError(
            message: '거래 내역을 불러오지 못했어요.',
            detail: '잠시 후 다시 시도해 주세요.',
          ),
          SizedBox(height: context.spacing.sm),
          RetryRow(message: '로컬 데이터를 다시 불러옵니다.', onRetry: _refreshPage),
        ],
      );
    }

    if (data.entries.isEmpty) {
      final hasAccounts = data.accounts.isNotEmpty;
      return EmptyStateCard(
        title: hasAccounts ? '아직 거래 내역이 없어요' : '거래를 기록할 계좌가 없어요',
        description: hasAccounts
            ? '첫 거래를 등록하고 자산 흐름을 기록하세요.'
            : '먼저 자산군을 만들고 자산 상세에서 보유 종목이나 현금 계좌를 추가해 주세요.',
        icon: AppIconName.wallet,
        actionLabel: hasAccounts ? '거래 추가' : '자산 추가',
        onAction: hasAccounts
            ? () => _openCreateFlow(data)
            : _openAssetFormForEmptyState,
        variant: EmptyStateVariant.embedded,
      );
    }

    return Column(
      children: [
        _TransactionQueryPanel(
          searchController: _searchController,
          selectedPeriod: _selectedPeriod,
          selectedCategory: _selectedCategory,
          selectedQuickFilter: _selectedQuickFilter,
          sortMode: _sortMode,
          onQuickFilterChanged: _selectQuickFilter,
          onFilterPressed: _openFilterSheet,
          onReset: _resetQuery,
        ),
        SizedBox(height: context.spacing.md),
        if (visibleEntries.isEmpty)
          EmptyStateCard(
            title: '조건에 맞는 거래가 없어요',
            description: '검색어나 필터를 조정해 보세요.',
            icon: AppIconName.sort,
            actionLabel: '조건 초기화',
            onAction: _resetQuery,
            variant: EmptyStateVariant.embedded,
          )
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: SlidableAutoCloseBehavior(
              child: Column(
                children: _buildTransactionListChildren(
                  context,
                  visibleEntries,
                ),
              ),
            ),
          ),
        SizedBox(height: context.spacing.xl),
      ],
    );
  }

  List<Widget> _buildTransactionListChildren(
    BuildContext context,
    List<_TransactionEntry> visibleEntries,
  ) {
    final allPeriodKeys = <String>[];
    for (final entry in visibleEntries) {
      final periodKey = _transactionStatementPeriodKey(entry.transaction.date);
      if (!allPeriodKeys.contains(periodKey)) {
        allPeriodKeys.add(periodKey);
      }
    }
    final shownPeriodKeys = allPeriodKeys.take(_visiblePeriodLimit).toSet();
    final shownEntries = visibleEntries
        .where(
          (entry) => shownPeriodKeys.contains(
            _transactionStatementPeriodKey(entry.transaction.date),
          ),
        )
        .toList();
    final children = <Widget>[];
    String? previousPeriodKey;

    for (var index = 0; index < shownEntries.length; index++) {
      final entry = shownEntries[index];
      final periodKey = _transactionStatementPeriodKey(entry.transaction.date);
      if (periodKey != previousPeriodKey) {
        if (children.isNotEmpty) {
          children.add(AppDivider(inset: context.spacing.md));
        }
        children.add(
          _TransactionMonthHeader(label: _statementPeriodLabel(periodKey)),
        );
        previousPeriodKey = periodKey;
      } else if (children.isNotEmpty) {
        children.add(AppDivider(inset: context.spacing.md));
      }

      children.add(
        _TransactionEntryRow(
          entry: entry,
          onTap: () =>
              _openTransactionForm(entry.account, item: entry.transaction),
          onDelete: () => _deleteTransaction(entry),
        ),
      );
    }

    final remainingPeriodCount = allPeriodKeys.length - shownPeriodKeys.length;
    if (remainingPeriodCount > 0) {
      children
        ..add(AppDivider(inset: context.spacing.md))
        ..add(_TransactionLoadMoreButton(onPressed: _showMoreEntries));
    }

    return children;
  }
}

class _TransactionMonthHeader extends StatelessWidget {
  const _TransactionMonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        context.spacing.sm,
        context.spacing.md,
        context.spacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: context.typography.meta.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: AppFontWeights.semibold,
          ),
        ),
      ),
    );
  }
}

class _TransactionLoadMoreButton extends StatelessWidget {
  const _TransactionLoadMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.expand_more_rounded),
          label: const Text('이전 기간 더 보기'),
        ),
      ),
    );
  }
}

class _TransactionQueryPanel extends StatelessWidget {
  const _TransactionQueryPanel({
    required this.searchController,
    required this.selectedPeriod,
    required this.selectedCategory,
    required this.selectedQuickFilter,
    required this.sortMode,
    required this.onQuickFilterChanged,
    required this.onFilterPressed,
    required this.onReset,
  });

  final TextEditingController searchController;
  final _TransactionPeriodFilter selectedPeriod;
  final _TransactionCategoryFilter selectedCategory;
  final _TransactionQuickFilter selectedQuickFilter;
  final _TransactionSortMode sortMode;
  final ValueChanged<_TransactionQuickFilter> onQuickFilterChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = _activeFilterSummary(
      searchText: searchController.text,
      period: selectedPeriod,
      category: selectedCategory,
      quickFilter: selectedQuickFilter,
      sortMode: sortMode,
    );
    return SectionCard(
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  style: context.typography.body,
                  decoration: InputDecoration(
                    hintText: '거래 검색',
                    prefixIcon: const Icon(Icons.search_rounded, size: 24),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: context.spacing.xl + context.spacing.sm,
                      minHeight: context.spacing.xxl,
                    ),
                    suffixIcon: searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            onPressed: searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    suffixIconConstraints: BoxConstraints(
                      minWidth: context.spacing.xxl,
                      minHeight: context.spacing.xxl,
                    ),
                    constraints: BoxConstraints(
                      minHeight: context.spacing.xxl,
                      maxHeight: context.spacing.xxl,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.spacing.sm,
                      vertical: context.spacing.sm,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.spacing.xs),
              _TransactionFilterButton(
                activeCount: _activeFilterCount(
                  period: selectedPeriod,
                  category: selectedCategory,
                  quickFilter: selectedQuickFilter,
                  sortMode: sortMode,
                ),
                onPressed: onFilterPressed,
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          _QuickFilterStrip(
            selected: selectedQuickFilter,
            onChanged: onQuickFilterChanged,
          ),
          if (summary != null) ...[
            SizedBox(height: context.spacing.sm),
            _ActiveFilterSummary(summary: summary, onReset: onReset),
          ],
        ],
      ),
    );
  }
}

class _TransactionFilterButton extends StatelessWidget {
  const _TransactionFilterButton({
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = activeCount > 0;
    return Semantics(
      button: true,
      label: '거래 상세 필터',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.tune_rounded, size: 20),
            label: const Text('필터'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, context.spacing.xxl),
              padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
              foregroundColor: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              side: BorderSide(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.radius.rPill),
              ),
            ),
          ),
          if (isActive)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: VisualSpec.icon.sizeBadge - context.spacing.xs / 4,
                  minHeight: VisualSpec.icon.sizeBadge - context.spacing.xs / 4,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xs - context.spacing.xs / 4,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(context.radius.rPill),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Text(
                  '$activeCount',
                  style: context.typography.meta.copyWith(
                    color: colorScheme.onPrimary,
                    fontSize: context.fontSizes.s12,
                    fontWeight: AppFontWeights.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickFilterStrip extends StatelessWidget {
  const _QuickFilterStrip({required this.selected, required this.onChanged});

  final _TransactionQuickFilter selected;
  final ValueChanged<_TransactionQuickFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterStrip<_TransactionQuickFilter>(
      values: _TransactionQuickFilter.values,
      selected: selected,
      labelBuilder: (filter) => filter.label,
      leadingIconBuilder: (filter) =>
          filter == selected ? Icons.check_rounded : null,
      onChanged: onChanged,
    );
  }
}

class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({required this.summary, required this.onReset});

  final String summary;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.meta.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: context.spacing.xs),
        TextButton(
          onPressed: onReset,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
            minimumSize: Size(0, context.spacing.xl),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('초기화'),
        ),
      ],
    );
  }
}

class _FilterStrip<T> extends StatelessWidget {
  const _FilterStrip({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    this.leadingIconBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final IconData? Function(T value)? leadingIconBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values) ...[
            Builder(
              builder: (context) {
                final icon = leadingIconBuilder?.call(value);
                final isSelected = selected == value;
                final pillStyle = MoneyfyPillStyle.resolve(
                  context,
                  size: MoneyfyPillSize.lg,
                  tone: isSelected
                      ? MoneyfyPillTone.primary
                      : MoneyfyPillTone.neutral,
                  variant: isSelected
                      ? MoneyfyPillVariant.selected
                      : MoneyfyPillVariant.outline,
                );
                return RawChip(
                  avatar: icon == null
                      ? null
                      : Icon(icon, size: 16, color: pillStyle.foreground),
                  label: Text(labelBuilder(value)),
                  selected: isSelected,
                  onPressed: () => onChanged(value),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: pillStyle.background,
                  selectedColor: pillStyle.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(pillStyle.radius),
                  ),
                  padding: pillStyle.padding,
                  labelPadding: EdgeInsets.zero,
                  side: BorderSide(
                    color: pillStyle.border,
                    width: pillStyle.borderWidth,
                  ),
                  labelStyle: pillStyle.textStyle.copyWith(
                    fontWeight: isSelected
                        ? AppFontWeights.semibold
                        : AppFontWeights.regular,
                  ),
                );
              },
            ),
            if (value != values.last) SizedBox(width: context.spacing.xs),
          ],
        ],
      ),
    );
  }
}

class _TransactionFilterDraft {
  const _TransactionFilterDraft({
    required this.period,
    required this.category,
    required this.sortMode,
  });

  final _TransactionPeriodFilter period;
  final _TransactionCategoryFilter category;
  final _TransactionSortMode sortMode;
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({
    required this.initialPeriod,
    required this.initialCategory,
    required this.initialSortMode,
  });

  final _TransactionPeriodFilter initialPeriod;
  final _TransactionCategoryFilter initialCategory;
  final _TransactionSortMode initialSortMode;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late _TransactionPeriodFilter _period;
  late _TransactionCategoryFilter _category;
  late _TransactionSortMode _sortMode;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _category = widget.initialCategory;
    _sortMode = widget.initialSortMode;
  }

  void _reset() {
    setState(() {
      _period = _TransactionPeriodFilter.all;
      _category = _TransactionCategoryFilter.all;
      _sortMode = _TransactionSortMode.dateDesc;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _TransactionFilterDraft(
        period: _period,
        category: _category,
        sortMode: _sortMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return AppSheetSurface(
      heightFactor: 0.82,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              context.spacing.sm,
              context.spacing.md,
              context.spacing.sm,
            ),
            child: Column(
              children: [
                const AppSheetHandle(),
                SizedBox(height: context.spacing.md),
                Row(
                  children: [
                    Text('상세 필터', style: context.typography.sectionTitle),
                    const Spacer(),
                    TextButton(onPressed: _reset, child: const Text('초기화')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                0,
                context.spacing.md,
                context.spacing.md,
              ),
              children: [
                _FilterSheetSection(
                  title: '기간',
                  child: _FilterOptionWrap<_TransactionPeriodFilter>(
                    values: _TransactionPeriodFilter.values,
                    selected: _period,
                    labelBuilder: (period) => period.label,
                    onChanged: (period) {
                      setState(() {
                        _period = period;
                      });
                    },
                  ),
                ),
                _FilterSheetSection(
                  title: '거래 유형',
                  child: _FilterOptionWrap<_TransactionCategoryFilter>(
                    values: _TransactionCategoryFilter.values,
                    selected: _category,
                    labelBuilder: (category) => category.label,
                    onChanged: (category) {
                      setState(() {
                        _category = category;
                      });
                    },
                  ),
                ),
                _FilterSheetSection(
                  title: '계좌',
                  child: _DisabledFilterNotice(text: '계좌별 필터는 다음 단계에서 추가합니다.'),
                ),
                _FilterSheetSection(
                  title: '자산',
                  child: _DisabledFilterNotice(text: '자산별 필터는 다음 단계에서 추가합니다.'),
                ),
                _FilterSheetSection(
                  title: '정렬',
                  child: _FilterOptionWrap<_TransactionSortMode>(
                    values: _TransactionSortMode.values,
                    selected: _sortMode,
                    labelBuilder: (mode) => mode.label,
                    onChanged: (mode) {
                      setState(() {
                        _sortMode = mode;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              context.spacing.sm,
              context.spacing.md,
              context.spacing.md + bottomInset,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('초기화'),
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('결과 보기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheetSection extends StatelessWidget {
  const _FilterSheetSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.typography.cardTitle),
          SizedBox(height: context.spacing.sm),
          child,
        ],
      ),
    );
  }
}

class _FilterOptionWrap<T> extends StatelessWidget {
  const _FilterOptionWrap({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.xs,
      runSpacing: context.spacing.xs,
      children: [
        for (final value in values)
          _FilterOptionChip<T>(
            value: value,
            selected: selected,
            labelBuilder: labelBuilder,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _FilterOptionChip<T> extends StatelessWidget {
  const _FilterOptionChip({
    required this.value,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final pillStyle = MoneyfyPillStyle.resolve(
      context,
      size: MoneyfyPillSize.lg,
      tone: isSelected ? MoneyfyPillTone.primary : MoneyfyPillTone.neutral,
      variant: isSelected
          ? MoneyfyPillVariant.selected
          : MoneyfyPillVariant.outline,
    );

    return RawChip(
      avatar: isSelected
          ? Icon(Icons.check_rounded, size: 16, color: pillStyle.foreground)
          : null,
      label: Text(labelBuilder(value)),
      selected: isSelected,
      showCheckmark: false,
      onPressed: () => onChanged(value),
      backgroundColor: pillStyle.background,
      selectedColor: pillStyle.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pillStyle.radius),
      ),
      padding: pillStyle.padding,
      labelPadding: EdgeInsets.zero,
      side: BorderSide(color: pillStyle.border, width: pillStyle.borderWidth),
      labelStyle: pillStyle.textStyle.copyWith(
        fontWeight: isSelected
            ? AppFontWeights.semibold
            : AppFontWeights.regular,
      ),
    );
  }
}

class _DisabledFilterNotice extends StatelessWidget {
  const _DisabledFilterNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radius.rMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: context.typography.meta.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TransactionEntryRow extends StatelessWidget {
  const _TransactionEntryRow({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final _TransactionEntry entry;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final transaction = entry.transaction;
    final amountValue = _transactionDisplayAmountValue(transaction);
    final amountText = _formatTransactionAmountInKrw(
      amountValue,
      sourceCurrency: entry.currencyCode,
      exchangeRate: entry.exchangeRate,
    );
    final signedAmountText = _signedAmountText(transaction, amountText);
    final amountColor = _externalCashAmountColor(context, transaction);
    final subtitle = [
      entry.accountSummary,
      entry.account.subtitle,
      transaction.date,
      if (!transaction.includeInCalculations) '기록전용',
    ].where((value) => value.trim().isNotEmpty).join(' · ');

    return Slidable(
      key: ValueKey(
        'transactions-page-${entry.entryKey}-${entry.account.holdingId}-${entry.originalIndex}',
      ),
      groupTag: _TransactionsPageState._kSlidableGroupTag,
      endActionPane: moneyfySingleSlideActionPane(
        onPressed: onDelete,
        icon: Icons.delete_outline_rounded,
        iconColor: Theme.of(context).colorScheme.error,
      ),
      child: TransactionRow(
        typeLabel: transaction.type,
        title: transaction.name,
        subtitle: subtitle,
        amountText: signedAmountText,
        amountColor: amountColor,
        onTap: onTap,
        typeColor: _transactionTypeColor(context, transaction.type),
      ),
    );
  }
}

enum _TransactionCreateKind {
  investment(
    '일반 거래',
    '보유 종목의 매수, 매도, 배당, 이자를 기록합니다.',
    Icons.trending_up_rounded,
  ),
  cash(
    '현금 계좌 거래',
    '현금 계좌의 입금, 출금, 이체, 환전을 기록합니다.',
    Icons.account_balance_wallet_rounded,
  );

  const _TransactionCreateKind(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;

  String get disabledSubtitle => switch (this) {
    _TransactionCreateKind.investment => '보유 종목을 먼저 추가해 주세요.',
    _TransactionCreateKind.cash => '현금 계좌를 먼저 추가해 주세요.',
  };
}

class _TransactionKindPickerSheet extends StatelessWidget {
  const _TransactionKindPickerSheet({required this.accounts});

  final List<_TransactionAccountOption> accounts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hasInvestmentAccount = accounts.any((account) => !account.isCash);
    final hasCashAccount = accounts.any((account) => account.isCash);

    return AppSheetSurface(
      heightFactor: 0.42,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              context.spacing.sm,
              context.spacing.md,
              context.spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AppSheetHandle()),
                SizedBox(height: context.spacing.md),
                Text('거래 유형 선택', style: context.typography.sectionTitle),
                SizedBox(height: context.spacing.xs / 2),
                Text(
                  '투자 거래는 보유 종목, 현금 거래는 현금 계좌가 필요해요.',
                  style: context.typography.meta.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                context.spacing.xs / 2,
                context.spacing.md,
                context.spacing.md + bottomInset,
              ),
              children: [
                _TransactionKindTile(
                  kind: _TransactionCreateKind.investment,
                  enabled: hasInvestmentAccount,
                ),
                SizedBox(height: context.spacing.sm),
                _TransactionKindTile(
                  kind: _TransactionCreateKind.cash,
                  enabled: hasCashAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionKindTile extends StatelessWidget {
  const _TransactionKindTile({required this.kind, required this.enabled});

  final _TransactionCreateKind kind;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(context.radius.rLg),
      onTap: enabled ? () => Navigator.of(context).pop(kind) : null,
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.sm,
          vertical: context.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.surfaceContainerLow
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(context.radius.rLg),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              kind.icon,
              size: 24,
              color: enabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    kind.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.cardTitle.copyWith(
                      color: enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: context.spacing.xs / 2),
                  Text(
                    enabled ? kind.subtitle : kind.disabledSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.meta.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: enabled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsPageData {
  const _TransactionsPageData({required this.entries, required this.accounts});

  const _TransactionsPageData.empty()
    : entries = const <_TransactionEntry>[],
      accounts = const <_TransactionAccountOption>[];

  final List<_TransactionEntry> entries;
  final List<_TransactionAccountOption> accounts;
}

class _TransactionEntry {
  const _TransactionEntry({
    required this.transaction,
    required this.account,
    required this.currencyCode,
    required this.exchangeRate,
    required this.originalIndex,
    this.relatedAccounts = const <_TransactionAccountOption>[],
  });

  final TransactionItem transaction;
  final _TransactionAccountOption account;
  final String currencyCode;
  final double exchangeRate;
  final int originalIndex;
  final List<_TransactionAccountOption> relatedAccounts;

  Object get entryKey =>
      transaction.ledgerEventId ?? transaction.id ?? hashCode;

  String get accountSummary {
    if (relatedAccounts.length <= 1) return account.title;
    return '${account.title} 외 ${relatedAccounts.length - 1}개';
  }

  String get searchText {
    return [
      transaction.name,
      transaction.type,
      transaction.date,
      transaction.amount,
      transaction.quantity,
      account.title,
      account.subtitle,
      for (final relatedAccount in relatedAccounts) ...[
        relatedAccount.title,
        relatedAccount.subtitle,
        relatedAccount.isCash ? '현금' : '투자',
      ],
      account.isCash ? '현금' : '투자',
      transaction.includeInCalculations ? '계산반영' : '기록전용 계산미반영',
    ].join(' ').toLowerCase();
  }
}

class _TransactionAccountOption {
  const _TransactionAccountOption({
    required this.assetId,
    required this.holdingId,
    required this.holdingClientId,
    required this.title,
    required this.subtitle,
    required this.isCash,
    required this.currencyCode,
    required this.exchangeRate,
  });

  final int assetId;
  final int holdingId;
  final String? holdingClientId;
  final String title;
  final String subtitle;
  final bool isCash;
  final String currencyCode;
  final double exchangeRate;
}

List<_TransactionEntry> _groupEntriesByLedgerEvent(
  List<_TransactionEntry> entries,
) {
  final ungrouped = <_TransactionEntry>[];
  final byEvent = <int, List<_TransactionEntry>>{};

  for (final entry in entries) {
    final eventId = entry.transaction.ledgerEventId;
    if (eventId == null) {
      ungrouped.add(entry);
      continue;
    }
    byEvent.putIfAbsent(eventId, () => <_TransactionEntry>[]).add(entry);
  }

  return [
    ...ungrouped,
    for (final group in byEvent.values) _representativeEventEntry(group),
  ];
}

_TransactionEntry _representativeEventEntry(List<_TransactionEntry> group) {
  final sorted = group.toList(growable: false)
    ..sort(_compareRepresentativeEntries);
  final representative = sorted.first;
  return _TransactionEntry(
    transaction: representative.transaction,
    account: representative.account,
    currencyCode: representative.currencyCode,
    exchangeRate: representative.exchangeRate,
    originalIndex: representative.originalIndex,
    relatedAccounts: _uniqueEventAccounts(representative, group),
  );
}

int _compareRepresentativeEntries(_TransactionEntry a, _TransactionEntry b) {
  final byPriority = _representativePriority(
    a,
  ).compareTo(_representativePriority(b));
  if (byPriority != 0) return byPriority;
  final byLineId = (a.transaction.ledgerLineId ?? 0).compareTo(
    b.transaction.ledgerLineId ?? 0,
  );
  if (byLineId != 0) return byLineId;
  return a.originalIndex.compareTo(b.originalIndex);
}

int _representativePriority(_TransactionEntry entry) {
  final action = entry.transaction.ledgerAction;
  if (!entry.account.isCash) return 0;
  if (action == 'transfer_out' ||
      action == 'fx_out' ||
      (entry.transaction.cashFlowAmount ?? 0) < 0) {
    return 1;
  }
  return 2;
}

List<_TransactionAccountOption> _uniqueEventAccounts(
  _TransactionEntry representative,
  List<_TransactionEntry> group,
) {
  final result = <_TransactionAccountOption>[];
  final seen = <String>{};

  void addAccount(_TransactionAccountOption account) {
    final key = '${account.isCash}:${account.holdingId}';
    if (seen.add(key)) result.add(account);
  }

  addAccount(representative.account);
  for (final entry in group) {
    addAccount(entry.account);
  }
  return List.unmodifiable(result);
}

@visibleForTesting
List<TransactionItem> groupTransactionEventsForTesting(
  List<TransactionItem> transactions, {
  Set<int> cashHoldingIds = const <int>{},
}) {
  final entries = <_TransactionEntry>[];
  for (var index = 0; index < transactions.length; index++) {
    final transaction = transactions[index];
    final holdingId = transaction.holdingId ?? index;
    final isCash = cashHoldingIds.contains(holdingId);
    entries.add(
      _TransactionEntry(
        transaction: transaction,
        account: _TransactionAccountOption(
          assetId: transaction.assetId ?? 0,
          holdingId: holdingId,
          holdingClientId: null,
          title: 'account-$holdingId',
          subtitle: '',
          isCash: isCash,
          currencyCode: 'KRW',
          exchangeRate: 1,
        ),
        currencyCode: 'KRW',
        exchangeRate: 1,
        originalIndex: index,
      ),
    );
  }
  return _groupEntriesByLedgerEvent(
    entries,
  ).map((entry) => entry.transaction).toList(growable: false);
}

int _compareTransactionEntries(_TransactionEntry a, _TransactionEntry b) {
  final byDate = _parseDate(
    b.transaction.date,
  ).compareTo(_parseDate(a.transaction.date));
  if (byDate != 0) return byDate;

  final aEventId = a.transaction.ledgerEventId ?? a.transaction.id ?? 0;
  final bEventId = b.transaction.ledgerEventId ?? b.transaction.id ?? 0;
  final byEvent = bEventId.compareTo(aEventId);
  if (byEvent != 0) return byEvent;

  return b.originalIndex.compareTo(a.originalIndex);
}

List<_TransactionEntry> _sortEntries(
  List<_TransactionEntry> entries,
  _TransactionSortMode sortMode,
) {
  final sorted = entries.toList(growable: false);
  switch (sortMode) {
    case _TransactionSortMode.dateDesc:
      sorted.sort(_compareTransactionEntries);
      return sorted;
    case _TransactionSortMode.dateAsc:
      sorted.sort((a, b) => _compareTransactionEntries(b, a));
      return sorted;
    case _TransactionSortMode.amountDesc:
      sorted.sort((a, b) => _entryAmountKrw(b).compareTo(_entryAmountKrw(a)));
      return sorted;
    case _TransactionSortMode.amountAsc:
      sorted.sort((a, b) => _entryAmountKrw(a).compareTo(_entryAmountKrw(b)));
      return sorted;
  }
}

enum _TransactionPeriodFilter {
  all('전체 기간', null),
  week('1주', Duration(days: 7)),
  month('1개월', Duration(days: 31)),
  threeMonths('3개월', Duration(days: 93)),
  sixMonths('6개월', Duration(days: 186)),
  year('1년', Duration(days: 366));

  const _TransactionPeriodFilter(this.label, this.duration);

  final String label;
  final Duration? duration;

  bool matches(_TransactionEntry entry) {
    final duration = this.duration;
    if (duration == null) return true;
    final transactionDate = _parseDate(entry.transaction.date);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final fromDate = todayDate.subtract(duration);
    return !transactionDate.isBefore(fromDate) &&
        !transactionDate.isAfter(todayDate);
  }
}

enum _TransactionQuickFilter {
  all('전체', _TransactionCategoryFilter.all),
  buy('매수', _TransactionCategoryFilter.buy),
  sell('매도', _TransactionCategoryFilter.sell),
  dividend('배당', _TransactionCategoryFilter.dividend),
  cashFlow('입출금', _TransactionCategoryFilter.all);

  const _TransactionQuickFilter(this.label, this.category);

  final String label;
  final _TransactionCategoryFilter category;

  static _TransactionQuickFilter fromCategory(
    _TransactionCategoryFilter category,
  ) {
    return switch (category) {
      _TransactionCategoryFilter.buy => _TransactionQuickFilter.buy,
      _TransactionCategoryFilter.sell => _TransactionQuickFilter.sell,
      _TransactionCategoryFilter.dividend => _TransactionQuickFilter.dividend,
      _ => _TransactionQuickFilter.all,
    };
  }

  bool matches(_TransactionEntry entry) {
    return switch (this) {
      _TransactionQuickFilter.all ||
      _TransactionQuickFilter.buy ||
      _TransactionQuickFilter.sell ||
      _TransactionQuickFilter.dividend => true,
      _TransactionQuickFilter.cashFlow =>
        _TransactionCategoryFilter.deposit.matches(entry) ||
            _TransactionCategoryFilter.withdrawal.matches(entry),
    };
  }
}

enum _TransactionCategoryFilter {
  all('전체 유형', {}),
  buy('매수', {'buy', '매수'}),
  sell('매도', {'sell', '매도'}),
  dividend('배당', {'dividend', '배당'}),
  interest('이자', {'interest', '이자'}),
  deposit('입금', {'deposit', 'opening_cash', '입금'}),
  withdrawal('출금', {'withdrawal', '출금'}),
  transfer('이체', {'transfer_out', 'transfer_in', '이체'}),
  exchange('환전', {'fx_out', 'fx_in', '환전'}),
  fee('수수료', {'fee', '수수료'}),
  tax('세금', {'tax', '세금'}),
  adjustment('조정', {'adjustment', 'opening_quantity', '초기', '조정'});

  const _TransactionCategoryFilter(this.label, this.actions);

  final String label;
  final Set<String> actions;

  bool matches(_TransactionEntry entry) {
    if (this == _TransactionCategoryFilter.all) return true;
    final transaction = entry.transaction;
    final action = transaction.ledgerAction ?? transaction.type.trim();
    return actions.contains(action) ||
        actions.contains(transaction.type.trim());
  }
}

int _activeFilterCount({
  required _TransactionPeriodFilter period,
  required _TransactionCategoryFilter category,
  required _TransactionQuickFilter quickFilter,
  required _TransactionSortMode sortMode,
}) {
  var count = 0;
  if (period != _TransactionPeriodFilter.all) count++;
  if (category != _TransactionCategoryFilter.all ||
      quickFilter != _TransactionQuickFilter.all) {
    count++;
  }
  if (sortMode != _TransactionSortMode.dateDesc) count++;
  return count;
}

String? _activeFilterSummary({
  required String searchText,
  required _TransactionPeriodFilter period,
  required _TransactionCategoryFilter category,
  required _TransactionQuickFilter quickFilter,
  required _TransactionSortMode sortMode,
}) {
  final parts = <String>[];
  final query = searchText.trim();
  if (query.isNotEmpty) parts.add('검색어: $query');
  if (period != _TransactionPeriodFilter.all) parts.add(period.label);
  if (category != _TransactionCategoryFilter.all) {
    parts.add(category.label);
  } else if (quickFilter != _TransactionQuickFilter.all) {
    parts.add(quickFilter.label);
  }
  if (sortMode != _TransactionSortMode.dateDesc) parts.add(sortMode.label);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

enum _TransactionSortMode {
  dateDesc('최신순', '최신'),
  dateAsc('오래된순', '오래된'),
  amountDesc('금액 큰순', '큰 금액'),
  amountAsc('금액 작은순', '작은 금액');

  const _TransactionSortMode(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

DateTime _parseDate(String value) {
  final parts = value.replaceAll('.', '-').split('-');
  if (parts.length != 3) return DateTime.fromMillisecondsSinceEpoch(0);
  final year = int.tryParse(parts[0]) ?? 0;
  final month = int.tryParse(parts[1]) ?? 1;
  final day = int.tryParse(parts[2]) ?? 1;
  if (year <= 0) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime(year, month, day);
}

String _transactionStatementPeriodKey(String date) {
  final parsed = _parseDate(date);
  if (parsed.year <= 1970 && !date.startsWith('1970')) return date;
  final start = parsed.day >= 20
      ? DateTime(parsed.year, parsed.month, 20)
      : DateTime(parsed.year, parsed.month - 1, 20);
  final month = start.month.toString().padLeft(2, '0');
  final day = start.day.toString().padLeft(2, '0');
  return '${start.year}-$month-$day';
}

String _statementPeriodLabel(String periodKey) {
  final parts = periodKey.split('-');
  if (parts.length != 3) return periodKey;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return periodKey;

  final start = DateTime(year, month, day);
  final end = DateTime(start.year, start.month + 1, 19);
  final endLabel = start.year == end.year
      ? '${end.month}월 ${end.day}일'
      : '${end.year}년 ${end.month}월 ${end.day}일';
  return '${start.year}년 ${start.month}월 ${start.day}일 ~ $endLabel';
}

String _signedAmountText(TransactionItem transaction, String amountText) {
  return switch (transaction.ledgerAction ?? transaction.type.trim()) {
    'sell' ||
    'dividend' ||
    'interest' ||
    'deposit' ||
    'transfer_in' ||
    'fx_in' ||
    '매도' ||
    '배당' ||
    '이자' ||
    '입금' => '+$amountText',
    'buy' ||
    'withdrawal' ||
    'transfer_out' ||
    'fx_out' ||
    'fee' ||
    'tax' ||
    '매수' ||
    '출금' ||
    '이체' ||
    '환전' => '-$amountText',
    _ => amountText,
  };
}

Color _externalCashAmountColor(
  BuildContext context,
  TransactionItem transaction,
) {
  final colors = context.colors;
  return switch (TransactionFlowCategory.normalize(transaction.flowCategory)) {
    TransactionFlowCategory.externalDeposit => colors.positiveOn,
    TransactionFlowCategory.externalWithdrawal => colors.negativeOn,
    _ => colors.neutralText,
  };
}

double _entryAmountKrw(_TransactionEntry entry) {
  final amount = _transactionDisplayAmountValue(entry.transaction);
  final normalizedSource = entry.currencyCode.toUpperCase();
  return normalizedSource == 'USD' && entry.exchangeRate > 0
      ? amount.abs() * entry.exchangeRate
      : amount.abs();
}

double _transactionDisplayAmountValue(TransactionItem transaction) {
  final grossAmount = transaction.grossAmount ?? 0;
  if (grossAmount.abs() > 0.0000001) {
    return grossAmount;
  }
  final amount =
      double.tryParse(transaction.amount.replaceAll(',', '').trim()) ?? 0;
  final quantity =
      double.tryParse(transaction.quantity.replaceAll(',', '').trim()) ?? 0;
  final action = transaction.ledgerAction ?? transaction.type.trim();
  if ((action == 'buy' ||
          action == 'sell' ||
          action == 'opening_quantity' ||
          action == '매수' ||
          action == '매도' ||
          action == '초기') &&
      quantity.abs() > 0.0000001) {
    return amount * quantity;
  }
  return amount;
}

String _formatTransactionAmountInKrw(
  double amount, {
  required String sourceCurrency,
  required double exchangeRate,
}) {
  final normalizedSource = sourceCurrency.toUpperCase();
  final amountKrw = normalizedSource == 'USD' && exchangeRate > 0
      ? amount.abs() * exchangeRate
      : amount.abs();
  return MoneyfyDisplayCurrencySettings.formatAmountFromKrw(amountKrw);
}

Color _transactionTypeColor(BuildContext context, String type) {
  final colors = context.colors;
  return switch (type.trim()) {
    '매수' || '출금' || '이체' || '환전' => colors.neutralSurfaceOverlay,
    '매도' || '배당' || '이자' || '입금' => colors.neutralSurfaceOverlay,
    _ => colors.neutralSurfaceOverlay,
  };
}
