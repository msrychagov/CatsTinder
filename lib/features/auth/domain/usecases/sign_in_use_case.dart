import '../auth_analytics.dart';
import '../auth_credentials_validator.dart';
import '../auth_repository.dart';
import '../auth_user.dart';

class SignInUseCase {
  const SignInUseCase({
    required AuthRepository repository,
    required AuthAnalytics analytics,
    required AuthCredentialsValidator validator,
  })  : _repository = repository,
        _analytics = analytics,
        _validator = validator;

  final AuthRepository _repository;
  final AuthAnalytics _analytics;
  final AuthCredentialsValidator _validator;

  Future<AuthUser> call({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    _validator.ensureValidCredentials(
        email: normalizedEmail, password: password);

    try {
      final user = await _repository.signIn(
        email: normalizedEmail,
        password: password,
      );
      await _safeLog(() => _analytics.logSignInSuccess(email: normalizedEmail));
      return user;
    } on Object catch (error) {
      await _safeLog(
        () => _analytics.logSignInFailure(
          email: normalizedEmail,
          reason: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> _safeLog(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Ignore analytics failures so they do not break auth flow.
    }
  }
}
