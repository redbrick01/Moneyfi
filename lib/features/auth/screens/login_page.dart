import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moneyfy/components/buttons/app_buttons.dart';
import 'package:moneyfy/components/feedback/app_snackbar.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/auth/services/app_data_lifecycle_service.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:moneyfy/features/analysis/services/company_news_summary_service.dart';
import 'package:moneyfy/features/portfolio/services/market_data_service.dart';
import 'package:moneyfy/features/analysis/services/market_news_summary_service.dart';
import 'package:moneyfy/features/sync/services/sync_service.dart';
import 'package:moneyfy/utils/input_validators.dart';
import 'signup_page.dart';
import 'package:moneyfy/features/sync/screens/sync_overlay.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _showSyncOverlay = false;
  String? _errorMessage;

  SyncStepState _coreState = SyncStepState.pending;
  SyncStepState _newsState = SyncStepState.pending;
  SyncStepState _snapshotState = SyncStepState.pending;
  String? _syncErrorMessage;
  String? _syncErrorDetail;
  String? _syncRetryMessage;
  _LoginSyncFailureStage? _syncFailureStage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailValidation = MoneyfyInputValidators.email(email);
    if (!emailValidation.isValid) {
      setState(() {
        _errorMessage = emailValidation.message;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = '비밀번호를 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _syncErrorMessage = null;
      _syncErrorDetail = null;
      _syncRetryMessage = null;
      _syncFailureStage = null;
    });

    AppDataLifecycleService.beginReplacement(message: '로그인 정보를 불러오고 있어요.');

    try {
      await AuthService.signIn(
        email: emailValidation.value!,
        password: password,
      );
      if (!mounted) return;
      await AppDatabase.instance.clearAllLocalUserData();
      await MarketDataService.instance.clearLocalCache();
      if (!mounted) return;

      setState(() {
        _showSyncOverlay = true;
        _coreState = SyncStepState.active;
        _newsState = SyncStepState.pending;
        _snapshotState = SyncStepState.pending;
      });

      final syncSuccess = await _runPostLoginSync();
      if (!mounted) return;

      if (!syncSuccess) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
      AppDataLifecycleService.completeReplacement(
        refreshReason: 'login_sync_complete',
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      AppSnackBar.showSuccess(context, '로그인됐어요.');
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      AppDataLifecycleService.completeReplacement();
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      AppDataLifecycleService.completeReplacement();
      if (!mounted) return;
      setState(() {
        _errorMessage = '로그인 중 오류가 발생했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (_coreState == SyncStepState.done &&
              _newsState == SyncStepState.done &&
              _snapshotState == SyncStepState.done) {
            _showSyncOverlay = false;
          }
        });
      }
    }
  }

  Future<bool> _runPostLoginSync() async {
    setState(() {
      _syncErrorMessage = null;
      _syncErrorDetail = null;
      _syncRetryMessage = null;
      _syncFailureStage = null;
      _coreState = SyncStepState.active;
      _newsState = SyncStepState.pending;
      _snapshotState = SyncStepState.pending;
    });

    final coreSuccess = await SyncService.instance.pullRemoteCoreData(
      reason: 'login_refresh_core',
    );
    if (!mounted) return false;
    if (!coreSuccess) {
      setState(() {
        _coreState = SyncStepState.failed;
        _applySyncFailureCopy(_LoginSyncFailureStage.core);
      });
      return false;
    }

    setState(() {
      _coreState = SyncStepState.done;
      _newsState = SyncStepState.active;
    });

    bool newsSuccess = true;
    try {
      await Future.wait([
        MarketNewsSummaryService.instance.fetchSummary(),
        CompanyNewsSummaryService.instance.fetchUserSummaries(),
      ]);
    } catch (_) {
      newsSuccess = false;
    }
    if (!mounted) return false;

    if (!newsSuccess) {
      setState(() {
        _newsState = SyncStepState.failed;
        _applySyncFailureCopy(_LoginSyncFailureStage.news);
      });
      return false;
    }

    setState(() {
      _newsState = SyncStepState.done;
      _snapshotState = SyncStepState.active;
    });

    final snapshotCount = await SyncService.instance.pullRemoteSnapshots(
      reason: 'login_refresh_snapshots',
    );
    if (!mounted) return false;
    if (snapshotCount < 0) {
      setState(() {
        _snapshotState = SyncStepState.failed;
        _applySyncFailureCopy(_LoginSyncFailureStage.snapshots);
      });
      return false;
    }

    setState(() {
      _snapshotState = SyncStepState.done;
    });
    return true;
  }

  void _applySyncFailureCopy(_LoginSyncFailureStage stage) {
    final copy = _loginSyncFailureCopy(stage);
    _syncFailureStage = stage;
    _syncErrorMessage = copy.message;
    _syncErrorDetail = copy.detail;
    _syncRetryMessage = copy.retryMessage;
  }

  bool get _canContinueAfterSyncFailure =>
      _syncFailureStage == _LoginSyncFailureStage.news ||
      _syncFailureStage == _LoginSyncFailureStage.snapshots;

  void _closeSyncOverlay() {
    if (_canContinueAfterSyncFailure) {
      AppDataLifecycleService.completeReplacement(
        refreshReason: 'login_sync_partial',
      );
      setState(() {
        _showSyncOverlay = false;
        _isSubmitting = false;
      });
      AppSnackBar.showInfo(context, '앱으로 이동합니다. 실패한 데이터는 My에서 다시 동기화할 수 있어요.');
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _showSyncOverlay = false;
      _isSubmitting = false;
    });
  }

  List<SyncStepItem> _buildSteps() {
    return [
      SyncStepItem(
        title: '코어 데이터',
        state: _coreState,
        meta: _syncStepMeta(_LoginSyncFailureStage.core, _coreState),
      ),
      SyncStepItem(
        title: '뉴스',
        state: _newsState,
        meta: _syncStepMeta(_LoginSyncFailureStage.news, _newsState),
      ),
      SyncStepItem(
        title: '스냅샷',
        state: _snapshotState,
        meta: _syncStepMeta(_LoginSyncFailureStage.snapshots, _snapshotState),
      ),
    ];
  }

  String? _syncStepMeta(_LoginSyncFailureStage stage, SyncStepState state) {
    if (state == SyncStepState.failed) {
      return _loginSyncFailureCopy(stage).stepMeta;
    }
    if (state == SyncStepState.done) {
      return switch (stage) {
        _LoginSyncFailureStage.core => '자산, 보유, 거래 데이터를 적용했어요.',
        _LoginSyncFailureStage.news => '뉴스 캐시를 확인했어요.',
        _LoginSyncFailureStage.snapshots => '스냅샷을 가져왔어요.',
      };
    }
    if (state == SyncStepState.active) {
      return switch (stage) {
        _LoginSyncFailureStage.core => '계정의 핵심 데이터를 서버에서 가져오는 중이에요.',
        _LoginSyncFailureStage.news => '시장/종목 뉴스 요약 캐시를 준비하는 중이에요.',
        _LoginSyncFailureStage.snapshots => '분석 차트에 필요한 스냅샷을 가져오는 중이에요.',
      };
    }
    return null;
  }

  String get _syncOverlayCloseLabel =>
      _canContinueAfterSyncFailure ? '앱으로 이동' : '닫기';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final horizontal = context.contentHorizontalPadding;

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(title: const Text('로그인')),
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  context.spacing.md,
                  horizontal,
                  context.spacing.xl + bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.spacing.sm),
                    SectionCard(
                      child: Column(
                        children: [
                          if ((_errorMessage ?? '').trim().isNotEmpty) ...[
                            InlineError(message: _errorMessage!),
                            SizedBox(height: context.spacing.sm),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: '이메일',
                              hintText: 'name@example.com',
                            ),
                          ),
                          SizedBox(height: context.spacing.sm),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                _isSubmitting ? null : _handleLogin(),
                            decoration: const InputDecoration(
                              labelText: '비밀번호',
                              hintText: '비밀번호를 입력하세요',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.spacing.md),
                    AppPrimaryButton(
                      label: '로그인',
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              _handleLogin();
                            },
                      isLoading: _isSubmitting,
                    ),
                    SizedBox(height: context.spacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SignupPage(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          disabledBackgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          disabledForegroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              context.radius.rMd,
                            ),
                          ),
                        ),
                        child: const Text('회원가입'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showSyncOverlay)
          Positioned.fill(
            child: SyncOverlay(
              steps: _buildSteps(),
              isRunning: _isSubmitting,
              errorMessage: _syncErrorMessage,
              errorDetail: _syncErrorDetail,
              retryMessage: _syncRetryMessage,
              closeLabel: _syncOverlayCloseLabel,
              onRetry: _runPostLoginSync,
              onClose: _closeSyncOverlay,
              onBackground: () {
                setState(() {
                  _showSyncOverlay = false;
                });
              },
            ),
          ),
      ],
    );
  }
}

