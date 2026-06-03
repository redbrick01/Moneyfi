import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/chips/moneyfy_pill.dart';
import '../components/feedback/app_snackbar.dart';
import '../components/panels/app_inner_panel.dart';
import '../components/panels/app_sheet_surface.dart';
import '../components/section_card.dart';
import '../design_system/context_extensions.dart';
import '../design_system/spec.dart';
import '../services/reddit_post_summary_service.dart';
import '../widgets/moneyfy_ui.dart';

enum _RedditPostFilter { valuable, all }

enum _RedditPostSort { latest, importance }

extension on _RedditPostFilter {
  String get label {
    return switch (this) {
      _RedditPostFilter.valuable => '핵심',
      _RedditPostFilter.all => '전체',
    };
  }
}

extension on _RedditPostSort {
  String get label {
    return switch (this) {
      _RedditPostSort.latest => '최신',
      _RedditPostSort.importance => '중요도',
    };
  }
}

class RedditPostSummariesPage extends StatefulWidget {
  const RedditPostSummariesPage({super.key});

  @override
  State<RedditPostSummariesPage> createState() =>
      _RedditPostSummariesPageState();
}

class _RedditPostSummariesPageState extends State<RedditPostSummariesPage> {
  late Future<_RedditPostPageData> _pageFuture;
  final TextEditingController _searchController = TextEditingController();
  _RedditPostFilter _filter = _RedditPostFilter.valuable;
  _RedditPostSort _sort = _RedditPostSort.latest;
  String? _selectedSubreddit;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
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

  Future<_RedditPostPageData> _loadPageData() async {
    final datesFuture = RedditPostSummaryService.instance.fetchSummaryDates();
    final summariesFuture = RedditPostSummaryService.instance.fetchSummaries(
      postedDate: _selectedDate,
      limit: _selectedDate == null ? 30 : 500,
    );
    final results = await Future.wait<Object>([datesFuture, summariesFuture]);
    return _RedditPostPageData(
      dates: results[0] as List<DateTime>,
      items: results[1] as List<RedditPostSummaryItem>,
    );
  }

  Future<void> _reloadPage() async {
    final future = _loadPageData();
    setState(() {
      _pageFuture = future;
    });
    await future;
  }

  Future<void> _refreshPage() => _reloadPage();

  Future<void> _openFilterSheet(_RedditPostPageData data) async {
    final draft = await showModalBottomSheet<_RedditPostFilterDraft>(
      context: context,
      backgroundColor: VisualSpec.surface.transparent,
      isScrollControlled: true,
      builder: (context) => _RedditPostFilterSheet(
        initialDate: _selectedDate,
        initialSubreddit: _selectedSubreddit,
        initialSort: _sort,
        dates: data.dates,
        subreddits: _subreddits(data.items),
      ),
    );
    if (draft == null || !mounted) return;
    final dateChanged = !_sameDate(_selectedDate, draft.date);
    setState(() {
      _selectedDate = draft.date;
      _selectedSubreddit = draft.subreddit;
      _sort = draft.sort;
    });
    if (dateChanged) {
      await _reloadPage();
    }
  }

