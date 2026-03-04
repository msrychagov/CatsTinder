import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_setup_task/features/auth/domain/auth_analytics.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_credentials_validator.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_repository.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_user.dart';
import 'package:flutter_setup_task/features/auth/domain/user_profile.dart';
import 'package:flutter_setup_task/features/auth/domain/user_profile_repository.dart';
import 'package:flutter_setup_task/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:flutter_setup_task/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:flutter_setup_task/features/auth/presentation/auth_flow.dart';
import 'package:flutter_setup_task/features/auth/presentation/sign_in_page.dart';

void main() {
  testWidgets('shows validation errors for invalid sign in form', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignInPage(
          validator: AuthCredentialsValidator(),
          onToggleToSignUp: () {},
          onSubmit: (_, __) async {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('sign_in_submit_button')));
    await tester.pump();

    expect(find.text('Введите почту'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });

  testWidgets('auth flow calls callback on successful sign in', (tester) async {
    final repository = _FakeAuthRepository();
    final analytics = _NoopAuthAnalytics();
    final userProfileRepository = _InMemoryUserProfileRepository();
    final validator = AuthCredentialsValidator();

    AuthUser? authenticatedUser;

    await tester.pumpWidget(
      MaterialApp(
        home: AuthFlow(
          validator: validator,
          signIn: SignInUseCase(
            repository: repository,
            analytics: analytics,
            validator: validator,
          ),
          signUp: SignUpUseCase(
            repository: repository,
            analytics: analytics,
            validator: validator,
            userProfileRepository: userProfileRepository,
          ),
          onAuthenticated: (user) {
            authenticatedUser = user;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('sign_in_email_field')),
      'cat@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign_in_password_field')),
      '123456',
    );

    await tester.tap(find.byKey(const Key('sign_in_submit_button')));
    await tester.pumpAndSettle();

    expect(authenticatedUser?.email, 'cat@example.com');
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  Future<AuthUser?> currentUser() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    return AuthUser(id: '42', email: email);
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    return AuthUser(id: '43', email: email);
  }

  @override
  Future<void> signOut() async {}
}

class _NoopAuthAnalytics implements AuthAnalytics {
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
  }) async {}

  @override
  Future<void> logSignUpSuccess({required String email}) async {}
}

class _InMemoryUserProfileRepository implements UserProfileRepository {
  final Map<String, UserProfile> _profiles = {};

  @override
  Future<UserProfile?> getProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<UserProfile> saveProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    _profiles[userId] = profile;
    return profile;
  }
}
