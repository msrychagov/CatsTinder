import 'package:firebase_analytics/firebase_analytics.dart';

import '../domain/auth_analytics.dart';

class FirebaseAuthAnalytics implements AuthAnalytics {
  const FirebaseAuthAnalytics(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logSignInSuccess({required String email}) {
    return _analytics.logEvent(
      name: 'auth_sign_in',
      parameters: const {
        'status': 'success',
      },
    );
  }

  @override
  Future<void> logSignInFailure({
    required String email,
    required String reason,
  }) {
    return _analytics.logEvent(
      name: 'auth_sign_in',
      parameters: {
        'status': 'failure',
        'reason': _normalizeReason(reason),
      },
    );
  }

  @override
  Future<void> logSignUpSuccess({required String email}) {
    return _analytics.logEvent(
      name: 'auth_sign_up',
      parameters: const {
        'status': 'success',
      },
    );
  }

  @override
  Future<void> logSignUpFailure({
    required String email,
    required String reason,
  }) {
    return _analytics.logEvent(
      name: 'auth_sign_up',
      parameters: {
        'status': 'failure',
        'reason': _normalizeReason(reason),
      },
    );
  }

  String _normalizeReason(String reason) {
    final normalized = reason.trim();
    if (normalized.length <= 96) {
      return normalized;
    }
    return normalized.substring(0, 96);
  }
}
