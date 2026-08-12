import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import 'widgets/auth_field.dart';
import 'widgets/forgot_password_sheet.dart';

/// Customer email/password authentication backed by Supabase Auth.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialSignUp = false});

  final bool initialSignUp;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _signIn;
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
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _nameController.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _requiredPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
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

  Future<void> _submitLogin() async {
    if (!(_signInFormKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final result = await ref.read(memberRepositoryProvider).logIn(
          email: _loginEmail.text.trim(),
          password: _loginPassword.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Ok():
        ref.read(authStateProvider.notifier).logIn();
      case Err(:final failure):
        _showMessage(failure.message, error: true);
    }
  }

  Future<void> _submitSignUp() async {
    if (!(_signUpFormKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final result = await ref.read(memberRepositoryProvider).signUp(
          name: _nameController.text.trim(),
          email: _signUpEmail.text.trim(),
          password: _signUpPassword.text,
          isStudent: _isStudent,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Ok():
        // Supabase may create an immediate session or require email
        // confirmation. In either case the auth service, not this widget,
        // decides whether AuthGate can enter the app.
        ref.read(authStateProvider.notifier).logIn();
        if (!ref.read(authStateProvider)) {
          _showMessage('Account created. Confirm your email, then sign in.');
          setState(() => _signIn = true);
        }
      case Err(:final failure):
        _showMessage(failure.message, error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AidaColors.error : AidaColors.espresso,
          content: Text(
            message,
            style: AidaType.sans(size: 13, color: AidaColors.cream),
          ),
        ),
      );
  }

  void _comingSoon(String feature) =>
      _showMessage('$feature is coming soon');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: SizedBox(
                      height: 230,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Image.asset(
                              _signIn
                                  ? 'assets/images/auth_coffee_beans.png'
                                  : 'assets/images/auth_barista.png',
                              key: ValueKey(_signIn),
                              fit: BoxFit.cover,
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AidaColors.espresso.withValues(alpha: 0.62),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 22,
                            right: 22,
                            bottom: 20,
                            child: Text(
                              _signIn ? 'Welcome back' : 'Join Aida Café',
                              style: AidaType.serif(
                                size: 30,
                                color: AidaColors.cream,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AuthTabs(
                    signIn: _signIn,
                    onChanged: (value) => setState(() => _signIn = value),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _signIn ? _signInForm() : _signUpForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        key: const ValueKey('sign-in-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            label: 'Email Address',
            controller: _loginEmail,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: validateEmail,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Password',
            controller: _loginPassword,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureLogin,
            onToggleObscure: () =>
                setState(() => _obscureLogin = !_obscureLogin),
            textInputAction: TextInputAction.done,
            validator: _requiredPassword,
            onFieldSubmit: (_) => _submitLogin(),
          ),
          const SizedBox(height: 24),
          _SubmitButton(
            label: 'Sign In',
            submitting: _submitting,
            onPressed: _submitLogin,
          ),
          TextButton(
            onPressed: () => showForgotPasswordSheet(context),
            child: const Text('Forgot Password?'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(
                label: 'Google',
                onTap: () => _comingSoon('Google sign-in'),
              ),
              const SizedBox(width: 10),
              _SocialButton(
                label: 'Facebook',
                onTap: () => _comingSoon('Facebook sign-in'),
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
        key: const ValueKey('sign-up-form'),
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
            onToggleObscure: () =>
                setState(() => _obscureSignUp = !_obscureSignUp),
            textInputAction: TextInputAction.next,
            validator: validatePassword,
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Confirm Password',
            controller: _confirmController,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            onToggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            textInputAction: TextInputAction.done,
            validator: _validateConfirm,
            onFieldSubmit: (_) => _submitSignUp(),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: _isStudent,
            onChanged: (value) => setState(() => _isStudent = value ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: AidaColors.coffee,
            title: Text(
              "I'm a City University student",
              style: AidaType.sans(size: 13, weight: FontWeight.w600),
            ),
            subtitle: Text(
              'Student benefits remain pending until admin verification.',
              style: AidaType.sans(size: 11, color: AidaColors.textMuted),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          _SubmitButton(
            label: 'Sign Up',
            submitting: _submitting,
            onPressed: _submitSignUp,
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.signIn, required this.onChanged});

  final bool signIn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('Sign In')),
        ButtonSegment(value: false, label: Text('Sign Up')),
      ],
      selected: {signIn},
      onSelectionChanged: (value) => onChanged(value.first),
      showSelectedIcon: false,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: submitting ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AidaColors.coffee,
        foregroundColor: AidaColors.cream,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: submitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AidaColors.cream,
              ),
            )
          : Text(label),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}
