import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Thin route that opens the unified auth screen on the Sign Up tab.
/// Prefer navigating with [LoginScreen.initialSignUp] directly when possible.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialSignUp: true);
  }
}
