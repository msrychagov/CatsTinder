abstract class AuthAnalytics {
  Future<void> logSignInSuccess({required String email});

  Future<void> logSignInFailure({
    required String email,
    required String reason,
  });

  Future<void> logSignUpSuccess({required String email});

  Future<void> logSignUpFailure({
    required String email,
    required String reason,
  });
}
