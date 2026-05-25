import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/buttons/app_buttons.dart';
import '../components/icons/app_icon.dart';
import '../components/states/inline_error.dart';
import '../components/states/retry_row.dart';
import '../design_system/spec.dart';
import '../design_system/context_extensions.dart';

enum SyncStepState { pending, active, done, failed }

class SyncStepItem {
  const SyncStepItem({required this.title, required this.state, this.meta});

  final String title;
  final SyncStepState state;
  final String? meta;
}

class SyncOverlay extends StatelessWidget {
  const SyncOverlay({
    super.key,
    required this.steps,
    required this.isRunning,
    this.errorMessage,
    this.errorDetail,
    this.retryMessage,
    this.closeLabel,
    this.onRetry,
    this.onClose,
    this.onBackground,
  });

  final List<SyncStepItem> steps;
  final bool isRunning;
  final String? errorMessage;
  final String? errorDetail;
  final String? retryMessage;
  final String? closeLabel;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final VoidCallback? onBackground;

  static const cardKey = ValueKey('sync-overlay-card');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final doneCount = steps
        .where((step) => step.state == SyncStepState.done)
        .length;
    final activeCount = steps
        .where((step) => step.state == SyncStepState.active)
        .length;
    final progress = steps.isEmpty
        ? 0.0
        : (doneCount + activeCount * 0.35) / steps.length;
    final hasFailed = steps.any((step) => step.state == SyncStepState.failed);
    final isSuccess = !isRunning && !hasFailed && doneCount == steps.length;
    final isPartialFailure = !isRunning && hasFailed && doneCount > 0;
    final title = isRunning
        ? '데이터를 맞추는 중'
        : isSuccess
        ? '동기화 완료'
        : '동기화 확인';
    final description = isRunning
        ? '로그인된 계정의 최신 데이터를 가져오고 있어요.'
        : isSuccess
        ? '이제 최신 자산 정보를 볼 수 있어요.'
        : isPartialFailure
        ? '일부 단계에서 오류가 발생했어요.'
        : '코어 → 뉴스 → 스냅샷 순서로 진행돼요.';

    return Material(
      color: colorScheme.scrim.withValues(alpha: 0.58),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final verticalPadding = context.spacing.lg;
            final minHeight = math.max(
              0.0,
              constraints.maxHeight - verticalPadding * 2,
            );
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.md,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: DecoratedBox(
                      key: cardKey,
                      decoration: BoxDecoration(
                        color: context.surfaces.surfaceOverlay,
                        borderRadius: BorderRadius.circular(context.radius.rLg),
                        border: Border.all(color: colorScheme.outlineVariant),
                        boxShadow: context.shadows.level3,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(context.spacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _SyncStatusMark(
                                  isRunning: isRunning,
                                  hasFailed: hasFailed,
                                  isSuccess: isSuccess,
                                ),
                                SizedBox(width: context.spacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: context.typography.cardTitle,
                                      ),
                                      SizedBox(height: context.spacing.xs / 2),
                                      Text(
                                        description,
                                        style: context.typography.meta,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.spacing.md),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                context.radius.rPill,
                              ),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: progress.clamp(0, 1),
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            SizedBox(height: context.spacing.md),
                            for (var i = 0; i < steps.length; i++) ...[
                              _SyncStepRow(item: steps[i]),
                              if (i != steps.length - 1)
                                SizedBox(height: context.spacing.xs),
                            ],
                            if ((errorMessage ?? '').trim().isNotEmpty) ...[
                              SizedBox(height: context.spacing.md),
                              InlineError(
                                message: errorMessage!,
                                detail: (errorDetail ?? '').trim().isNotEmpty
                                    ? errorDetail
                                    : '재시도하면 실패한 단계부터 다시 진행할 수 있어요.',
                              ),
                              if (onRetry != null) ...[
                                SizedBox(height: context.spacing.xs),
                                RetryRow(
                                  message:
                                      (retryMessage ?? '').trim().isNotEmpty
                                      ? retryMessage!
                                      : '실패한 단계를 다시 시도할 수 있어요.',
                                  onRetry: onRetry!,
                                ),
                              ],
                            ],
                            SizedBox(height: context.spacing.md),
                            Row(
                              children: [
                                if (isRunning)
                                  Expanded(
                                    child: AppGhostButton(
                                      label: '백그라운드로',
                                      onPressed: onBackground ?? onClose,
                                      expand: true,
                                    ),
                                  ),
                                if (hasFailed) ...[
                                  Expanded(
                                    child: AppGhostButton(
                                      label: closeLabel ?? '나중에',
                                      onPressed: onClose,
                                      expand: true,
                                    ),
                                  ),
                                  SizedBox(width: context.spacing.sm),
                                  Expanded(
                                    child: AppPrimaryButton(
                                      label: CopySpec.retry,
                                      onPressed: onRetry,
                                    ),
                                  ),
                                ],
                                if (isSuccess)
                                  Expanded(
                                    child: AppPrimaryButton(
                                      label: '확인',
                                      onPressed: onClose,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SyncStatusMark extends StatelessWidget {
  const _SyncStatusMark({
    required this.isRunning,
    required this.hasFailed,
    required this.isSuccess,
  });

  final bool isRunning;
  final bool hasFailed;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = hasFailed
        ? colorScheme.error
        : isSuccess
        ? colorScheme.secondary
        : colorScheme.primary;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: isRunning
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
            )
          : AppIcon(
              hasFailed
                  ? AppIconName.error
                  : isSuccess
                  ? AppIconName.checkCircle
                  : AppIconName.sync,
              color: color,
            ),
    );
  }
}

class _SyncStepRow extends StatelessWidget {
  const _SyncStepRow({required this.item});

  final SyncStepItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (item.state) {
      SyncStepState.pending => AppIcon(
        AppIconName.circle,
        color: colorScheme.onSurfaceVariant,
      ),
      SyncStepState.active => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: colorScheme.primary,
        ),
      ),
      SyncStepState.done => AppIcon(
        AppIconName.checkCircle,
        color: colorScheme.secondary,
      ),
      SyncStepState.failed => AppIcon(
        AppIconName.error,
        color: colorScheme.error,
      ),
    };

    final statusText = switch (item.state) {
      SyncStepState.pending => '대기',
      SyncStepState.active => '진행 중...',
      SyncStepState.done => '완료',
      SyncStepState.failed => '실패',
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          icon,
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.title, style: context.typography.cardTitle),
                SizedBox(height: context.spacing.xs / 2),
                Text(
                  item.meta?.trim().isNotEmpty == true
                      ? item.meta!
                      : statusText,
                  style: context.typography.caption.copyWith(
                    color: item.state == SyncStepState.failed
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
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
