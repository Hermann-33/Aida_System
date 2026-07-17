import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/member.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_wave_clipper.dart';
import 'widgets/forgot_password_sheet.dart';

/// Wave-header Sign In / Sign Up — coffee-beans + barista heroes, tabbed
/// form sheet. Auth (C2) has no real backend yet — see
/// [MemberRepository.logIn] — so Sign In accepts any filled attempt for demo.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialSignUp = false});

  /// Opens on the Sign Up tab when true (used by the old [SignUpScreen]
  /// route so existing navigation still lands in the right place).
  final bool initialSignUp;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late bool _signIn;
  late final AnimationController _waveController;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _nameController = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureSignUp = true;
  bool _obscureConfirm = true;
  bool _isStudent = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _signIn = !widget.initialSignUp;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: _signIn ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _nameController.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _selectTab(bool signIn) {
    if (_signIn == signIn) return;
    setState(() => _signIn = signIn);
    if (signIn) {
      _waveController.reverse();
    } else {
      _waveController.forward();
    }
  }

  Future<void> _submitLogin() async {
    // No backend exists yet to check a real credential against, so this
    // deliberately does not gate on field validation — anyone reviewing the
    // build should be able to tap Sign In and land in the app.
    setState(() => _submitting = true);

    final repo = ref.read(memberRepositoryProvider);
    final result = await repo.logIn(
      email: _loginEmail.text.trim(),
      password: _loginPassword.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Ok():
        ref.read(authStateProvider.notifier).logIn();
      case Err(:final failure):
        _showError(failure.message);
    }
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter your name';
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != _signUpPassword.text) return 'Passwords don\'t match';
    return null;
  }

  Future<void> _submitSignUp() async {
    if (!(_signUpFormKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final repo = ref.read(memberRepositoryProvider);
    final name = _nameController.text.trim();
    final email = _signUpEmail.text.trim();
    final result = await repo.signUp(
      name: name,
      email: email,
      password: _signUpPassword.text,
      isStudent: _isStudent,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Ok():
        final code =
            'AIDA-${1000 + Random().nextInt(9000)}-${1000 + Random().nextInt(9000)}';
        ref
            .read(memberEditsProvider.notifier)
            .apply(
              Member(
                id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                memberCode: code,
                name: name,
                email: email,
                studentStatus:
                    _isStudent ? StudentStatus.pending : StudentStatus.none,
              ),
            );
        ref.read(authStateProvider.notifier).logIn();
      case Err(:final failure):
        _showError(failure.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AidaColors.error,
          content: Text(
            message,
            style: AidaType.sans(size: 13, color: AidaColors.cream),
          ),
        ),
      );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AidaColors.espresso,
          content: Text(
            '$feature is coming soon',
            style: AidaType.sans(size: 13, color: AidaColors.cream),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.sizeOf(context).height * 0.38;

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_waveController.value);
          // Cross-fade heroes with the tab; clipper flips via signIn flag.
          return Stack(
            fit: StackFit.expand,
            children: [
              // Heroes sit under the wave sheet.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight + 40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 1 - t,
                      child: Image.asset(
                        'assets/images/auth_coffee_beans.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    Opacity(
                      opacity: t,
                      child: Image.asset(
                        'assets/images/auth_barista.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    // Soft rose wash so the brand stays present over photo.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AidaColors.coffee.withValues(alpha: 0.18),
                            AidaColors.espresso.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form sheet with animated wave top.
              Positioned.fill(
                top: heroHeight - 56,
                child: ClipPath(
                  clipper: AuthWaveClipper(progress: t),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AidaColors.cardWhite,
                      boxShadow: [
                        BoxShadow(
                          color: AidaColors.espresso.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 64, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthTabs(
                              signIn: _signIn,
                              onSignIn: () => _selectTab(true),
                              onSignUp: () => _selectTab(false),
                            ),
                            const SizedBox(height: 28),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child:
                                  _signIn
                                      ? KeyedSubtree(
                                        key: const ValueKey('signIn'),
                                        child: _signInForm(),
                                      )
                                      : KeyedSubtree(
                                        key: const ValueKey('signUp'),
                                        child: _signUpForm(),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _signInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            label: 'Email Address',
            controller: _loginEmail,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Password',
            controller: _loginPassword,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureLogin,
            onToggleObscure: () => setState(() => _obscureLogin = !_obscureLogin),
            textInputAction: TextInputAction.done,
            onFieldSubmit: (_) => _submitLogin(),
          ),
          const SizedBox(height: 28),
          _PillButton(
            label: 'Sign In',
            submitting: _submitting,
            onPressed: _submitting ? null : _submitLogin,
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => showForgotPasswordSheet(context),
              child: Text(
                'Forgot Password?',
                style: AidaType.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AidaColors.espresso,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _OrDivider(),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialCircle(
                icon: Icons.g_mobiledata_rounded,
                onTap: () => _comingSoon('Google sign-in'),
              ),
              const SizedBox(width: 16),
              _SocialCircle(
                icon: Icons.facebook_rounded,
                onTap: () => _comingSoon('Facebook sign-in'),
              ),
              const SizedBox(width: 16),
              _SocialCircle(
                icon: Icons.close_rounded,
                onTap: () => _comingSoon('X sign-in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            label: 'Full name',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: _validateName,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Email Address',
            controller: _signUpEmail,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: validateEmail,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Password',
            controller: _signUpPassword,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureSignUp,
            onToggleObscure:
                () => setState(() => _obscureSignUp = !_obscureSignUp),
            textInputAction: TextInputAction.next,
            validator: validatePassword,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Confirm Password',
            controller: _confirmController,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            onToggleObscure:
                () => setState(() => _obscureConfirm = !_obscureConfirm),
            textInputAction: TextInputAction.done,
            validator: _validateConfirm,
            onFieldSubmit: (_) => _submitSignUp(),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => setState(() => _isStudent = !_isStudent),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _isStudent
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 22,
                    color: _isStudent ? AidaColors.coffee : AidaColors.latte,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "I'm a City University student",
                      style: AidaType.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _PillButton(
            label: 'Sign Up',
            submitting: _submitting,
            onPressed: _submitting ? null : _submitSignUp,
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.signIn,
    required this.onSignIn,
    required this.onSignUp,
  });

  final bool signIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabLabel(
            label: 'Sign In',
            active: signIn,
            onTap: onSignIn,
          ),
        ),
        Expanded(
          child: _TabLabel(
            label: 'Sign Up',
            active: !signIn,
            onTap: onSignUp,
          ),
        ),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: AidaType.serif(
              size: 26,
              color:
                  active
                      ? AidaColors.espresso
                      : AidaColors.textMuted.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 3,
            width: active ? 56 : 0,
            decoration: BoxDecoration(
              color: AidaColors.espresso,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final bool submitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AidaColors.coffee,
          foregroundColor: AidaColors.cardWhite,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child:
            submitting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AidaColors.cardWhite,
                  ),
                )
                : Text(
                  label,
                  style: AidaType.sans(size: 15, weight: FontWeight.w700),
                ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AidaColors.latte.withValues(alpha: 0.9))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: AidaType.sans(size: 12, color: AidaColors.textMuted),
          ),
        ),
        Expanded(child: Divider(color: AidaColors.latte.withValues(alpha: 0.9))),
      ],
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AidaColors.espresso.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Icon(icon, size: 22, color: AidaColors.espresso),
        ),
      ),
    );
  }
}