  void _resetFilters() {
    final dateChanged = _selectedDate != null;
    setState(() {
      _searchController.clear();
      _filter = _RedditPostFilter.valuable;
      _sort = _RedditPostSort.latest;
      _selectedSubreddit = null;
      _selectedDate = null;
      if (dateChanged) {
        _pageFuture = _loadPageData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RedditPostPageData>(
      future: _pageFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _RedditPostPageData.empty();
        final allItems = data.items;
        final subreddits = _subreddits(allItems);
        if (_selectedSubreddit != null &&
            !subreddits.contains(_selectedSubreddit)) {
          _selectedSubreddit = null;
        }
        final visibleItems = _visibleItems(allItems);

        return MoneyfyPage(
          title: 'Reddit 요약',
          onRefresh: _refreshPage,
          children: [
            _RedditPostSummaryToolbar(
              totalCount: allItems.length,
              visibleCount: visibleItems.length,
              filter: _filter,
              searchController: _searchController,
              onFilterChanged: (filter) => setState(() => _filter = filter),
              activeCount: _activeFilterCount(),
              activeSummary: _activeFilterSummary(),
              onFilterPressed: () => _openFilterSheet(data),
              onReset: _resetFilters,
            ),
            SizedBox(height: context.spacing.sectionGap),
            if (snapshot.hasError)
              _RedditPostEmptyState(
                title: 'Reddit 요약을 불러오지 못했어요',
                message: '로그인 상태와 Supabase 권한을 확인한 뒤 다시 시도해 주세요.',
              )
            else if (snapshot.connectionState == ConnectionState.waiting &&
                allItems.isEmpty)
              const _RedditPostLoadingState()
            else if (visibleItems.isEmpty)
              _RedditPostEmptyState(
                title: allItems.isEmpty ? '표시할 요약이 없어요' : '검색 결과가 없어요',
                message: allItems.isEmpty
                    ? 'reddit_post_summaries 테이블에 데이터가 쌓이면 여기에 표시됩니다.'
                    : '필터나 검색어를 조금 넓혀 보세요.',
              )
            else
              Column(
                children: [
                  for (final item in visibleItems) ...[
                    _RedditPostSummaryCard(item: item),
                    if (item != visibleItems.last)
                      SizedBox(height: context.spacing.md),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  List<RedditPostSummaryItem> _visibleItems(List<RedditPostSummaryItem> items) {
    final query = _searchController.text;
    final filtered = items
        .where((item) {
          final passesFilter = switch (_filter) {
            _RedditPostFilter.valuable => item.isValuable,
            _RedditPostFilter.all => true,
          };
          final passesSubreddit =
              _selectedSubreddit == null ||
              item.subreddit == _selectedSubreddit;
          return passesFilter && passesSubreddit && item.matches(query);
        })
        .toList(growable: false);

    return [...filtered]..sort((a, b) {
      return switch (_sort) {
        _RedditPostSort.latest => _compareDateDesc(
          _summaryDateTime(a),
          _summaryDateTime(b),
        ),
        _RedditPostSort.importance => b.importanceScore.compareTo(
          a.importanceScore,
        ),
      };
    });
  }

  List<String> _subreddits(List<RedditPostSummaryItem> items) {
    final values =
        items
            .map((item) => item.subreddit)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    return values;
  }

  int _activeFilterCount() {
    var count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_selectedDate != null) count++;
    if (_selectedSubreddit != null) count++;
    if (_sort != _RedditPostSort.latest) count++;
    return count;
  }

  String? _activeFilterSummary() {
    final parts = <String>[
      if (_selectedDate != null) _dateKey(_selectedDate),
      ?_selectedSubreddit,
      if (_sort != _RedditPostSort.latest) _sort.label,
      if (_searchController.text.trim().isNotEmpty)
        '"${_searchController.text.trim()}"',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

class _RedditPostPageData {
  const _RedditPostPageData({required this.dates, required this.items});

  const _RedditPostPageData.empty() : dates = const [], items = const [];

  final List<DateTime> dates;
  final List<RedditPostSummaryItem> items;
}

class _RedditPostSummaryToolbar extends StatelessWidget {
  const _RedditPostSummaryToolbar({
    required this.totalCount,
    required this.visibleCount,
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
    required this.activeCount,
    required this.activeSummary,
    required this.onFilterPressed,
    required this.onReset,
  });

  final int totalCount;
  final int visibleCount;
  final _RedditPostFilter filter;
  final TextEditingController searchController;
  final ValueChanged<_RedditPostFilter> onFilterChanged;
  final int activeCount;
  final String? activeSummary;
  final VoidCallback onFilterPressed;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      dense: true,
      variant: SectionCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '요약 ${visibleCount.toString()} / ${totalCount.toString()}',
                  style: context.typography.sectionTitle,
                ),
              ),
              MoneyfyBadge(
                label: 'remote',
                size: MoneyfyPillSize.sm,
                variant: MoneyfyPillVariant.outline,
                backgroundColor: context.colors.neutralSurfaceBase,
                textColor: context.colors.neutralTextMuted,
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  style: context.typography.body,
                  decoration: InputDecoration(
                    hintText: 'Reddit 요약 검색',
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
                    fillColor: context.colors.neutralSurfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(
                        color: context.colors.neutralOutline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(
                        color: context.colors.neutralOutline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.radius.rPill),
                      borderSide: BorderSide(color: context.colors.primary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.spacing.xs),
              _RedditPostFilterButton(
                activeCount: activeCount,
                onPressed: onFilterPressed,
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              _RedditPostQuickFilterStrip(
                selected: filter,
                onChanged: onFilterChanged,
              ),
            ],
          ),
          if (activeSummary != null) ...[
            SizedBox(height: context.spacing.sm),
            _RedditPostActiveFilterSummary(
              summary: activeSummary!,
              onReset: onReset,
            ),
          ],
        ],
      ),
    );
  }
}

class _RedditPostFilterButton extends StatelessWidget {
  const _RedditPostFilterButton({
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return Semantics(
      button: true,
      label: 'Reddit 상세 필터',
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
                  ? context.colors.primary
                  : context.colors.neutralTextMuted,
              side: BorderSide(
                color: isActive
                    ? context.colors.primary
                    : context.colors.neutralOutline,
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
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(context.radius.rPill),
                  border: Border.all(
                    color: context.colors.neutralSurfaceBase,
                    width: VisualSpec.surface.borderWidth * 2,
                  ),
                ),
                child: Text(
                  '$activeCount',
                  style: context.typography.meta.copyWith(
                    color: VisualSpec.brand.onPrimary,
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

class _RedditPostQuickFilterStrip extends StatelessWidget {
  const _RedditPostQuickFilterStrip({
    required this.selected,
    required this.onChanged,
  });

  final _RedditPostFilter selected;
  final ValueChanged<_RedditPostFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterStrip<_RedditPostFilter>(
      values: _RedditPostFilter.values,
      selected: selected,
      labelBuilder: (filter) => filter.label,
      leadingIconBuilder: (filter) =>
          filter == selected ? Icons.check_rounded : null,
      onChanged: onChanged,
    );
  }
}

class _RedditPostActiveFilterSummary extends StatelessWidget {
  const _RedditPostActiveFilterSummary({
    required this.summary,
    required this.onReset,
  });

  final String summary;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
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

class _RedditPostFilterDraft {
  const _RedditPostFilterDraft({
    required this.date,
    required this.subreddit,
    required this.sort,
  });

  final DateTime? date;
  final String? subreddit;
  final _RedditPostSort sort;
}

class _RedditPostFilterSheet extends StatefulWidget {
  const _RedditPostFilterSheet({
    required this.initialDate,
    required this.initialSubreddit,
    required this.initialSort,
    required this.dates,
    required this.subreddits,
  });

  final DateTime? initialDate;
  final String? initialSubreddit;
  final _RedditPostSort initialSort;
  final List<DateTime> dates;
  final List<String> subreddits;

  @override
  State<_RedditPostFilterSheet> createState() => _RedditPostFilterSheetState();
}

class _RedditPostFilterSheetState extends State<_RedditPostFilterSheet> {
  late DateTime? _date;
  late String? _subreddit;
  late _RedditPostSort _sort;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _subreddit = widget.initialSubreddit;
    _sort = widget.initialSort;
  }

  void _reset() {
    setState(() {
      _date = null;
      _subreddit = null;
      _sort = _RedditPostSort.latest;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _RedditPostFilterDraft(date: _date, subreddit: _subreddit, sort: _sort),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  title: '날짜',
                  child: _DateFilterField(
                    dates: widget.dates,
                    selectedDate: _date,
                    onChanged: (date) => setState(() => _date = date),
                  ),
                ),
                _FilterSheetSection(
                  title: '서브레딧',
                  child: _FilterOptionWrap<String?>(
                    values: [null, ...widget.subreddits],
                    selected: _subreddit,
                    labelBuilder: (subreddit) => subreddit ?? '전체',
                    onChanged: (subreddit) {
                      setState(() {
                        _subreddit = subreddit;
                      });
                    },
                  ),
                ),
                _FilterSheetSection(
                  title: '정렬',
                  child: _FilterOptionWrap<_RedditPostSort>(
                    values: _RedditPostSort.values,
                    selected: _sort,
                    labelBuilder: (sort) => sort.label,
                    onChanged: (sort) => setState(() => _sort = sort),
                  ),
                ),
                SizedBox(height: context.spacing.xl + bottomInset),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              context.spacing.sm,
              context.spacing.md,
              context.spacing.md + bottomInset,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _apply, child: const Text('적용')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.dates,
    required this.selectedDate,
    required this.onChanged,
  });

  final List<DateTime> dates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedDate == null
        ? '전체 날짜'
        : _dateKey(selectedDate);
    return AppInnerPanel(
      dense: true,
      tone: AppInnerPanelTone.base,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.radius.rMd),
        onTap: () => _openDatePicker(context),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: VisualSpec.icon.sizeDefault,
                color: context.colors.neutralTextMuted,
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Text(
                  selectedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.body.copyWith(
                    color: context.colors.neutralText,
                  ),
                ),
              ),
              if (selectedDate != null) ...[
                IconButton(
                  tooltip: '날짜 초기화',
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.close_rounded),
                ),
                SizedBox(width: context.spacing.xs),
              ],
              Icon(
                Icons.expand_more_rounded,
                size: VisualSpec.icon.sizeDefault,
                color: context.colors.neutralTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final choice = await showModalBottomSheet<_DateFilterChoice>(
      context: context,
      backgroundColor: VisualSpec.surface.transparent,
      builder: (context) =>
          _DateFilterSheet(dates: dates, selectedDate: selectedDate),
    );
    if (choice == null) return;
    onChanged(choice.date);
  }
}

class _DateFilterChoice {
  const _DateFilterChoice(this.date);

  final DateTime? date;
}

class _DateFilterSheet extends StatelessWidget {
  const _DateFilterSheet({required this.dates, required this.selectedDate});

  final List<DateTime> dates;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return AppSheetSurface(
      heightFactor: 0.58,
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
                    Text('날짜 선택', style: context.typography.sectionTitle),
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
                context.spacing.md + bottomInset,
              ),
              children: [
                _DateFilterRow(
                  label: '전체 날짜',
                  selected: selectedDate == null,
                  onTap: () =>
                      Navigator.of(context).pop(const _DateFilterChoice(null)),
                ),
                for (final date in dates)
                  _DateFilterRow(
                    label: _dateKey(date),
                    selected: _sameDate(selectedDate, date),
                    onTap: () =>
                        Navigator.of(context).pop(_DateFilterChoice(date)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.radius.rMd),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.xs,
          vertical: context.spacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.typography.body.copyWith(
                  color: selected
                      ? context.colors.primary
                      : context.colors.neutralText,
                  fontWeight: selected
                      ? AppFontWeights.semibold
                      : AppFontWeights.regular,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                size: VisualSpec.icon.sizeDefault,
                color: context.colors.primary,
              ),
          ],
        ),
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
          Text(
            title,
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
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
          Builder(
            builder: (context) {
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
                avatar: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: pillStyle.foreground,
                      )
                    : null,
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
      ],
    );
  }
}

class _RedditPostSummaryCard extends StatelessWidget {
  const _RedditPostSummaryCard({required this.item});

  final RedditPostSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      variant: SectionCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              MoneyfyBadge(
                label: item.subreddit,
                size: MoneyfyPillSize.sm,
                backgroundColor: context.colors.neutralSurfaceRaised,
                textColor: context.colors.neutralText,
              ),
              if (item.categoryLabel.isNotEmpty)
                MoneyfyBadge(
                  label: item.categoryLabel,
                  size: MoneyfyPillSize.sm,
                  variant: MoneyfyPillVariant.outline,
                  backgroundColor: context.colors.neutralSurfaceBase,
                  textColor: context.colors.neutralTextMuted,
                ),
              if (item.importanceLabel.isNotEmpty)
                MoneyfyBadge(
                  label:
                      '${item.importanceLabel} ${item.importanceScore.toString()}',
                  size: MoneyfyPillSize.sm,
                  backgroundColor: _importanceBackground(context, item),
                  textColor: _importanceText(context, item),
                ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          _PostTitleLink(item: item),
          SizedBox(height: context.spacing.xs),
          _PostMetricStrip(item: item),
          if (item.tickers.isNotEmpty) ...[
            SizedBox(height: context.spacing.sm),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                for (final ticker in item.tickers)
                  MoneyfyBadge(
                    label: ticker,
                    size: MoneyfyPillSize.sm,
                    variant: MoneyfyPillVariant.outline,
                    backgroundColor: context.colors.neutralSurfaceBase,
                    textColor: context.colors.primary,
                  ),
              ],
            ),
          ],
          if (item.hasInsight) ...[
            SizedBox(height: context.spacing.md),
            _InsightBlock(body: item.insightKo),
          ],
          if (item.hasPostSummary) ...[
            SizedBox(height: context.spacing.md),
            _SummaryBlock(title: '게시글 요약', body: item.postSummaryKo),
          ],
          if (item.hasCommentsSummary) ...[
            SizedBox(height: context.spacing.md),
            _SummaryBlock(title: '댓글 요약', body: item.commentsSummaryKo),
          ],
          if (item.importanceReasonsKo.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _SummaryBlock(title: '중요도 근거', body: item.importanceReasonsKo),
          ],
        ],
      ),
    );
  }
}

class _PostTitleLink extends StatelessWidget {
  const _PostTitleLink({required this.item});

  final RedditPostSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.radius.rSm),
      onTap: () => _openPostUrl(context, item.url),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.xs / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.displayTitle,
                style: context.typography.cardTitle.copyWith(
                  color: context.colors.neutralText,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openPostUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    AppSnackBar.showError(context, '링크를 열 수 없어요.', hasFloatingNavInset: true);
    return;
  }
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppSnackBar.showError(context, '링크를 열 수 없어요.', hasFloatingNavInset: true);
  }
}

class _PostMetricStrip extends StatelessWidget {
  const _PostMetricStrip({required this.item});

  final RedditPostSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.xs,
      runSpacing: context.spacing.xs,
      children: [
        if (_summaryDateTime(item) != null)
          _PostMetricPill(
            icon: Icons.calendar_month_rounded,
            label: _formatDateTime(_summaryDateTime(item)!),
          ),
        _PostMetricPill(
          icon: Icons.arrow_upward_rounded,
          label: '점수 ${item.score.toString()}',
        ),
        _PostMetricPill(
          icon: Icons.chat_bubble_outline_rounded,
          label: '댓글 ${item.commentCount.toString()}',
        ),
        if (item.qualityLabel.isNotEmpty)
          _PostMetricPill(
            icon: Icons.verified_rounded,
            label: item.qualityLabel,
          ),
      ],
    );
  }
}

class _PostMetricPill extends StatelessWidget {
  const _PostMetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pillStyle = MoneyfyPillStyle.resolve(
      context,
      size: MoneyfyPillSize.sm,
      tone: MoneyfyPillTone.neutral,
      variant: MoneyfyPillVariant.outline,
    );

