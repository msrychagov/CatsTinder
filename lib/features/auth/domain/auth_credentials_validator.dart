import 'auth_validation_exception.dart';

class AuthCredentialsValidator {
  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Введите почту';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return 'Некорректный email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Введите пароль';
    }
    if (password.length < 6) {
      return 'Минимум 6 символов';
    }
    return null;
  }

  void ensureValidCredentials({
    required String email,
    required String password,
  }) {
    final emailError = validateEmail(email);
    if (emailError != null) {
      throw AuthValidationException(emailError);
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      throw AuthValidationException(passwordError);
    }
  }
}
