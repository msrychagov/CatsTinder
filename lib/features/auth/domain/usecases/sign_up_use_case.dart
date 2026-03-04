import '../auth_analytics.dart';
import '../auth_credentials_validator.dart';
import '../auth_repository.dart';
import '../auth_user.dart';
import '../auth_validation_exception.dart';
import '../user_profile.dart';
import '../user_profile_repository.dart';

class SignUpUseCase {
  const SignUpUseCase({
    required AuthRepository repository,
    required AuthAnalytics analytics,
    required AuthCredentialsValidator validator,
    required UserProfileRepository userProfileRepository,
  })  : _repository = repository,
        _analytics = analytics,
        _validator = validator,
        _userProfileRepository = userProfileRepository;

  final AuthRepository _repository;
  final AuthAnalytics _analytics;
  final AuthCredentialsValidator _validator;
  final UserProfileRepository _userProfileRepository;

  Future<AuthUser> call({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    final normalizedEmail = email.trim();
    _validator.ensureValidCredentials(
      email: normalizedEmail,
      password: password,
    );
    _validateProfile(profile);

    try {
      final user = await _repository.signUp(
        email: normalizedEmail,
        password: password,
      );
      await _userProfileRepository.saveProfile(
        userId: user.id,
        profile: profile,
      );
      await _safeLog(() => _analytics.logSignUpSuccess(email: normalizedEmail));
      return user;
    } on Object catch (error) {
      await _safeLog(
        () => _analytics.logSignUpFailure(
          email: normalizedEmail,
          reason: error.toString(),
        ),
      );
      rethrow;
    }
  }

  void _validateProfile(UserProfile profile) {
    if (profile.photoPath.trim().isEmpty) {
      throw AuthValidationException('Добавьте фото профиля');
    }

    final levels = [
      profile.energyLevel,
      profile.intelligence,
      profile.affectionLevel,
      profile.socialNeeds,
    ];

    final hasOutOfRange = levels.any((value) => value < 1 || value > 5);
    if (hasOutOfRange) {
      throw AuthValidationException(
          'Оценки характеристик должны быть от 1 до 5');
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
