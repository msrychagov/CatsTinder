import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_setup_task/features/auth/domain/auth_credentials_validator.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_validation_exception.dart';

void main() {
  group('AuthCredentialsValidator', () {
    final validator = AuthCredentialsValidator();

    test('validates email and password fields', () {
      expect(validator.validateEmail(''), 'Введите почту');
      expect(validator.validateEmail('wrong-email'), 'Некорректный email');
      expect(validator.validatePassword('123'), 'Минимум 6 символов');
      expect(validator.validateEmail('cat@example.com'), isNull);
      expect(validator.validatePassword('123456'), isNull);
    });

    test('throws validation exception when credentials are invalid', () {
      expect(
        () => validator.ensureValidCredentials(
          email: 'cat@example.com',
          password: '123',
        ),
        throwsA(isA<AuthValidationException>()),
      );
    });
  });
}
