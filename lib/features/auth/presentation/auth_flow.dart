import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/auth_credentials_validator.dart';
import '../domain/auth_user.dart';
import '../domain/usecases/sign_in_use_case.dart';
import '../domain/usecases/sign_up_use_case.dart';
import 'auth_error_message.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';

typedef AuthCompleted = void Function(AuthUser user);

class AuthFlow extends StatefulWidget {
  const AuthFlow({
    super.key,
    required this.validator,
    required this.signIn,
    required this.signUp,
    required this.onAuthenticated,
  });

  final AuthCredentialsValidator validator;
  final SignInUseCase signIn;
  final SignUpUseCase signUp;
  final AuthCompleted onAuthenticated;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _isSignIn = true;

  void _toggleMode() {
    setState(() => _isSignIn = !_isSignIn);
  }

  Future<void> _handleSignIn(String email, String password) async {
    try {
      final user = await widget.signIn(email: email, password: password);
      if (!mounted) {
        return;
      }
      widget.onAuthenticated(user);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  Future<void> _handleSignUp(SignUpFormData formData) async {
    try {
      final user = await widget.signUp(
        email: formData.email,
        password: formData.password,
        profile: formData.toUserProfile(),
      );
      if (!mounted) {
        return;
      }
      widget.onAuthenticated(user);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (error is FirebaseAuthException) {
      debugPrint(
        'FirebaseAuthException code=${error.code}, message=${error.message}',
      );
    } else {
      debugPrint('Auth error: $error');
    }

    final suffix = kDebugMode && error is FirebaseAuthException
        ? '\n[code: ${error.code}]'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${authErrorMessage(error)}$suffix')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isSignIn
        ? SignInPage(
            validator: widget.validator,
            onToggleToSignUp: _toggleMode,
            onSubmit: _handleSignIn,
          )
        : SignUpPage(
            validator: widget.validator,
            onToggleToSignIn: _toggleMode,
            onSubmit: _handleSignUp,
          );
  }
}
