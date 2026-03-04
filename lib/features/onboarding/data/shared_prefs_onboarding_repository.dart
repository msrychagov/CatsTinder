import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_repository.dart';

class SharedPrefsOnboardingRepository implements OnboardingRepository {
  SharedPrefsOnboardingRepository(this._prefs);

  static const _keyCompleted = 'onboarding_completed';

  final SharedPreferences _prefs;

  @override
  Future<bool> isCompleted() async {
    return _prefs.getBool(_keyCompleted) ?? false;
  }

  @override
  Future<void> complete() async {
    await _prefs.setBool(_keyCompleted, true);
  }
}
