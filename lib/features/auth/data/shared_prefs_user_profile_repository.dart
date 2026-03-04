import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';

class SharedPrefsUserProfileRepository implements UserProfileRepository {
  const SharedPrefsUserProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  String _key(String userId) => 'user_profile_$userId';

  @override
  Future<UserProfile> saveProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    final raw = json.encode(profile.toJson());
    await _prefs.setString(_key(userId), raw);
    return profile;
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final raw = _prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final jsonMap = json.decode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }
}
