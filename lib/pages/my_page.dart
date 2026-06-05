import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/buttons/app_buttons.dart';
import '../components/cards/status_card.dart';
import '../components/feedback/app_snackbar.dart';
import '../components/icons/app_avatar.dart';
import '../components/icons/app_icon.dart';
import '../components/rows/settings_action_row.dart';
import '../components/section_card.dart';
import '../components/separators/app_divider.dart';
import '../design_system/spec.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../navigation/moneyfy_navigation.dart';
import '../services/auth_service.dart';
import '../services/gpt_db_summary_builder.dart';
import '../services/market_data_service.dart';
import '../services/sync_service.dart';
import '../ui_scaffold/app_page_scaffold.dart';
import '../utils/input_validators.dart';

enum _SyncBannerState { idle, running, success, failed }

class MyPage extends StatelessWidget {
  const MyPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'My',
      hasFloatingNavInset: true,
      scrollController: scrollController,
      body: const _MyPageBody(),
    );
  }
}

class _MyPageBody extends StatelessWidget {
  const _MyPageBody();

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isConfigured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusCard(
            icon: AppIconName.settings,
            title: '동기화 설정이 필요해요',
            description:
                'assets/config.json이 없거나 비어 있어요. 샘플 설정 파일을 복사해 Supabase URL과 Anon Key를 채워 주세요.',
            iconBackgroundColor: context.colors.primaryContainer,
            iconColor: context.colors.primary,
            primaryLabel: '설정하기',
            onPrimary: () {
              AppSnackBar.showInfo(context, '설정 정보를 확인해 주세요.');
            },
            secondaryLabel: '자세히',
            onSecondary: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (context) => Padding(
                  padding: EdgeInsets.all(context.spacing.md),
                  child: Text(
                    '${AuthService.configSetupMessage}\n\n'
                    '설정이 없어도 앱은 시작되지만 로그인과 기기 간 동기화는 비활성화됩니다.',
                    style: context.typography.body,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService.currentUser;
        if (user == null) {
          return const _LoggedOutView();
        }
        return _LoggedInView(user: user);
      },
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) {
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
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaces.surfaceRaised,
                borderRadius: BorderRadius.circular(
                  VisualSpec.surface.radiusCard,
                ),
                boxShadow: context.shadows.level3,
              ),
              padding: EdgeInsets.all(context.cardPadding()),
              child: SectionCard(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 188),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppIcon(
                          AppIconName.person,
                          size: VisualSpec.icon.iconSizeLarge,
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.66),
                        ),
                        SizedBox(height: context.spacing.sm),
                        Text(
                          '로그인이 필요해요',
                          textAlign: TextAlign.center,
                          style: context.typography.cardTitle.copyWith(
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          '로그인하면 기기 간 동기화를 사용할 수 있어요.',
                          textAlign: TextAlign.center,
                          style: context.typography.meta,
                        ),
                        SizedBox(height: context.spacing.md),
                        AppPrimaryButton(
                          label: '로그인',
                          expand: true,
                          onPressed: context.openLogin,
                        ),
                        SizedBox(height: context.spacing.xs),
                        AppGhostButton(
                          label: '회원가입',
                          expand: true,
                          onPressed: context.openSignup,
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
    );
  }
}

class _LoggedInView extends StatefulWidget {
  const _LoggedInView({required this.user});

  final User user;

