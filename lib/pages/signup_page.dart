import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/buttons/app_buttons.dart';
import '../components/feedback/app_snackbar.dart';
import '../components/section_card.dart';
import '../components/states/inline_error.dart';
import '../design_system/context_extensions.dart';
import '../db/app_database.dart';
import '../services/auth_service.dart';
import '../services/market_data_service.dart';
import '../services/sync_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = '모든 항목을 입력해 주세요.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = '비밀번호가 일치하지 않습니다.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
      );
      if (!mounted) return;

      if (response.session == null) {
        AppSnackBar.showSuccess(context, '회원가입 완료. 이메일 인증 후 로그인해 주세요.');
        Navigator.of(context).pop();
        return;
      }

      await AppDatabase.instance.clearAllLocalUserData();
      await MarketDataService.instance.clearLocalCache();
      if (!mounted) return;
      await SyncService.instance.refreshFromServer(reason: 'signup_refresh');
      if (!mounted) return;
      AppSnackBar.showSuccess(context, '회원가입이 완료됐어요.');
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '회원가입 중 오류가 발생했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final horizontal = context.contentHorizontalPadding;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              SingleChildScrollView(
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
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '이름',
                              hintText: '이름을 입력하세요',
                            ),
                          ),
                          SizedBox(height: context.spacing.sm),
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
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '비밀번호',
                              hintText: '비밀번호를 입력하세요',
                            ),
                          ),
                          SizedBox(height: context.spacing.sm),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                _isSubmitting ? null : _handleSignup(),
                            decoration: const InputDecoration(
                              labelText: '비밀번호 확인',
                              hintText: '비밀번호를 다시 입력하세요',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.spacing.md),
                    AppPrimaryButton(
                      label: '회원가입',
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              _handleSignup();
                            },
                      isLoading: _isSubmitting,
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
