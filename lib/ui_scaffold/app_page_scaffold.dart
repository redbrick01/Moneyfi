import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'app_insets.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.scrollable = true,
    this.enablePullToRefresh = false,
    this.onRefresh,
    this.paddingOverride,
    this.hasFloatingNavInset = true,
    this.useSliver = false,
    this.scrollController,
  }) : isFormPage = false,
       primaryActionLabel = null,
       isPrimaryActionLoading = false,
       onPrimaryActionPressed = null;

  const AppPageScaffold.form({
    super.key,
    required this.title,
    required this.body,
    required this.primaryActionLabel,
    required this.onPrimaryActionPressed,
    this.subtitle,
    this.actions,
    this.paddingOverride,
    this.scrollController,
    this.isPrimaryActionLoading = false,
  }) : isFormPage = true,
       titleWidget = null,
       scrollable = true,
       enablePullToRefresh = false,
       onRefresh = null,
       hasFloatingNavInset = false,
       useSliver = false;

  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final bool scrollable;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;
  final EdgeInsets? paddingOverride;
  final bool hasFloatingNavInset;
  final bool useSliver;
  final ScrollController? scrollController;

  final bool isFormPage;
  final String? primaryActionLabel;
  final bool isPrimaryActionLoading;
  final VoidCallback? onPrimaryActionPressed;

  @override
  Widget build(BuildContext context) {
    if (isFormPage) {
      return _buildFormPage(context);
    }

    final content = _buildScrollableContent(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: content),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    final padding =
        paddingOverride ??
        AppInsets.pagePadding(context, hasFloatingNav: hasFloatingNavInset);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: title,
          titleWidget: titleWidget,
          subtitle: subtitle,
          actions: actions,
        ),
        SizedBox(height: context.spacing.sectionGap),
        body,
      ],
    );

    if (!scrollable) {
      return Padding(padding: padding, child: content);
    }

    final scrollView = useSliver
        ? CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: SliverToBoxAdapter(child: content),
              ),
            ],
          )
        : SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: content,
          );

    if (enablePullToRefresh && onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
    }

    return scrollView;
  }

  Widget _buildFormPage(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomActionHeight = context.spacing.xxxl + context.spacing.xl;

    final contentPadding =
        paddingOverride ??
        AppInsets.pagePadding(
          context,
          hasFloatingNav: false,
          top: context.spacing.md,
          bottomAdditional:
              bottomActionHeight + context.spacing.xl + bottomInset,
        );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: contentPadding,
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.contentHorizontalPadding,
            context.spacing.sm,
            context.contentHorizontalPadding,
            context.spacing.lg + bottomInset,
          ),
          child: FilledButton(
            onPressed: isPrimaryActionLoading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    onPrimaryActionPressed?.call();
                  },
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(bottomActionHeight),
            ),
            child: Text(
              isPrimaryActionLoading
                  ? '${primaryActionLabel ?? '저장'} 중...'
                  : (primaryActionLabel ?? '저장'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.actions,
  });

  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final actionWidgets = actions ?? const <Widget>[];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget ??
                  Text(
                    title,
                    style: context.typography.pageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              if (subtitle != null) ...[
                SizedBox(height: context.spacing.xs),
                Text(
                  subtitle!,
                  style: context.typography.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (actionWidgets.isNotEmpty) SizedBox(width: context.spacing.sm),
        ..._resolveActions(context, actionWidgets),
      ],
    );
  }

  List<Widget> _resolveActions(BuildContext context, List<Widget> actions) {
    if (actions.length <= 2) return actions;

    final overflowActions = actions.skip(2).toList();
    final overflowCallbacks = overflowActions
        .map((action) => action is IconButton ? action.onPressed : null)
        .toList();
    final overflowLabels = overflowActions.asMap().entries.map((entry) {
      final action = entry.value;
      if (action is IconButton && action.tooltip != null) {
        return action.tooltip!;
      }
      return '동작 ${entry.key + 1}';
    }).toList();

    return [
      ...actions.take(2),
      PopupMenuButton<int>(
        tooltip: '더보기',
        icon: const AppIcon(AppIconName.more),
        itemBuilder: (context) => [
          for (var i = 0; i < overflowLabels.length; i++)
            PopupMenuItem<int>(
              value: i,
              child: Text(overflowLabels[i], style: context.typography.meta),
            ),
        ],
        onSelected: (index) => overflowCallbacks[index]?.call(),
      ),
    ];
  }
}