enum _LoginSyncFailureStage { core, news, snapshots }

@visibleForTesting
LoginSyncFailureCopy loginSyncFailureCopyForTesting(String stage) {
  return _loginSyncFailureCopy(switch (stage) {
    'core' => _LoginSyncFailureStage.core,
    'news' => _LoginSyncFailureStage.news,
    'snapshots' => _LoginSyncFailureStage.snapshots,
    _ => _LoginSyncFailureStage.core,
  });
}

LoginSyncFailureCopy _loginSyncFailureCopy(_LoginSyncFailureStage stage) {
  return switch (stage) {
    _LoginSyncFailureStage.core => const LoginSyncFailureCopy(
      message: '코어 데이터를 가져오지 못했어요.',
      detail:
          '자산, 보유, 거래 내역을 불러와야 앱을 안전하게 시작할 수 있어요. 인터넷 연결과 로그인 상태를 확인한 뒤 다시 시도해 주세요.',
      retryMessage: '연결이 회복됐거나 잠시 기다렸다면 코어 데이터 가져오기를 다시 시도하세요.',
      stepMeta: '앱 시작에 필요한 핵심 데이터가 아직 적용되지 않았어요.',
    ),
    _LoginSyncFailureStage.news => const LoginSyncFailureCopy(
      message: '뉴스 데이터를 준비하지 못했어요.',
      detail:
          '자산과 거래 데이터는 적용됐어요. 뉴스 요약은 일부 비어 있거나 캐시/기본 안내로 표시될 수 있고, 앱 진입 후 My에서 다시 동기화할 수 있어요.',
      retryMessage: '뉴스 요약이 꼭 필요하면 재시도하고, 아니면 앱으로 이동해도 됩니다.',
      stepMeta: '시장/종목 뉴스 요약은 나중에 다시 받을 수 있어요.',
    ),
    _LoginSyncFailureStage.snapshots => const LoginSyncFailureCopy(
      message: '스냅샷 데이터를 가져오지 못했어요.',
      detail:
          '자산과 뉴스 단계는 끝났어요. 분석 차트나 과거 성과 일부가 최신이 아닐 수 있으니 앱 진입 후 My에서 다시 동기화해 주세요.',
      retryMessage: '분석 화면의 최신 스냅샷이 필요하면 재시도하고, 아니면 앱으로 이동해도 됩니다.',
      stepMeta: '분석 차트용 스냅샷은 나중에 다시 받을 수 있어요.',
    ),
  };
}

class LoginSyncFailureCopy {
  const LoginSyncFailureCopy({
    required this.message,
    required this.detail,
    required this.retryMessage,
    required this.stepMeta,
  });

  final String message;
  final String detail;
  final String retryMessage;
  final String stepMeta;
}
