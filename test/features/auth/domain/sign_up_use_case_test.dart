import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_setup_task/features/auth/domain/auth_analytics.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_credentials_validator.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_repository.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_user.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_validation_exception.dart';
import 'package:flutter_setup_task/features/auth/domain/user_profile.dart';
import 'package:flutter_setup_task/features/auth/domain/user_profile_repository.dart';
import 'package:flutter_setup_task/features/auth/domain/usecases/sign_up_use_case.dart';

void main() {
  group('SignUpUseCase', () {
    test('returns user, saves profile and logs success', () async {
      final repository = _FakeAuthRepository();
      final analytics = _FakeAuthAnalytics();
      final userProfileRepository = _FakeUserProfileRepository();
      final useCase = SignUpUseCase(
        repository: repository,
        analytics: analytics,
        validator: AuthCredentialsValidator(),
        userProfileRepository: userProfileRepository,
      );

      final user = await useCase(
        email: '  cat@example.com  ',
        password: '123456',
        profile: _profile(photoPath: '/tmp/avatar.png'),
      );

      expect(user.email, 'cat@example.com');
      expect(repository.lastSignUpEmail, 'cat@example.com');
      expect(userProfileRepository.lastSavedUserId, 'u1');
      expect(userProfileRepository.lastSavedProfile?.photoPath, '/tmp/avatar.png');
      expect(analytics.signUpSuccessCount, 1);
      expect(analytics.signUpFailureCount, 0);
    });

    test('logs failure and rethrows exception when sign up fails', () async {
      final repository = _FakeAuthRepository(shouldFailSignUp: true);
      final analytics = _FakeAuthAnalytics();
      final userProfileRepository = _FakeUserProfileRepository();
      final useCase = SignUpUseCase(
        repository: repository,
        analytics: analytics,
        validator: AuthCredentialsValidator(),
        userProfileRepository: userProfileRepository,
      );

      await expectLater(
        () => useCase(
          email: 'cat@example.com',
          password: '123456',
          profile: _profile(photoPath: '/tmp/avatar.png'),
        ),
        throwsA(isA<StateError>()),
      );

      expect(analytics.signUpSuccessCount, 0);
      expect(analytics.signUpFailureCount, 1);
      expect(userProfileRepository.lastSavedProfile, isNull);
    });

    test('throws validation error when photo is missing', () async {
      final repository = _FakeAuthRepository();
      final analytics = _FakeAuthAnalytics();
      final userProfileRepository = _FakeUserProfileRepository();
      final useCase = SignUpUseCase(
        repository: repository,
        analytics: analytics,
        validator: AuthCredentialsValidator(),
        userProfileRepository: userProfileRepository,
      );

      await expectLater(
        () => useCase(
          email: 'cat@example.com',
          password: '123456',
          profile: _profile(photoPath: ''),
        ),
        throwsA(
          isA<AuthValidationException>().having(
            (error) => error.message,
            'message',
            'Добавьте фото профиля',
          ),
        ),
      );

      expect(repository.lastSignUpEmail, isNull);
      expect(analytics.signUpSuccessCount, 0);
      expect(analytics.signUpFailureCount, 0);
    });
  });
}

UserProfile _profile({required String photoPath}) {
  return UserProfile(
    description: 'Люблю котиков',
    energyLevel: 4,
    intelligence: 5,
    affectionLevel: 4,
    socialNeeds: 3,
    photoPath: photoPath,
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.shouldFailSignUp = false});

  final bool shouldFailSignUp;
  String? lastSignUpEmail;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  Future<AuthUser?> currentUser() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    throw StateError('sign in is not used in this test');
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    if (shouldFailSignUp) {
      throw StateError('sign up failed');
    }
    lastSignUpEmail = email;
    return AuthUser(id: 'u1', email: email);
  }

  @override
  Future<void> signOut() async {}
}

class _FakeAuthAnalytics implements AuthAnalytics {
  int signUpSuccessCount = 0;
  int signUpFailureCount = 0;

  @override
  Future<void> logSignInFailure({
    required String email,
    required String reason,
  }) async {}

  @override
  Future<void> logSignInSuccess({required String email}) async {}

  @override
  Future<void> logSignUpFailure({
    required String email,
    required String reason,
  }) async {
    signUpFailureCount++;
  }

  @override
  Future<void> logSignUpSuccess({required String email}) async {
    signUpSuccessCount++;
  }
}

class _FakeUserProfileRepository implements UserProfileRepository {
  String? lastSavedUserId;
  UserProfile? lastSavedProfile;

  @override
  Future<UserProfile?> getProfile(String userId) async => null;

  @override
  Future<UserProfile> saveProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    lastSavedUserId = userId;
    lastSavedProfile = profile;
    return profile;
  }
}