    return Container(
      constraints: BoxConstraints(minHeight: pillStyle.height),
      padding: pillStyle.padding,
      decoration: BoxDecoration(
        color: pillStyle.background,
        borderRadius: BorderRadius.circular(pillStyle.radius),
        border: Border.all(
          color: pillStyle.border,
          width: pillStyle.borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: VisualSpec.icon.chipIcon,
            color: pillStyle.foreground,
          ),
          SizedBox(width: context.spacing.xs / 2),
          Text(
            label,
            style: pillStyle.textStyle.copyWith(
              color: pillStyle.foreground,
              fontWeight: AppFontWeights.regular,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      tone: AppInnerPanelTone.base,
      padding: EdgeInsets.all(context.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.typography.meta.copyWith(
              color: context.colors.neutralTextMuted,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            body,
            style: context.typography.body.copyWith(
              color: context.colors.neutralText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return AppInnerPanel(
      tone: AppInnerPanelTone.base,
      padding: EdgeInsets.all(context.spacing.sm),
      child: Text(
        body,
        style: context.typography.body.copyWith(
          color: context.colors.primary,
          fontWeight: AppFontWeights.semibold,
          height: 1.5,
        ),
      ),
    );
  }
}

class _RedditPostLoadingState extends StatelessWidget {
  const _RedditPostLoadingState();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      variant: SectionCardVariant.base,
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: context.spacing.sm),
          Text(
            'Reddit 요약을 불러오는 중',
            style: context.typography.body.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedditPostEmptyState extends StatelessWidget {
  const _RedditPostEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      variant: SectionCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.typography.cardTitle),
          SizedBox(height: context.spacing.xs),
          Text(
            message,
            style: context.typography.body.copyWith(
              color: context.colors.neutralTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}.${two(value.month)}.${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

String _dateKey(DateTime? value) {
  if (value == null) return '';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}.${two(value.month)}.${two(value.day)}';
}

int _compareDateDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

DateTime? _summaryDateTime(RedditPostSummaryItem item) {
  return item.postedAt ??
      item.syncedAt ??
      item.insightGeneratedAt ??
      item.judgedAt ??
      item.analyzedAt;
}

bool _sameDate(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Color _importanceBackground(BuildContext context, RedditPostSummaryItem item) {
  if (item.importanceScore >= 80) return context.colors.negativeContainer;
  if (item.importanceScore >= 60) return context.colors.warningContainer;
  return context.colors.neutralSurfaceRaised;
}

Color _importanceText(BuildContext context, RedditPostSummaryItem item) {
  if (item.importanceScore >= 80) return context.colors.negativeOn;
  if (item.importanceScore >= 60) return context.colors.warningOn;
  return context.colors.neutralText;
}