  @override
  State<_LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<_LoggedInView> {
  bool _isSyncing = false;
  bool _isPullingCoreData = false;
  bool _isCopyingDbSummary = false;
  bool _isUpdatingProfile = false;
  bool _isUpdatingPassword = false;
  bool _isSigningOut = false;
  _SyncBannerState _syncBannerState = _SyncBannerState.idle;
  String? _syncMessage;
  DateTime? _lastSyncedAt;

  Future<bool> _confirmSyncAction({
    required String title,
    required String content,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            AppGhostButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(false),
              label: '취소',
            ),
            if (isDestructive)
              AppDestructiveButton(
                expand: false,
                onPressed: () => Navigator.of(context).pop(true),
                label: confirmLabel,
              )
            else
              AppPrimaryButton(
                expand: false,
                onPressed: () => Navigator.of(context).pop(true),
                label: confirmLabel,
              ),
          ],
        );
      },
    );
    return approved == true;
  }

  Future<void> _confirmAndHandleSync() async {
    final approved = await _confirmSyncAction(
      title: '지금 동기화할까요?',
      content: '로컬 변경사항을 서버와 동기화합니다. 원치 않으면 취소해 주세요.',
      confirmLabel: '동기화 시작',
    );
    if (!approved || !mounted || _isSyncing || _isPullingCoreData) return;
    await _handleSync();
  }

  Future<void> _confirmAndHandleCorePull() async {
    final approved = await _confirmSyncAction(
      title: '코어 데이터를 가져올까요?',
      content: '서버의 코어 데이터를 가져와 로컬 DB에 반영합니다.',
      confirmLabel: '가져오기',
    );
    if (!approved || !mounted || _isPullingCoreData || _isSyncing) return;
    await _handleCorePull();
  }

  Future<void> _showEditNameDialog(String currentName) async {
    if (_isUpdatingProfile) return;
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름 수정'),
          content: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '이름',
              hintText: '표시할 이름을 입력하세요',
            ),
            onSubmitted: (_) => Navigator.of(context).pop(controller.text),
          ),
          actions: [
            AppGhostButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(),
              label: '취소',
            ),
            AppPrimaryButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(controller.text),
              label: '저장',
              icon: VisualSpec.icon.check,
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || !mounted) return;

    final validation = MoneyfyInputValidators.requiredText(
      result,
      fieldName: '이름',
    );
    if (!validation.isValid) {
      AppSnackBar.showError(
        context,
        validation.message!,
        hasFloatingNavInset: true,
      );
      return;
    }

    final nextName = validation.value!;
    if (nextName == currentName.trim()) {
      AppSnackBar.showInfo(context, '변경된 이름이 없습니다.', hasFloatingNavInset: true);
      return;
    }

    setState(() {
      _isUpdatingProfile = true;
    });
    try {
      await AuthService.updateProfileName(nextName);
      if (!mounted) return;
      setState(() {});
      AppSnackBar.showSuccess(context, '이름을 수정했어요.', hasFloatingNavInset: true);
    } on AuthException catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, error.message, hasFloatingNavInset: true);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        '이름 수정에 실패했어요. 잠시 후 다시 시도해 주세요.',
        hasFloatingNavInset: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    if (_isUpdatingPassword) return;
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final result = await showDialog<_PasswordChangeInput>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  hintText: '6자 이상 입력하세요',
                ),
              ),
              SizedBox(height: context.spacing.sm),
              TextField(
                controller: confirmController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호 확인',
                  hintText: '한 번 더 입력하세요',
                ),
                onSubmitted: (_) => Navigator.of(context).pop(
                  _PasswordChangeInput(
                    password: passwordController.text,
                    confirmPassword: confirmController.text,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            AppGhostButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(),
              label: '취소',
            ),
            AppPrimaryButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(
                _PasswordChangeInput(
                  password: passwordController.text,
                  confirmPassword: confirmController.text,
                ),
              ),
              label: '변경',
              icon: VisualSpec.icon.check,
            ),
          ],
        );
      },
    );
    passwordController.dispose();
    confirmController.dispose();
    if (result == null || !mounted) return;

    final validation = validatePasswordChangeForTesting(
      result.password,
      result.confirmPassword,
    );
    if (validation != null) {
      AppSnackBar.showError(context, validation, hasFloatingNavInset: true);
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });
    try {
      await AuthService.updatePassword(result.password);
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        '비밀번호를 변경했어요.',
        hasFloatingNavInset: true,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, error.message, hasFloatingNavInset: true);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        '비밀번호 변경에 실패했어요. 다시 로그인한 뒤 시도해 주세요.',
        hasFloatingNavInset: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
      _syncBannerState = _SyncBannerState.running;
      _syncMessage = '동기화를 시작했어요.';
    });

    final success = await SyncService.instance.syncNow(
      reason: 'my_page_manual_sync',
    );
    if (!mounted) return;

    setState(() {
      _isSyncing = false;
      _syncBannerState = success
          ? _SyncBannerState.success
          : _SyncBannerState.failed;
      _syncMessage = success ? '코어 동기화가 완료됐어요.' : '동기화에 실패했어요. 다시 시도해 주세요.';
      if (success) {
        _lastSyncedAt = DateTime.now();
      }
    });

    if (success) {
      AppSnackBar.showSuccess(
        context,
        '동기화가 완료됐어요.',
        hasFloatingNavInset: true,
      );
    } else {
      AppSnackBar.showError(
        context,
        '동기화 실패',
        actionLabel: CopySpec.retry,
        onAction: _confirmAndHandleSync,
        hasFloatingNavInset: true,
      );
    }
  }

  Future<void> _handleCorePull() async {
    setState(() {
      _isPullingCoreData = true;
      _syncBannerState = _SyncBannerState.running;
      _syncMessage = '서버 코어 데이터를 가져오는 중이에요.';
    });

    final success = await SyncService.instance.pullRemoteCoreData(
      reason: 'my_page_pull_remote_core',
    );
    if (!mounted) return;

    setState(() {
      _isPullingCoreData = false;
      _syncBannerState = success
          ? _SyncBannerState.success
          : _SyncBannerState.failed;
      _syncMessage = success
          ? '서버 코어 데이터를 로컬 DB에 적용했어요.'
          : '코어 데이터 가져오기에 실패했어요.';
      if (success) {
        _lastSyncedAt = DateTime.now();
      }
    });

    if (success) {
      AppSnackBar.showSuccess(
        context,
        '코어 데이터를 가져와 적용했어요.',
        hasFloatingNavInset: true,
      );
    } else {
      AppSnackBar.showError(
        context,
        '코어 데이터 가져오기 실패',
        actionLabel: CopySpec.retry,
        onAction: _confirmAndHandleCorePull,
        hasFloatingNavInset: true,
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그아웃할까요?'),
          content: const Text('동기화되지 않은 변경사항이 있을 수 있어요.'),
          actions: [
            AppGhostButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(false),
              label: '취소',
            ),
            AppDestructiveButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(true),
              label: '로그아웃',
              icon: VisualSpec.icon.logout,
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await AuthService.signOut();
      await AppDatabase.instance.clearAllLocalUserData();
      await MarketDataService.instance.clearLocalCache();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, '로그아웃 됐어요.');
    } on AuthException catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _copyInternalDbSummaryForGpt() async {
    if (_isCopyingDbSummary) return;

    setState(() {
      _isCopyingDbSummary = true;
    });

    try {
      final db = AppDatabase.instance;
      final assets = await db.fetchAssets();
      final targetRatios = await db.fetchAssetAllocationTargets();
      final transactionDates = await db.fetchTransactionDates();
      final snapshots = await db.fetchRecentPortfolioSnapshots(maxDates: 24);
      final payload = buildGptDbSummaryPayload(
        assets: assets,
        targetRatios: targetRatios,
        transactionDates: transactionDates,
        snapshots: snapshots,
      );

      await Clipboard.setData(
        ClipboardData(text: buildGptDbSummaryReportText(payload)),
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'GPT용 DB 요약을 클립보드에 복사했어요.',
        hasFloatingNavInset: true,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'DB 요약 복사 실패: $error',
        hasFloatingNavInset: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCopyingDbSummary = false;
        });
      }
    }
  }

  Widget _inlineProgressIndicator(BuildContext context) {
    return SizedBox(
      width: VisualSpec.icon.progressIndicatorSize,
      height: VisualSpec.icon.progressIndicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: VisualSpec.icon.progressIndicatorStroke,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSyncError = _syncBannerState == _SyncBannerState.failed;
    final metadata = widget.user.userMetadata ?? const <String, dynamic>{};
    final displayName = (metadata['name'] as String?)?.trim();
    final resolvedName = (displayName?.isNotEmpty == true)
        ? displayName!
        : '사용자';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusCard(
          icon: AppIconName.sync,
          title: '동기화 상태',
          description: _statusDescription(),
          iconBackgroundColor: hasSyncError
              ? context.colors.negativeContainer
              : context.colors.primaryContainer,
          iconColor: hasSyncError
              ? context.colors.negativeOn
              : context.colors.primary,
          primaryLabel: (_isSyncing || _isPullingCoreData) ? '진행 중' : '지금 동기화',
          onPrimary: (_isSyncing || _isPullingCoreData)
              ? null
              : _confirmAndHandleSync,
          meta: _syncMetaLine(),
        ),
        SizedBox(height: context.spacing.sectionGap),
        SectionCard(
          child: Row(
            children: [
              AppAvatar(
                child: Text(
                  resolvedName.substring(0, 1).toUpperCase(),
                  style: context.typography.cardTitle,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resolvedName, style: context.typography.cardTitle),
                    SizedBox(height: context.spacing.xs / 2),
                    Text(
                      widget.user.email ?? '-',
                      style: context.typography.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.sectionGap),
        SectionCard(
          title: '계정 및 동기화',
          child: Column(
            children: [
              SettingsActionRow(
                icon: VisualSpec.icon.person,
                title: _isUpdatingProfile ? '이름 수정 중...' : '이름 수정',
                subtitle: 'My 화면에 표시되는 이름을 변경해요',
                enabled: !_isUpdatingProfile && !_isUpdatingPassword,
                onTap: () => _showEditNameDialog(resolvedName),
                trailing: _isUpdatingProfile
                    ? _inlineProgressIndicator(context)
                    : null,
              ),
              AppDivider(),
              SettingsActionRow(
                icon: VisualSpec.icon.settings,
                title: _isUpdatingPassword ? '비밀번호 변경 중...' : '비밀번호 변경',
                subtitle: '현재 로그인된 계정의 비밀번호를 새 값으로 바꿔요',
                enabled: !_isUpdatingPassword && !_isUpdatingProfile,
                onTap: _showChangePasswordDialog,
                trailing: _isUpdatingPassword
                    ? _inlineProgressIndicator(context)
                    : null,
              ),
              AppDivider(),
              SettingsActionRow(
                icon: VisualSpec.icon.sync,
                title: '지금 동기화',
                subtitle: _isSyncing ? '동기화 진행 중' : '로컬 변경사항을 서버와 동기화',
                enabled: !_isSyncing && !_isPullingCoreData,
                onTap: _confirmAndHandleSync,
                trailing: _isSyncing ? _inlineProgressIndicator(context) : null,
              ),
              AppDivider(),
              SettingsActionRow(
                icon: VisualSpec.icon.currencyExchange,
                title: '코어 데이터 가져오기',
                subtitle: _isPullingCoreData
                    ? '코어 데이터 적용 중'
                    : '서버 코어 데이터를 로컬 DB에 반영해요',
                enabled: !_isPullingCoreData && !_isSyncing,
                onTap: _confirmAndHandleCorePull,
                trailing: _isPullingCoreData
                    ? _inlineProgressIndicator(context)
                    : null,
              ),
              AppDivider(),
              SettingsActionRow(
                icon: VisualSpec.icon.insights,
                title: 'GPT용 DB 요약 복사',
                subtitle: _isCopyingDbSummary
                    ? '클립보드 복사 준비 중'
                    : '포트폴리오 분석에 쓸 요약 데이터를 클립보드에 복사해요',
                enabled: !_isCopyingDbSummary,
                onTap: _copyInternalDbSummaryForGpt,
                trailing: _isCopyingDbSummary
                    ? _inlineProgressIndicator(context)
                    : null,
              ),
              AppDivider(),
              SettingsActionRow(
                icon: VisualSpec.icon.logout,
                title: _isSigningOut ? '로그아웃 중...' : '로그아웃',
                subtitle: '현재 기기에서 로그아웃합니다',
                enabled: !_isSigningOut,
                onTap: _confirmSignOut,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusDescription() {
    return switch (_syncBannerState) {
      _SyncBannerState.idle => '마지막 동기화 상태를 확인하고 필요 시 수동 동기화를 실행하세요.',
      _SyncBannerState.running => '동기화 중…',
      _SyncBannerState.success => '최근 동기화가 성공적으로 완료됐어요.',
      _SyncBannerState.failed => '동기화 실패: 재시도해 주세요.',
    };
  }

  String _syncMetaLine() {
    final syncedAt = _lastSyncedAt;
    final timeText = syncedAt == null
        ? '아직 동기화 이력이 없어요.'
        : '마지막 동기화: ${syncedAt.hour.toString().padLeft(2, '0')}:${syncedAt.minute.toString().padLeft(2, '0')}';
    if ((_syncMessage ?? '').trim().isEmpty) return timeText;
    return '$timeText · $_syncMessage';
  }
}

@visibleForTesting
String? validatePasswordChangeForTesting(
  String password,
  String confirmPassword,
) {
  if (password.trim().isEmpty || confirmPassword.trim().isEmpty) {
    return '새 비밀번호와 확인 값을 모두 입력해 주세요.';
  }
  if (password.length < 6) {
    return '새 비밀번호는 6자 이상이어야 합니다.';
  }
  if (password != confirmPassword) {
    return '새 비밀번호가 일치하지 않습니다.';
  }
  return null;
}

class _PasswordChangeInput {
  const _PasswordChangeInput({
    required this.password,
    required this.confirmPassword,
  });

  final String password;
  final String confirmPassword;
}
