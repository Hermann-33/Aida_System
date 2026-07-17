import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';

/// Underline auth field — leading icon + bottom border only, matching the
/// wave-header Sign In / Sign Up reference.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmit,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscureText;

  /// Non-null shows a show/hide eye icon — only relevant for password
  /// fields.
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmit;

  @override
  Widget build(BuildContext context) {
    final underline = UnderlineInputBorder(
      borderSide: BorderSide(
        color: AidaColors.espresso.withValues(alpha: 0.35),
        width: 1.1,
      ),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmit,
      style: AidaType.sans(
        size: 15,
        weight: FontWeight.w500,
        color: AidaColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AidaType.sans(size: 14, color: AidaColors.textMuted),
        floatingLabelStyle: AidaType.sans(
          size: 13,
          weight: FontWeight.w600,
          color: AidaColors.coffee,
        ),
        hintStyle: AidaType.sans(size: 14, color: AidaColors.textMuted),
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon:
            icon == null
                ? null
                : Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(icon, size: 20, color: AidaColors.espresso),
                ),
        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        suffixIcon:
            onToggleObscure == null
                ? null
                : IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 19,
                    color: AidaColors.textMuted,
                  ),
                ),
        border: underline,
        enabledBorder: underline,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AidaColors.coffee, width: 1.6),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AidaColors.error, width: 1.2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AidaColors.error, width: 1.4),
        ),
        errorStyle: AidaType.sans(size: 11.5, color: AidaColors.error),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Enter your password';
  if (v.length < 6) return 'At least 6 characters';
  return null;
}
