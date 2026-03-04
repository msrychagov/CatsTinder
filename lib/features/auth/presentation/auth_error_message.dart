import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_validation_exception.dart';

String authErrorMessage(Object error) {
  if (error is AuthValidationException) {
    return error.message;
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-disabled':
        return 'Пользователь отключен';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'weak-password':
        return 'Слишком простой пароль';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      default:
        return error.message ?? 'Ошибка авторизации';
    }
  }

  return 'Не удалось выполнить авторизацию. Попробуйте снова';
}
