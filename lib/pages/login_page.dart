import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/buttons/app_buttons.dart';
import '../components/feedback/app_snackbar.dart';
import '../components/section_card.dart';
import '../components/states/inline_error.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../services/auth_service.dart';
import '../services/company_news_summary_service.dart';
import '../services/market_data_service.dart';
import '../services/market_news_summary_service.dart';
import '../services/sync_service.dart';
import 'signup_page.dart';
import 'sync_overlay.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '이메일과 비밀번호를 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _syncErrorMessage = null;
    });

    try {
      await AuthService.signIn(email: email, password: password);
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
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      AppSnackBar.showSuccess(context, '로그인됐어요.');
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
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
        _syncErrorMessage = '코어 데이터 단계에서 실패했어요.';
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
        _syncErrorMessage = '뉴스 데이터 단계에서 실패했어요.';
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
        _syncErrorMessage = '스냅샷 단계에서 실패했어요.';
      });
      return false;
    }

    setState(() {
      _snapshotState = SyncStepState.done;
    });
    return true;
  }

  List<SyncStepItem> _buildSteps() {
    return [
      SyncStepItem(title: '코어 데이터', state: _coreState),
      SyncStepItem(title: '뉴스', state: _newsState),
      SyncStepItem(title: '스냅샷', state: _snapshotState),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final horizontal = context.contentHorizontalPadding;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('로그인')),
      body: Stack(
        children: [
          SafeArea(
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
          if (_showSyncOverlay)
            Positioned.fill(
              child: SyncOverlay(
                steps: _buildSteps(),
                isRunning: _isSubmitting,
                errorMessage: _syncErrorMessage,
                onRetry: _runPostLoginSync,
                onClose: () {
                  setState(() {
                    _showSyncOverlay = false;
                  });
                },
                onBackground: () {
                  setState(() {
                    _showSyncOverlay = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
