import 'package:moneyfy/utils/monthly_pivot.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:moneyfy/components/buttons/app_buttons.dart';
import 'package:moneyfy/components/feedback/app_snackbar.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/icons/app_icon_button.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/empty_state.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/components/states/retry_row.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/portfolio/screens/snapshot_detail_page.dart';

class SnapshotCalendarSection extends StatefulWidget {
  const SnapshotCalendarSection({
    super.key,
    required this.snapshots,
    required this.transactionDates,
    this.sectionError,
    required this.onRetry,
  });
  final List<DailyPortfolioSnapshot> snapshots;
  final Set<String> transactionDates;
  final Object? sectionError;
  final Future<void> Function() onRetry;
  @override
  State<SnapshotCalendarSection> createState() =>
      _SnapshotCalendarSectionState();
}

class _SnapshotCalendarSectionState extends State<SnapshotCalendarSection> {
  DateTime? _focusedMonth;
  String? _selectedDateKey;

  void onMonthChanged(DateTime date) =>
      setState(() => _focusedMonth = DateTime(date.year, date.month));

  @override
  Widget build(BuildContext context) {
    final snapshots = widget.snapshots;
    final transactionDates = widget.transactionDates;
    final onRetry = widget.onRetry;
    if (widget.sectionError != null) {
      return SectionCard(
        title: '스냅샷 캘린더',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InlineError(
              message: '캘린더 데이터를 불러오지 못했어요.',
              detail: '다시 시도해 주세요.',
            ),
            SizedBox(height: context.spacing.sm),
            RetryRow(message: '다시 시도해 주세요.', onRetry: onRetry),
          ],
        ),
      );
    }

    final snapshotByDate = <String, DailyPortfolioSnapshot>{};
    for (final snapshot in snapshots) {
      final normalized = _normalizeDateKey(snapshot.snapshotDate);
      if (normalized == null) continue;
      snapshotByDate[normalized] = snapshot;
    }
    final normalizedTransactionDates = transactionDates
        .map(_normalizeDateKey)
        .whereType<String>()
        .toSet();

    if (snapshots.isEmpty) {
      final isLoggedIn = AuthService.currentUser != null;
      if (!isLoggedIn) {
        return buildCenteredStatisticsEmptyCard(
          context,
          title: '아직 스냅샷이 없어요',
          description: '스냅샷이 쌓이면 월말 변화와 비교를 볼 수 있어요.',
          actionLabel: CopySpec.refresh,
          onAction: onRetry,
        );
      }
      return EmptyStateCard(
        title: '아직 스냅샷이 없어요',
        description: '스냅샷이 쌓이면 월말 변화와 비교를 볼 수 있어요.',
        actionLabel: CopySpec.refresh,
        onAction: onRetry,
      );
    }

    final latest =
        DateTime.tryParse(snapshots.last.snapshotDate) ?? DateTime.now();
    final focusedMonth = _focusedMonth ?? DateTime(latest.year, latest.month);
    final pivotDate = MonthlyPivot.current.inMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    return SectionCard(
      title: '스냅샷 캘린더',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('날짜별 저장 기록과 거래 흔적을 확인해요.', style: context.typography.meta),
          SizedBox(height: context.spacing.sm),
          Row(
            children: [
              _MonthControlButton(
                icon: AppIconName.chevronLeft,
                tooltip: '이전 달',
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${focusedMonth.year}년 ${focusedMonth.month}월',
                    style: context.typography.cardTitle,
                  ),
                ),
              ),
              _MonthControlButton(
                icon: AppIconName.chevronRight,
                tooltip: '다음 달',
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(label, style: context.typography.caption),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: context.spacing.xs),
          TableCalendar<void>(
            firstDay: DateTime.utc(1),
            lastDay: DateTime.utc(9999, 12, 31),
            focusedDay: focusedMonth,
            headerVisible: false,
            daysOfWeekVisible: false,
            availableGestures: AvailableGestures.horizontalSwipe,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            onPageChanged: onMonthChanged,
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, date, focused) {
                if (date.month != focused.month) return const SizedBox.shrink();
                final day = date.day;
                final dateKey = _dateKey(date);
                final snapshot = snapshotByDate[dateKey];
                final hasSnapshot = snapshot != null;
                final hasTransaction = normalizedTransactionDates.contains(
                  dateKey,
                );
                final isPivotDay = MonthlyPivot.current.matches(date);
                final isSelected = _selectedDateKey == dateKey;
                final isToday = _dateKey(DateTime.now()) == dateKey;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 4,
                  ),
                  child: _CalendarDayCell(
                    day: day,
                    hasSnapshot: hasSnapshot,
                    hasTransaction: hasTransaction,
                    isPivotDay: isPivotDay,
                    isSelected: isSelected,
                    isToday: isToday,
                    onTap: () {
                      setState(() => _selectedDateKey = dateKey);
                      if (!hasSnapshot) {
                        AppSnackBar.showInfo(
                          context,
                          '선택한 날짜에 스냅샷이 없어요.',
                          hasFloatingNavInset: true,
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              SnapshotDetailPage(snapshot: snapshot),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: context.spacing.md),
          Center(child: _CalendarLegendRow(pivotDate.day)),
        ],
      ),
    );
  }
}

