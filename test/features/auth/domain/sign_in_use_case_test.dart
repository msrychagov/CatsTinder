import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_setup_task/features/auth/domain/auth_analytics.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_credentials_validator.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_repository.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_user.dart';
import 'package:flutter_setup_task/features/auth/domain/usecases/sign_in_use_case.dart';

void main() {
  group('SignInUseCase', () {
    test('returns user and logs success', () async {
      final repository = _FakeAuthRepository();
      final analytics = _FakeAuthAnalytics();
      final useCase = SignInUseCase(
        repository: repository,
        analytics: analytics,
        validator: AuthCredentialsValidator(),
      );

      final user = await useCase(
        email: '  cat@example.com  ',
        password: '123456',
      );

      expect(user.email, 'cat@example.com');
      expect(repository.lastSignInEmail, 'cat@example.com');
      expect(analytics.signInSuccessCount, 1);
      expect(analytics.signInFailureCount, 0);
    });

    test('logs failure and rethrows exception', () async {
      final repository = _FakeAuthRepository(shouldFailSignIn: true);
      final analytics = _FakeAuthAnalytics();
      final useCase = SignInUseCase(
        repository: repository,
        analytics: analytics,
        validator: AuthCredentialsValidator(),
      );

      await expectLater(
        () => useCase(email: 'cat@example.com', password: '123456'),
        throwsA(isA<StateError>()),
      );
      expect(analytics.signInSuccessCount, 0);
      expect(analytics.signInFailureCount, 1);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.shouldFailSignIn = false});

  final bool shouldFailSignIn;
  String? lastSignInEmail;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  Future<AuthUser?> currentUser() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (shouldFailSignIn) {
      throw StateError('sign in failed');
    }
    lastSignInEmail = email;
    return AuthUser(id: 'u1', email: email);
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class _FakeAuthAnalytics implements AuthAnalytics {
  int signInSuccessCount = 0;
  int signInFailureCount = 0;

  @override
  Future<void> logSignInFailure({
    required String email,
    required String reason,
  }) async {
    signInFailureCount++;
  }

  @override
  Future<void> logSignInSuccess({required String email}) async {
    signInSuccessCount++;
  }

  @override
  Future<void> logSignUpFailure({
    required String email,
    required String reason,
  }) async {}

  @override
  Future<void> logSignUpSuccess({required String email}) async {}
}
