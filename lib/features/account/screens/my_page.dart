import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moneyfy/components/buttons/app_buttons.dart';
import 'package:moneyfy/components/cards/status_card.dart';
import 'package:moneyfy/components/feedback/app_snackbar.dart';
import 'package:moneyfy/components/icons/app_avatar.dart';
import 'package:moneyfy/components/icons/app_icon.dart';
import 'package:moneyfy/components/rows/settings_action_row.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/separators/app_divider.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/navigation/moneyfy_navigation.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/auth/services/app_data_lifecycle_service.dart';
import 'package:moneyfy/features/analysis/services/gpt_db_summary_builder.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
import 'package:moneyfy/ui_scaffold/app_page_scaffold.dart';
import 'package:moneyfy/utils/input_validators.dart';

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
  bool _isPullingCoreData = false;
  bool _isCopyingDbSummary = false;
  bool _isSigningOut = false;
  bool _pullFailed = false;
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

  Future<void> _copyReviewBackup(String? owner) async {
    final backup = await AppDatabase.instance.exportReviewBackup(owner);
    if (!mounted || (owner != null && AuthService.currentUser?.id != owner)) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: backup));
    if (mounted) {
      AppSnackBar.showSuccess(context, '일지 백업을 복사했어요. 개인 파일에 저장해 주세요.');
    }
  }

  Future<void> _confirmAndHandleCorePull() async {
    final owner = await AppDatabase.instance.localDataOwner();
    final pending = await AppDatabase.instance.hasPendingSyncChanges();
    final hasLocalData = await AppDatabase.instance.hasLocalCoreData();
    final userId = AuthService.currentUser?.id;
    if (!mounted || userId == null) return;
    if (pending && owner != null && owner != userId) {
      AppSnackBar.showError(
        context,
        '이전 계정의 미동기화 데이터가 있습니다. 해당 계정으로 로그인해 먼저 동기화해 주세요.',
      );
      return;
    }
    if (pending && owner == null) {
      final adopt = await _confirmSyncAction(
        title: '로컬 데이터를 이 계정에 연결할까요?',
        content: '소유 계정을 확인할 수 없는 로컬 거래가 있습니다. 현재 로그인된 계정에 연결해 서버로 동기화합니다.',
        confirmLabel: '연결하고 동기화',
      );
      if (!adopt || !mounted) return;
      await AppDatabase.instance.assignLocalDataOwner(userId);
      await _handleCorePull();
      return;
    }
    if (owner == null &&
        hasLocalData &&
        (await (AppDatabase.instance.select(
          AppDatabase.instance.dailyInvestmentReviews,
        )..limit(1)).get()).isNotEmpty) {
      if (!mounted) return;
      final backup = await _confirmSyncAction(
        title: '기존 투자 일지를 보관할까요?',
        content:
            '소유자를 확인할 수 없는 일지를 먼저 복사해 개인 파일에 저장해 주세요. 이후 코어 데이터를 가져올 수 있어요.',
        confirmLabel: '백업 복사',
      );
      if (!backup || !mounted) return;
      await _copyReviewBackup(null);
      if (!mounted) return;
    }
    final approved = await _confirmSyncAction(
      title: '코어 데이터를 가져올까요?',
      content: hasLocalData && owner != userId
          ? '현재 로컬 데이터의 계정이 다르거나 확인되지 않습니다. 계속하면 이 기기의 기존 자산, 스냅샷, 투자 일지가 현재 계정의 데이터로 교체됩니다. 기존 계정의 투자 일지는 기기에 보관되며 해당 계정으로 돌아오면 복원됩니다.'
          : '이 기기에 아직 보내지 않은 변경사항이 있으면 먼저 서버에 저장한 뒤, 현재 계정의 자산과 거래 내역을 가져옵니다.',
      confirmLabel: '가져오기',
    );
    if (!approved || !mounted || _isPullingCoreData) return;
    await _handleCorePull(allowAccountSwitch: owner != userId);
  }

  Future<void> _handleCorePull({bool allowAccountSwitch = false}) async {
    setState(() {
      _isPullingCoreData = true;
      _pullFailed = false;
      _syncMessage = '서버 코어 데이터를 가져오는 중이에요.';
    });

    final success = await SyncService.instance.pullRemoteCoreData(
      reason: 'my_page_pull_remote_core',
      allowAccountSwitch: allowAccountSwitch,
    );
    final snapshotCount = success && allowAccountSwitch
        ? await SyncService.instance.pullRemoteSnapshots(
            reason: 'my_page_account_switch',
          )
        : 0;
    if (!mounted) return;

    setState(() {
      _isPullingCoreData = false;
      _pullFailed = !success;
      _syncMessage = success
          ? '서버 코어 데이터를 로컬 DB에 적용했어요.'
          : '코어 데이터 가져오기에 실패했어요.';
      if (success) {
        _lastSyncedAt = DateTime.now();
      }
    });

    if (success) {
      AppDataLifecycleService.completeReplacement(
        refreshReason: 'manual_core_pull',
      );
      if (snapshotCount < 0) {
        AppSnackBar.showInfo(
          context,
          '자산은 적용됐지만 과거 스냅샷은 가져오지 못했습니다. 다시 시도해 주세요.',
        );
      } else {
        AppSnackBar.showSuccess(
          context,
          '코어 데이터를 가져와 적용했어요.',
          hasFloatingNavInset: true,
        );
      }
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

  @override
  Widget build(BuildContext context) {
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
          title: '코어 데이터',
          description:
              _syncMessage ?? '서버에 저장된 자산, 보유 종목, 현금 계좌와 거래 내역을 이 기기로 가져와요.',
          iconBackgroundColor: _pullFailed
              ? context.colors.negativeContainer
              : context.colors.primaryContainer,
          iconColor: _pullFailed
              ? context.colors.negativeOn
              : context.colors.primary,
          primaryLabel: _isPullingCoreData ? '가져오는 중…' : '코어 데이터 가져오기',
          onPrimary: _isPullingCoreData ? null : _confirmAndHandleCorePull,
          meta: _syncMetaLine(),
        ),
        SizedBox(height: context.spacing.sectionGap),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Semantics(
            button: true,
            label: '내 계정',
            child: InkWell(
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _AccountDetailsPage(userId: widget.user.id),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(context.cardPadding()),
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
                          Text(
                            resolvedName,
                            style: context.typography.cardTitle,
                          ),
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
                    const AppIcon(AppIconName.chevronRight),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.sectionGap),
        SectionCard(
          title: '계정 및 데이터',
          child: Column(
            children: [
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

  String? _syncMetaLine() {
    final syncedAt = _lastSyncedAt;
    if (syncedAt == null) return null;
    return '마지막 가져오기 ${syncedAt.hour.toString().padLeft(2, '0')}:${syncedAt.minute.toString().padLeft(2, '0')}';
  }
}

class _AccountDetailsPage extends StatefulWidget {
  const _AccountDetailsPage({required this.userId});
  final String userId;

  @override
  State<_AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<_AccountDetailsPage> {
  bool _isUpdatingProfile = false;
  bool _isUpdatingPassword = false;
  Future<void> _showEditNameDialog(String currentName) async {
    if (_isUpdatingProfile) return;
    var name = currentName;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름 수정'),
          content: TextFormField(
            initialValue: currentName,
            onChanged: (value) => name = value,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '이름',
              hintText: '표시할 이름을 입력하세요',
            ),
            onFieldSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            AppGhostButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(),
              label: '취소',
            ),
            AppPrimaryButton(
              expand: false,
              onPressed: () => Navigator.of(context).pop(name),
              label: '저장',
              icon: VisualSpec.icon.check,
            ),
          ],
        );
      },
    );
    if (result == null ||
        !mounted ||
        AuthService.currentUser?.id != widget.userId) {
      return;
    }

    final validation = MoneyfyInputValidators.requiredText(
      result,
      fieldName: '이름',
    );
    if (!validation.isValid) {
      AppSnackBar.showError(
        context,
        validation.message!,
        hasFloatingNavInset: false,
      );
      return;
    }

    final nextName = validation.value!;
    if (nextName == currentName.trim()) {
      AppSnackBar.showInfo(
        context,
        '변경된 이름이 없습니다.',
        hasFloatingNavInset: false,
      );
      return;
    }

    setState(() {
      _isUpdatingProfile = true;
    });
    try {
      await AuthService.updateProfileName(nextName);
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        '이름을 수정했어요.',
        hasFloatingNavInset: false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, error.message, hasFloatingNavInset: false);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        '이름 수정에 실패했어요. 잠시 후 다시 시도해 주세요.',
        hasFloatingNavInset: false,
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
    var password = '';
    var confirmation = '';
    final result = await showDialog<_PasswordChangeInput>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => password = value,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  hintText: '6자 이상 입력하세요',
                ),
              ),
              SizedBox(height: context.spacing.sm),
              TextField(
                onChanged: (value) => confirmation = value,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호 확인',
                  hintText: '한 번 더 입력하세요',
                ),
                onSubmitted: (_) => Navigator.of(context).pop(
                  _PasswordChangeInput(
                    password: password,
                    confirmPassword: confirmation,
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
                  password: password,
                  confirmPassword: confirmation,
                ),
              ),
              label: '변경',
              icon: VisualSpec.icon.check,
            ),
          ],
        );
      },
    );
    if (result == null ||
        !mounted ||
        AuthService.currentUser?.id != widget.userId) {
      return;
    }

    final validation = validatePasswordChangeForTesting(
      result.password,
      result.confirmPassword,
    );
    if (validation != null) {
      AppSnackBar.showError(context, validation, hasFloatingNavInset: false);
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
        hasFloatingNavInset: false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, error.message, hasFloatingNavInset: false);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        '비밀번호 변경에 실패했어요. 다시 로그인한 뒤 시도해 주세요.',
        hasFloatingNavInset: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 계정')),
      body: StreamBuilder<AuthState>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          final user = AuthService.currentUser;
          if (user == null || user.id != widget.userId) {
            return const Center(child: Text('계정 정보를 확인할 수 없어요.'));
          }
          final name = (user.userMetadata?['name'] as String?)?.trim() ?? '';
          return ListView(
            padding: EdgeInsets.all(context.cardPadding()),
            children: [
              SectionCard(
                child: Column(
                  children: [
                    SettingsActionRow(
                      icon: VisualSpec.icon.person,
                      title: _isUpdatingProfile ? '이름 수정 중...' : '이름 수정',
                      subtitle: name.isEmpty ? '사용자' : name,
                      enabled: !_isUpdatingProfile && !_isUpdatingPassword,
                      onTap: () => _showEditNameDialog(name),
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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