class _MonthControlButton extends StatelessWidget {
  const _MonthControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final AppIconName icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(tooltip: tooltip, onPressed: onPressed, icon: icon);
  }
}

class _CalendarLegendRow extends StatelessWidget {
  const _CalendarLegendRow(this.pivotDay);
  final int pivotDay;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: context.spacing.md,
      runSpacing: context.spacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(context.radius.rSm / 2),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.28),
                ),
              ),
            ),
            SizedBox(width: context.spacing.xs / 2),
            Text('스냅샷 있음', style: context.typography.caption),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: context.spacing.xs / 2),
            Text('거래 있음', style: context.typography.caption),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$pivotDay',
              style: context.typography.caption.copyWith(
                color: VisualSpec.brand.brandRed,
                fontWeight: AppFontWeights.semibold,
              ),
            ),
            SizedBox(width: context.spacing.xs / 2),
            Text('월 분기점($pivotDay일)', style: context.typography.caption),
          ],
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.hasSnapshot,
    required this.hasTransaction,
    required this.isPivotDay,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool hasSnapshot;
  final bool hasTransaction;
  final bool isPivotDay;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background = isSelected
        ? context.surfaces.surfaceRaised
        : context.surfaces.surfaceBase;
    final dayColor = isPivotDay
        ? VisualSpec.brand.brandRed
        : hasSnapshot
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final borderColor = isPivotDay
        ? VisualSpec.brand.brandRed.withValues(alpha: 0.34)
        : hasSnapshot
        ? colorScheme.primary.withValues(alpha: 0.28)
        : colorScheme.outlineVariant.withValues(alpha: 0.85);

    return InkWell(
      borderRadius: BorderRadius.circular(context.radius.rSm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion.fast,
        curve: Curves.easeOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(context.radius.rSm),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: context.typography.meta.copyWith(
                color: dayColor,
                fontWeight: isPivotDay
                    ? AppFontWeights.bold
                    : AppFontWeights.semibold,
              ),
            ),
            SizedBox(height: context.spacing.xs / 2),
            if (hasTransaction)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 6, height: 6),
          ],
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String? _normalizeDateKey(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return _dateKey(DateTime(parsed.year, parsed.month, parsed.day));
  }
  if (value.length >= 10) {
    final head = value.substring(0, 10);
    final headParsed = DateTime.tryParse(head);
    if (headParsed != null) {
      return _dateKey(
        DateTime(headParsed.year, headParsed.month, headParsed.day),
      );
    }
  }
  return null;
}

Widget buildCenteredStatisticsEmptyCard(
  BuildContext context, {
  required String title,
  required String description,
  String? actionLabel,
  Future<void> Function()? onAction,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = context.cardWidths.apply(
        constraints.maxWidth,
        level: 1,
      );
      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: cardWidth,
          child: SectionCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 188),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppIcon(
                      AppIconName.insights,
                      size: VisualSpec.icon.iconSizeLarge,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.66),
                    ),
                    SizedBox(height: context.spacing.sm),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.typography.cardTitle.copyWith(
                        fontWeight: AppFontWeights.semibold,
                      ),
                    ),
                    SizedBox(height: context.spacing.xs),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: context.typography.meta,
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      SizedBox(height: context.spacing.md),
                      AppPrimaryButton(
                        label: actionLabel,
                        onPressed: () => onAction(),
                        expand: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
