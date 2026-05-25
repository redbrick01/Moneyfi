import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/icons/app_icon.dart';
import '../components/section_card.dart';
import '../components/states/empty_state.dart';
import '../components/states/inline_error.dart';
import '../components/states/retry_row.dart';
import '../components/states/skeletons.dart';
import '../db/app_database.dart';
import '../design_system/context_extensions.dart';
import '../models/asset_item.dart';
import '../services/sync_service.dart';
import '../theme/moneyfy_theme.dart';
import '../ui_scaffold/app_page_scaffold.dart';
import '../utils/display_currency.dart';
import '../widgets/moneyfy_ui.dart';
import 'forms/cash_transaction_form_page.dart';
import 'forms/transaction_form_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    this.scrollController,
    this.dataRefreshTick = 0,
  });

  final ScrollController? scrollController;
  final int dataRefreshTick;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const String _kSlidableGroupTag = 'transactions_page_slidable_group';
  late Future<_TransactionsPageData> _pageFuture;
  late final TextEditingController _searchController;
  _TransactionFilter _selectedFilter = _TransactionFilter.all;
  _TransactionSortMode _sortMode = _TransactionSortMode.dateDesc;

  @override
  void initState() {
    super.initState();
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
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant TransactionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataRefreshTick != widget.dataRefreshTick) {
      setState(() {
        _pageFuture = _loadPageData();
      });
    }
  }

  Future<_TransactionsPageData> _loadPageData() async {
    final assets = await AppDatabase.instance.fetchAssets();
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
    final nextFuture = _loadPageData();
    setState(() {
      _pageFuture = nextFuture;
    });
    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder renders the error state; pull-to-refresh should settle.
    }
  }

  Future<void> _openCreateFlow(_TransactionsPageData data) async {
    if (data.accounts.isEmpty) return;
    final account = await showModalBottomSheet<_TransactionAccountOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MoneyfyPalette.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (context) => _AccountPickerSheet(accounts: data.accounts),
    );
    if (account == null || !mounted) return;
    await _openTransactionForm(account);
  }

  void _resetQuery() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    setState(() {
      _selectedFilter = _TransactionFilter.all;
      _sortMode = _TransactionSortMode.dateDesc;
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

    final changed = await Navigator.of(context).push<bool>(
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

    if (changed == true && mounted) {
      setState(() {
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
          if (!_selectedFilter.matches(entry)) return false;
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
      return EmptyStateCard(
        title: '아직 거래 내역이 없어요',
        description: data.accounts.isEmpty
            ? '자산이나 현금 계좌를 먼저 추가해 주세요.'
            : '첫 거래를 등록하고 자산 흐름을 기록하세요.',
        icon: AppIconName.wallet,
        actionLabel: data.accounts.isEmpty ? null : '거래 추가',
        onAction: data.accounts.isEmpty ? null : () => _openCreateFlow(data),
        variant: EmptyStateVariant.embedded,
      );
    }

    return Column(
      children: [
        _TransactionQueryPanel(
          searchController: _searchController,
          selectedFilter: _selectedFilter,
          sortMode: _sortMode,
          onFilterChanged: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          onSortChanged: (mode) {
            setState(() {
              _sortMode = mode;
            });
          },
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
                children: [
                  for (
                    var index = 0;
                    index < visibleEntries.length;
                    index++
                  ) ...[
                    _TransactionEntryRow(
                      entry: visibleEntries[index],
                      onTap: () => _openTransactionForm(
                        visibleEntries[index].account,
                        item: visibleEntries[index].transaction,
                      ),
                      onDelete: () => _deleteTransaction(visibleEntries[index]),
                    ),
                    if (index != visibleEntries.length - 1)
                      Divider(
                        height: 1,
                        indent: context.spacing.md,
                        endIndent: context.spacing.md,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TransactionQueryPanel extends StatelessWidget {
  const _TransactionQueryPanel({
    required this.searchController,
    required this.selectedFilter,
    required this.sortMode,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final _TransactionFilter selectedFilter;
  final _TransactionSortMode sortMode;
  final ValueChanged<_TransactionFilter> onFilterChanged;
  final ValueChanged<_TransactionSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '거래 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: searchController.clear,
                      icon: const Icon(Icons.close_rounded),
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
          SizedBox(height: context.spacing.sm),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in _TransactionFilter.values) ...[
                        ChoiceChip(
                          label: Text(filter.label),
                          selected: selectedFilter == filter,
                          onSelected: (_) => onFilterChanged(filter),
                        ),
                        if (filter != _TransactionFilter.values.last)
                          SizedBox(width: context.spacing.xs),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.spacing.sm),
              PopupMenuButton<_TransactionSortMode>(
                tooltip: '정렬',
                initialValue: sortMode,
                onSelected: onSortChanged,
                itemBuilder: (context) => [
                  for (final mode in _TransactionSortMode.values)
                    PopupMenuItem<_TransactionSortMode>(
                      value: mode,
                      child: Row(
                        children: [
                          Expanded(child: Text(mode.label)),
                          if (mode == sortMode)
                            Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(context.radius.rPill),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort_rounded, size: 18),
                      SizedBox(width: context.spacing.xs),
                      Text(sortMode.shortLabel, style: context.typography.meta),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
      child: _CompactTransactionRow(
        typeLabel: transaction.type,
        title: transaction.name,
        subtitle: subtitle,
        amountText: signedAmountText,
        amountColor: amountColor,
        onTap: onTap,
      ),
    );
  }
}

class _CompactTransactionRow extends StatelessWidget {
  const _CompactTransactionRow({
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.amountColor,
    required this.onTap,
  });

  final String typeLabel;
  final String title;
  final String subtitle;
  final String amountText;
  final Color amountColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _transactionTypeColor(context, typeLabel);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.rMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                height: 28,
                padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(context.radius.rPill),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.caption.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: context.spacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.cardTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.spacing.xs / 2),
                    Text(
                      subtitle,
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 118),
                child: Text(
                  amountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  softWrap: false,
                  style: context.typography.cardTitle.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
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

class _AccountPickerSheet extends StatelessWidget {
  const _AccountPickerSheet({required this.accounts});

  final List<_TransactionAccountOption> accounts;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final investmentAccounts = accounts
        .where((account) => !account.isCash)
        .toList(growable: false);
    final cashAccounts = accounts
        .where((account) => account.isCash)
        .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.70,
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: MoneyfyPalette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: MoneyfyPalette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '거래 계좌 선택',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '거래를 등록할 보유 항목을 선택하세요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 2, 20, 24 + bottomInset),
                  children: [
                    if (investmentAccounts.isNotEmpty) ...[
                      _AccountPickerSection(
                        title: '투자 보유',
                        accounts: investmentAccounts,
                      ),
                      if (cashAccounts.isNotEmpty) const SizedBox(height: 18),
                    ],
                    if (cashAccounts.isNotEmpty)
                      _AccountPickerSection(
                        title: '현금 계좌',
                        accounts: cashAccounts,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPickerSection extends StatelessWidget {
  const _AccountPickerSection({required this.title, required this.accounts});

  final String title;
  final List<_TransactionAccountOption> accounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: MoneyfyPalette.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < accounts.length; index++) ...[
          _AccountOptionTile(account: accounts[index]),
          if (index != accounts.length - 1)
            Divider(
              height: 1,
              indent: 2,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.52),
            ),
        ],
      ],
    );
  }
}

class _AccountOptionTile extends StatelessWidget {
  const _AccountOptionTile({required this.account});

  final _TransactionAccountOption account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _cleanAccountSubtitle(account.subtitle);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).pop(account),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    account.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: MoneyfyPalette.tertiaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, size: 24),
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

String? _cleanAccountSubtitle(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '+') {
    return null;
  }
  return normalized;
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

enum _TransactionFilter {
  all('전체'),
  investment('투자'),
  cash('현금'),
  income('입금·수익'),
  expense('출금·매수');

  const _TransactionFilter(this.label);

  final String label;

  bool matches(_TransactionEntry entry) {
    return switch (this) {
      _TransactionFilter.all => true,
      _TransactionFilter.investment => !entry.account.isCash,
      _TransactionFilter.cash => entry.account.isCash,
      _TransactionFilter.income => _isIncomeTransaction(entry.transaction),
      _TransactionFilter.expense => _isExpenseTransaction(entry.transaction),
    };
  }
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
  final colorScheme = Theme.of(context).colorScheme;
  return switch (TransactionFlowCategory.normalize(transaction.flowCategory)) {
    TransactionFlowCategory.externalDeposit => colorScheme.primary,
    TransactionFlowCategory.externalWithdrawal => colorScheme.error,
    _ => colorScheme.onSurface,
  };
}

bool _isIncomeTransaction(TransactionItem transaction) {
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
    '입금' => true,
    _ => false,
  };
}

bool _isExpenseTransaction(TransactionItem transaction) {
  return switch (transaction.ledgerAction ?? transaction.type.trim()) {
    'buy' ||
    'withdrawal' ||
    'transfer_out' ||
    'fx_out' ||
    'fee' ||
    'tax' ||
    '매수' ||
    '출금' ||
    '이체' ||
    '환전' => true,
    _ => false,
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
  final colorScheme = Theme.of(context).colorScheme;
  return switch (type.trim()) {
    '매수' ||
    '출금' ||
    '이체' ||
    '환전' => colorScheme.errorContainer.withValues(alpha: 0.36),
    '매도' ||
    '배당' ||
    '이자' ||
    '입금' => colorScheme.primaryContainer.withValues(alpha: 0.5),
    _ => colorScheme.surfaceContainerHighest,
  };
}
