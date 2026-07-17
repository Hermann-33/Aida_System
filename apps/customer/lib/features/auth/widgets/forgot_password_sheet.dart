import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import 'auth_field.dart';

/// Password reset as a modal bottom sheet — the same pattern as the cart's
/// payment method picker, per explicit request, rather than a full page.
Future<void> showForgotPasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ForgotPasswordSheet(),
  );
}

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final repo = ref.read(memberRepositoryProvider);
    await repo.requestPasswordReset(email: _emailController.text.trim());

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: AidaColors.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child:
              _sent
                  ? _SentConfirmation(email: _emailController.text.trim())
                  : _form(),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AidaColors.latte,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Reset your password',
            style: AidaType.serif(size: 19, color: AidaColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            "Enter your account email and we'll send you a reset link.",
            style: AidaType.sans(size: 13, color: AidaColors.textMuted),
          ),
          const SizedBox(height: 18),
          AuthField(
            label: 'Email',
            controller: _emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: validateEmail,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AidaColors.coffee,
                foregroundColor: AidaColors.cream,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child:
                  _submitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AidaColors.cream,
                        ),
                      )
                      : Text(
                        'Send Reset Link',
                        style: AidaType.sans(size: 15, weight: FontWeight.w700),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AidaColors.success.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 30,
            color: AidaColors.success,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Check your email',
          style: AidaType.serif(size: 19, color: AidaColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'If an account exists for $email, a reset link is on its way.',
          textAlign: TextAlign.center,
          style: AidaType.sans(
            size: 13,
            color: AidaColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AidaColors.textPrimary,
              side: const BorderSide(color: AidaColors.latte),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'Done',
              style: AidaType.sans(size: 14, weight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
